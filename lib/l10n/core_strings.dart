import '../data/app_settings.dart';

/// نصوص النواة المشتركة (الشِل، بطاقة المنتج، بطاقة الحسبة، عامة)
/// بثلاث لغات. كل ميزة لها ملف نصوصها الخاص بنفس النمط.
class CoreStrings {
  CoreStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  // ── عام ──
  static String get appTitle => _t('لكطة', 'لكطة', 'Lugta');
  static String get unknownRouteTitle =>
      _t('صفحة غير موجودة', 'پەڕە نەدۆزرایەوە', 'Page not found');
  static String get unknownRouteBody => _t(
    'المسار المطلوب غير معرّف',
    'ئەو ڕێگەیەی داواکراوە پێناسە نەکراوە',
    'The requested route is not defined',
  );
  static String get refreshTooltip =>
      _t('تحديث البيانات', 'نوێکردنەوەی داتا', 'Refresh data');
  static String get increaseQuantity =>
      _t('زيادة الكمية', 'زیادکردنی بڕ', 'Increase quantity');
  static String get decreaseQuantity =>
      _t('تقليل الكمية', 'کەمکردنەوەی بڕ', 'Decrease quantity');
  static String get refreshFailed => _t(
    'تعذر تحديث البيانات. تحقق من الإنترنت وحاول مرة أخرى.',
    'نوێکردنەوەی داتا سەرکەوتوو نەبوو. ئینتەرنێت بپشکنەوە و دووبارە هەوڵ بدە.',
    'Could not refresh data. Check your connection and try again.',
  );
  static String get imageUnavailableTapToRetry => _t(
    'تعذر تحميل الصورة\nاضغط لإعادة المحاولة',
    'وێنەکە بارنەکرا\nبۆ هەوڵدانەوە دەستی لێبدە',
    'Image could not load\nTap to retry',
  );

  // ── تبويبات الشِل ──
  static String get tabHome => _t('الرئيسية', 'سەرەکی', 'Home');
  static String get tabProducts => _t('المنتجات', 'بەرهەمەکان', 'Products');
  static String get tabOrders => _t('طلباتي', 'داواکارییەکانم', 'Orders');
  static String get tabWallet => _t('المحفظة', 'جزدان', 'Wallet');
  static String get tabProfile => _t('حسابي', 'هەژمارم', 'Account');

  // ── بطاقة المنتج ──
  static String get wholesaleShort => _t('الجملة', 'کۆمەڵ', 'Wholesale');
  static String sellsFor(String price) =>
      _t('يُباع $price', 'دەفرۆشرێت بە $price', 'Sells $price');
  static String get badgeNew => _t('جديد', 'نوێ', 'New');
  static String get badgeOutOfStock => _t('نفد', 'نەماوە', 'Out');
  static String badgeLeft(String count) =>
      _t('بقي $count', '$count ماوە', '$count left');
  static String badgeDiscount(String percent) =>
      _t('٪$percent-', '٪$percent-', '-$percent%');
  static String get addToFavorites =>
      _t('إضافة إلى المفضلة', 'زیادکردن بۆ دڵخوازەکان', 'Add to favorites');
  static String get removeFromFavorites =>
      _t('إزالة من المفضلة', 'لابردن لە دڵخوازەکان', 'Remove from favorites');

  // ── بطاقة الحسبة ──
  static String get priceSummaryTitle =>
      _t('تفاصيل الحسبة', 'وردەکاری ژمێرکاری', 'Price breakdown');
  static String priceSummaryTitleWithQty(String qty) => _t(
    'تفاصيل الحسبة ($qty قطعة)',
    'وردەکاری ژمێرکاری ($qty دانە)',
    'Price breakdown ($qty pcs)',
  );
  static String get wholesalePrice =>
      _t('سعر الجملة', 'نرخی کۆمەڵ', 'Wholesale price');
  static String get salePrice => _t('سعر البيع', 'نرخی فرۆشتن', 'Sale price');
  static String get yourProfit =>
      _t('ربحك من الطلب', 'قازانجی تۆ لەم داواکارییەدا', 'Your profit');
  static String get deliveryFeeOnCustomer => _t(
    'أجرة التوصيل (على الزبون)',
    'کرێی گەیاندن (لەسەر کڕیار)',
    'Delivery fee (on customer)',
  );
  static String get packagingFeeOnCustomer => _t(
    'التعليب (على الزبون)',
    'پاکەتکردن (لەسەر کڕیار)',
    'Packaging (on customer)',
  );
  static String get deliveryDiscount => _t(
    'خصم التوصيل المجاني',
    'داشکاندنی گەیاندنی خۆڕایی',
    'Free-delivery discount',
  );
  static String get customerTotal =>
      _t('المبلغ النهائي على الزبون', 'کۆی گشتی لەسەر کڕیار', 'Customer total');
}
