import '../../data/app_settings.dart';

/// نصوص واجهة الكتالوج (الرئيسية، المنتجات، البحث، المفضلة، الفلاتر)
/// بثلاث لغات — بنفس نمط [CoreStrings].
class CatalogStrings {
  CatalogStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  // ── الرئيسية ──
  static String get favorites => _t('المفضلة', 'دڵخوازەکان', 'Favorites');
  static String get notifications =>
      _t('الإشعارات', 'ئاگادارکردنەوەکان', 'Notifications');
  static String get shopByCategory =>
      _t('تسوّق حسب التصنيف', 'بەپێی پۆل بازاڕ بکە', 'Shop by category');
  static String get newArrivals =>
      _t('وصل حديثاً', 'تازە گەیشتووەکان', 'New arrivals');
  static String get bestSellers =>
      _t('الأكثر طلباً', 'زۆرترین داواکراوەکان', 'Best sellers');

  // ── إعلان الفتح ──
  static String get promoNewArrivalsTitle =>
      _t('وصلت لَگطات جديدة', 'لقطەی نوێ گەیشت', 'New finds just landed');
  static String get promoSwipeUp =>
      _t('اسحب لفوق', 'بەرەو سەرەوە ڕایبکێشە', 'Swipe up');
  static String get promoDismiss => _t('تخطّي', 'تێپەڕاندن', 'Dismiss');
  static String get promoProductImage =>
      _t('صورة المنتج', 'وێنەی بەرهەم', 'Product image');
  static String get searchHint =>
      _t('ابحث عن منتج...', 'بەدوای بەرهەمێکدا بگەڕێ...', 'Search products...');

  // ── صفحة المنتجات ──
  static String get categoryButton => _t('الفئة', 'پۆل', 'Category');
  static String get chooseCategory =>
      _t('اختر الفئة', 'پۆلێک هەڵبژێرە', 'Choose a category');
  static String get allCategories =>
      _t('كل الفئات', 'هەموو پۆلەکان', 'All categories');
  static String get sortProductsTitle =>
      _t('ترتيب المنتجات', 'ڕیزکردنی بەرهەمەکان', 'Sort products');
  static String get sortButton => _t('الترتيب', 'ڕیزکردن', 'Sort');
  static String get refineButton => _t('التصنيف', 'پاڵێوەرەکان', 'Filters');
  static String get hotDeals =>
      _t('التخفيضات 🔥', 'داشکاندنەکان 🔥', 'Hot deals 🔥');
  static String get allProducts =>
      _t('كل المنتجات', 'هەموو بەرهەمەکان', 'All products');
  static String productsCount(String count) =>
      _t('$count منتج', '$count بەرهەم', '$count products');
  static String get noMatchingResults => _t(
    'لا توجد نتائج مطابقة',
    'هیچ ئەنجامێکی گونجاو نەدۆزرایەوە',
    'No matching results',
  );
  static String get noMatchingResultsHint => _t(
    'جرّب تعديل البحث أو الفئة أو فلاتر التصنيف.',
    'هەوڵبدە گەڕانەکە یان پۆل یان پاڵێوەرەکان بگۆڕیت.',
    'Try adjusting your search, category, or filters.',
  );
  static String get resetAll =>
      _t('إعادة تعيين الكل', 'ڕێکخستنەوەی هەمووی', 'Reset all');

  // ── البحث ──
  static String get searchLongHint => _t(
    'ابحث عن ساعات، نظارات، إكسسوارات...',
    'بەدوای کاتژمێر، چاویلکە، ئێکسسوار بگەڕێ...',
    'Search watches, glasses, accessories...',
  );
  static String get clear => _t('مسح', 'سڕینەوە', 'Clear');
  static String get recentSearches =>
      _t('عمليات بحث سابقة', 'گەڕانە پێشووەکان', 'Recent searches');
  static String get clearAll => _t('مسح الكل', 'سڕینەوەی هەمووی', 'Clear all');
  static String get remove => _t('حذف', 'سڕینەوە', 'Remove');
  static String get suggestedCategories =>
      _t('تصنيفات مقترحة', 'پۆلە پێشنیارکراوەکان', 'Suggested categories');
  static String noResultsFor(String query) => _t(
    'لا نتائج لـ «$query»',
    'هیچ ئەنجامێک نییە بۆ «$query»',
    'No results for "$query"',
  );
  static String get noResultsHint => _t(
    'تأكد من الكلمات أو جرّب البحث باسم التصنيف مثل «ساعات».',
    'لە وشەکان دڵنیابە یان بە ناوی پۆلەکە بگەڕێ وەک «کاتژمێر».',
    'Check your spelling or try a category name like "Watches".',
  );
  static String resultsCountFor(String count, String query) => _t(
    '$count نتيجة لـ «$query»',
    '$count ئەنجام بۆ «$query»',
    '$count results for "$query"',
  );

  // ── المفضلة ──
  static String get favoritesEmptyTitle => _t(
    'لا توجد منتجات في المفضلة',
    'هیچ بەرهەمێک لە دڵخوازەکاندا نییە',
    'No favorites yet',
  );
  static String get favoritesEmptySubtitle => _t(
    'اضغط على أيقونة القلب في أي منتج لحفظه هنا والرجوع إليه بسرعة.',
    'کرتە لە ئایکۆنی دڵ بکە لەسەر هەر بەرهەمێک بۆ ئەوەی لێرە هەڵبگیرێت و بە خێرایی بیدۆزیتەوە.',
    'Tap the heart icon on any product to save it here.',
  );
  static String get browseProducts =>
      _t('تصفح المنتجات', 'بە بەرهەمەکاندا بگەڕێ', 'Browse products');
  static String productsCountWithOutOfStock(String total, String out) => _t(
    '$total منتج — منها $out نافد حالياً',
    '$total بەرهەم — $out لەوانە ئێستا نەماوە',
    '$total products — $out currently out of stock',
  );

  // ── منتجات التصنيف ──
  static String get filtersAndSort =>
      _t('الفلاتر والترتيب', 'پاڵێوەر و ڕیزکردن', 'Filters & sort');
  static String get noProductsMatchFilters => _t(
    'لا توجد منتجات مطابقة للفلاتر',
    'هیچ بەرهەمێک لەگەڵ پاڵێوەرەکان ناگونجێت',
    'No products match your filters',
  );
  static String get noProductsMatchFiltersHint => _t(
    'جرّب توسيع نطاق سعر الجملة أو إلغاء خيار «المتوفر فقط».',
    'هەوڵبدە مەودای نرخی کۆمەڵ فراوانتر بکەیت یان «تەنها بەردەستەکان» لاببەیت.',
    'Try widening the wholesale price range or turning off "In stock only".',
  );
  static String get resetFilters =>
      _t('إعادة تعيين الفلاتر', 'ڕێکخستنەوەی پاڵێوەرەکان', 'Reset filters');
  static String get emptyCategoryTitle => _t(
    'لا توجد منتجات في هذا التصنيف حالياً',
    'ئێستا هیچ بەرهەمێک لەم پۆلەدا نییە',
    'No products in this category yet',
  );
  static String get emptyCategorySubtitle => _t(
    'نضيف منتجات جديدة باستمرار — تابع الإشعارات ليصلك الجديد أولاً.',
    'بەردەوام بەرهەمی نوێ زیاد دەکەین — چاودێری ئاگادارکردنەوەکان بکە بۆ ئەوەی نوێیەکانت یەکەم جار پێ بگەن.',
    'We add new products all the time — watch notifications to catch them first.',
  );
  static String get resetTheFilters =>
      _t('إعادة التعيين', 'ڕێکخستنەوە', 'Reset');

  // ── ورقة الفلاتر ──
  static String get categorySection => _t('التصنيف', 'پۆل', 'Category');
  static String get wholesalePricePerPiece => _t(
    'سعر الجملة (للقطعة الواحدة)',
    'نرخی کۆمەڵ (بۆ یەک دانە)',
    'Wholesale price (per piece)',
  );
  static String get inStockOnly =>
      _t('المتوفر فقط', 'تەنها بەردەستەکان', 'In stock only');
  static String get hideOutOfStock => _t(
    'إخفاء المنتجات التي نفد مخزونها',
    'شاردنەوەی ئەو بەرهەمانەی کۆگاکەیان نەماوە',
    'Hide out-of-stock products',
  );
  static String get sortSection => _t('الترتيب', 'ڕیزکردن', 'Sort by');
  static String get apply => _t('تطبيق', 'جێبەجێکردن', 'Apply');
  static String get reset => _t('إعادة تعيين', 'ڕێکخستنەوە', 'Reset');
}
