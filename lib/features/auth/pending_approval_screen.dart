import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/external_actions.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'auth_navigation.dart';
import 'auth_strings.dart';

/// شاشة انتظار الموافقة — تظهر بعد التسجيل حتى يوافق فريق الإدارة على الحساب.
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  /// تأرجح/نبض مستمر لطيف لأيقونة الساعة الرملية.
  late final AnimationController _swayController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  late final CurvedAnimation _sway = CurvedAnimation(
    parent: _swayController,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _sway.dispose();
    _swayController.dispose();
    super.dispose();
  }

  Future<void> _recheckStatus() async {
    try {
      await session.refreshAuthenticatedData();
      if (!mounted) return;
      final profile = session.seller;
      if (profile.status != AccountStatus.pending) {
        openAuthenticatedDestination(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthStrings.stillUnderReviewSnack)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _contactSupport() async {
    final opened = await launchWhatsApp(session.supportWhatsapp);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthStrings.contactAppUnavailable)),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await session.signOut();
    } catch (_) {
      // Remote revocation failure must not keep local account data visible.
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.goldDark,
            onRefresh: _recheckStatus,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const SizedBox(height: AppSpacing.xl),
                Entrance(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _sway,
                      builder: (context, child) {
                        final t = _sway.value;
                        return Transform.rotate(
                          angle: (t - .5) * .22,
                          child: Transform.scale(
                            scale: 1 + .04 * t,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Colors.white, AppColors.warningSoft],
                          ),
                          boxShadow: AppShadows.card,
                        ),
                        child: Icon(
                          Icons.hourglass_top_rounded,
                          size: 58,
                          color: AppColors.warning,
                        ),
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
                        AuthStrings.requestUnderReview,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AuthStrings.pendingBody,
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
                Entrance(
                  index: 2,
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _StepRow(
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                          label: AuthStrings.stepReceived,
                          done: true,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _StepRow(
                          icon: Icons.hourglass_bottom_rounded,
                          color: AppColors.warning,
                          label: AuthStrings.stepReviewing,
                          done: false,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _StepRow(
                          icon: Icons.rocket_launch_outlined,
                          color: AppColors.textSecondary,
                          label: AuthStrings.stepActivate,
                          done: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Entrance(
                  index: 3,
                  child: SecondaryButton(
                    label: AuthStrings.contactSupport,
                    icon: Icons.support_agent_rounded,
                    onPressed: _contactSupport,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Entrance(
                  index: 4,
                  child: SecondaryButton(
                    label: AuthStrings.logout,
                    icon: Icons.logout_rounded,
                    color: AppColors.error,
                    onPressed: _logout,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // ────────────────────────────────────────────────────────────
                // زر معاينة تصميمية فقط: يتيح لفريق التصميم/المراجعة الدخول إلى
                // الواجهة الرئيسية دون منطق موافقة حقيقي.
                // يُحذف هذا الزر بالكامل عند الربط بالـAPI الحقيقي.
                // ────────────────────────────────────────────────────────────
                if (session.isDemo)
                  Entrance(
                    index: 5,
                    child: PrimaryButton(
                      label: AuthStrings.previewApprovedLogin,
                      icon: Icons.visibility_outlined,
                      gold: true,
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        Routes.shell,
                        (route) => false,
                      ),
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

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.done,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: done ? FontWeight.w700 : FontWeight.w500,
              color: done ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
