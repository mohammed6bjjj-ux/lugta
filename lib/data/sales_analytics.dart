import 'app_settings.dart';
import 'models.dart';

class SalesAnalyticsSummary {
  const SalesAnalyticsSummary({
    this.orderCount = 0,
    this.completedCount = 0,
    this.unsuccessfulCount = 0,
    this.unitsSold = 0,
    this.salesTotal = 0,
    this.netProfit = 0,
    this.pendingProfit = 0,
    this.deliveryContribution = 0,
    this.averageOrderValue = 0,
    this.successRate = 0,
  });

  final int orderCount;
  final int completedCount;
  final int unsuccessfulCount;
  final int unitsSold;
  final int salesTotal;
  final int netProfit;
  final int pendingProfit;
  final int deliveryContribution;
  final int averageOrderValue;
  final double successRate;
}

class SalesAnalyticsTrendPoint {
  const SalesAnalyticsTrendPoint({
    required this.bucket,
    required this.orderCount,
    required this.completedCount,
    required this.salesTotal,
    required this.netProfit,
  });

  final DateTime bucket;
  final int orderCount;
  final int completedCount;
  final int salesTotal;
  final int netProfit;
}

class SalesAnalyticsStatusCount {
  const SalesAnalyticsStatusCount({
    required this.status,
    required this.orderCount,
  });

  final OrderStatus status;
  final int orderCount;
}

class SalesAnalyticsTopProduct {
  const SalesAnalyticsTopProduct({
    required this.productId,
    required this.nameAr,
    required this.orderCount,
    required this.unitsSold,
    required this.salesTotal,
    required this.netProfit,
    this.nameCkb,
    this.nameEn,
  });

  final String productId;
  final String nameAr;
  final String? nameCkb;
  final String? nameEn;
  final int orderCount;
  final int unitsSold;
  final int salesTotal;
  final int netProfit;

  String get localizedName => switch (appSettings.language) {
    AppLanguage.ckb => nameCkb?.trim().isNotEmpty == true ? nameCkb! : nameAr,
    AppLanguage.en => nameEn?.trim().isNotEmpty == true ? nameEn! : nameAr,
    AppLanguage.ar => nameAr,
  };
}

class SalesAnalyticsSnapshot {
  const SalesAnalyticsSnapshot({
    required this.from,
    required this.to,
    required this.previousFrom,
    required this.granularity,
    required this.current,
    required this.previous,
    this.trend = const <SalesAnalyticsTrendPoint>[],
    this.statuses = const <SalesAnalyticsStatusCount>[],
    this.topProducts = const <SalesAnalyticsTopProduct>[],
  });

  final DateTime from;
  final DateTime to;
  final DateTime previousFrom;
  final String granularity;
  final SalesAnalyticsSummary current;
  final SalesAnalyticsSummary previous;
  final List<SalesAnalyticsTrendPoint> trend;
  final List<SalesAnalyticsStatusCount> statuses;
  final List<SalesAnalyticsTopProduct> topProducts;

  bool get isEmpty => current.orderCount == 0;
}
