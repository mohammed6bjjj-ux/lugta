import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import 'engagement_strings.dart';

Future<bool> showPromotionNotificationPopup(
  BuildContext context,
  AppNotification notification,
) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: EngagementStrings.close,
    barrierColor: Colors.black.withValues(alpha: .52),
    transitionDuration: AppDurations.base,
    pageBuilder: (_, _, _) => _PromotionPopup(notification: notification),
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppCurves.emphasized,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
  return result ?? false;
}

class _PromotionPopup extends StatelessWidget {
  const _PromotionPopup({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final referral =
        notification.type == NotificationType.referral ||
        notification.targetType?.toLowerCase() == 'referral';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: AppColors.goldSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            referral
                                ? Icons.group_add_outlined
                                : Icons.redeem_outlined,
                            color: AppColors.goldDark,
                            size: 29,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        notification.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        notification.body,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.65,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        key: const ValueKey('promotion_popup_open'),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          referral
                              ? EngagementStrings.viewReferrals
                              : EngagementStrings.viewOffer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        key: const ValueKey('promotion_popup_close'),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(EngagementStrings.close),
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  top: AppSpacing.sm,
                  end: AppSpacing.sm,
                  child: IconButton(
                    tooltip: EngagementStrings.close,
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
