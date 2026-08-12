import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/request_id.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/repositories/repositories.dart';
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
    final stockReservation = summary.currentTier?.stockReservation;
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
            icon: Icons.auto_awesome_outlined,
            title: LoyaltyStrings.myBenefits,
          ),
          const SizedBox(height: AppSpacing.sm),
          _BenefitsSection(summary: summary),
          if (stockReservation?.enabled == true) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(
              icon: Icons.diamond_outlined,
              title: LoyaltyStrings.stockReservationTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            _StockReservationCard(entitlement: stockReservation!),
            const SizedBox(height: AppSpacing.md),
            _StockReservations(reservations: summary.recentStockReservations),
          ],
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(
            icon: Icons.assignment_outlined,
            title: LoyaltyStrings.benefitRequests,
          ),
          const SizedBox(height: AppSpacing.sm),
          _BenefitRequests(requests: summary.recentBenefitRequests),
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
    final isDiamond = tier?.code == LoyaltyTierCode.diamond;
    final secondaryColor = isDiamond
        ? AppColors.onPrimary.withValues(alpha: .82)
        : AppColors.textSecondary;
    final next = summary.nextTier;
    final progressLabel = next == null
        ? LoyaltyStrings.highestLevel
        : LoyaltyStrings.pointsRemaining(
            summary.effectivePointsToNextTier,
            next.localizedName,
          );

    return AppCard(
      color: isDiamond ? AppColors.primary : AppColors.surfaceAlt,
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
                  color: isDiamond
                      ? AppColors.accent
                      : tierColor.withValues(
                          alpha: AppColors.isDark ? .2 : .12,
                        ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _tierIcon(tier?.code),
                  color: isDiamond ? AppColors.onAccent : tierColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LoyaltyStrings.currentLevel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryColor,
                      ),
                    ),
                    Text(
                      tier?.localizedName ?? '—',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDiamond ? AppColors.accent : tierColor,
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
              color: isDiamond ? AppColors.accent : tierColor,
              backgroundColor: isDiamond
                  ? AppColors.onPrimary.withValues(alpha: .18)
                  : AppColors.divider,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            progressLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: secondaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LoyaltyStrings.pointsPerUnit(summary.pointsPerSoldUnit),
            style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
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
                for (final benefit in tier.benefits.where(
                  (benefit) => benefit.enabled,
                )) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_benefitIcon(benefit.type), size: 18, color: color),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '${_benefitTitle(benefit.type)} · ${LoyaltyStrings.requestsRemaining(benefit.monthlyLimit, benefit.monthlyLimit)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (tier.stockReservation?.enabled == true) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_clock_outlined, size: 18, color: color),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '${LoyaltyStrings.stockReservationTitle} · ${LoyaltyStrings.reservedUnits(tier.stockReservation!.activeUnits, tier.stockReservation!.maxActiveUnits)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection({required this.summary});

  final LoyaltySummary summary;

  @override
  Widget build(BuildContext context) {
    final benefits =
        summary.currentTier?.benefits
            .where((benefit) => benefit.enabled)
            .toList(growable: false) ??
        const <LoyaltyTierBenefit>[];
    if (benefits.isEmpty) {
      return AppCard(
        child: Text(
          LoyaltyStrings.noBenefits,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < benefits.length; index++) ...[
          _BenefitCard(benefit: benefits[index]),
          if (index < benefits.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.benefit});

  final LoyaltyTierBenefit benefit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = benefit.effectiveRemaining > 0;
    final title = _benefitTitle(benefit.type);
    final limitLabel = benefit.type == LoyaltyBenefitType.customPhotography
        ? LoyaltyStrings.maxPhotos(benefit.maxPerRequest)
        : LoyaltyStrings.maxUnits(benefit.maxPerRequest);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: AppColors.isDark ? .2 : .1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _benefitIcon(benefit.type),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      LoyaltyStrings.requestsRemaining(
                        benefit.effectiveRemaining,
                        benefit.monthlyLimit,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: available
                            ? AppColors.textSecondary
                            : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      limitLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: available
                  ? () => _openBenefitRequest(context, benefit)
                  : null,
              icon: Icon(
                available ? Icons.arrow_forward_rounded : Icons.lock_outline,
              ),
              label: Text(
                available
                    ? LoyaltyStrings.requestBenefit
                    : LoyaltyStrings.quotaFinished,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Kept as a compact presentation variant for future narrow layouts.
// ignore: unused_element
class _StockReservationSummaryCard extends StatelessWidget {
  const _StockReservationSummaryCard({required this.entitlement});

  final StockReservationEntitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: AppColors.isDark ? .22 : .1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LoyaltyStrings.stockReservationSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      LoyaltyStrings.reservedUnits(
                        entitlement.activeUnits,
                        entitlement.maxActiveUnits,
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: entitlement.maxActiveUnits <= 0
                  ? 0
                  : (entitlement.activeUnits / entitlement.maxActiveUnits)
                        .clamp(0, 1)
                        .toDouble(),
              backgroundColor: AppColors.surfaceAlt,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Badge(
                label: LoyaltyStrings.reservationRemaining(
                  entitlement.remainingUnits,
                ),
                color: entitlement.canReserve
                    ? AppColors.success
                    : AppColors.warning,
              ),
              _Badge(
                label: LoyaltyStrings.maxPerReservation(
                  entitlement.maxPerReservation,
                ),
                color: AppColors.info,
              ),
              _Badge(
                label: LoyaltyStrings.reservationHoldHours(
                  entitlement.holdHours,
                ),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _StockReservationSummaries extends StatelessWidget {
  const _StockReservationSummaries({required this.reservations});

  final List<StockReservation> reservations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (reservations.isEmpty) {
      return AppCard(
        child: Text(
          LoyaltyStrings.noStockReservations,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LoyaltyStrings.myStockReservations,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < reservations.length; index++) ...[
                _StockReservationSummaryTile(reservation: reservations[index]),
                if (index < reservations.length - 1)
                  Divider(height: 1, color: AppColors.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StockReservationSummaryTile extends StatelessWidget {
  const _StockReservationSummaryTile({required this.reservation});

  final StockReservation reservation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = reservation.isActive
        ? AppColors.success
        : switch (reservation.status) {
            StockReservationStatus.consumed => AppColors.info,
            StockReservationStatus.expired ||
            StockReservationStatus.released => AppColors.textSecondary,
            StockReservationStatus.active => AppColors.success,
          };
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: reservation.imageUrl.trim().isEmpty
                ? Container(
                    width: 64,
                    height: 64,
                    color: AppColors.surfaceAlt,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.textSecondary,
                    ),
                  )
                : AppNetworkImage(
                    reservation.imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (reservation.variantName.trim().isNotEmpty)
                  Text(
                    reservation.variantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Badge(
                      label: LoyaltyStrings.reservationStatus(
                        reservation.status,
                      ),
                      color: statusColor,
                    ),
                    _Badge(
                      label: LoyaltyStrings.reservedQuantity(
                        reservation.quantity,
                      ),
                      color: AppColors.primary,
                    ),
                    if (reservation.consumedQuantity > 0)
                      _Badge(
                        label: LoyaltyStrings.reservationUsed(
                          reservation.consumedQuantity,
                        ),
                        color: AppColors.info,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${LoyaltyStrings.reservationNumber(reservation.reservationNumber.toString())} · ${LoyaltyStrings.reservationExpires(formatDateTime(reservation.expiresAt))}',
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

class _StockReservationCard extends StatelessWidget {
  const _StockReservationCard({required this.entitlement});

  final StockReservationEntitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canReserve = entitlement.remainingUnits > 0;
    final progress = entitlement.maxActiveUnits <= 0
        ? 0.0
        : (entitlement.activeUnits / entitlement.maxActiveUnits).clamp(
            0.0,
            1.0,
          );
    return Semantics(
      container: true,
      label: LoyaltyStrings.stockReservationTitle,
      value: LoyaltyStrings.reservedUnits(
        entitlement.activeUnits,
        entitlement.maxActiveUnits,
      ),
      child: Container(
        key: const ValueKey('diamond_stock_reservation_card'),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .2),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
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
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.diamond_rounded,
                    color: AppColors.onAccent,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LoyaltyStrings.stockReservationTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        LoyaltyStrings.stockReservationSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: .82),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              LoyaltyStrings.reservedUnits(
                entitlement.activeUnits,
                entitlement.maxActiveUnits,
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: AppColors.accent,
              backgroundColor: AppColors.onPrimary.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _DiamondDetailChip(
                  icon: Icons.add_box_outlined,
                  label: LoyaltyStrings.maxPerReservation(
                    entitlement.maxPerReservation,
                  ),
                ),
                _DiamondDetailChip(
                  icon: Icons.schedule_rounded,
                  label: LoyaltyStrings.reservationHoldHours(
                    entitlement.holdHours,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              canReserve
                  ? LoyaltyStrings.reservationRemaining(
                      entitlement.remainingUnits,
                    )
                  : LoyaltyStrings.reservationLimitReached,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onPrimary.withValues(alpha: .86),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                key: const ValueKey('open_stock_reservation_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  disabledBackgroundColor: AppColors.onPrimary.withValues(
                    alpha: .12,
                  ),
                  disabledForegroundColor: AppColors.onPrimary.withValues(
                    alpha: .5,
                  ),
                ),
                onPressed: canReserve
                    ? () => _openStockReservation(context, entitlement)
                    : null,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(LoyaltyStrings.reserveStock),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiamondDetailChip extends StatelessWidget {
  const _DiamondDetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.onPrimary.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockReservations extends StatelessWidget {
  const _StockReservations({required this.reservations});

  final List<StockReservation> reservations;

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return AppCard(
        child: Text(
          LoyaltyStrings.noStockReservations,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LoyaltyStrings.myStockReservations,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < reservations.length; index++) ...[
          _StockReservationTile(reservation: reservations[index]),
          if (index < reservations.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _StockReservationTile extends StatefulWidget {
  const _StockReservationTile({required this.reservation});

  final StockReservation reservation;

  @override
  State<_StockReservationTile> createState() => _StockReservationTileState();
}

class _StockReservationTileState extends State<_StockReservationTile> {
  bool _releasing = false;

  bool get _canRelease =>
      widget.reservation.status == StockReservationStatus.active &&
      widget.reservation.remainingQuantity > 0 &&
      widget.reservation.expiresAt.isAfter(DateTime.now());

  Future<void> _release() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LoyaltyStrings.releaseReservationTitle),
        content: Text(LoyaltyStrings.releaseReservationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(LoyaltyStrings.keepReservation),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(LoyaltyStrings.releaseReservation),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _releasing = true);
    try {
      await session.releaseProductReservation(widget.reservation.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LoyaltyStrings.reservationReleased)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is BackendException
                ? error.message
                : LoyaltyStrings.reservationFailed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _releasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reservation = widget.reservation;
    final status = _reservationStatusPresentation(reservation.status);
    final imageUrl = reservation.imageUrl.trim();
    return AppCard(
      key: ValueKey('stock_reservation_${reservation.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox.square(
                  dimension: 68,
                  child: imageUrl.isEmpty
                      ? ColoredBox(
                          color: AppColors.surfaceAlt,
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : AppNetworkImage(
                          imageUrl,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (reservation.variantName.trim().isNotEmpty)
                      Text(
                        reservation.variantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      LoyaltyStrings.reservationNumber(
                        formatNumber(reservation.reservationNumber),
                      ),
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ReservationStatusBadge(
                label: LoyaltyStrings.reservationStatus(reservation.status),
                icon: status.icon,
                color: status.color,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _ReservationInfo(
                icon: Icons.inventory_2_outlined,
                text: LoyaltyStrings.reservedQuantity(
                  reservation.remainingQuantity,
                ),
              ),
              if (reservation.consumedQuantity > 0)
                _ReservationInfo(
                  icon: Icons.shopping_bag_outlined,
                  text: LoyaltyStrings.reservationUsed(
                    reservation.consumedQuantity,
                  ),
                ),
              _ReservationInfo(
                icon: Icons.schedule_rounded,
                text: LoyaltyStrings.reservationExpires(
                  formatDateTime(reservation.expiresAt.toLocal()),
                ),
              ),
            ],
          ),
          if (_canRelease) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                key: ValueKey('release_stock_reservation_${reservation.id}'),
                onPressed: _releasing ? null : _release,
                icon: _releasing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_rounded),
                label: Text(LoyaltyStrings.releaseReservation),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReservationInfo extends StatelessWidget {
  const _ReservationInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReservationStatusBadge extends StatelessWidget {
  const _ReservationStatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark ? .2 : .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

({Color color, IconData icon}) _reservationStatusPresentation(
  StockReservationStatus status,
) {
  return switch (status.name) {
    'active' => (color: AppColors.success, icon: Icons.lock_clock_outlined),
    'consumed' => (color: AppColors.primary, icon: Icons.shopping_bag_outlined),
    'released' => (
      color: AppColors.textSecondary,
      icon: Icons.lock_open_rounded,
    ),
    'expired' => (color: AppColors.warning, icon: Icons.timer_off_outlined),
    _ => (color: AppColors.warning, icon: Icons.timer_off_outlined),
  };
}

Future<void> _openStockReservation(
  BuildContext context,
  StockReservationEntitlement entitlement,
) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    builder: (context) => _StockReservationSheet(entitlement: entitlement),
  );
  if (created == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(LoyaltyStrings.reservationCreated)));
  }
}

class _StockReservationSheet extends StatefulWidget {
  const _StockReservationSheet({required this.entitlement});

  final StockReservationEntitlement entitlement;

  @override
  State<_StockReservationSheet> createState() => _StockReservationSheetState();
}

class _StockReservationSheetState extends State<_StockReservationSheet> {
  String? _attemptFingerprint;
  String? _attemptRequestId;
  Product? _product;
  ProductVariant? _variant;
  int _quantity = 1;
  bool _submitting = false;
  String? _error;

  int get _maxQuantity {
    final variant = _variant;
    if (variant == null) return 0;
    return math.min(
      variant.stock,
      math.min(
        widget.entitlement.remainingUnits,
        widget.entitlement.maxPerReservation,
      ),
    );
  }

  String _requestIdFor(ProductVariant variant, int quantity) {
    final fingerprint = '${variant.id}:$quantity';
    if (_attemptFingerprint != fingerprint || _attemptRequestId == null) {
      _attemptFingerprint = fingerprint;
      _attemptRequestId = newUuidV4();
    }
    // An unchanged payload keeps the same UUID after an ambiguous timeout;
    // changing the variant/quantity intentionally starts a new operation.
    return _attemptRequestId!;
  }

  Future<void> _pickProduct() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _ReservationProductPicker(selectedId: _product?.id),
    );
    if (!mounted || product == null) return;
    setState(() {
      _product = product;
      _variant = null;
      _quantity = 1;
      _error = null;
    });
  }

  void _selectVariant(ProductVariant variant) {
    setState(() {
      _variant = variant;
      _quantity = 1;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final variant = _variant;
    if (variant == null) {
      setState(() => _error = LoyaltyStrings.variantRequired);
      return;
    }
    final maxQuantity = _maxQuantity;
    if (maxQuantity <= 0 || _quantity > maxQuantity) {
      setState(() => _error = LoyaltyStrings.reservationLimitReached);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await session.reserveProductStock(
        variantId: variant.id,
        quantity: _quantity,
        clientRequestId: _requestIdFor(variant, _quantity),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is BackendException
            ? error.message
            : LoyaltyStrings.reservationFailed;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxQuantity = _maxQuantity;
    return FractionallySizedBox(
      heightFactor: .92,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.diamond_rounded, color: AppColors.onAccent),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    LoyaltyStrings.stockReservationTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: LoyaltyStrings.close,
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              key: const ValueKey('stock_reservation_sheet'),
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              children: [
                _ReservationQuotaSummary(entitlement: widget.entitlement),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  LoyaltyStrings.chooseReservationProduct,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProductSelectionButton(
                  key: const ValueKey('reservation_product_selector'),
                  product: _product,
                  onTap: _submitting ? null : _pickProduct,
                ),
                if (_product != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    LoyaltyStrings.chooseReservationVariant,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final variant in _product!.variants.where(
                    (variant) => variant.inStock,
                  )) ...[
                    _ReservationVariantTile(
                      product: _product!,
                      variant: variant,
                      selected: _variant?.id == variant.id,
                      enabled: !_submitting,
                      onTap: () => _selectVariant(variant),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ],
                if (_variant != null && maxQuantity > 0) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    LoyaltyStrings.reservationQuantity,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    LoyaltyStrings.availableToReserve(maxQuantity),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuantityStepper(
                    value: _quantity,
                    max: maxQuantity,
                    enabled: !_submitting,
                    onChanged: (value) => setState(() => _quantity = value),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  key: const ValueKey('confirm_stock_reservation_button'),
                  onPressed: _submitting || _variant == null || maxQuantity <= 0
                      ? null
                      : _submit,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_clock_outlined),
                  label: Text(LoyaltyStrings.confirmReservation),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationQuotaSummary extends StatelessWidget {
  const _ReservationQuotaSummary({required this.entitlement});

  final StockReservationEntitlement entitlement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: AppColors.isDark ? .22 : .08,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              LoyaltyStrings.reservationRemaining(entitlement.remainingUnits),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationVariantTile extends StatelessWidget {
  const _ReservationVariantTile({
    required this.product,
    required this.variant,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Product product;
  final ProductVariant variant;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = variant.imageUrl.trim().isEmpty
        ? product.coverImage
        : variant.imageUrl;
    return Semantics(
      key: ValueKey('reservation_variant_${variant.id}'),
      button: true,
      selected: selected,
      label:
          '${variant.localizedName}, ${LoyaltyStrings.availableToReserve(variant.stock)}',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(
                    alpha: AppColors.isDark ? .2 : .08,
                  )
                : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AppNetworkImage(
                imageUrl,
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant.localizedName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      LoyaltyStrings.availableToReserve(variant.stock),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationProductPicker extends StatelessWidget {
  const _ReservationProductPicker({required this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final products = session.products
        .where((product) => product.variants.any((variant) => variant.inStock))
        .toList(growable: false);
    return FractionallySizedBox(
      heightFactor: .8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    LoyaltyStrings.chooseReservationProduct,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: LoyaltyStrings.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                      child: Text(
                        LoyaltyStrings.noReservableProducts,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    key: const ValueKey('reservation_product_picker'),
                    padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final selected = product.id == selectedId;
                      return ListTile(
                        minTileHeight: 64,
                        selected: selected,
                        selectedTileColor: AppColors.primary.withValues(
                          alpha: .08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        leading: _ProductThumb(product: product, size: 48),
                        title: Text(
                          product.localizedName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          LoyaltyStrings.availableToReserve(
                            product.variants.fold<int>(
                              0,
                              (sum, variant) => sum + variant.stock,
                            ),
                          ),
                        ),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).pop(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRequests extends StatelessWidget {
  const _BenefitRequests({required this.requests});

  final List<LoyaltyBenefitRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return AppCard(
        child: Text(
          LoyaltyStrings.noBenefitRequests,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < requests.length; index++) ...[
            _BenefitRequestTile(request: requests[index]),
            if (index < requests.length - 1)
              Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _BenefitRequestTile extends StatelessWidget {
  const _BenefitRequestTile({required this.request});

  final LoyaltyBenefitRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _requestStatusColor(request.status);
    final subject = request.itemName?.trim().isNotEmpty == true
        ? request.itemName!
        : request.productName?.trim().isNotEmpty == true
        ? request.productName!
        : _benefitTitle(request.benefitType);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_benefitIcon(request.benefitType), color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${LoyaltyStrings.requestNumber(request.requestNumber)} · ${timeAgo(request.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Badge(
                label: LoyaltyStrings.requestStatus(request.status),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${request.benefitType == LoyaltyBenefitType.customPhotography ? (request.contentKind == LoyaltyContentKind.video ? LoyaltyStrings.videoCount : LoyaltyStrings.photoCount) : LoyaltyStrings.quantity}: ${formatNumber(request.requestedQuantity)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (request.referenceImageUrl?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AppNetworkImage(
                  request.referenceImageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          if (request.details.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              request.details,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (request.adminResponse?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '${LoyaltyStrings.adminReply}: ${request.adminResponse}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openBenefitRequest(
  BuildContext context,
  LoyaltyTierBenefit benefit,
) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _BenefitRequestSheet(benefit: benefit),
  );
  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(LoyaltyStrings.requestSent)));
  }
}

class _BenefitRequestSheet extends StatefulWidget {
  const _BenefitRequestSheet({required this.benefit});

  final LoyaltyTierBenefit benefit;

  @override
  State<_BenefitRequestSheet> createState() => _BenefitRequestSheetState();
}

class _BenefitRequestSheetState extends State<_BenefitRequestSheet> {
  static const _maxReferenceImageBytes = 8 * 1024 * 1024;

  final _itemNameController = TextEditingController();
  final _detailsController = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _productId;
  LoyaltyReferenceImage? _referenceImage;
  LoyaltyContentKind _contentKind = LoyaltyContentKind.photo;
  int _quantity = 1;
  bool _pickingImage = false;
  bool _submitting = false;
  String? _error;

  bool get _isPhotography =>
      widget.benefit.type == LoyaltyBenefitType.customPhotography;

  Product? get _selectedProduct {
    for (final product in session.products) {
      if (product.id == _productId) return product;
    }
    return null;
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _chooseProduct() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _ProductPicker(selectedId: _productId),
    );
    if (product != null && mounted) {
      setState(() {
        _productId = product.id;
        _error = null;
      });
    }
  }

  Future<void> _pickReferenceImage() async {
    if (_pickingImage || _submitting) return;
    setState(() => _pickingImage = true);
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 88,
      );
      if (file == null) return;
      final length = await file.length();
      if (length <= 0 || length > _maxReferenceImageBytes) {
        if (mounted) {
          setState(() => _error = LoyaltyStrings.referenceImageInvalid);
        }
        return;
      }
      final bytes = Uint8List.fromList(await file.readAsBytes());
      final mimeType = _referenceImageMimeType(bytes, file.mimeType);
      if (mimeType == null) {
        if (mounted) {
          setState(() => _error = LoyaltyStrings.referenceImageInvalid);
        }
        return;
      }
      if (mounted) {
        setState(() {
          _referenceImage = LoyaltyReferenceImage(
            bytes: bytes,
            mimeType: mimeType,
          );
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = LoyaltyStrings.referenceImageInvalid);
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final itemName = _itemNameController.text.trim();
    if (!_isPhotography && itemName.isEmpty) {
      setState(() => _error = LoyaltyStrings.itemNameRequired);
      return;
    }
    if (!_isPhotography && _referenceImage == null) {
      setState(() => _error = LoyaltyStrings.referenceImageRequired);
      return;
    }
    if (_isPhotography && _productId == null) {
      setState(() => _error = LoyaltyStrings.productRequired);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await session.submitLoyaltyBenefitRequest(
        type: widget.benefit.type,
        quantity: _quantity,
        itemName: _isPhotography ? null : itemName,
        productId: _isPhotography ? _productId : null,
        details: _detailsController.text.trim(),
        referenceImage: _isPhotography ? null : _referenceImage,
        contentKind: _isPhotography ? _contentKind : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedProduct = _selectedProduct;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _benefitIcon(widget.benefit.type),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _benefitTitle(widget.benefit.type),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        LoyaltyStrings.requestsRemaining(
                          widget.benefit.effectiveRemaining,
                          widget.benefit.monthlyLimit,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: LoyaltyStrings.close,
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isPhotography)
              _ProductSelectionButton(
                product: selectedProduct,
                onTap: _submitting ? null : _chooseProduct,
              )
            else
              TextField(
                controller: _itemNameController,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: LoyaltyStrings.itemName,
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
              ),
            if (!_isPhotography) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                LoyaltyStrings.referenceImage,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ReferenceImagePicker(
                image: _referenceImage,
                loading: _pickingImage,
                enabled: !_submitting,
                onTap: _pickReferenceImage,
              ),
            ],
            if (_isPhotography) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                LoyaltyStrings.contentType,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<LoyaltyContentKind>(
                segments: [
                  ButtonSegment(
                    value: LoyaltyContentKind.photo,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(LoyaltyStrings.photos),
                  ),
                  ButtonSegment(
                    value: LoyaltyContentKind.video,
                    icon: const Icon(Icons.videocam_outlined),
                    label: Text(LoyaltyStrings.video),
                  ),
                ],
                selected: {_contentKind},
                showSelectedIcon: false,
                onSelectionChanged: _submitting
                    ? null
                    : (selection) => setState(() {
                        _contentKind = selection.first;
                        _quantity = 1;
                      }),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              _isPhotography
                  ? (_contentKind == LoyaltyContentKind.video
                        ? LoyaltyStrings.videoCount
                        : LoyaltyStrings.photoCount)
                  : LoyaltyStrings.quantity,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuantityStepper(
              value: _quantity,
              max: widget.benefit.maxPerRequest,
              enabled: !_submitting,
              onChanged: (value) => setState(() => _quantity = value),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _detailsController,
              enabled: !_submitting,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: LoyaltyStrings.requestDetails,
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 52),
                  child: Icon(Icons.notes_rounded),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(LoyaltyStrings.submitRequest),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceImagePicker extends StatelessWidget {
  const _ReferenceImagePicker({
    required this.image,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final LoyaltyReferenceImage? image;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: image == null
          ? LoyaltyStrings.addReferenceImage
          : LoyaltyStrings.changeReferenceImage,
      child: InkWell(
        onTap: enabled && !loading ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          height: image == null ? 112 : 190,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.divider),
          ),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : image == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, size: 32),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      LoyaltyStrings.addReferenceImage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md - 1),
                      child: Image.memory(image!.bytes, fit: BoxFit.cover),
                    ),
                    PositionedDirectional(
                      end: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_outlined, size: 18),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                LoyaltyStrings.changeReferenceImage,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
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

class _ProductSelectionButton extends StatelessWidget {
  const _ProductSelectionButton({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product? product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              _ProductThumb(product: product, size: 54),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  product?.localizedName ?? LoyaltyStrings.chooseProductHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: product == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPicker extends StatelessWidget {
  const _ProductPicker({required this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final products = session.products;
    return FractionallySizedBox(
      heightFactor: .78,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    LoyaltyStrings.chooseProduct,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: LoyaltyStrings.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final product = products[index];
                final selected = product.id == selectedId;
                return ListTile(
                  minTileHeight: 64,
                  selected: selected,
                  selectedTileColor: AppColors.primary.withValues(alpha: .08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  leading: _ProductThumb(product: product, size: 48),
                  title: Text(
                    product.localizedName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pop(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product, required this.size});

  final Product? product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = product?.coverImage.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceAlt,
        child: url.isEmpty
            ? Icon(Icons.image_outlined, color: AppColors.textSecondary)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.value,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              onPressed: enabled && value > 1
                  ? () => onChanged(value - 1)
                  : null,
              icon: const Icon(Icons.remove_rounded),
            ),
          ),
          Expanded(
            child: Text(
              formatNumber(value),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: IconButton(
              onPressed: enabled && value < max
                  ? () => onChanged(value + 1)
                  : null,
              icon: const Icon(Icons.add_rounded),
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
  LoyaltyTierCode.diamond => AppColors.primary,
  null => AppColors.primary,
};

IconData _tierIcon(LoyaltyTierCode? code) => switch (code) {
  LoyaltyTierCode.bronze => Icons.shield_outlined,
  LoyaltyTierCode.silver => Icons.workspace_premium_outlined,
  LoyaltyTierCode.gold => Icons.emoji_events_outlined,
  LoyaltyTierCode.diamond => Icons.diamond_outlined,
  null => Icons.stars_outlined,
};

String _benefitTitle(LoyaltyBenefitType type) => switch (type) {
  LoyaltyBenefitType.productSourcing => LoyaltyStrings.productSourcing,
  LoyaltyBenefitType.customPhotography => LoyaltyStrings.customPhotography,
};

IconData _benefitIcon(LoyaltyBenefitType type) => switch (type) {
  LoyaltyBenefitType.productSourcing => Icons.manage_search_rounded,
  LoyaltyBenefitType.customPhotography => Icons.photo_camera_outlined,
};

Color _requestStatusColor(LoyaltyBenefitRequestStatus status) =>
    switch (status) {
      LoyaltyBenefitRequestStatus.pending => AppColors.warning,
      LoyaltyBenefitRequestStatus.approved => AppColors.info,
      LoyaltyBenefitRequestStatus.inProgress => AppColors.primary,
      LoyaltyBenefitRequestStatus.completed => AppColors.success,
      LoyaltyBenefitRequestStatus.rejected ||
      LoyaltyBenefitRequestStatus.cancelled => AppColors.error,
    };

String? _referenceImageMimeType(Uint8List bytes, String? hintedMimeType) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  final hinted = hintedMimeType?.trim().toLowerCase().split(';').first;
  if (const {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/avif',
  }.contains(hinted)) {
    return hinted;
  }
  return null;
}

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
