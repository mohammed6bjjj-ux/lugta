import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/sales_analytics.dart';
import 'package:flutter_app/features/profile/sales_analytics_screen.dart';
import 'package:flutter_app/features/profile/sales_analytics_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    appSettings.setLanguage(AppLanguage.ar);
    AppColors.p = AppPalette.light;
  });

  testWidgets('analytics is usable at 320dp and 200% text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: SalesAnalyticsScreen(
          loader: (from, to) async => _fixture(from: from, to: to),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(SalesAnalyticsStrings.title), findsOneWidget);
    expect(find.text(SalesAnalyticsStrings.netProfit), findsWidgets);
    expect(
      find.byKey(const ValueKey('analytics_period_month')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('analytics_period_year')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const ValueKey('sales_analytics_scroll')),
      const Offset(0, -2200),
    );
    await tester.pumpAndSettle();
    expect(find.text(SalesAnalyticsStrings.statusDistribution), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('analytics error exposes a working retry action', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: SalesAnalyticsScreen(
          loader: (from, to) async {
            calls += 1;
            if (calls == 1) throw Exception('offline');
            return _fixture(from: from, to: to);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sales_analytics_error')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sales_analytics_retry')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const ValueKey('sales_analytics_error')), findsNothing);
    expect(find.text(SalesAnalyticsStrings.netProfit), findsWidgets);
  });
}

SalesAnalyticsSnapshot _fixture({
  required DateTime from,
  required DateTime to,
}) {
  return SalesAnalyticsSnapshot(
    from: from,
    to: to,
    previousFrom: from.subtract(to.difference(from)),
    granularity: 'day',
    current: const SalesAnalyticsSummary(
      orderCount: 18,
      completedCount: 12,
      unsuccessfulCount: 2,
      unitsSold: 21,
      salesTotal: 425000,
      netProfit: 118000,
      pendingProfit: 27000,
      deliveryContribution: 15000,
      averageOrderValue: 35417,
      successRate: 85.7,
    ),
    previous: const SalesAnalyticsSummary(
      orderCount: 14,
      completedCount: 9,
      netProfit: 92000,
      salesTotal: 340000,
    ),
    trend: [
      SalesAnalyticsTrendPoint(
        bucket: from,
        orderCount: 6,
        completedCount: 4,
        salesTotal: 120000,
        netProfit: 32000,
      ),
      SalesAnalyticsTrendPoint(
        bucket: from.add(const Duration(days: 8)),
        orderCount: 5,
        completedCount: 4,
        salesTotal: 140000,
        netProfit: 39000,
      ),
      SalesAnalyticsTrendPoint(
        bucket: from.add(const Duration(days: 16)),
        orderCount: 7,
        completedCount: 4,
        salesTotal: 165000,
        netProfit: 47000,
      ),
    ],
    statuses: const [
      SalesAnalyticsStatusCount(status: OrderStatus.completed, orderCount: 12),
      SalesAnalyticsStatusCount(status: OrderStatus.confirmed, orderCount: 4),
      SalesAnalyticsStatusCount(status: OrderStatus.returned, orderCount: 2),
    ],
    topProducts: const [
      SalesAnalyticsTopProduct(
        productId: 'watch-1',
        nameAr: 'ساعة رجالية كلاسيكية',
        orderCount: 8,
        unitsSold: 10,
        salesTotal: 210000,
        netProfit: 68000,
      ),
      SalesAnalyticsTopProduct(
        productId: 'watch-2',
        nameAr: 'ساعة نسائية',
        orderCount: 5,
        unitsSold: 7,
        salesTotal: 145000,
        netProfit: 36000,
      ),
    ],
  );
}
