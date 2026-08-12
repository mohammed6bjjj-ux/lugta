import '../../data/app_settings.dart';

class CartStrings {
  CartStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  static String get title => _t('سلة الطلب', 'سەبەتەی داواکاری', 'Order cart');
  static String get openCart => _t('فتح السلة', 'کردنەوەی سەبەتە', 'Open cart');
  static String get emptyTitle =>
      _t('السلة فارغة', 'سەبەتەکە بەتاڵە', 'Your cart is empty');
  static String get emptySubtitle => _t(
    'أضف المنتجات التي تريد إرسالها لنفس الزبون، ثم أنشئها كطلب واحد.',
    'ئەو بەرهەمانە زیاد بکە کە دەتەوێت بۆ هەمان کڕیار بنێریت، پاشان وەک یەک داواکاری دروستی بکە.',
    'Add products for the same customer, then create them as one order.',
  );
  static String get browseProducts =>
      _t('تصفح المنتجات', 'بینینی بەرهەمەکان', 'Browse products');
  static String get addToCart =>
      _t('أضف للسلة', 'زیادکردن بۆ سەبەتە', 'Add to cart');
  static String get buyNow => _t('اطلب الآن', 'ئێستا داوا بکە', 'Buy now');
  static String get addedToCart =>
      _t('تمت الإضافة إلى السلة', 'زیاد کرا بۆ سەبەتە', 'Added to cart');
  static String get configureProduct => _t(
    'جهّز المنتج للسلة',
    'بەرهەمەکە بۆ سەبەتە ئامادە بکە',
    'Configure for cart',
  );
  static String get editConfiguration => _t(
    'تعديل خيارات المنتج',
    'دەستکاریکردنی هەڵبژاردەکانی بەرهەم',
    'Edit product options',
  );
  static String get configureProductSubtitle => _t(
    'حدّد سعر البيع والكمية والعلبة قبل الإضافة.',
    'پێش زیادکردن نرخی فرۆشتن و ژمارە و قاپ دیاری بکە.',
    'Choose the sale price, quantity, and box before adding.',
  );
  static String get quantity => _t('الكمية', 'ژمارە', 'Quantity');
  static String availableStock(String count) =>
      _t('المتوفر $count قطعة', '$count دانە بەردەستە', '$count available');
  static String reservedForYou(String count) => _t(
    'من حجزك الألماسي: $count قطعة',
    'لە حجزە ئەڵماسییەکەت: $count دانە',
    '$count from your Diamond reservation',
  );
  static String priceRange(String minimum, String maximum) => _t(
    'سعر البيع من $minimum إلى $maximum',
    'نرخی فرۆشتن لە $minimum بۆ $maximum',
    'Sale price from $minimum to $maximum',
  );
  static String get packagingChargedPerPiece => _t(
    'اختيارية، وسعرها يُحسب لكل قطعة.',
    'ئارەزوومەندانەیە و نرخەکەی بۆ هەر دانەیەک ژمێردرێت.',
    'Optional; its price is charged per piece.',
  );
  static String get noPackagingBoxesAvailable => _t(
    'لا توجد علب متاحة حالياً.',
    'لە ئێستادا هیچ قاپێک بەردەست نییە.',
    'No boxes are available right now.',
  );
  static String get productsTotal =>
      _t('سعر القطع', 'نرخی کاڵاکان', 'Items price');
  static String get customerSubtotal => _t(
    'المطلوب قبل التوصيل',
    'داواکراو پێش گەیاندن',
    'Subtotal before delivery',
  );
  static String get addConfiguredToCart => _t(
    'تأكيد وإضافة للسلة',
    'پشتڕاستکردنەوە و زیادکردن بۆ سەبەتە',
    'Confirm and add to cart',
  );
  static String get updateCart => _t(
    'حفظ تعديلات السلة',
    'پاشەکەوتکردنی گۆڕانکارییەکان',
    'Save cart changes',
  );
  static String get editOptions =>
      _t('تعديل الخيارات', 'دەستکاری هەڵبژاردەکان', 'Edit options');
  static String get editOptionsShort => _t('تعديل', 'دەستکاری', 'Edit');
  static String cartReadySubtitle(String productName, String count) => _t(
    'تمت إضافة $productName. السلة الآن تحتوي $count قطعة.',
    '$productName زیاد کرا. ئێستا $count دانە لە سەبەتەکەدایە.',
    '$productName added. The cart now has $count pieces.',
  );
  static String get viewCart => _t('عرض السلة', 'بینینی سەبەتە', 'View cart');
  static String get chooseVariantFirst => _t(
    'اختر اللون أو الخيار المطلوب أولاً.',
    'سەرەتا ڕەنگ یان جۆری داواکراو هەڵبژێرە.',
    'Choose a variant first.',
  );
  static String get cartStep => _t('السلة', 'سەبەتە', 'Cart');
  static String get customerStep => _t('الزبون', 'کڕیار', 'Customer');
  static String get reviewStep => _t('المراجعة', 'پێداچوونەوە', 'Review');
  static String get itemsTitle => _t(
    'منتجات هذا الطلب',
    'بەرهەمەکانی ئەم داواکارییە',
    'Products in this order',
  );
  static String piecesAndProducts(String pieces, String products) => _t(
    '$pieces قطعة من $products منتج',
    '$pieces دانە لە $products بەرهەم',
    '$pieces pieces across $products products',
  );
  static String get salePrice =>
      _t('سعر البيع للقطعة', 'نرخی فرۆشتنی دانە', 'Sale price per piece');
  static String get salePriceRequired =>
      _t('أدخل سعر البيع.', 'نرخی فرۆشتن بنووسە.', 'Enter the sale price.');
  static String minimumPrice(String amount) =>
      _t('الحد الأدنى $amount', 'کەمترین نرخ $amount', 'Minimum $amount');
  static String maximumPrice(String amount) =>
      _t('الحد الأعلى $amount', 'زۆرترین نرخ $amount', 'Maximum $amount');
  static String get packaging => _t('العلبة', 'قاپ', 'Packaging');
  static String get choosePackaging =>
      _t('اختر علبة', 'قاپ هەڵبژێرە', 'Choose a box');
  static String get noPackaging => _t('بدون علبة', 'بێ قاپ', 'No packaging');
  static String get free => _t('مجانية', 'خۆڕایی', 'Free');
  static String get remove => _t('حذف', 'سڕینەوە', 'Remove');
  static String get clearCart =>
      _t('تفريغ السلة', 'بەتاڵکردنی سەبەتە', 'Clear cart');
  static String get clearCartTitle =>
      _t('تفريغ السلة؟', 'سەبەتەکە بەتاڵ بکرێتەوە؟', 'Clear the cart?');
  static String get clearCartBody => _t(
    'سيتم حذف جميع المنتجات المضافة.',
    'هەموو بەرهەمە زیادکراوەکان دەسڕدرێنەوە.',
    'All added products will be removed.',
  );
  static String get cancel => _t('إلغاء', 'هەڵوەشاندنەوە', 'Cancel');
  static String get continueToCustomer => _t(
    'متابعة إلى بيانات الزبون',
    'بەردەوامبوون بۆ زانیاری کڕیار',
    'Continue to customer details',
  );
  static String get reviewOrder =>
      _t('مراجعة الطلب', 'پێداچوونەوەی داواکاری', 'Review order');
  static String get confirmOrder =>
      _t('تأكيد الطلب', 'پشتڕاستکردنەوەی داواکاری', 'Confirm order');
  static String get back => _t('السابق', 'پێشوو', 'Back');
  static String get invalidPrices => _t(
    'راجع أسعار البيع المعلّمة قبل المتابعة.',
    'پێش بەردەوامبوون نرخە دیاریکراوەکان بپشکنە.',
    'Review the highlighted sale prices before continuing.',
  );
  static String get changedBeforeSubmit => _t(
    'تغيّر المخزون أو السعر أو التعليب. حدثنا السلة؛ راجعها ثم أكد من جديد.',
    'کۆگا یان نرخ یان قاپ گۆڕاوە. سەبەتەکە نوێ کرایەوە؛ بیپشکنە و دووبارە پشتڕاستی بکەوە.',
    'Stock, pricing, or packaging changed. Review the updated cart and confirm again.',
  );
  static String get summary =>
      _t('ملخص الحساب', 'پوختەی حساب', 'Price summary');
  static String get wholesaleTotal =>
      _t('إجمالي الجملة', 'کۆی کۆمەڵ', 'Wholesale total');
  static String get saleTotal => _t('إجمالي البيع', 'کۆی فرۆشتن', 'Sale total');
  static String get packagingTotal =>
      _t('إجمالي العلب', 'کۆی قاپەکان', 'Packaging total');
  static String get profitTotal =>
      _t('إجمالي ربحك', 'کۆی قازانجت', 'Your total profit');
  static String get deliveryFee =>
      _t('أجرة التوصيل', 'کرێی گەیاندن', 'Delivery fee');
  static String get customerTotal =>
      _t('المطلوب من الزبون', 'داواکراو لە کڕیار', 'Customer total');
  static String multipleProducts(String count) => _t(
    '$count منتجات في طلب واحد',
    '$count بەرهەم لە یەک داواکاریدا',
    '$count products in one order',
  );
}
