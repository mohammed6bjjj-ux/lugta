import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'profile_strings.dart';

/// شاشة الإشعارات — مقسمة حسب الزمن (اليوم / هذا الأسبوع / أقدم).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _markReadBestEffort(String notificationId) async {
    try {
      await session.markNotificationRead(notificationId);
    } catch (_) {
      // Reading the linked content must not be blocked by a mark-read failure.
      // The session restores the unread state, so the user can retry later.
    }
  }

  Future<void> _markAllReadBestEffort() async {
    try {
      await session.markAllNotificationsRead();
    } catch (_) {
      // The session restores the unread state after a repository failure.
    }
  }

  void _open(AppNotification notification) {
    unawaited(_markReadBestEffort(notification.id));
    if (!mounted) return;

    final targetType = notification.targetType?.trim().toLowerCase();
    if (targetType == 'referral' ||
        notification.type == NotificationType.referral) {
      Navigator.pushNamed(context, Routes.referrals);
      return;
    }
    if (notification.targetPromotionId != null ||
        targetType == 'promotion' ||
        targetType == 'reward' ||
        notification.type == NotificationType.promotion ||
        notification.type == NotificationType.reward) {
      Navigator.pushNamed(context, Routes.promotions);
      return;
    }

    if (notification.targetOrderId != null) {
      final order = session.orderById(notification.targetOrderId!);
      if (order != null) {
        Navigator.pushNamed(context, Routes.orderDetail, arguments: order);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ProfileStrings.linkedOrderNotFound)),
        );
      }
      return;
    }

    if (notification.targetProductId != null) {
      final product = session.productById(notification.targetProductId!);
      if (product != null) {
        Navigator.pushNamed(context, Routes.productDetail, arguments: product);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final unread = session.unreadNotificationsCount;
        final items =
            session.notifications
                .where((notification) => notification.showInbox)
                .toList(growable: false)
              ..sort((a, b) => b.at.compareTo(a.at));

        final now = DateTime.now();
        final today = <AppNotification>[];
        final thisWeek = <AppNotification>[];
        final older = <AppNotification>[];
        for (final n in items) {
          final bucket = switch (now.difference(n.at)) {
            Duration(inHours: < 24) => today,
            Duration(inDays: < 7) => thisWeek,
            _ => older,
          };
          bucket.add(n);
        }

        final sections = <(String, List<AppNotification>)>[
          (ProfileStrings.sectionToday, today),
          (ProfileStrings.sectionThisWeek, thisWeek),
          (ProfileStrings.sectionOlder, older),
        ].where((s) => s.$2.isNotEmpty).toList();

        // قائمة مسطّحة بدخول متدرج موحّد عبر الأقسام.
        final children = <Widget>[];
        var entranceIndex = 0;
        for (final (title, notifications) in sections) {
          children.add(
            Entrance(
              index: entranceIndex++,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _SectionCapsule(title: title),
                ),
              ),
            ),
          );
          for (final n in notifications) {
            children.add(
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Entrance(
                  index: entranceIndex++,
                  child: _NotificationTile(
                    notification: n,
                    onTap: () => _open(n),
                  ),
                ),
              ),
            );
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(ProfileStrings.notifications),
            actions: [
              if (MediaQuery.sizeOf(context).width >= 480)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: TextButton(
                    key: const ValueKey('notifications_mark_all_read'),
                    onPressed: unread == 0
                        ? null
                        : () => unawaited(_markAllReadBestEffort()),
                    child: Text(ProfileStrings.markAllRead),
                  ),
                )
              else
                IconButton(
                  key: const ValueKey('notifications_mark_all_read'),
                  onPressed: unread == 0
                      ? null
                      : () => unawaited(_markAllReadBestEffort()),
                  tooltip: ProfileStrings.markAllRead,
                  icon: const Icon(Icons.done_all_rounded),
                ),
            ],
          ),
          body: SessionRefreshIndicator(
            onRefresh: session.refreshNotifications,
            child: items.isEmpty
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: ProfileStrings.notificationsEmptyTitle,
                          subtitle: ProfileStrings.notificationsEmptySubtitle,
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    children: children,
                  ),
          ),
        );
      },
    );
  }
}

/// عنوان زمني على شكل كبسولة صغيرة.
class _SectionCapsule extends StatelessWidget {
  const _SectionCapsule({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralChip,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = notification;

    return AppCard(
      onTap: onTap,
      // غير المقروء بخلفية ذهبية خفيفة جداً.
      color: n.isRead
          ? AppColors.surface
          : Color.alphaBlend(
              AppColors.goldSoft.withValues(alpha: .45),
              Colors.white,
            ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: n.type.color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(n.type.icon, size: 22, color: n.type.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: n.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!n.isRead) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: _PulsingDot(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  n.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        timeAgo(n.at),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// نقطة ذهبية نابضة لغير المقروء — نبض مستمر بـ AnimatedContainer.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _expanded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          onEnd: () {
            if (mounted) setState(() => _expanded = !_expanded);
          },
          width: _expanded ? 10 : 7,
          height: _expanded ? 10 : 7,
          decoration: BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: _expanded ? .45 : .15),
                blurRadius: _expanded ? 10 : 4,
                spreadRadius: _expanded ? 2 : 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
