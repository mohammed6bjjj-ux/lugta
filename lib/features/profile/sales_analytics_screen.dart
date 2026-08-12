import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../data/sales_analytics.dart';
import '../../data/session.dart';
import '../../data/models.dart';
import 'sales_analytics_strings.dart';

typedef SalesAnalyticsLoader =
    Future<SalesAnalyticsSnapshot> Function(DateTime from, DateTime to);

enum _AnalyticsPeriod { week, month, year }

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key, this.loader});

  final SalesAnalyticsLoader? loader;

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  _AnalyticsPeriod _period = _AnalyticsPeriod.month;
  SalesAnalyticsSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ({DateTime from, DateTime to}) _rangeFor(_AnalyticsPeriod period) {
    final to = DateTime.now();
    final from = switch (period) {
      _AnalyticsPeriod.week => DateTime(
        to.year,
        to.month,
        to.day,
      ).subtract(Duration(days: to.weekday - DateTime.monday)),
      _AnalyticsPeriod.month => DateTime(to.year, to.month),
      _AnalyticsPeriod.year => DateTime(to.year),
    };
    return (from: from, to: to);
  }

  Future<void> _load() async {
    final generation = ++_requestGeneration;
    final range = _rangeFor(_period);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loader =
          widget.loader ??
          (DateTime from, DateTime to) =>
              session.fetchSalesAnalytics(from: from, to: to);
      final snapshot = await loader(range.from, range.to);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _setPeriod(_AnalyticsPeriod value) {
    if (_period == value) return;
    setState(() => _period = value);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(SalesAnalyticsStrings.title),
        actions: [
          IconButton(
            key: const ValueKey('sales_analytics_refresh'),
            tooltip: SalesAnalyticsStrings.retry,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const ValueKey('sales_analytics_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _PeriodSelector(selected: _period, onSelected: _setPeriod),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const _AnalyticsLoading()
            else if (_error != null)
              _AnalyticsError(error: _error!, onRetry: _load)
            else if (_snapshot case final snapshot?)
              if (snapshot.isEmpty)
                const _AnalyticsEmpty()
              else
                _AnalyticsContent(snapshot: snapshot),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelected});

  final _AnalyticsPeriod selected;
  final ValueChanged<_AnalyticsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;
          final choices = <(_AnalyticsPeriod, String)>[
            (_AnalyticsPeriod.week, SalesAnalyticsStrings.week),
            (_AnalyticsPeriod.month, SalesAnalyticsStrings.month),
            (_AnalyticsPeriod.year, SalesAnalyticsStrings.year),
          ];
          return Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final choice in choices)
                SizedBox(
                  width: compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSpacing.xs * 2) / 3,
                  height: 48,
                  child: Material(
                    color: selected == choice.$1
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      key: ValueKey('analytics_period_${choice.$1.name}'),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => onSelected(choice.$1),
                      child: Center(
                        child: Text(
                          choice.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: selected == choice.$1
                                    ? AppColors.onPrimary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsLoading extends StatelessWidget {
  const _AnalyticsLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 360,
      child: Center(
        child: CircularProgressIndicator(
          key: ValueKey('sales_analytics_loading'),
        ),
      ),
    );
  }
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('sales_analytics_error'),
      color: AppColors.errorSoft,
      child: Column(
        children: [
          Icon(Icons.query_stats_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.sm),
          Text(
            SalesAnalyticsStrings.loadFailed,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            error.toString(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const ValueKey('sales_analytics_retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(SalesAnalyticsStrings.retry),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsEmpty extends StatelessWidget {
  const _AnalyticsEmpty();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('sales_analytics_empty'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              SalesAnalyticsStrings.emptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              SalesAnalyticsStrings.emptySubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.snapshot});

  final SalesAnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OverviewCard(snapshot: snapshot),
        const SizedBox(height: AppSpacing.md),
        _SectionTitle(SalesAnalyticsStrings.overview),
        const SizedBox(height: AppSpacing.sm),
        _MetricsGrid(summary: snapshot.current),
        if (snapshot.trend.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(SalesAnalyticsStrings.performance),
          const SizedBox(height: AppSpacing.sm),
          _TrendCard(points: snapshot.trend),
        ],
        if (snapshot.topProducts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(SalesAnalyticsStrings.topProducts),
          const SizedBox(height: AppSpacing.sm),
          _TopProductsCard(products: snapshot.topProducts),
        ],
        if (snapshot.statuses.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(SalesAnalyticsStrings.statusDistribution),
          const SizedBox(height: AppSpacing.sm),
          _StatusCard(statuses: snapshot.statuses),
        ],
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.snapshot});

  final SalesAnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final current = snapshot.current;
    return AppCard(
      gradient: AppColors.darkGradient,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: AppColors.onSelectedNavPill),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatDate(snapshot.from)} — ${formatDate(snapshot.to)}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.onSelectedNavPill.withValues(
                            alpha: .8,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        SalesAnalyticsStrings.updatedNow,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSelectedNavPill.withValues(
                            alpha: .72,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: AppColors.onAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 520;
                final width = stack
                    ? constraints.maxWidth
                    : (constraints.maxWidth - AppSpacing.sm * 2) / 3;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _HeroMetric(
                      width: width,
                      label: SalesAnalyticsStrings.sales,
                      value: formatIqd(current.salesTotal),
                    ),
                    _HeroMetric(
                      width: width,
                      label: SalesAnalyticsStrings.netProfit,
                      value: formatIqd(current.netProfit),
                      comparison: _comparison(
                        current.netProfit,
                        snapshot.previous.netProfit,
                      ),
                    ),
                    _HeroMetric(
                      width: width,
                      label: SalesAnalyticsStrings.orders,
                      value: formatNumber(current.orderCount),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  _Comparison _comparison(num current, num previous) {
    if (previous == 0) {
      return current == 0
          ? const _Comparison(_ComparisonDirection.same, 0)
          : const _Comparison(_ComparisonDirection.newValue, 0);
    }
    final percent = ((current - previous) / previous.abs()) * 100;
    if (percent.abs() < .05) {
      return const _Comparison(_ComparisonDirection.same, 0);
    }
    return _Comparison(
      percent > 0 ? _ComparisonDirection.up : _ComparisonDirection.down,
      percent.abs(),
    );
  }
}

enum _ComparisonDirection { up, down, same, newValue }

class _Comparison {
  const _Comparison(this.direction, this.percent);

  final _ComparisonDirection direction;
  final double percent;
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.width,
    required this.label,
    required this.value,
    this.comparison,
  });

  final double width;
  final String label;
  final String value;
  final _Comparison? comparison;

  @override
  Widget build(BuildContext context) {
    final comparison = this.comparison;
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: .13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: .78),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (comparison != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _ComparisonBadge(comparison: comparison),
          ],
        ],
      ),
    );
  }
}

class _ComparisonBadge extends StatelessWidget {
  const _ComparisonBadge({required this.comparison});

  final _Comparison comparison;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (comparison.direction) {
      _ComparisonDirection.up => (
        Icons.trending_up_rounded,
        SalesAnalyticsStrings.increase(
          '${comparison.percent.toStringAsFixed(1)}%',
        ),
      ),
      _ComparisonDirection.down => (
        Icons.trending_down_rounded,
        SalesAnalyticsStrings.decrease(
          '${comparison.percent.toStringAsFixed(1)}%',
        ),
      ),
      _ComparisonDirection.same => (
        Icons.horizontal_rule_rounded,
        SalesAnalyticsStrings.unchanged,
      ),
      _ComparisonDirection.newValue => (
        Icons.auto_awesome_rounded,
        SalesAnalyticsStrings.newPerformance,
      ),
    };
    return Tooltip(
      message: SalesAnalyticsStrings.comparedWithPrevious,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.summary});

  final SalesAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final metrics = <(IconData, String, String, Color, Color)>[
      (
        Icons.verified_outlined,
        SalesAnalyticsStrings.completed,
        formatNumber(summary.completedCount),
        AppColors.success,
        AppColors.successSoft,
      ),
      (
        Icons.inventory_2_outlined,
        SalesAnalyticsStrings.unitsSold,
        formatNumber(summary.unitsSold),
        AppColors.info,
        AppColors.infoSoft,
      ),
      (
        Icons.receipt_long_outlined,
        SalesAnalyticsStrings.averageOrder,
        formatIqd(summary.averageOrderValue),
        AppColors.primary,
        AppColors.surfaceAlt,
      ),
      (
        Icons.schedule_rounded,
        SalesAnalyticsStrings.pendingProfit,
        formatIqd(summary.pendingProfit),
        AppColors.warning,
        AppColors.warningSoft,
      ),
      (
        Icons.local_shipping_outlined,
        SalesAnalyticsStrings.deliveryContribution,
        formatIqd(summary.deliveryContribution),
        AppColors.accentStrong,
        AppColors.accentSoft,
      ),
      (
        Icons.task_alt_rounded,
        SalesAnalyticsStrings.successRate,
        '${summary.successRate.toStringAsFixed(1)}%',
        AppColors.success,
        AppColors.successSoft,
      ),
      (
        Icons.error_outline_rounded,
        SalesAnalyticsStrings.unsuccessful,
        formatNumber(summary.unsuccessfulCount),
        AppColors.error,
        AppColors.errorSoft,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 360
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _MetricCard(
                  icon: metric.$1,
                  label: metric.$2,
                  value: metric.$3,
                  color: metric.$4,
                  softColor: metric.$5,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.softColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});

  final List<SalesAnalyticsTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final totalSales = points.fold<int>(
      0,
      (sum, point) => sum + point.salesTotal,
    );
    final totalProfit = points.fold<int>(
      0,
      (sum, point) => sum + point.netProfit,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _Legend(
                color: AppColors.primary,
                label: SalesAnalyticsStrings.salesLegend,
              ),
              _Legend(
                color: AppColors.accentStrong,
                label: SalesAnalyticsStrings.profitLegend,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label:
                '${SalesAnalyticsStrings.sales}: ${formatIqd(totalSales)}. '
                '${SalesAnalyticsStrings.netProfit}: ${formatIqd(totalProfit)}.',
            image: true,
            child: SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _TrendPainter(
                  points: points,
                  salesColor: AppColors.primary,
                  profitColor: AppColors.accentStrong,
                  gridColor: AppColors.divider,
                ),
              ),
            ),
          ),
          if (points.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: Text(formatDate(points.first.bucket))),
                if (points.length > 1)
                  Expanded(
                    child: Text(
                      formatDate(points.last.bucket),
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.points,
    required this.salesColor,
    required this.profitColor,
    required this.gridColor,
  });

  final List<SalesAnalyticsTrendPoint> points;
  final Color salesColor;
  final Color profitColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = 8.0;
    final chart = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: .75)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chart.top + chart.height * i / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    if (points.isEmpty) return;
    final maximum = points.fold<num>(1, (value, point) {
      return math.max(value, math.max(point.salesTotal, point.netProfit));
    }).toDouble();
    _drawSeries(canvas, chart, maximum, [
      for (final point in points) point.salesTotal.toDouble(),
    ], salesColor);
    _drawSeries(canvas, chart, maximum, [
      for (final point in points) point.netProfit.toDouble(),
    ], profitColor);
  }

  void _drawSeries(
    Canvas canvas,
    Rect chart,
    double maximum,
    List<double> values,
    Color color,
  ) {
    final path = Path();
    final pointsOffsets = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? chart.center.dx
          : chart.left + chart.width * index / (values.length - 1);
      final y = chart.bottom - chart.height * (values[index] / maximum);
      final offset = Offset(x, y);
      pointsOffsets.add(offset);
      index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dotPaint = Paint()..color = color;
    for (final offset in pointsOffsets) {
      canvas.drawCircle(offset, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.salesColor != salesColor ||
      oldDelegate.profitColor != profitColor ||
      oldDelegate.gridColor != gridColor;
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products});

  final List<SalesAnalyticsTopProduct> products;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        children: [
          for (final (index, product) in products.indexed) ...[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppColors.accent
                          : AppColors.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      formatNumber(index + 1),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: index == 0
                            ? AppColors.onAccent
                            : AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.localizedName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Text(
                              SalesAnalyticsStrings.productUnits(
                                formatNumber(product.unitsSold),
                              ),
                            ),
                            Text(
                              SalesAnalyticsStrings.productOrders(
                                formatNumber(product.orderCount),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _InlineValue(
                              label: SalesAnalyticsStrings.productSales,
                              value: formatIqd(product.salesTotal),
                              color: AppColors.primary,
                            ),
                            _InlineValue(
                              label: SalesAnalyticsStrings.productProfit,
                              value: formatIqd(product.netProfit),
                              color: AppColors.success,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (index != products.length - 1)
              const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
          ],
        ],
      ),
    );
  }
}

class _InlineValue extends StatelessWidget {
  const _InlineValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.statuses});

  final List<SalesAnalyticsStatusCount> statuses;

  @override
  Widget build(BuildContext context) {
    final maximum = statuses.fold<int>(
      1,
      (value, item) => math.max(value, item.orderCount),
    );
    return AppCard(
      child: Column(
        children: [
          for (final (index, item) in statuses.indexed) ...[
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.status.softColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.status.icon,
                    size: 19,
                    color: item.status.color,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.status.labelAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            formatNumber(item.orderCount),
                            style: TextStyle(
                              color: item.status.color,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: item.orderCount / maximum,
                          minHeight: 6,
                          color: item.status.color,
                          backgroundColor: item.status.softColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (index != statuses.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}
