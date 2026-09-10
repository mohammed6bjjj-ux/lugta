import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/session.dart';
import '../promotions/engagement_strings.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    // The protected-route gate listens to the same session. Defer the first
    // notification until its current build has completed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || session.referralSummaryLoaded) return;
      unawaited(session.refreshReferralSummary().catchError((_) {}));
    });
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(EngagementStrings.copied)));
  }

  Future<void> _share(String code) => SharePlus.instance.share(
    ShareParams(text: EngagementStrings.shareMessage(code)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(EngagementStrings.referrals),
        actions: [
          SessionRefreshButton(onRefresh: session.refreshReferralSummary),
        ],
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final summary = session.referralSummary;
          final initialLoading =
              session.referralSummaryLoading && !session.referralSummaryLoaded;
          if (initialLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!session.referralSummaryLoaded &&
              session.referralSummaryError != null) {
            return EmptyState(
              icon: Icons.link_off_rounded,
              title: EngagementStrings.loadFailed,
              subtitle: session.referralSummaryError,
              actionLabel: EngagementStrings.retry,
              onAction: () => unawaited(
                session.refreshReferralSummary().catchError((_) {}),
              ),
            );
          }

          final code = summary?.referralCode.trim() ?? '';
          if (summary == null || code.isEmpty) {
            return SessionRefreshIndicator(
              onRefresh: session.refreshReferralSummary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.group_add_outlined,
                      title: EngagementStrings.referralUnavailable,
                      actionLabel: EngagementStrings.retry,
                      onAction: () => unawaited(
                        session.refreshReferralSummary().catchError((_) {}),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return SessionRefreshIndicator(
            onRefresh: session.refreshReferralSummary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                if (summary.signupDeliveryActive ||
                    summary.signupDeliveryEarned) ...[
                  AppCard(
                    key: const ValueKey('referral_signup_offer'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.redeem_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          summary.signupDeliveryActive
                              ? EngagementStrings.referralSignupTitle
                              : EngagementStrings.referralSignupEarned,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          summary.signupDeliveryActive
                              ? EngagementStrings.referralSignupBody
                              : EngagementStrings.referralSignupPaused,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.65),
                        ),
                        if (summary.signupDeliveryActive &&
                            summary.signupDeliveryEarned) ...[
                          const Divider(height: AppSpacing.xl),
                          Text(
                            EngagementStrings.referralSignupEarned,
                            key: const ValueKey('referral_signup_earned'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (summary.rewardKind != null ||
                    summary.profitShareActive ||
                    summary.profitShareEarned > 0) ...[
                  AppCard(
                    key: const ValueKey('referral_profit_offer'),
                    color: AppColors.accentSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.rewardKind != null
                              ? EngagementStrings.rewardTitle(
                                  summary.rewardKind!,
                                  summary.rewardValue,
                                )
                              : EngagementStrings.referralProfitTitle(
                                  summary.profitSharePercent,
                                ),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.accentStrong,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          (summary.rewardKind != null
                                  ? summary.referralEnabled
                                  : summary.profitShareActive)
                              ? (summary.rewardKind != null
                                    ? EngagementStrings.configuredRewardBody
                                    : EngagementStrings.referralProfitBody)
                              : EngagementStrings.referralProfitPaused,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.65),
                        ),
                        if (summary.profitShareActive &&
                            summary.rewardKind == null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            EngagementStrings.referralProfitExample,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(height: 1.65),
                          ),
                        ],
                        const Divider(height: AppSpacing.xl),
                        if (summary.rewardKind != null) ...[
                          Text(
                            '${EngagementStrings.pendingCash}: ${formatIqd(summary.pendingCash)}',
                            key: const ValueKey('referral_pending_cash'),
                          ),
                          if (summary.pendingPoints > 0 ||
                              summary.rewardKind == 'points')
                            Text(
                              '${EngagementStrings.pendingPoints}: ${summary.pendingPoints}',
                            ),
                          if (summary.pendingDelivery > 0 ||
                              summary.rewardKind == 'delivery_credit')
                            Text(
                              '${EngagementStrings.pendingDelivery}: ${formatIqd(summary.pendingDelivery)}',
                            ),
                          if (summary.releasedPoints > 0)
                            Text(
                              '${EngagementStrings.releasedPoints}: ${summary.releasedPoints}',
                            ),
                          if (summary.releasedDelivery > 0)
                            Text(
                              '${EngagementStrings.releasedDelivery}: ${formatIqd(summary.releasedDelivery)}',
                            ),
                          if (summary.rewardKind == 'delivery_credit' ||
                              summary.releasedDelivery > 0 ||
                              summary.pendingDelivery > 0)
                            Text(EngagementStrings.deliveryCreditHelp),
                          const Divider(height: AppSpacing.xl),
                        ],
                        Text(EngagementStrings.referralProfitEarned),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          formatIqd(summary.profitShareEarned),
                          key: const ValueKey('referral_profit_earned'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.accentStrong,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(
                  EngagementStrings.referralSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  color: AppColors.accentSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        EngagementStrings.yourCode,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: SelectableText(
                          code,
                          key: const ValueKey('referral_code'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.accentStrong,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey('copy_referral_code'),
                              onPressed: () => unawaited(_copy(code)),
                              icon: const Icon(Icons.copy_rounded),
                              label: Text(EngagementStrings.copy),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              key: const ValueKey('share_referral_code'),
                              onPressed: () => unawaited(_share(code)),
                              icon: const Icon(Icons.ios_share_rounded),
                              label: Text(EngagementStrings.share),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _MetricGrid(
                  children: [
                    _MetricCard(
                      key: const ValueKey('referral_invited_count'),
                      value: formatNumber(summary.invitedCount),
                      label: EngagementStrings.invited,
                      icon: Icons.person_add_alt_1_outlined,
                    ),
                    _MetricCard(
                      key: const ValueKey('referral_qualified_count'),
                      value: formatNumber(summary.qualifiedCount),
                      label: EngagementStrings.qualified,
                      icon: Icons.verified_outlined,
                    ),
                    _MetricCard(
                      key: const ValueKey('referral_rewarded_count'),
                      value: formatNumber(summary.rewardedCount),
                      label: EngagementStrings.rewarded,
                      icon: Icons.redeem_outlined,
                    ),
                    _MetricCard(
                      key: const ValueKey('referral_completed_orders_count'),
                      value: formatNumber(summary.completedReferredOrders),
                      label: EngagementStrings.completedReferredOrders,
                      icon: Icons.shopping_bag_outlined,
                    ),
                    _MetricCard(
                      key: const ValueKey(
                        'referral_available_deliveries_count',
                      ),
                      value: formatNumber(summary.availableFreeDeliveries),
                      label: EngagementStrings.availableFreeDeliveries,
                      icon: Icons.local_shipping_outlined,
                    ),
                    _MetricCard(
                      key: const ValueKey('referral_wallet_rewards_amount'),
                      value: formatIqd(summary.walletRewardsEarned),
                      label: EngagementStrings.walletRewardsEarned,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final totalGaps = AppSpacing.sm * (columns - 1);
        final width = (constraints.maxWidth - totalGaps) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentStrong),
          const SizedBox(height: AppSpacing.xs),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
