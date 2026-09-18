import '../../data/app_settings.dart';

abstract final class StorefrontStrings {
  static String get sharedPrice => t(
    'سعر واحد لكل الألوان المختارة',
    'یەک نرخ بۆ هەموو ڕەنگە هەڵبژێردراوەکان',
    'One price for all selected colours',
  );
  static String get recentOrders => t(
    'آخر ١٠ طلبات — الطلبات القديمة تُحسب أيضاً',
    'دوا ١٠ داواکاری — کۆنەکانیش دەژمێردرێن',
    'Latest 10 orders — earlier orders also count',
  );
  static String progressReason(String status) => switch (status) {
    'completed' => t(
      'محتسب — اكتملت التسوية',
      'ژمێردراوە — یەکلاکردنەوە تەواوە',
      'Counted — settlement complete',
    ),
    'delivered' => t(
      'معلّق — تم التسليم وبانتظار إكمال التسوية',
      'چاوەڕوانە — گەیەندراوە، یەکلاکردنەوە ماوە',
      'Pending — delivered, awaiting settlement',
    ),
    'cancelled' || 'rejected' => t(
      'غير محتسب — الطلب ملغي أو مرفوض',
      'ناژمێردرێت — هەڵوەشاوە یان ڕەتکراوە',
      'Not counted — cancelled or rejected',
    ),
    'returned' || 'returning' => t(
      'غير محتسب — طلب إرجاع',
      'ناژمێردرێت — گەڕاندنەوە',
      'Not counted — return',
    ),
    'pending_review' => t(
      'معلّق — بانتظار مراجعة وتأكيد الطلب',
      'چاوەڕوانی پشکنین و پشتڕاستکردنەوەیە',
      'Pending — awaiting review and confirmation',
    ),
    'confirmed' => t(
      'معلّق — مؤكد ولم يكتمل التسليم والتسوية',
      'پشتڕاستکراوە، گەیاندن و یەکلاکردنەوە ماوە',
      'Pending — confirmed, delivery and settlement outstanding',
    ),
    'shipped' => t(
      'معلّق — قيد التوصيل ولم تكتمل التسوية',
      'لە گەیاندندایە، یەکلاکردنەوە ماوە',
      'Pending — shipping, settlement outstanding',
    ),
    _ => t(
      'معلّق — لم يصل إلى حالة مكتمل',
      'چاوەڕوانە — هێشتا تەواو نەکراوە',
      'Pending — not yet completed',
    ),
  };
  static String t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  static String get title => t('متجري', 'فرۆشگاکەم', 'My store');
  static String get uncertainSave => t(
    'تأخر رد الخادم؛ ممكن الحفظ تم. اضغط التحديث للتحقق قبل إعادة المحاولة. اختياراتك باقية هنا.',
    'وەڵامی ڕاژە دوا کەوت؛ لەوانەیە پاشەکەوت بووبێت. نوێکردنەوە دابگرە بۆ دڵنیابوون.',
    'The server response timed out; saving may have succeeded. Refresh to check before retrying. Your choices remain here.',
  );
  static String get listingLimit => t(
    'وصل متجرك لحد ٢٠٠ خيار منتج. عدّل خياراً موجوداً أو تواصل مع الإدارة.',
    'گەیشتیتە سنووری ٢٠٠ هەڵبژاردە. هەڵبژاردەیەک دەستکاری بکە یان پەیوەندی بە بەڕێوەبردن بکە.',
    'Your store reached 200 variant slots. Edit an existing listing or contact support.',
  );
  static String get refreshProduct => t(
    'تغيّر سعر المنتج أو توفره. حدّث بياناته وراجع الاختيار.',
    'نرخ یان بەردەستی بەرهەم گۆڕاوە. زانیاری نوێ بکەرەوە.',
    'Product price or availability changed. Refresh and review your selection.',
  );
  static String get priceRefreshRequired => t(
    'تعذر التحقق من أحدث سعر ومخزون. أعد المحاولة قبل الحفظ؛ السعر الذي كتبته لن يُمسح.',
    'نەتوانرا نوێترین نرخ و کۆگا بپشکنرێت. پێش پاشەکەوتکردن هەوڵ بدەوە.',
    'Could not verify current price and stock. Retry before saving; your entered price is retained.',
  );
  static String get signInAgain => t(
    'انتهت جلسة الحساب. سجّل الدخول مجدداً ثم أعد المحاولة.',
    'دانیشتنەکەت تەواو بوو. دووبارە بچۆ ژوورەوە.',
    'Your session ended. Sign in again and retry.',
  );
  static String get publishedAfterSave => t(
    'المتجر مفعّل. بعد الحفظ يظهر المنتج للزوار خلال نحو ٣٠ ثانية.',
    'فرۆشگا چالاکە. دوای پاشەکەوتکردن بە نزیکەی ٣٠ چرکە دەردەکەوێت.',
    'Your store is active. Saved products appear to visitors in about 30 seconds.',
  );
  static String get savedWhilePaused => t(
    'متجرك متوقف حالياً. تقدر تحفظ المنتج، لكن حتى يظهر للزبائن اضغط «تفعيل المتجر».',
    'فرۆشگاکەت ڕاگیراوە. دەتوانیت بەرهەم پاشەکەوت بکەیت، بۆ پیشاندان چالاکی بکە.',
    'Your store is paused. You can save products, but activate the store to show them to customers.',
  );
  static String get working => t('جارٍ التنفيذ…', 'جێبەجێ دەکرێت…', 'Working…');
  static String get addProduct =>
      t('أضف لمتجري', 'زیادکردن بۆ فرۆشگاکەم', 'Add to my store');
  static String get manageProduct => t(
    'إدارة المنتج في متجري',
    'بەڕێوەبردنی بەرهەم لە فرۆشگاکەم',
    'Manage store product',
  );
  static String get editListing =>
      t('تعديل الإضافة', 'دەستکاری بەرهەمی زیادکراو', 'Edit listing');
  static String get listed =>
      t('مضاف للمتجر', 'لە فرۆشگا زیادکراوە', 'In your store');
  static String get listingHelp => t(
    'عدّل الألوان المختارة وسعرها الموحّد، أو أوقف المنتج بكل ألوانه من متجرك فقط.',
    'ڕەنگە هەڵبژێردراوەکان و نرخە یەکسانەکە بگۆڕە، یان بەرهەمەکە لە فرۆشگاکەت ڕابگرە.',
    'Edit the selected colours and their shared price, or pause the entire product in your store only.',
  );
  static String get listingUpdated => t(
    'تم تعديل الإضافة',
    'بەرهەمە زیادکراوەکە دەستکاری کرا',
    'Listing updated',
  );
  static String get listingRemoved => t(
    'تمت الإزالة من متجرك فقط',
    'تەنها لە فرۆشگاکەت لابرا',
    'Removed from your store only',
  );
  static String get removeNotConfirmed => t(
    'لم نتأكد من الإزالة. حدّث الصفحة للتحقق قبل إعادة المحاولة.',
    'لابردن پشتڕاست نەکرایەوە. پێش هەوڵدانەوە پەڕەکە نوێ بکەرەوە.',
    'Removal was not confirmed. Refresh to check before trying again.',
  );
  static String get themes => t(
    'اختر قالب متجرك',
    'قاڵبی فرۆشگاکەت هەڵبژێرە',
    'Choose your store theme',
  );
  static String get preview =>
      t('معاينة كاملة', 'پێشبینینی تەواو', 'Full preview');
  static String get select =>
      t('اختيار القالب', 'هەڵبژاردنی قاڵب', 'Choose theme');
  static String get selected =>
      t('القالب المختار', 'قاڵبی هەڵبژێردراو', 'Selected theme');
  static String get details =>
      t('هوية متجرك', 'ناسنامەی فرۆشگاکەت', 'Store identity');
  static String get brand =>
      t('اسم العلامة التجارية', 'ناوی بازرگانی', 'Brand name');
  static String get slug =>
      t('عنوان المتجر', 'ناونیشانی فرۆشگا', 'Store address');
  static String get slugHelp => t(
    'من 3 إلى 30 حرفاً إنجليزياً صغيراً أو رقماً أو شرطة. لا شرطات متتالية ولا أسماء محجوزة.',
    'لە 3 بۆ 30 پیتی بچووکی ئینگلیزی، ژمارە یان هێڵ. هێڵی دووبارە و ناوی گیراو ڕێگەپێنەدراوە.',
    '3–30 lowercase letters, numbers or hyphens. No consecutive hyphens or reserved names.',
  );
  static String get logo => t('شعار المتجر', 'لۆگۆی فرۆشگا', 'Store logo');
  static String get pickLogo =>
      t('اختيار صورة الشعار', 'هەڵبژاردنی وێنەی لۆگۆ', 'Choose logo image');
  static String get logoHelp => t(
    'PNG أو JPEG أو WebP، بحد أقصى 2 ميغابايت.',
    'PNG، JPEG یان WebP، زۆرترین 2 مێگابایت.',
    'PNG, JPEG or WebP, up to 2 MB.',
  );
  static String get create =>
      t('إنشاء متجري', 'دروستکردنی فرۆشگاکەم', 'Create my store');
  static String get save =>
      t('حفظ التغييرات', 'پاشەکەوتکردنی گۆڕانکاری', 'Save changes');
  static String get edit =>
      t('تعديل هوية المتجر', 'دەستکاری ناسنامەی فرۆشگا', 'Edit store identity');
  static String get retry => t('إعادة المحاولة', 'هەوڵدانەوە', 'Try again');
  static String get loading =>
      t('جارٍ تحميل متجرك', 'فرۆشگاکەت بار دەکرێت', 'Loading your store');
  static String get loadError => t(
    'تعذر الاتصال. تحقق من الإنترنت ثم حدّث الصفحة للتحقق من النتيجة. بياناتك المدخلة باقية هنا.',
    'پەیوەندی سەرکەوتوو نەبوو. ئینتەرنێت بپشکنەوە و پەڕەکە نوێ بکەرەوە. زانیارییەکانت لێرە ماون.',
    'Could not connect. Check your connection, then refresh to verify the result. Your entries remain here.',
  );
  static String get unavailable => t(
    'خدمة المتاجر غير متاحة حالياً. أعد المحاولة لاحقاً.',
    'خزمەتگوزاری فرۆشگا ئێستا بەردەست نییە. دواتر هەوڵ بدەوە.',
    'Stores are not available yet. Please try again later.',
  );
  static String get eligibility => t(
    'متجرك بعد ١٠ طلبات مكتملة',
    'فرۆشگاکەت دوای ١٠ داواکاری تەواوکراو',
    'Your store unlocks after 10 completed orders',
  );
  static String get eligibilityBody => t(
    'تُفتح ميزة المتجر بعد إكمال تسوية ١٠ طلبات. الطلبات الملغاة أو التي لم تكتمل تسويتها لا تُحسب. هذا لا يغيّر مستوى حسابك.',
    'دوای تەواوکردنی یەکلاکردنەوەی ١٠ داواکاری فرۆشگاکەت دەکرێتەوە. داواکاری هەڵوەشاوە یان ناتەواو ناژمێردرێت. ئاستی هەژمارەکەت ناگۆڕێت.',
    'Unlock your store after 10 fully settled orders. Cancelled or unsettled orders do not count. Your account level is unchanged.',
  );
  static String get emptyProducts => t(
    'متجرك جاهز لإضافة المنتجات',
    'فرۆشگاکەت ئامادەی زیادکردنی بەرهەمە',
    'Your store is ready for products',
  );
  static String get emptyProductsBody => t(
    'افتح أي منتج واضغط «أضف لمتجري» بجانب القلب، ثم اختر النوع وسعر البيع.',
    'بەرهەمێک بکەرەوە و «زیادکردن بۆ فرۆشگاکەم» لە تەنیشت دڵەکە دابگرە، پاشان جۆر و نرخ هەڵبژێرە.',
    'Open a product and tap “Add to my store” beside the heart, then choose a variant and retail price.',
  );
  static String get browse =>
      t('تصفح المنتجات', 'بینینی بەرهەمەکان', 'Browse products');
  static String get products =>
      t('منتجات متجري', 'بەرهەمەکانی فرۆشگاکەم', 'My store products');
  static String get activate =>
      t('تفعيل المتجر', 'چالاککردنی فرۆشگا', 'Activate store');
  static String get active =>
      t('المتجر مفعّل', 'فرۆشگا چالاکە', 'Store active');
  static String get paused =>
      t('المتجر غير مفعّل', 'فرۆشگا ناچالاکە', 'Store inactive');
  static String get activationBody => t(
    'يبقى متجرك مفعّلاً ويستقبل الطلبات إلى أن توقفه أنت أو الإدارة. لا يحتاج تجديداً يومياً.',
    'فرۆشگاکەت چالاک دەمێنێتەوە تا تۆ یان بەڕێوەبردن ڕایبگرێت. نوێکردنەوەی ڕۆژانە پێویست نییە.',
    'Your store stays active until you or an administrator pause it. No daily renewal is needed.',
  );
  static String get open => t('فتح المتجر', 'کردنەوەی فرۆشگا', 'Open store');
  static String get copy => t('نسخ الرابط', 'کۆپیکردنی بەستەر', 'Copy link');
  static String get copied =>
      t('تم نسخ الرابط', 'بەستەر کۆپی کرا', 'Link copied');
  static String get variant => t(
    'النوع / اللون / القياس',
    'جۆر / ڕەنگ / قەبارە',
    'Variant / color / size',
  );
  static String get price => t(
    'سعر البيع للزبون (د.ع)',
    'نرخی فرۆشتن بۆ کڕیار (د.ع)',
    'Customer retail price (IQD)',
  );
  static String get chooseVariant => t(
    'اختر نوعاً متاحاً من المنتج',
    'جۆرێکی بەردەستی بەرهەم هەڵبژێرە',
    'Choose an available product variant',
  );
  static String get invalidPrice => t(
    'أدخل سعراً صحيحاً ضمن الحدود المسموحة',
    'نرخێکی دروست لە سنووری ڕێگەپێدراو بنووسە',
    'Enter a whole price within the allowed range',
  );
  static String get added => t(
    'تم حفظ المنتج في متجرك',
    'بەرهەم لە فرۆشگاکەت پاشەکەوت کرا',
    'Product saved to your store',
  );
  static String get remove =>
      t('إزالة من المتجر', 'لابردن لە فرۆشگا', 'Remove from store');
  static String get cancel => t('إلغاء', 'پاشگەزبوونەوە', 'Cancel');
  static String get required =>
      t('هذا الحقل مطلوب', 'ئەم خانەیە پێویستە', 'This field is required');
  static String get logoError => t(
    'تعذر اختيار الشعار. اختر صورة PNG أو JPEG أو WebP أصغر من 2 ميغابايت.',
    'نەتوانرا لۆگۆ هەڵبژێردرێت. وێنەی PNG، JPEG یان WebP بچووکتر لە 2 مێگابایت هەڵبژێرە.',
    'Could not select the logo. Choose a PNG, JPEG or WebP under 2 MB.',
  );
  static String get saved =>
      t('تم حفظ متجرك', 'فرۆشگاکەت پاشەکەوت کرا', 'Your store has been saved');
  static String get draft => t(
    'تُحفظ بيانات الإعداد تلقائياً على هذا الجهاز.',
    'زانیاری دامەزراندن خۆکارانە لەم ئامێرە پاشەکەوت دەکرێت.',
    'Setup details are saved automatically on this device.',
  );
}
