import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_settings.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../data/services/device_token_registrar.dart';
import '../../data/session.dart';
import '../../l10n/core_strings.dart';
import '../catalog/home_screen.dart';
import '../catalog/new_arrivals_promo.dart';
import '../catalog/products_screen.dart';
import '../orders/orders_screen.dart';
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
  VoidCallback? _promoWaiter;

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
    _schedulePromo();
  }

  /// The catalog usually lands a moment after the shell mounts, so wait for it
  /// instead of checking once and giving up. A push notification that opens a
  /// specific screen always wins — interrupting that with an ad would hijack a
  /// deliberate tap.
  void _schedulePromo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void attempt() {
        if (!mounted) return;
        if (_queuedPushOpens.isNotEmpty || _pushNavigationInFlight) {
          session.removeListener(attempt);
          return;
        }
        if (session.products.isEmpty) return;
        session.removeListener(attempt);
        unawaited(NewArrivalsPromo.maybeShow(context));
      }

      session.addListener(attempt);
      _promoWaiter = attempt;
      attempt();
    });
  }

  void _queuePushOpen(PushOpenEvent event) {
    if (!mounted) return;
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

        Order? order;
        Product? product;
        if (event.orderId != null) {
          try {
            order = await session.refreshOrderById(event.orderId!);
          } catch (_) {
            // Missing/RLS-denied/offline targets fall back to the durable list;
            // never open the potentially stale cached order snapshot.
          }
        }
        if (order == null && event.productId != null) {
          try {
            product = await session.refreshProductById(event.productId!);
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
    if (_promoWaiter != null) session.removeListener(_promoWaiter!);
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
