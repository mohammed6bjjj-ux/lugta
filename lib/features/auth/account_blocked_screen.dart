import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/external_actions.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/session.dart';
import 'auth_navigation.dart';
import 'auth_strings.dart';

/// شاشة الحساب المرفوض/المحظور — تعرض السبب وخيارات الدعم والخروج.
class AccountBlockedScreen extends StatelessWidget {
  const AccountBlockedScreen({
    super.key,
    required this.isRejected,
    required this.reason,
  });

  /// true = طلب التسجيل مرفوض، false = حساب فعّال تم حظره.
  final bool isRejected;
  final String reason;

  Future<void> _contactSupport(BuildContext context) async {
    final opened = await launchWhatsApp(session.supportWhatsapp);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthStrings.contactAppUnavailable)),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await session.signOut();
    } catch (_) {
      // Remote revocation failure must not keep local account data visible.
    }
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
  }

  Future<void> _recheckStatus(BuildContext context) async {
    await session.refreshAllData();
    if (!context.mounted) return;
    final stillOnThisState = isRejected
        ? session.destination == SessionDestination.rejected
        : session.destination == SessionDestination.blocked;
    if (!stillOnThisState) openAuthenticatedDestination(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // العنوان والوصف بحسب حالة الحساب (Record + switch expression).
    final (title, subtitle) = switch (isRejected) {
      true => (AuthStrings.rejectedTitle, AuthStrings.rejectedSubtitle),
      false => (AuthStrings.blockedTitle, AuthStrings.blockedSubtitle),
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: SessionRefreshIndicator(
            onRefresh: () => _recheckStatus(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const SizedBox(height: AppSpacing.xxl),
                // الأيقونة تدخل بتكبير + تلاشٍ داخل دائرة ناعمة بظل.
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: AppCurves.spring,
                    builder: (context, t, child) => Opacity(
                      opacity: t.clamp(0.0, 1.0).toDouble(),
                      child: Transform.scale(scale: .6 + .4 * t, child: child),
                    ),
                    child: Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Colors.white, AppColors.errorSoft],
                        ),
                        boxShadow: AppShadows.card,
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        size: 58,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Entrance(
                  index: 1,
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // بطاقة السبب — سطح ناعم بظل مع شارة الخطأ.
                Entrance(
                  index: 2,
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.errorSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                AuthStrings.reasonTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          reason,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Entrance(
                  index: 3,
                  child: PrimaryButton(
                    label: AuthStrings.contactSupport,
                    icon: Icons.support_agent_rounded,
                    onPressed: () => _contactSupport(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Entrance(
                  index: 4,
                  child: SecondaryButton(
                    label: AuthStrings.logout,
                    icon: Icons.logout_rounded,
                    onPressed: () => _logout(context),
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
