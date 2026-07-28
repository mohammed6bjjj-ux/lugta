import '../../data/app_settings.dart';

/// نصوص واجهة مجلد المنتج (تفاصيل المنتج، عارض الوسائط، ورقة المشاركة)
/// بثلاث لغات — بنفس نمط CoreStrings.
class ProductStrings {
  ProductStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  // ── شاشة تفاصيل المنتج ──
  static String get back => _t('رجوع', 'گەڕانەوە', 'Back');
  static String get addToFavorites =>
      _t('إضافة إلى المفضلة', 'زیادکردن بۆ دڵخوازەکان', 'Add to favorites');
  static String get removeFromFavorites =>
      _t('إزالة من المفضلة', 'لابردن لە دڵخوازەکان', 'Remove from favorites');
  static String get shareMediaTooltip =>
      _t('مشاركة الوسائط', 'هاوبەشکردنی میدیا', 'Share media');
  static String get video => _t('فيديو', 'ڤیدیۆ', 'Video');
  static String get availableVariants =>
      _t('المتغيرات المتوفرة', 'جۆرە بەردەستەکان', 'Available variants');
  static String get specifications =>
      _t('المواصفات', 'تایبەتمەندییەکان', 'Specifications');
  static String get descriptionTitle => _t('الوصف', 'وەسف', 'Description');
  static String get copyDescription =>
      _t('نسخ الوصف', 'کۆپیکردنی وەسف', 'Copy description');
  static String get descriptionCopied => _t(
    'تم نسخ الوصف — جاهز للصقه في منشورك',
    'وەسفەکە کۆپی کرا — ئامادەیە بۆ دانان لە پۆستەکەت',
    'Description copied — ready to paste in your post',
  );
  static String ordersViaPlatform(String count) => _t(
    '$count طلب عبر المنصة',
    '$count داواکاری لە ڕێگەی پلاتفۆرمەوە',
    '$count orders on the platform',
  );
  static String discountBadge(String percent) =>
      _t('خصم $percent٪', 'داشکاندنی ٪$percent', '$percent% off');
  static String get suggestedSalePrice => _t(
    'السعر المقترح للبيع',
    'نرخی پێشنیارکراوی فرۆشتن',
    'Suggested sale price',
  );
  static String approxProfit(String amount) => _t(
    'ربحك التقريبي عند البيع بالسعر المقترح: $amount',
    'قازانجی نزیکەیی تۆ بە فرۆشتن بە نرخی پێشنیارکراو: $amount',
    'Est. profit at the suggested price: $amount',
  );
  static String minSalePrice(String amount) => _t(
    'الحد الأدنى المسموح للبيع: $amount',
    'کەمترین نرخی ڕێگەپێدراو بۆ فرۆشتن: $amount',
    'Minimum allowed sale price: $amount',
  );
  static String variantInStock(String count) =>
      _t('متوفر: $count', 'بەردەستە: $count', 'In stock: $count');
  static String get outOfStockTemporarily => _t(
    'نفد المخزون مؤقتاً',
    'کۆگا بە کاتی بەتاڵە',
    'Temporarily out of stock',
  );
  static String lowStockWarning(String count) => _t(
    'بقي $count فقط — اطلب قبل النفاد',
    'تەنها $count ماوە — پێش تەواوبوون داوا بکە',
    'Only $count left — order before it runs out',
  );
  static String totalStockAvailable(String count) => _t(
    'متوفر — الإجمالي في المخزون: $count قطعة',
    'بەردەستە — کۆی گشتی لە کۆگا: $count دانە',
    'In stock — $count pcs total',
  );
  static String get createOrder =>
      _t('إنشاء طلب', 'دروستکردنی داواکاری', 'Create order');
  static String get notifyMe => _t(
    'نبّهني عند التوفر',
    'کە بەردەست بوو ئاگادارم بکەرەوە',
    'Notify me when available',
  );
  static String get alertActive => _t(
    'سيصلك إشعار عند التوفر ✓',
    'کاتێک بەردەست بوو ئاگادارکردنەوەیەکت بۆ دێت ✓',
    'You\'ll be notified when available ✓',
  );
  static String get alertActivated => _t(
    'تم تفعيل التنبيه — سنعلمك فور توفر المنتج',
    'ئاگادارکردنەوە چالاک کرا — کە بەرهەمەکە بەردەست بوو ئاگادارت دەکەینەوە',
    'Alert set — we\'ll notify you as soon as it\'s back',
  );

  // ── عارض الوسائط ──
  static String get close => _t('إغلاق', 'داخستن', 'Close');
  static String get noMedia =>
      _t('لا توجد وسائط', 'هیچ میدیایەک نییە', 'No media');
  static String get videoLoadFailed => _t(
    'تعذر تشغيل الفيديو. أعد المحاولة، وإذا استمرت المشكلة أعد فتح الفيديو.',
    'نەتوانرا ڤیدیۆکە لێ بدرێت. دووبارە هەوڵ بدەوە، ئەگەر کێشەکە بەردەوام بوو ڤیدیۆکە دووبارە بکەرەوە.',
    'Could not play the video. Try again, or reopen it if the problem continues.',
  );
  static String get retry =>
      _t('إعادة المحاولة', 'دووبارە هەوڵدانەوە', 'Retry');
  static String get download => _t('تحميل', 'داگرتن', 'Download');
  static String get share => _t('مشاركة', 'هاوبەشکردن', 'Share');
  static String get mediaPreparing => _t(
    'جارٍ تجهيز الوسائط...',
    'میدیا ئامادە دەکرێت...',
    'Preparing media...',
  );
  static String mediaSaved(String count) => _t(
    'تم حفظ $count من الوسائط في المعرض',
    '$count میدیا لە گەلەریدا پاشەکەوت کرا',
    'Saved $count media to the gallery',
  );
  static String get mediaSaveFailed => _t(
    'تعذر حفظ الوسائط. تحقق من الاتصال وأعد المحاولة',
    'پاشەکەوتکردنی میدیا سەرکەوتوو نەبوو. پەیوەندی بپشکنە و دووبارە هەوڵ بدە',
    'Could not save the media. Check your connection and try again',
  );
  static String get mediaShareFailed => _t(
    'تعذر تجهيز الوسائط للمشاركة. تحقق من الاتصال وأعد المحاولة',
    'ئامادەکردنی میدیا بۆ هاوبەشکردن سەرکەوتوو نەبوو. پەیوەندی بپشکنە و دووبارە هەوڵ بدە',
    'Could not prepare the media for sharing. Check your connection and try again',
  );
  static String get mediaPermissionDenied => _t(
    'يحتاج التطبيق إذن الوصول إلى الصور لحفظ الوسائط',
    'ئەپەکە مۆڵەتی دەستگەیشتن بە وێنەکانی پێویستە بۆ پاشەکەوتکردن',
    'The app needs photo access permission to save media',
  );
  static String get mediaLinkUnavailable => _t(
    'لا يوجد رابط متاح لهذه الوسائط',
    'هیچ لینکێک بۆ ئەم میدیایە بەردەست نییە',
    'No link is available for this media',
  );
  static String get shareVia =>
      _t('مشاركة عبر', 'هاوبەشکردن لە ڕێگەی', 'Share via');
  static String get whatsapp => _t('واتساب', 'واتسئاپ', 'WhatsApp');
  static String get instagram => _t('إنستغرام', 'ئینستاگرام', 'Instagram');
  static String get telegram => _t('تيليغرام', 'تێلێگرام', 'Telegram');
  static String get copyLink => _t('نسخ الرابط', 'کۆپیکردنی لینک', 'Copy link');
  static String get mediaLinkCopied =>
      _t('تم نسخ رابط الوسائط', 'لینکی میدیاکە کۆپی کرا', 'Media link copied');

  // ── ورقة تحميل ومشاركة الوسائط ──
  static String get downloadAndShareMedia => _t(
    'تحميل ومشاركة الوسائط',
    'داگرتن و هاوبەشکردنی میدیا',
    'Download & share media',
  );
  static String get nothingSelectedYet => _t(
    'لم تحدد أي عنصر بعد',
    'هێشتا هیچ شتێکت هەڵنەبژاردووە',
    'Nothing selected yet',
  );
  static String selectedOf(String selected, String total) => _t(
    'تم تحديد $selected من $total',
    '$selected لە $total هەڵبژێردراوە',
    '$selected of $total selected',
  );
  static String get selectAll =>
      _t('تحديد الكل', 'هەڵبژاردنی هەمووی', 'Select all');
  static String get deselectAll =>
      _t('إلغاء التحديد', 'هەڵوەشاندنەوەی هەڵبژاردن', 'Deselect all');
  static String get downloadToDevice =>
      _t('تحميل إلى الجهاز', 'داگرتن بۆ ئامێر', 'Download to device');
  static String get copyPostText =>
      _t('نسخ نص المنشور', 'کۆپیکردنی دەقی پۆست', 'Copy post text');
  static String get postTextCopied => _t(
    'تم نسخ نص المنشور — بالسعر المقترح فقط',
    'دەقی پۆستەکە کۆپی کرا — تەنها بە نرخی پێشنیارکراو',
    'Post text copied — suggested price only',
  );
  static String get safeContentNote => _t(
    'المحتوى لا يتضمن سعر الجملة — آمن للنشر لزبائنك',
    'ناوەڕۆکەکە نرخی کۆمەڵی تێدا نییە — سەلامەتە بۆ بڵاوکردنەوە بۆ کڕیارەکانت',
    'No wholesale price included — safe to share with your customers',
  );

  /// نص المنشور: سطر السعر (السعر المقترح فقط — لا يتضمن سعر الجملة أبداً).
  static String postPriceLine(String price) =>
      _t('السعر: $price', 'نرخ: $price', 'Price: $price');
}
