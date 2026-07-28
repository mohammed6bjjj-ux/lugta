import '../../data/app_settings.dart';

/// نصوص معالج إنشاء الطلب وشاشة نجاح الطلب — بثلاث لغات.
class WizardStrings {
  WizardStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  // ── أسماء الخطوات ──
  static String get stepProduct => _t('المنتج', 'بەرهەم', 'Product');
  static String get stepPrice => _t('السعر', 'نرخ', 'Price');
  static String get stepCustomer => _t('الزبون', 'کڕیار', 'Customer');
  static String get stepReview => _t('المراجعة', 'پێداچوونەوە', 'Review');

  // ── الشريط العلوي وحوار الخروج ──
  static String get closeTooltip => _t('إغلاق', 'داخستن', 'Close');
  static String get exitDialogTitle =>
      _t('الخروج من الطلب؟', 'دەرچوون لە داواکارییەکە؟', 'Leave this order?');
  static String get exitDialogBody => _t(
    'ستفقد البيانات المدخلة إذا خرجت الآن.',
    'ئەگەر ئێستا دەربچیت، ئەو زانیارییانەی تۆمارت کردوون لەدەست دەچن.',
    'Your entered data will be lost if you leave now.',
  );
  static String get stay => _t('البقاء', 'مانەوە', 'Stay');
  static String get exit => _t('خروج', 'دەرچوون', 'Leave');

  // ── الشريط السفلي ──
  static String get back => _t('السابق', 'پێشوو', 'Back');
  static String get next => _t('التالي', 'دواتر', 'Next');
  static String get confirmOrder =>
      _t('تأكيد الطلب', 'پشتڕاستکردنەوەی داواکاری', 'Confirm order');

  // ── الخطوة 1: المتغير والكمية ──
  static String get variantsTitle => _t(
    'اختر المتغيرات والكميات',
    'جۆرەکان و بڕەکان هەڵبژێرە',
    'Choose variants & quantities',
  );
  static String get variantsSubtitle => _t(
    'يمكنك اختيار أكثر من متغير بنفس الطلب — الحد الأقصى لكل متغير هو مخزونه المتاح.',
    'دەتوانیت لە هەمان داواکاریدا زیاتر لە جۆرێک هەڵبژێریت — زۆرترین بڕ بۆ هەر جۆرێک ئەوەندەیە کە لە کۆگا بەردەستە.',
    'You can pick multiple variants in one order — each is capped at its available stock.',
  );
  static String totalPieces(String count) =>
      _t('إجمالي القطع: $count', 'کۆی دانەکان: $count', 'Total pieces: $count');
  static String get noPiecesSelected => _t(
    'لم تختر أي قطعة بعد',
    'هێشتا هیچ دانەیەکت هەڵنەبژاردووە',
    'No pieces selected yet',
  );
  static String wholesaleTotal(String amount) => _t(
    'إجمالي الجملة: $amount',
    'کۆی کۆمەڵ: $amount',
    'Wholesale total: $amount',
  );
  static String get increaseQuantityHint => _t(
    'زد الكمية من العدّاد أمام المتغير المطلوب',
    'بڕەکە لە ژمێرەری بەردەم جۆرە داواکراوەکە زیاد بکە',
    'Use the counter next to a variant to add quantity',
  );
  static String stockCount(String count) =>
      _t('المخزون: $count', 'کۆگا: $count', 'Stock: $count');
  static String stockLimited(String count) => _t(
    'المخزون: $count — كمية محدودة!',
    'کۆگا: $count — بڕێکی سنووردارە!',
    'Stock: $count — limited!',
  );
  static String get tooManyVariants => _t(
    'يمكن إضافة 50 خياراً مختلفاً كحد أقصى للطلب الواحد.',
    'بۆ هەر داواکارییەک زۆرترین ٥٠ جۆری جیاواز دەتوانرێت زیاد بکرێت.',
    'An order can contain at most 50 distinct variants.',
  );
  static String get stockChangedBeforeSubmit => _t(
    'تغيّر المخزون أو أحد خيارات المنتج. راجع الكميات المحدّثة ثم أكّد الطلب من جديد.',
    'کۆگا یان یەکێک لە جۆرەکانی بەرهەمەکە گۆڕاوە. بڕە نوێکراوەکان بپشکنە و دووبارە پشتڕاستی بکەوە.',
    'Stock or product options changed. Review the updated quantities, then confirm again.',
  );
  static String get packagingTitle =>
      _t('اختيار العلبة', 'هەڵبژاردنی قاپ', 'Choose packaging');
  static String get packagingSubtitle => _t(
    'اختياري — سعر العلبة يُضاف على الزبون ولا يُخصم من ربحك.',
    'ئارەزوومەندانە — نرخی قاپەکە دەخرێتە سەر کڕیار و لە قازانجت کەم ناکرێتەوە.',
    'Optional — the box price is charged to the customer and does not reduce your profit.',
  );
  static String get noPackaging => _t('بدون علبة', 'بێ قاپ', 'No packaging');
  static String get freePackaging => _t('مجانية', 'خۆڕایی', 'Free');
  static String get packagingChangedBeforeSubmit => _t(
    'العلبة المختارة لم تعد متاحة. اختر علبة أخرى أو أكمل بدون علبة.',
    'ئەو قاپەی هەڵتبژاردووە چیتر بەردەست نییە. قاپێکی تر هەڵبژێرە یان بەبێ قاپ بەردەوام بە.',
    'The selected box is no longer available. Choose another one or continue without packaging.',
  );
  static String get priceChangedBeforeSubmit => _t(
    'تغيّرت حدود سعر المنتج. راجع السعر المحدّث ثم أكّد الطلب من جديد.',
    'سنووری نرخی بەرهەمەکە گۆڕاوە. نرخە نوێکراوەکە بپشکنە و دووبارە پشتڕاستی بکەوە.',
    'The product price limits changed. Review the updated price, then confirm again.',
  );
  static String get deliveryZoneUnavailable => _t(
    'المحافظة المختارة لم تعد متاحة للتوصيل. اختر محافظة أخرى.',
    'ئەو پارێزگایەی هەڵتبژاردووە چیتر بۆ گەیاندن بەردەست نییە. پارێزگایەکی تر هەڵبژێرە.',
    'The selected governorate is no longer available for delivery. Choose another one.',
  );
  static String get deliveryFeeChangedBeforeSubmit => _t(
    'تغيّرت أجرة التوصيل. راجع المبلغ النهائي ثم أكّد الطلب من جديد.',
    'کرێی گەیاندن گۆڕاوە. کۆی کۆتایی بپشکنە و دووبارە پشتڕاستی بکەوە.',
    'The delivery fee changed. Review the final total, then confirm again.',
  );

  // ── الخطوة 2: التسعير ──
  static String get pricingTitle => _t(
    'حدد سعر البيع للقطعة',
    'نرخی فرۆشتن بۆ هەر دانەیەک دیاری بکە',
    'Set your sale price per piece',
  );
  static String get pricingSubtitle => _t(
    'ربحك هو الفرق بين سعر بيعك وسعر الجملة — أجرة التوصيل تُضاف على الزبون.',
    'قازانجی تۆ جیاوازییەکەیە لە نێوان نرخی فرۆشتنت و نرخی کۆمەڵ — کرێی گەیاندن دەخرێتە سەر کڕیار.',
    'Your profit is the gap between your price and wholesale — delivery is charged to the customer.',
  );
  static String get wholesalePerPiece => _t(
    'سعر الجملة للقطعة',
    'نرخی کۆمەڵ بۆ هەر دانەیەک',
    'Wholesale per piece',
  );
  static String get suggestedPrice =>
      _t('السعر المقترح', 'نرخی پێشنیارکراو', 'Suggested price');
  static String get minAllowedPrice =>
      _t('أدنى سعر مسموح', 'کەمترین نرخی ڕێگەپێدراو', 'Minimum allowed price');
  static String get maxAllowedPrice =>
      _t('أقصى سعر مسموح', 'زۆرترین نرخی ڕێگەپێدراو', 'Maximum allowed price');
  static String get salePriceLabel => _t(
    'سعر البيع للقطعة (د.ع)',
    'نرخی فرۆشتن بۆ هەر دانەیەک (د.ع)',
    'Sale price per piece (IQD)',
  );
  static String exampleHint(String value) =>
      _t('مثال: $value', 'نموونە: $value', 'e.g. $value');
  static String cannotSellBelow(String amount) => _t(
    'لا يمكن البيع بأقل من $amount',
    'ناتوانرێت بە کەمتر لە $amount بفرۆشرێت',
    'Cannot sell below $amount',
  );
  static String cannotSellAbove(String amount) => _t(
    'لا يمكن البيع بأكثر من $amount',
    'ناتوانرێت بە زیاتر لە $amount بفرۆشرێت',
    'Cannot sell above $amount',
  );
  static String useSuggestedPrice(String amount) => _t(
    'استخدم السعر المقترح ($amount)',
    'نرخی پێشنیارکراو بەکاربهێنە ($amount)',
    'Use suggested price ($amount)',
  );
  static String get profitCalcTitle =>
      _t('حسبة ربحك', 'ژمێرکاری قازانجەکەت', 'Your profit');
  static String piecesCount(String count) =>
      _t('$count قطعة', '$count دانە', '$count pcs');
  static String get profitPerPiece =>
      _t('ربحك للقطعة', 'قازانجت بۆ هەر دانەیەک', 'Profit per piece');
  static String get totalProfit =>
      _t('إجمالي ربحك', 'کۆی قازانجەکەت', 'Total profit');

  // ── الخطوة 3: الزبون والعنوان ──
  static String get customerTitle => _t(
    'معلومات الزبون والتوصيل',
    'زانیاری کڕیار و گەیاندن',
    'Customer & delivery info',
  );
  static String get customerSubtitle => _t(
    'تأكد من دقة رقم الهاتف والعنوان — شركة التوصيل ستعتمد عليها.',
    'دڵنیابە لە دروستی ژمارەی تەلەفۆن و ناونیشانەکە — کۆمپانیای گەیاندن پشتیان پێ دەبەستێت.',
    'Double-check the phone and address — the courier relies on them.',
  );
  static String get customerName =>
      _t('اسم الزبون', 'ناوی کڕیار', 'Customer name');
  static String get customerNameHint =>
      _t('الاسم الثلاثي للزبون', 'ناوی سیانی کڕیار', 'Customer full name');
  static String get customerNameRequired =>
      _t('اسم الزبون مطلوب', 'ناوی کڕیار پێویستە', 'Customer name is required');
  static String get customerPhone =>
      _t('رقم هاتف الزبون', 'ژمارەی تەلەفۆنی کڕیار', 'Customer phone');
  static String get altPhone => _t(
    'رقم هاتف بديل (اختياري)',
    'ژمارەی تەلەفۆنی یەدەگ (ئارەزوومەندانە)',
    'Alternate phone (optional)',
  );
  static String get governorate => _t('المحافظة', 'پارێزگا', 'Governorate');
  static String get selectGovernorate =>
      _t('اختر المحافظة', 'پارێزگا هەڵبژێرە', 'Select governorate');
  static String deliveryFeeIs(String amount) => _t(
    'أجرة التوصيل: $amount',
    'کرێی گەیاندن: $amount',
    'Delivery fee: $amount',
  );
  static String get freeDelivery => _t(
    'التوصيل مجاني لهذا الطلب',
    'گەیاندن بۆ ئەم داواکارییە خۆڕاییە',
    'Free delivery for this order',
  );
  static String get checkingDeliveryOffer => _t(
    'جاري فحص عرض التوصيل...',
    'پشکنینی ئۆفەری گەیاندن...',
    'Checking delivery offer...',
  );
  static String get addressLabel => _t(
    'العنوان التفصيلي / أقرب نقطة دالة',
    'ناونیشانی ورد / نزیکترین شوێنی ناسراو',
    'Detailed address / nearest landmark',
  );
  static String get addressHint => _t(
    'مثال: حي الجامعة — قرب مطعم الخيمة، زقاق 5، بيت أبيض',
    'نموونە: گەڕەکی زانکۆ — نزیک چێشتخانەی خەیمە، کۆڵانی ٥، خانووی سپی',
    'e.g. University district — near Al-Khaima restaurant, alley 5, white house',
  );
  static String get addressRequired => _t(
    'العنوان التفصيلي مطلوب',
    'ناونیشانی ورد پێویستە',
    'Detailed address is required',
  );
  static String get deliveryNotes => _t(
    'ملاحظات للتوصيل (اختياري)',
    'تێبینی بۆ گەیاندن (ئارەزوومەندانە)',
    'Delivery notes (optional)',
  );
  static String get deliveryNotesHint => _t(
    'مثال: الاتصال قبل الوصول بنصف ساعة',
    'نموونە: نیو کاتژمێر پێش گەیشتن پەیوەندی بکرێت',
    'e.g. Call half an hour before arrival',
  );

  // ── الخطوة 4: المراجعة ──
  static String get reviewTitle => _t(
    'راجع الطلب قبل التأكيد',
    'پێش پشتڕاستکردنەوە داواکارییەکە بپشکنە',
    'Review before confirming',
  );
  static String get productAndItems =>
      _t('المنتج والعناصر', 'بەرهەم و بڕگەکان', 'Product & items');
  static String get customerAndAddress =>
      _t('الزبون والعنوان', 'کڕیار و ناونیشان', 'Customer & address');
  static String storeNameNotice(String store) => _t(
    'سيصل الطلب لزبونك باسم متجرك: «$store»',
    'داواکارییەکە بە ناوی فرۆشگاکەت دەگاتە کڕیارەکەت: «$store»',
    'The order reaches your customer under your store name: "$store"',
  );
  static String get orderPolicyNotice => _t(
    'بتأكيد الطلب تقر بأن الزبون طلبه ووافق على مشاركة بياناته للتجهيز والتوصيل. الدفع نقداً، والإلغاء المباشر خلال ساعة، ويجب فحص المنتج أمام المندوب.',
    'بە پشتڕاستکردنەوە دڵنیایی دەدەیت کە کڕیار داواکاری کردووە و ڕازییە داتاکانی بۆ ئامادەکردن و گەیاندن هاوبەش بکرێت. پارەدان نەقدە، هەڵوەشاندنەوەی ڕاستەوخۆ تا یەک کاتژمێرە و پشکنین لەبەردەم نێردراو پێویستە.',
    'By confirming, you state that the customer requested the order and agreed to the data needed for fulfilment and delivery. Payment is cash on delivery, direct cancellation is available for one hour, and the item must be inspected with the courier present.',
  );
  static String get readOrderPolicy => _t(
    'اقرأ سياسة الطلب والتوصيل',
    'سیاسەتی داواکاری و گەیاندن بخوێنەوە',
    'Read the order and delivery policy',
  );

  // ── شاشة نجاح الطلب ──
  static String orderCodeCopied(String code) => _t(
    'تم نسخ رقم الطلب $code',
    'ژمارەی داواکاری $code کۆپی کرا',
    'Order code $code copied',
  );
  static String get orderSentTitle => _t(
    'تم إرسال طلبك بنجاح',
    'داواکارییەکەت بە سەرکەوتوویی نێردرا',
    'Order submitted successfully',
  );
  static String get orderSentSubtitle => _t(
    'سيراجع فريقنا الطلب ويجهزه بأقرب وقت',
    'تیمەکەمان بە زووترین کات پێداچوونەوە بە داواکارییەکە دەکات و ئامادەی دەکات',
    'Our team will review and prepare it shortly',
  );
  static String get tapCodeToCopy => _t(
    'اضغط على الرقم لنسخه',
    'بۆ کۆپیکردن کرتە لە ژمارەکە بکە',
    'Tap the code to copy',
  );
  static String get viewOrder =>
      _t('عرض الطلب', 'بینینی داواکاری', 'View order');
  static String get backToHome =>
      _t('العودة للرئيسية', 'گەڕانەوە بۆ سەرەکی', 'Back to home');
}
