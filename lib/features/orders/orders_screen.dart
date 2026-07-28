import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/session_refresh.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../l10n/core_strings.dart';
import 'orders_strings.dart';

/// فلاتر قائمة الطلبات.
enum _OrdersFilter { all, active, completed, returned, cancelled }

extension _OrdersFilterX on _OrdersFilter {
  String get label => switch (this) {
    _OrdersFilter.all => OrdersStrings.filterAll,
    _OrdersFilter.active => OrdersStrings.filterActive,
    _OrdersFilter.completed => OrdersStrings.filterCompleted,
    _OrdersFilter.returned => OrdersStrings.filterReturned,
    _OrdersFilter.cancelled => OrdersStrings.filterCancelled,
  };

  bool matches(OrderStatus status) => switch (this) {
    _OrdersFilter.all => true,
    _OrdersFilter.active =>
      status == OrderStatus.pendingReview ||
          status == OrderStatus.confirmed ||
          status == OrderStatus.shipped ||
          status == OrderStatus.delivered,
    _OrdersFilter.completed => status == OrderStatus.completed,
    _OrdersFilter.returned =>
      status == OrderStatus.deliveryFailed ||
          status == OrderStatus.returning ||
          status == OrderStatus.returned ||
          status == OrderStatus.rejected,
    _OrdersFilter.cancelled => status == OrderStatus.cancelled,
  };

  IconData get emptyIcon => switch (this) {
    _OrdersFilter.all => Icons.receipt_long_outlined,
    _OrdersFilter.active => Icons.local_shipping_outlined,
    _OrdersFilter.completed => Icons.verified_rounded,
    _OrdersFilter.returned => Icons.assignment_return_outlined,
    _OrdersFilter.cancelled => Icons.cancel_outlined,
  };

  String get emptyTitle => switch (this) {
    _OrdersFilter.all => OrdersStrings.emptyAllTitle,
    _OrdersFilter.active => OrdersStrings.emptyActiveTitle,
    _OrdersFilter.completed => OrdersStrings.emptyCompletedTitle,
    _OrdersFilter.returned => OrdersStrings.emptyReturnedTitle,
    _OrdersFilter.cancelled => OrdersStrings.emptyCancelledTitle,
  };

  String get emptySubtitle => switch (this) {
    _OrdersFilter.all => OrdersStrings.emptyAllSubtitle,
    _OrdersFilter.active => OrdersStrings.emptyActiveSubtitle,
    _OrdersFilter.completed => OrdersStrings.emptyCompletedSubtitle,
    _OrdersFilter.returned => OrdersStrings.emptyReturnedSubtitle,
    _OrdersFilter.cancelled => OrdersStrings.emptyCancelledSubtitle,
  };
}

/// شاشة تبويب «طلباتي» — رأس مخصص، فلاتر نصية خفيفة،
/// وبطاقات مكثفة بشريط ربح ملوّن حسب الحالة.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  _OrdersFilter _filter = _OrdersFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            final orders = session.orders;
            final filtered = orders
                .where((o) => _filter.matches(o.status))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── الرأس ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        CoreStrings.tabOrders,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          OrdersStrings.ordersCount(
                            formatNumber(orders.length),
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── الفلاتر النصية الخفيفة ──
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: _OrdersFilter.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final filter = _OrdersFilter.values[index];
                      final count = orders
                          .where((o) => filter.matches(o.status))
                          .length;
                      return _FilterPill(
                        label: filter.label,
                        count: count,
                        selected: filter == _filter,
                        onTap: () => setState(() => _filter = filter),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── القائمة ──
                Expanded(
                  child: SessionRefreshIndicator(
                    onRefresh: session.refreshOrders,
                    child: filtered.isEmpty
                        ? CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 110),
                                  child: EmptyState(
                                    icon: _filter.emptyIcon,
                                    title: _filter.emptyTitle,
                                    subtitle: _filter.emptySubtitle,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            // حشوة سفلية لأن الشِل extendBody بشريط عائم.
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              2,
                              AppSpacing.md,
                              110,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm + 2),
                            itemBuilder: (context, index) => Entrance(
                              key: ValueKey(filtered[index].id),
                              index: index,
                              child: _OrderCard(order: filtered[index]),
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// فلتر نصي خفيف: المختار كبسولة داكنة، وغير المختار نص هادئ بلا خلفية.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.base,
        curve: AppCurves.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: AppDurations.base,
              style: (theme.textTheme.labelMedium ?? const TextStyle())
                  .copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
              child: Text(label),
            ),
            const SizedBox(width: 5),
            Text(
              formatNumber(count),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: selected
                    ? AppColors.gold
                    : AppColors.textSecondary.withValues(alpha: .7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة طلب مكثفة: صورة + اسم وحالة وسطر تعريف، ثم شريط ربح ملوّن.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(10),
      radius: AppRadius.md + 2,
      onTap: () =>
          Navigator.pushNamed(context, Routes.orderDetail, arguments: order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppNetworkImage(
                order.productImage,
                width: 54,
                height: 54,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        OrderStatusChip(status: order.status, compact: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${order.code} • ${order.customerName} — ${order.governorateName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeAgo(order.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary.withValues(
                              alpha: .8,
                            ),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfitStrip(order: order),
        ],
      ),
    );
  }
}

/// شريط الربح أسفل البطاقة — لونه ورسالته حسب مصير الطلب:
/// معلق (برتقالي) / متاح (أخضر) / بلا ربح للطلبات الراجعة والملغاة (محايد).
class _ProfitStrip extends StatelessWidget {
  const _ProfitStrip({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (
      Color bg,
      Color fg,
      IconData icon,
      String text,
    ) = switch (order.status) {
      OrderStatus.completed => (
        AppColors.successSoft,
        AppColors.success,
        Icons.verified_rounded,
        OrdersStrings.profitYours(formatIqd(order.profit)),
      ),
      OrderStatus.pendingReview ||
      OrderStatus.confirmed ||
      OrderStatus.shipped ||
      OrderStatus.delivered => (
        AppColors.goldSoft,
        AppColors.goldDark,
        Icons.schedule_rounded,
        OrdersStrings.profitPending(formatIqd(order.profit)),
      ),
      _ => (
        AppColors.neutralChip,
        AppColors.textSecondary,
        Icons.do_not_disturb_on_outlined,
        OrdersStrings.noProfitNoCharges,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            OrdersStrings.totalAmount(formatIqd(order.customerTotal)),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
