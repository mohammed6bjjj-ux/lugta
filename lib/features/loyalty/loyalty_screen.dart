import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'loyalty_strings.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  @override
  void initState() {
    super.initState();
    if (!session.loyaltySummaryLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshSilently();
      });
    }
  }

  Future<void> _refreshSilently() async {
    try {
      await session.refreshLoyaltySummary();
    } catch (_) {
      // The session exposes the localized error and keeps any usable snapshot.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LoyaltyStrings.title),
        actions: [
          SessionRefreshButton(onRefresh: session.refreshLoyaltySummary),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            final summary = session.loyaltySummary;
            if (summary == null && session.loyaltySummaryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (summary == null) {
              return SessionRefreshIndicator(
                onRefresh: session.refreshLoyaltySummary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    EmptyState(
                      icon: Icons.workspace_premium_outlined,
                      title: LoyaltyStrings.loadError,
                      subtitle: session.loyaltySummaryError,
                      actionLabel: LoyaltyStrings.retry,
                      onAction: _refreshSilently,
                    ),
                  ],
                ),
              );
            }
            if (!summary.programEnabled) {
              return SessionRefreshIndicator(
                onRefresh: session.refreshLoyaltySummary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    EmptyState(
                      icon: Icons.workspace_premium_outlined,
                      title: LoyaltyStrings.disabledTitle,
                      subtitle: LoyaltyStrings.disabledBody,
                    ),
                  ],
                ),
              );
            }
            return _LoyaltyContent(summary: summary);
          },
        ),
      ),
    );
  }
}

class _LoyaltyContent extends StatelessWidget {
  const _LoyaltyContent({required this.summary});

  final LoyaltySummary summary;

  @override
  Widget build(BuildContext context) {
    return SessionRefreshIndicator(
      onRefresh: session.refreshLoyaltySummary,
      child: ListView(
        key: const ValueKey('loyalty_scroll_view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          Entrance(child: _CurrentTierCard(summary: summary)),
          const SizedBox(height: AppSpacing.md),
          Entrance(index: 1, child: _Stats(summary: summary)),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(
            icon: Icons.route_outlined,
            title: LoyaltyStrings.levels,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < summary.tiers.length; index++) ...[
            Entrance(
              index: index + 2,
              child: _TierCard(
                tier: summary.tiers[index],
                isCurrent:
                    summary.currentTier?.code == summary.tiers[index].code,
                isReached:
                    summary.totalPoints >= summary.tiers[index].threshold,
              ),
            ),
            if (index < summary.tiers.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(
            icon: Icons.history_rounded,
            title: LoyaltyStrings.recentActivity,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (summary.recentEntries.isEmpty)
            AppCard(
              child: Text(
                LoyaltyStrings.noActivity,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < summary.recentEntries.length;
                    index++
                  ) ...[
                    _PointEntryTile(entry: summary.recentEntries[index]),
                    if (index < summary.recentEntries.length - 1)
                      Divider(height: 1, color: AppColors.divider),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CurrentTierCard extends StatelessWidget {
  const _CurrentTierCard({required this.summary});

  final LoyaltySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = summary.currentTier;
    final tierColor = _tierColor(tier?.code);
    final next = summary.nextTier;
    final progressLabel = next == null
        ? LoyaltyStrings.highestLevel
        : LoyaltyStrings.pointsRemaining(
            summary.effectivePointsToNextTier,
            next.localizedName,
          );

    return AppCard(
      color: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tierColor.withValues(
                    alpha: AppColors.isDark ? .2 : .12,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_tierIcon(tier?.code), color: tierColor, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LoyaltyStrings.currentLevel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      tier?.localizedName ?? '—',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: tierColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            label: progressLabel,
            value: '${(summary.progressToNextTier * 100).round()}%',
            child: LinearProgressIndicator(
              value: summary.progressToNextTier,
              minHeight: 10,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: tierColor,
              backgroundColor: AppColors.divider,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            progressLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LoyaltyStrings.pointsPerUnit(summary.pointsPerSoldUnit),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.summary});

  final LoyaltySummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 420
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SizedBox(
              width: width,
              child: _StatTile(
                icon: Icons.stars_rounded,
                label: LoyaltyStrings.totalPoints,
                value:
                    '${formatNumber(summary.totalPoints)} ${LoyaltyStrings.point}',
              ),
            ),
            SizedBox(
              width: width,
              child: _StatTile(
                icon: Icons.inventory_2_outlined,
                label: LoyaltyStrings.soldUnits,
                value: formatNumber(summary.completedUnits),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.isCurrent,
    required this.isReached,
  });

  final LoyaltyTierDefinition tier;
  final bool isCurrent;
  final bool isReached;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _tierColor(tier.code);
    return AppCard(
      color: isCurrent
          ? color.withValues(alpha: AppColors.isDark ? .15 : .08)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isReached ? Icons.check_circle_rounded : _tierIcon(tier.code),
            color: isReached ? color : AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      tier.localizedName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isCurrent)
                      _Badge(label: LoyaltyStrings.currentBadge, color: color),
                  ],
                ),
                Text(
                  LoyaltyStrings.threshold(tier.threshold),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _rewardLabel(tier),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (tier.rewardEnabled && tier.rewardValidDays != null)
                  Text(
                    LoyaltyStrings.validDays(tier.rewardValidDays!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointEntryTile extends StatelessWidget {
  const _PointEntryTile({required this.entry});

  final LoyaltyPointEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = entry.isCredit ? AppColors.success : AppColors.error;
    final title = entry.description.trim().isEmpty
        ? LoyaltyStrings.entryType(entry.type)
        : entry.description;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            entry.isCredit
                ? Icons.add_circle_rounded
                : Icons.remove_circle_rounded,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (entry.orderNumber?.isNotEmpty == true)
                  Text(
                    entry.orderNumber!,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                Text(
                  timeAgo(entry.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${entry.isCredit ? '+' : ''}${formatNumber(entry.points)}',
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark ? .22 : .12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _tierColor(LoyaltyTierCode? code) => switch (code) {
  LoyaltyTierCode.bronze => AppColors.warning,
  LoyaltyTierCode.silver => AppColors.info,
  LoyaltyTierCode.gold => AppColors.accentStrong,
  null => AppColors.primary,
};

IconData _tierIcon(LoyaltyTierCode? code) => switch (code) {
  LoyaltyTierCode.bronze => Icons.shield_outlined,
  LoyaltyTierCode.silver => Icons.workspace_premium_outlined,
  LoyaltyTierCode.gold => Icons.emoji_events_outlined,
  null => Icons.stars_outlined,
};

String _rewardLabel(LoyaltyTierDefinition tier) {
  if (!tier.rewardEnabled) return LoyaltyStrings.noReward;
  return switch (tier.rewardType) {
    'free_delivery' => LoyaltyStrings.freeDeliveryReward(tier.rewardValue),
    'wallet_credit' ||
    'cashback' => LoyaltyStrings.walletReward(formatIqd(tier.rewardValue)),
    'percent' ||
    'percentage_discount' => LoyaltyStrings.percentReward(tier.rewardValue),
    _ => LoyaltyStrings.reward,
  };
}
