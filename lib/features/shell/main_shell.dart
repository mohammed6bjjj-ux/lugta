import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_settings.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../data/notification_deep_link.dart';
import '../../data/services/device_token_registrar.dart';
import '../../data/session.dart';
import '../../l10n/core_strings.dart';
import '../catalog/home_screen.dart';
import '../catalog/products_screen.dart';
import '../orders/orders_screen.dart';
import '../promotions/promotion_notification_popup.dart';
import '../profile/profile_screen.dart';
import '../wallet/wallet_screen.dart';

/// الحاوية الرئيسية بعد تسجيل الدخول: 5 تبويبات
/// بشريط تنقل عائم زجاجي حديث (Floating glass pill).
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.deviceTokens});

  final DeviceTokenRegistrar? deviceTokens;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  StreamSubscription<PushOpenEvent>? _pushOpenSubscription;
  final List<PushOpenEvent> _queuedPushOpens = [];
  bool _pushNavigationScheduled = false;
  bool _pushNavigationInFlight = false;
  VoidCallback? _popupWaiter;
  bool _popupShownThisShell = false;
  bool _popupDialogOpen = false;

  late final List<Widget?> _tabs = <Widget?>[
    const HomeScreen(),
    null,
    null,
    null,
    null,
  ];

  Widget _createTab(int index) => switch (index) {
    0 => const HomeScreen(),
    1 => const ProductsScreen(),
    2 => const OrdersScreen(),
    3 => const WalletScreen(),
    4 => const ProfileScreen(),
    _ => const SizedBox.shrink(),
  };

  void _selectTab(int index) {
    if (_index == index) return;
    setState(() {
      _tabs[index] ??= _createTab(index);
      _index = index;
    });
  }

  @override
  void initState() {
    super.initState();
    final deviceTokens = widget.deviceTokens ?? appBackend.deviceTokens;
    // Subscribe before draining the terminated-state queue so a platform event
    // arriving between those operations cannot be lost.
    _pushOpenSubscription = deviceTokens.notificationOpens.listen(
      _queuePushOpen,
    );
    PushOpenEvent? pending;
    while ((pending = deviceTokens.takePendingNotificationOpen()) != null) {
      _queuePushOpen(pending!);
    }
    _scheduleNotificationPopup();
  }

  /// Wait for the durable server notification instead of choosing a random
  /// catalog item. An explicit push tap always wins over an automatic popup.
  void _scheduleNotificationPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void attempt() {
        if (!mounted) return;
        if (_queuedPushOpens.isNotEmpty || _pushNavigationInFlight) {
          session.removeListener(attempt);
          return;
        }
        if (_popupShownThisShell || _popupDialogOpen) {
          session.removeListener(attempt);
          return;
        }
        final notification = session.nextPopupNotification;
        if (notification == null) return;
        session.removeListener(attempt);
        _popupShownThisShell = true;
        unawaited(_showNotificationPopup(notification));
      }

      session.addListener(attempt);
      _popupWaiter = attempt;
      attempt();
    });
  }

  Future<void> _showNotificationPopup(AppNotification notification) async {
    await session.markNotificationPopupSeen(notification.id);
    if (!mounted || _queuedPushOpens.isNotEmpty) return;
    _popupDialogOpen = true;
    final open = await showPromotionNotificationPopup(context, notification);
    _popupDialogOpen = false;
    if (!open || !mounted || _queuedPushOpens.isNotEmpty) return;
    try {
      await session.markNotificationRead(notification.id);
    } catch (_) {
      // Opening the linked content is more important than read-state sync.
    }
    if (!mounted) return;
    await _openNotificationTarget(notification);
  }

  Future<void> _openNotificationTarget(AppNotification notification) async {
    final type = notification.targetType?.trim().toLowerCase();
    if (type == 'referral' || notification.type == NotificationType.referral) {
      _refreshPromotionEngagement(includeReferralSummary: true);
      await Navigator.of(context).pushNamed(Routes.referrals);
      return;
    }
    if (notification.targetPromotionId != null ||
        type == 'promotion' ||
        type == 'reward' ||
        notification.type == NotificationType.promotion ||
        notification.type == NotificationType.reward) {
      _refreshPromotionEngagement();
      await Navigator.of(context).pushNamed(Routes.promotions);
      return;
    }

    final deepTarget = parseTrustedNotificationDeepLink(notification.deepLink);
    final orderId =
        notification.targetOrderId ??
        (deepTarget?.kind == NotificationDeepLinkKind.order
            ? deepTarget?.entityId
            : null);
    if (orderId != null) {
      try {
        final order = await session.refreshOrderById(orderId);
        if (mounted) {
          await Navigator.of(
            context,
          ).pushNamed(Routes.orderDetail, arguments: order);
          return;
        }
      } catch (_) {
        // Missing, offline or RLS-denied targets use the durable inbox fallback.
      }
    }

    final productId =
        notification.targetProductId ??
        (deepTarget?.kind == NotificationDeepLinkKind.product
            ? deepTarget?.entityId
            : null);
    if (productId != null) {
      try {
        final product = await session.refreshProductById(productId);
        if (mounted) {
          await Navigator.of(
            context,
          ).pushNamed(Routes.productDetail, arguments: product);
          return;
        }
      } catch (_) {
        // The durable notifications page remains a safe fallback.
      }
    }

    if (!mounted) return;
    if (deepTarget?.kind == NotificationDeepLinkKind.referrals) {
      _refreshPromotionEngagement(includeReferralSummary: true);
      await Navigator.of(context).pushNamed(Routes.referrals);
      return;
    }
    if (deepTarget?.kind == NotificationDeepLinkKind.promotions) {
      _refreshPromotionEngagement();
      await Navigator.of(context).pushNamed(Routes.promotions);
      return;
    }
    if (deepTarget?.kind == NotificationDeepLinkKind.products) {
      await Navigator.of(context).pushNamed(Routes.products);
      return;
    }
    await Navigator.of(context).pushNamed(Routes.notifications);
  }

  void _refreshPromotionEngagement({bool includeReferralSummary = false}) {
    unawaited(
      session
          .refreshPromotionEngagement(
            includeReferralSummary: includeReferralSummary,
          )
          .catchError((_) {}),
    );
  }

  void _queuePushOpen(PushOpenEvent event) {
    if (!mounted) return;
    if (_popupDialogOpen) {
      _popupDialogOpen = false;
      Navigator.of(context, rootNavigator: true).pop(false);
    }
    // Keep only the newest explicit tap while a target is being resolved. This
    // prevents a burst of OS callbacks from stacking several detail screens.
    _queuedPushOpens
      ..clear()
      ..add(event);
    _schedulePushNavigation();
  }

  void _schedulePushNavigation() {
    if (_pushNavigationScheduled || _pushNavigationInFlight || !mounted) return;
    _pushNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pushNavigationScheduled = false;
      if (!mounted) return;
      unawaited(_drainPushTargets());
    });
  }

  Future<void> _drainPushTargets() async {
    if (_pushNavigationInFlight) return;
    _pushNavigationInFlight = true;
    try {
      while (mounted && _queuedPushOpens.isNotEmpty) {
        // Several rapid taps are coalesced; the most recent user action wins.
        final event = _queuedPushOpens.removeLast();
        _queuedPushOpens.clear();

        // MainShell is the approved-account destination, but verify the live
        // state before and after every network boundary.
        if (!session.isAuthenticated ||
            session.seller.status != AccountStatus.approved) {
          _queuedPushOpens.clear();
          return;
        }
        if (!mounted) return;
        final navigator = Navigator.of(context);

        final durable = event.notificationId == null
            ? null
            : session.notificationById(event.notificationId!);
        final targetType = (event.targetType ?? durable?.targetType)
            ?.trim()
            .toLowerCase();
        final targetPromotionId =
            event.promotionId ?? durable?.targetPromotionId;
        final deepTarget = parseTrustedNotificationDeepLink(
          event.deepLink ?? durable?.deepLink,
        );
        if (durable != null) {
          unawaited(
            session.markNotificationRead(durable.id).catchError((_) {}),
          );
        }
        if (targetType == 'referral' ||
            durable?.type == NotificationType.referral) {
          _refreshPromotionEngagement(includeReferralSummary: true);
          await navigator.pushNamed(Routes.referrals);
          continue;
        }
        if (targetPromotionId != null ||
            targetType == 'promotion' ||
            targetType == 'reward' ||
            durable?.type == NotificationType.promotion ||
            durable?.type == NotificationType.reward) {
          _refreshPromotionEngagement();
          await navigator.pushNamed(Routes.promotions);
          continue;
        }

        Order? order;
        Product? product;
        final explicitOrderId = event.orderId ?? durable?.targetOrderId;
        final explicitProductId = event.productId ?? durable?.targetProductId;
        if (explicitOrderId == null && explicitProductId == null) {
          if (deepTarget?.kind == NotificationDeepLinkKind.referrals) {
            _refreshPromotionEngagement(includeReferralSummary: true);
            await navigator.pushNamed(Routes.referrals);
            continue;
          }
          if (deepTarget?.kind == NotificationDeepLinkKind.promotions) {
            _refreshPromotionEngagement();
            await navigator.pushNamed(Routes.promotions);
            continue;
          }
          if (deepTarget?.kind == NotificationDeepLinkKind.products) {
            await navigator.pushNamed(Routes.products);
            continue;
          }
        }
        final orderId =
            explicitOrderId ??
            (deepTarget?.kind == NotificationDeepLinkKind.order
                ? deepTarget?.entityId
                : null);
        final productId =
            explicitProductId ??
            (deepTarget?.kind == NotificationDeepLinkKind.product
                ? deepTarget?.entityId
                : null);
        if (orderId != null) {
          try {
            order = await session.refreshOrderById(orderId);
          } catch (_) {
            // Missing/RLS-denied/offline targets fall back to the durable list;
            // never open the potentially stale cached order snapshot.
          }
        }
        if (order == null && productId != null) {
          try {
            product = await session.refreshProductById(productId);
          } catch (_) {
            // The durable notifications page remains a safe fallback.
          }
        }

        if (!mounted ||
            !session.isAuthenticated ||
            session.seller.status != AccountStatus.approved) {
          return;
        }

        // A newer tap arrived while the entity was fetched. Discard this
        // resolved target and process the latest one instead of stacking pages.
        if (_queuedPushOpens.isNotEmpty) continue;

        if (order != null) {
          await Navigator.of(
            context,
          ).pushNamed(Routes.orderDetail, arguments: order);
          continue;
        }

        if (product != null) {
          await Navigator.of(
            context,
          ).pushNamed(Routes.productDetail, arguments: product);
          continue;
        }

        await Navigator.of(context).pushNamed(Routes.notifications);
      }
    } finally {
      _pushNavigationInFlight = false;
      if (mounted && _queuedPushOpens.isNotEmpty) _schedulePushNavigation();
    }
  }

  /*
    Push targets intentionally do not use session.orderById/productById here.
    Notifications can arrive after a server-side status, price, stock, or media
    change; opening a cached object would make the detail screen stale.
  */

  @override
  void dispose() {
    unawaited(_pushOpenSubscription?.cancel());
    if (_popupWaiter != null) session.removeListener(_popupWaiter!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // Keep every tab mounted so switching sections preserves scroll/filter
      // state and does not rebuild all network-backed media from scratch. Tabs
      // are created lazily, so the first frame does not initialize four hidden
      // pages or trigger their screen-specific refreshes.
      body: IndexedStack(
        index: _index,
        children: [for (final tab in _tabs) tab ?? const SizedBox.shrink()],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
        ),
        // الغلاف الزجاجي داخل المستمع نفسه: أي تغيير في الإعدادات
        // (لغة/داكن) أو الجلسة يعيد رسم الشريط كاملاً بلوحته الصحيحة.
        child: ListenableBuilder(
          listenable: Listenable.merge([session, appSettings]),
          builder: (context, _) {
            final activeOrders = session.orders
                .where((o) => !o.status.isTerminal)
                .length;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.floating,
              ),
              child: FrostedPanel(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm - 2,
                    vertical: AppSpacing.xs + 1,
                  ),
                  child: Row(
                    children: [
                      _NavItem(
                        key: const ValueKey('home_nav_tab'),
                        icon: Icons.storefront_outlined,
                        activeIcon: Icons.storefront_rounded,
                        label: CoreStrings.tabHome,
                        selected: _index == 0,
                        onTap: () => _selectTab(0),
                      ),
                      _NavItem(
                        key: const ValueKey('products_nav_tab'),
                        icon: Icons.grid_view_outlined,
                        activeIcon: Icons.grid_view_rounded,
                        label: CoreStrings.tabProducts,
                        selected: _index == 1,
                        onTap: () => _selectTab(1),
                      ),
                      _NavItem(
                        key: const ValueKey('orders_nav_tab'),
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long_rounded,
                        label: CoreStrings.tabOrders,
                        selected: _index == 2,
                        badgeCount: activeOrders,
                        onTap: () => _selectTab(2),
                      ),
                      _NavItem(
                        key: const ValueKey('wallet_nav_tab'),
                        icon: Icons.account_balance_wallet_outlined,
                        activeIcon: Icons.account_balance_wallet_rounded,
                        label: CoreStrings.tabWallet,
                        selected: _index == 3,
                        onTap: () => _selectTab(3),
                      ),
                      _NavItem(
                        key: const ValueKey('profile_nav_tab'),
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: CoreStrings.tabProfile,
                        selected: _index == 4,
                        badgeCount: session.unreadNotificationsCount,
                        onTap: () => _selectTab(4),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Pressable(
        onTap: onTap,
        scale: .93,
        child: AnimatedContainer(
          duration: AppDurations.base,
          curve: AppCurves.emphasized,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.selectedNavPill : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badgeCount > 0,
                label: Text('$badgeCount', style: const TextStyle(fontSize: 9)),
                backgroundColor: AppColors.gold,
                textColor: Colors.white,
                child: AnimatedSwitcher(
                  duration: AppDurations.fast,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    selected ? activeIcon : icon,
                    key: ValueKey(selected),
                    size: 21,
                    color: selected ? AppColors.gold : AppColors.textSecondary,
                  ),
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: AppDurations.fast,
                style: theme.textTheme.labelSmall!.copyWith(
                  fontSize: 10,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? AppColors.onSelectedNavPill
                      : AppColors.textSecondary,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, maxLines: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
