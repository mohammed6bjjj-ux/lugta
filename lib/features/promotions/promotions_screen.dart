import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/session_refresh.dart';
import '../../core/widgets/shimmer.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'engagement_strings.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  PromotionGrantStatus _status = PromotionGrantStatus.available;

  @override
  void initState() {
    super.initState();
    // This screen is mounted inside the route guard's session listener.
    // Starting the request here synchronously would notify that ancestor while
    // it is still building this child and leave its Element dirty.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || session.promotionGrantsLoaded) return;
      unawaited(session.refreshPromotionGrants().catchError((_) {}));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(EngagementStrings.promotions),
        actions: [
          SessionRefreshButton(onRefresh: session.refreshPromotionGrants),
        ],
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final initialLoading =
              session.promotionGrantsLoading && !session.promotionGrantsLoaded;
          if (initialLoading) return const _RewardsSkeleton();
          if (!session.promotionGrantsLoaded &&
              session.promotionGrantsError != null) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: EngagementStrings.loadFailed,
              subtitle: session.promotionGrantsError,
              actionLabel: EngagementStrings.retry,
              onAction: () => unawaited(
                session.refreshPromotionGrants().catchError((_) {}),
              ),
            );
          }

          final all = session.promotionGrants;
          if (all.isEmpty) {
            return SessionRefreshIndicator(
              onRefresh: session.refreshPromotionGrants,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.redeem_outlined,
                      title: EngagementStrings.promotionsEmpty,
                      subtitle: EngagementStrings.promotionsEmptyBody,
                    ),
                  ),
                ],
              ),
            );
          }

          final filtered =
              all
                  .where((grant) => grant.status == _status)
                  .toList(growable: false)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return SessionRefreshIndicator(
            onRefresh: session.refreshPromotionGrants,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      itemCount: PromotionGrantStatus.values.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final status = PromotionGrantStatus.values[index];
                        return ChoiceChip(
                          key: ValueKey('promotion_status_${status.name}'),
                          selected: _status == status,
                          onSelected: (_) => setState(() => _status = status),
                          avatar: Icon(
                            _statusIcon(status),
                            size: 17,
                            color: _statusColor(status),
                          ),
                          label: Text(
                            '${_statusLabel(status)} (${all.where((item) => item.status == status).length})',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: _statusIcon(_status),
                      title: EngagementStrings.promotionsEmpty,
                      subtitle: EngagementStrings.promotionsEmptyBody,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) =>
                          _RewardCard(grant: filtered[index]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.grant});

  final PromotionGrant grant;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(grant.status);
    final statusLabel = _statusLabel(grant.status);
    final promotion = grant.promotion;
    final title = promotion?.localizedName.trim();
    final description = promotion?.localizedDescription.trim();

    return AppCard(
      key: ValueKey('promotion_grant_${grant.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_rewardIcon(grant.rewardType), color: statusColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title == null || title.isEmpty
                          ? _rewardValue(grant)
                          : title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _rewardValue(grant),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.accentStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  grant.expiresAt == null
                      ? EngagementStrings.noExpiry
                      : '${EngagementStrings.validUntil}: ${formatDate(grant.expiresAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardsSkeleton extends StatelessWidget {
  const _RewardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const ShimmerBox(height: 132),
    );
  }
}

String _statusLabel(PromotionGrantStatus status) => switch (status) {
  PromotionGrantStatus.available => EngagementStrings.available,
  PromotionGrantStatus.used => EngagementStrings.used,
  PromotionGrantStatus.expired => EngagementStrings.expired,
};

Color _statusColor(PromotionGrantStatus status) => switch (status) {
  PromotionGrantStatus.available => AppColors.success,
  PromotionGrantStatus.used => AppColors.info,
  PromotionGrantStatus.expired => AppColors.textSecondary,
};

IconData _statusIcon(PromotionGrantStatus status) => switch (status) {
  PromotionGrantStatus.available => Icons.card_giftcard_rounded,
  PromotionGrantStatus.used => Icons.check_circle_outline_rounded,
  PromotionGrantStatus.expired => Icons.history_toggle_off_rounded,
};

IconData _rewardIcon(String type) => switch (type.toLowerCase()) {
  'free_delivery' => Icons.local_shipping_outlined,
  'wallet_credit' || 'cashback' => Icons.account_balance_wallet_outlined,
  'percent_discount' || 'percentage_discount' => Icons.percent_rounded,
  _ => Icons.redeem_outlined,
};

String _rewardValue(PromotionGrant grant) =>
    switch (grant.rewardType.toLowerCase()) {
      'free_delivery' => EngagementStrings.freeDelivery,
      'wallet_credit' || 'cashback' => formatIqd(grant.rewardValue),
      'percent_discount' ||
      'percentage_discount' => EngagementStrings.percent(grant.rewardValue),
      _ => formatNumber(grant.rewardValue),
    };
