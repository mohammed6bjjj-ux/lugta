import '../../data/app_settings.dart';

abstract final class SalesAnalyticsStrings {
  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  static String get title => _t('الإحصائيات', 'ئامارەکان', 'Analytics');
  static String get settingsSubtitle => _t(
    'مبيعاتك وأرباحك وأداء الطلبات حسب الفترة',
    'فرۆشتن و قازانج و ئەدای داواکارییەکان بەپێی ماوە',
    'Sales, profit, and order performance by period',
  );
  static String get week => _t('أسبوع', 'هەفتە', 'Week');
  static String get month => _t('شهر', 'مانگ', 'Month');
  static String get year => _t('سنة', 'ساڵ', 'Year');
  static String get overview =>
      _t('ملخص الفترة', 'پوختەی ماوە', 'Period overview');
  static String get comparedWithPrevious => _t(
    'مقارنةً بالفترة السابقة',
    'بەراورد بە ماوەی پێشوو',
    'Compared with the previous period',
  );
  static String get noPreviousData => _t(
    'لا توجد بيانات سابقة للمقارنة',
    'داتای پێشوو بۆ بەراورد نییە',
    'No previous data to compare',
  );
  static String get sales => _t('إجمالي المبيعات', 'کۆی فرۆشتن', 'Total sales');
  static String get netProfit =>
      _t('الربح الصافي', 'قازانجی پاک', 'Net profit');
  static String get orders => _t('الطلبات', 'داواکارییەکان', 'Orders');
  static String get completed => _t('المكتملة', 'تەواوبووەکان', 'Completed');
  static String get unitsSold =>
      _t('القطع المباعة', 'پارچە فرۆشراوەکان', 'Units sold');
  static String get averageOrder =>
      _t('متوسط الطلب', 'تێکڕای داواکاری', 'Average order');
  static String get pendingProfit =>
      _t('ربح قيد الانتظار', 'قازانجی چاوەڕوان', 'Pending profit');
  static String get deliveryContribution =>
      _t('التوصيل المتحمّل', 'بەشی گواستنەوە', 'Delivery covered');
  static String get successRate =>
      _t('نسبة النجاح', 'ڕێژەی سەرکەوتن', 'Success rate');
  static String get unsuccessful =>
      _t('غير الناجحة', 'سەرنەکەوتوو', 'Unsuccessful');
  static String get performance => _t(
    'أداء المبيعات والربح',
    'ئەدای فرۆشتن و قازانج',
    'Sales and profit trend',
  );
  static String get salesLegend => _t('المبيعات', 'فرۆشتن', 'Sales');
  static String get profitLegend => _t('الربح', 'قازانج', 'Profit');
  static String get topProducts =>
      _t('أفضل المنتجات', 'باشترین بەرهەمەکان', 'Top products');
  static String get statusDistribution =>
      _t('حالات الطلبات', 'دۆخی داواکارییەکان', 'Order statuses');
  static String get productSales => _t('المبيعات', 'فرۆشتن', 'Sales');
  static String get productProfit => _t('الربح', 'قازانج', 'Profit');
  static String productUnits(String count) =>
      _t('$count قطعة', '$count پارچە', '$count units');
  static String productOrders(String count) =>
      _t('$count طلب', '$count داواکاری', '$count orders');
  static String get emptyTitle => _t(
    'لا توجد طلبات بهذه الفترة',
    'هیچ داواکارییەک لەم ماوەیەدا نییە',
    'No orders in this period',
  );
  static String get emptySubtitle => _t(
    'جرّب فترة أخرى أو ارجع لاحقاً بعد وصول طلبات جديدة.',
    'ماوەیەکی تر هەڵبژێرە یان دوای داواکاری نوێ بگەڕێوە.',
    'Try another period or return after new orders arrive.',
  );
  static String get loadFailed => _t(
    'تعذر تحميل الإحصائيات',
    'بارکردنی ئامارەکان سەرکەوتوو نەبوو',
    'Could not load analytics',
  );
  static String get retry => _t('إعادة المحاولة', 'هەوڵدانەوە', 'Try again');
  static String get updatedNow => _t(
    'الأرقام محدثة من قاعدة البيانات',
    'ژمارەکان لە بنکەدراوە نوێکراونەتەوە',
    'Numbers are updated from the database',
  );
  static String get newPerformance => _t('جديد', 'نوێ', 'New');
  static String increase(String value) =>
      _t('ارتفاع $value', 'زیادبوون $value', 'Up $value');
  static String decrease(String value) =>
      _t('انخفاض $value', 'کەمبوونەوە $value', 'Down $value');
  static String get unchanged => _t('بدون تغيير', 'بێ گۆڕان', 'No change');
}
