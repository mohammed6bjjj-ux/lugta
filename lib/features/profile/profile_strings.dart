import '../../data/app_settings.dart';

/// نصوص مجلد «حسابي» (الملف الشخصي، الإعدادات، الإشعارات، الدعم،
/// السياسات، حول التطبيق، تعديل الملف) بثلاث لغات.
class ProfileStrings {
  ProfileStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  // ── بطاقة المتجر ──
  static String get verifiedSeller =>
      _t('بائع معتمد ✓', 'فرۆشیاری متمانەپێکراو ✓', 'Verified seller ✓');
  static String memberSince(String date) =>
      _t('معك منذ $date', 'لەگەڵمانیت لە $dateوە', 'With us since $date');
  static String openingInstagram(String url) => _t(
    'جارٍ فتح إنستغرام — $url',
    'ئینستاگرام دەکرێتەوە — $url',
    'Opening Instagram — $url',
  );

  // ── الإحصائيات ──
  static String get statTotalOrders =>
      _t('إجمالي الطلبات', 'کۆی داواکارییەکان', 'Total orders');
  static String get statCompletedOrders =>
      _t('طلبات مكتملة', 'داواکاری تەواوبوو', 'Completed orders');
  static String get statTotalEarnings =>
      _t('إجمالي الأرباح', 'کۆی قازانجەکان', 'Total earnings');

  // ── القوائم ──
  static String get editProfile =>
      _t('تعديل الملف الشخصي', 'دەستکاری پرۆفایل', 'Edit profile');
  static String get notifications =>
      _t('الإشعارات', 'ئاگادارکردنەوەکان', 'Notifications');
  static String get favorites => _t('المفضلة', 'دڵخوازەکان', 'Favorites');
  static String get withdrawalsHistory =>
      _t('سجل السحوبات', 'مێژووی ڕاکێشانەکان', 'Withdrawal history');
  static String get groupSupport => _t('الدعم', 'پشتگیری', 'Support');
  static String get contactUs =>
      _t('تواصل معنا', 'پەیوەندیمان پێوە بکە', 'Contact us');
  static String get policies =>
      _t('الشروط والسياسات', 'مەرج و سیاسەتەکان', 'Terms & policies');
  static String get about =>
      _t('حول التطبيق', 'دەربارەی ئەپەکە', 'About the app');
  static String get settings => _t('الإعدادات', 'ڕێکخستنەکان', 'Settings');

  // ── تسجيل الخروج ──
  static String get logout => _t('تسجيل الخروج', 'چوونەدەرەوە', 'Log out');
  static String get logoutConfirmBody => _t(
    'هل أنت متأكد من رغبتك بتسجيل الخروج من حسابك؟ يمكنك الدخول مجدداً برقم هاتفك وكلمة المرور.',
    'دڵنیایت دەتەوێت لە هەژمارەکەت بچیتەدەرەوە؟ دەتوانیت دووبارە بە ژمارەی مۆبایل و وشەی نهێنی بچیتەژوورەوە.',
    'Are you sure you want to log out? You can sign back in with your phone number and password.',
  );
  static String get cancel => _t('إلغاء', 'هەڵوەشاندنەوە', 'Cancel');

  // ── حذف الحساب ──
  static String get deleteAccount =>
      _t('حذف الحساب', 'سڕینەوەی هەژمار', 'Delete account');
  static String get deleteAccountTitle => _t(
    'حذف الحساب نهائياً',
    'سڕینەوەی هەژمار بە یەکجاری',
    'Permanently delete account',
  );
  static String get deleteAccountBody => _t(
    'هذا طلب مراجعة وليس حذفاً فورياً. يجب تسوية الرصيد والطلبات أولاً. '
        'بعد الموافقة يُوقف الدخول وتُعمّى البيانات الشخصية غير اللازمة، '
        'بينما تبقى سجلات الطلبات والحركات المالية المطلوبة للمحاسبة والالتزامات القانونية.',
    'ئەمە داواکارییەکی پێداچوونەوەیە و سڕینەوەی دەستبەجێ نییە. سەرەتا '
        'باڵانس و داواکارییەکان یەکلایی دەکرێنەوە. دوای پەسەندکردن چوونەژوورەوە '
        'دەوەستێت و زانیاری کەسییە ناپێویستەکان ناشناس دەکرێن؛ بەڵام تۆمارە '
        'دارایی و داواکارییە پێویستەکان بۆ ژمێریاری و یاسا دەمێننەوە.',
    'This submits a review request; deletion is not immediate. Balances and '
        'orders must be settled first. After approval, access is disabled and '
        'unneeded personal data is anonymized, while required order and financial '
        'records remain for accounting and legal obligations.',
  );
  static String get deleteConfirmWord => _t('حذف', 'سڕینەوە', 'DELETE');
  static String get deleteConfirmLabel => _t(
    'للتأكيد اكتب كلمة «حذف»',
    'بۆ دڵنیابوونەوە وشەی «سڕینەوە» بنووسە',
    'Type "DELETE" to confirm',
  );
  static String get deleteConfirmSubmit => _t(
    'تأكيد طلب الحذف',
    'پشتڕاستکردنەوەی داواکاری سڕینەوە',
    'Confirm deletion request',
  );
  static String get deleteCancel => _t('تراجع', 'پاشگەزبوونەوە', 'Go back');
  static String get deleteRequestReceived => _t(
    'تم استلام طلبك — سيتواصل معك الدعم لإتمام الحذف',
    'داواکارییەکەت وەرگیرا — پشتگیری پەیوەندیت پێوە دەکات بۆ تەواوکردنی سڕینەوەکە',
    'Request received — support will contact you to complete the deletion',
  );
  static String get deletionRequestPending => _t(
    'طلب حذف الحساب قيد المراجعة. يبقى حسابك فعالاً حتى صدور القرار وتسوية الالتزامات.',
    'داواکاری سڕینەوەی هەژمار لە پێداچوونەوەدایە. هەژمارەکەت تا بڕیار و یەکلاییکردنەوە چالاک دەمێنێت.',
    'Your deletion request is under review. The account remains active until a decision and settlement.',
  );
  static String get cancelDeletionRequest => _t(
    'إلغاء طلب حذف الحساب',
    'هەڵوەشاندنەوەی داواکاری سڕینەوە',
    'Cancel deletion request',
  );
  static String get cancelDeletionRequestBody => _t(
    'هل تريد إبقاء الحساب وإلغاء طلب الحذف المعلّق؟',
    'دەتەوێت هەژمارەکە بهێڵیتەوە و داواکاری سڕینەوە هەڵبوەشێنیتەوە؟',
    'Keep the account and cancel the pending deletion request?',
  );
  static String get confirmCancelDeletion =>
      _t('نعم، إلغاء الطلب', 'بەڵێ، هەڵوەشاندنەوە', 'Yes, cancel request');
  static String get deletionRequestCancelled => _t(
    'تم إلغاء طلب حذف الحساب.',
    'داواکاری سڕینەوەی هەژمار هەڵوەشێنرایەوە.',
    'The account deletion request was cancelled.',
  );
  static String get deleteReasonLabel =>
      _t('سبب طلب الحذف', 'هۆکاری داواکاری سڕینەوە', 'Reason for deletion');
  static String get deleteReasonHint => _t(
    'اكتب السبب باختصار لمساعدة فريق المراجعة',
    'هۆکارەکە بە کورتی بنووسە بۆ یارمەتیدانی تیمی پێداچوونەوە',
    'Briefly explain the reason for the review team',
  );
  static String get deleteReasonRequired => _t(
    'اكتب سبباً من 3 أحرف على الأقل',
    'هۆکارێک بە لایەنی کەم ٣ پیت بنووسە',
    'Enter a reason of at least 3 characters',
  );
  static String get readDeletionPolicy => _t(
    'اقرأ سياسة حذف الحساب والبيانات',
    'سیاسەتی سڕینەوەی هەژمار و داتا بخوێنەوە',
    'Read the account and data deletion policy',
  );

  // ── الإعدادات: المظهر واللغة ──
  static String get sectionAppearance => _t('المظهر', 'ڕووکار', 'Appearance');
  static String get darkMode => _t('الوضع الداكن', 'دۆخی تاریک', 'Dark mode');
  static String get darkModeSubtitle => _t(
    'ألوان مريحة للعين في الإضاءة الخافتة',
    'ڕەنگی ئارام بۆ چاو لە ڕووناکی کەمدا',
    'Easier on the eyes in low light',
  );
  static String get sectionLanguage => _t('اللغة', 'زمان', 'Language');

  // ── الإعدادات: حسابات استلام الأرباح ──
  static String get sectionPayments =>
      _t('الأرباح والاستلام', 'قازانج و وەرگرتن', 'Earnings & payout');
  static String get payoutAccounts => _t(
    'حسابات استلام الأرباح',
    'هەژمارەکانی وەرگرتنی قازانج',
    'Payout accounts',
  );
  static String get payoutAccountsSubtitle => _t(
    'إضافة زين كاش أو سوبر كي ومتابعة التوثيق',
    'زیادکردنی زەین کاش یان سوپەر کی و بەدواداچوونی پشتڕاستکردنەوە',
    'Add ZainCash or SuperQi and track verification',
  );

  // ── الإعدادات: مفاتيح الإشعارات ──
  static String get ordersNotifTitle =>
      _t('تحديثات طلباتي', 'نوێکارییەکانی داواکارییەکانم', 'Order updates');
  static String get ordersNotifSubtitle => _t(
    'إشعار عند كل تغيير في حالة طلباتك',
    'ئاگادارکردنەوە لە هەر گۆڕانکارییەک لە دۆخی داواکارییەکانت',
    'Get notified on every order status change',
  );
  static String get walletNotifTitle =>
      _t('المحفظة والأرباح', 'جزدان و قازانجەکان', 'Wallet & earnings');
  static String get walletNotifSubtitle => _t(
    'إشعار عند تحول الأرباح ونتائج السحب',
    'ئاگادارکردنەوە بۆ بەردەستبوونی قازانج و ئەنجامی ڕاکێشانەکان',
    'Profit releases and withdrawal results',
  );
  static String get newProductsNotifTitle =>
      _t('منتجات جديدة', 'بەرهەمی نوێ', 'New products');
  static String get newProductsNotifSubtitle => _t(
    'كن أول من يعرف عند نزول منتج جديد',
    'یەکەم کەس بە کە بزانێت کاتێک بەرهەمی نوێ زیاد دەکرێت',
    'Be first to know about new arrivals',
  );
  static String get offersNotifTitle => _t('العروض', 'ئۆفەرەکان', 'Offers');
  static String get offersNotifSubtitle => _t(
    'تخفيضات أسعار الجملة والحملات الموسمية',
    'داشکاندنی نرخی کۆمەڵ و هەڵمەتە وەرزییەکان',
    'Wholesale discounts and seasonal campaigns',
  );

  // ── الإعدادات: عام ──
  static String get sectionGeneral => _t('عام', 'گشتی', 'General');
  static String get clearCache =>
      _t('مسح ذاكرة التخزين المؤقت', 'سڕینەوەی کاشی کاتی', 'Clear cache');
  static String get clearCacheSubtitle => _t(
    'صور التطبيق المخزنة في الذاكرة مؤقتاً',
    'وێنە کاشکراوەکانی ئەپەکە لە بیرگەدا',
    'App images cached in memory',
  );
  static String get cacheCleared => _t(
    'تم مسح ذاكرة الصور المؤقتة',
    'کاشی کاتیی وێنەکان سڕایەوە',
    'Temporary image cache cleared',
  );
  static String get version => _t('الإصدار', 'وەشان', 'Version');

  // ── الإشعارات ──
  static String get markAllRead => _t(
    'تحديد الكل كمقروء',
    'هەمووی وەک خوێندراوە دیاری بکە',
    'Mark all as read',
  );
  static String get sectionToday => _t('اليوم', 'ئەمڕۆ', 'Today');
  static String get sectionThisWeek =>
      _t('هذا الأسبوع', 'ئەم هەفتەیە', 'This week');
  static String get sectionOlder => _t('أقدم', 'کۆنتر', 'Older');
  static String get notificationsEmptyTitle => _t(
    'لا إشعارات بعد',
    'هێشتا هیچ ئاگادارکردنەوەیەک نییە',
    'No notifications yet',
  );
  static String get notificationsEmptySubtitle => _t(
    'ستصلك هنا تحديثات طلباتك وأرباح محفظتك والمنتجات الجديدة.',
    'لێرەدا نوێکاری داواکارییەکانت و قازانجی جزدانەکەت و بەرهەمە نوێیەکانت بۆ دێن.',
    'Order updates, wallet earnings, and new products will appear here.',
  );
  static String get linkedOrderNotFound => _t(
    'تعذر العثور على الطلب المرتبط',
    'داواکارییە پەیوەندیدارەکە نەدۆزرایەوە',
    'Linked order not found',
  );

  // ── الدعم ──
  static String get phoneCall =>
      _t('اتصال هاتفي', 'پەیوەندی تەلەفۆنی', 'Phone call');
  static String get whatsapp => _t('واتساب', 'واتسئاپ', 'WhatsApp');
  static String openingPhoneApp(String phone) => _t(
    'جارٍ فتح تطبيق الهاتف للاتصال بـ $phone',
    'ئەپی تەلەفۆن دەکرێتەوە بۆ پەیوەندیکردن بە $phone',
    'Opening phone app to call $phone',
  );
  static String openingWhatsapp(String number) => _t(
    'جارٍ فتح واتساب للمراسلة على $number',
    'واتسئاپ دەکرێتەوە بۆ نامەنووسین بۆ $number',
    'Opening WhatsApp to message $number',
  );
  static String get contactAppUnavailable => _t(
    'تعذر فتح تطبيق الاتصال على هذا الجهاز.',
    'نەتوانرا ئەپی پەیوەندی لەم ئامێرە بکرێتەوە.',
    'Could not open the contact app on this device.',
  );
  static String get supportHours => _t(
    'فريق الدعم متاح يومياً من 10 صباحاً حتى 10 مساءً',
    'تیمی پشتگیری هەموو ڕۆژێک لە 10ی بەیانی تا 10ی شەو بەردەستە',
    'Support is available daily, 10 AM to 10 PM',
  );
  static String get faqTitle => _t('الأسئلة الشائعة', 'پرسیارە باوەکان', 'FAQ');

  // ── الشروط والسياسات ──
  static String lastUpdated(String date) =>
      _t('آخر تحديث: $date', 'دوایین نوێکاری: $date', 'Last updated: $date');
  static String get policiesFooter => _t(
    'باستخدامك التطبيق فأنت توافق على هذه الشروط. قد تُحدَّث السياسات '
        'من وقت لآخر وسيصلك إشعار بأي تغيير جوهري.',
    'بە بەکارهێنانی ئەپەکە تۆ ڕازیت بەم مەرجانە. ڕەنگە سیاسەتەکان کات بە کات '
        'نوێ بکرێنەوە و لە هەر گۆڕانکارییەکی گرنگ ئاگادار دەکرێیتەوە.',
    'By using the app you agree to these terms. Policies may be updated '
        'from time to time, and you will be notified of any material change.',
  );

  // ── حول التطبيق ──
  static String get brandTagline => _t(
    'كل يوم لكطة جديدة',
    'هەموو ڕۆژێک لكطةیەکی نوێ',
    'A new find every day',
  );
  static String get aboutTitle => _t(
    'منصة عراقية للتجارة بالوساطة (دروبشيبينغ)',
    'پلاتفۆرمێکی عێراقی بۆ بازرگانی بە ناوبژیوانی (درۆپشیپینگ)',
    'An Iraqi dropshipping platform',
  );
  static String get aboutBody => _t(
    'نوفر لك تشكيلة ساعات ونظارات وإكسسوارات بأسعار جملة — '
        'المنصة هي المورد الوحيد وتتكفل بالتجهيز والتوصيل والتحصيل، '
        'وأنت تسوّق لزبائنك وتحدد سعر البيع وتربح الفرق، '
        'والدفع عند الاستلام في كل المحافظات.',
    'کۆمەڵێک کاتژمێر و چاویلکە و ئێکسسوارت بۆ دابین دەکەین بە نرخی کۆمەڵ — '
        'پلاتفۆرمەکە تاکە دابینکەرە و ئامادەکردن و گەیاندن و وەرگرتنی پارە '
        'لە ئەستۆ دەگرێت، تۆش بۆ کڕیارەکانت بازاڕگەری دەکەیت و نرخی فرۆشتن '
        'دیاری دەکەیت و جیاوازییەکە قازانج دەکەیت، پارەدانیش لە کاتی '
        'وەرگرتندایە لە هەموو پارێزگاکان.',
    'We supply watches, eyewear, and accessories at wholesale prices — '
        'the platform is your sole supplier and handles preparation, delivery, '
        'and collection. You market to your customers, set your sale price, '
        'and earn the difference, with cash on delivery across all '
        'governorates.',
  );
  static String get feature1 => _t(
    'بدون رأس مال أو مخزون — المنصة تجهز الطلب وتشحنه باسم متجرك',
    'بەبێ سەرمایە یان کۆگا — پلاتفۆرمەکە داواکارییەکە ئامادە دەکات و بە ناوی فرۆشگاکەت دەینێرێت',
    'No capital or inventory — we prepare and ship orders under your store name',
  );
  static String get feature2 => _t(
    'سوّق المنتجات على صفحاتك وأدخل طلبات زبائنك عبر التطبيق',
    'لە پەیجەکانت بازاڕگەری بۆ بەرهەمەکان بکە و داواکاری کڕیارەکانت لە ڕێی ئەپەکەوە تۆمار بکە',
    'Promote products on your pages and submit customer orders in the app',
  );
  static String get feature3 => _t(
    'ربحك هو الفرق بين سعر الجملة وسعر بيعك — يصل محفظتك بعد التوصيل',
    'قازانجی تۆ جیاوازی نێوان نرخی کۆمەڵ و نرخی فرۆشتنەکەتە — دوای گەیاندن دەگاتە جزدانەکەت',
    'Your profit is the gap between wholesale and your sale price — paid to your wallet after delivery',
  );
  static String get copyright => _t(
    '© 2026 لكطة — جميع الحقوق محفوظة',
    '© 2026 لكطة — هەموو مافەکان پارێزراون',
    '© 2026 Lugta — All rights reserved',
  );
  static String get madeInIraq =>
      _t('صُنع في العراق', 'لە عێراق دروستکراوە', 'Made in Iraq');

  // ── تعديل الملف الشخصي ──
  static String get fullNameLabel =>
      _t('الاسم الكامل', 'ناوی تەواو', 'Full name');
  static String get fullNameHint =>
      _t('اسمك الثلاثي', 'ناوە سیانییەکەت', 'Your full name');
  static String get fullNameRequired =>
      _t('الاسم الكامل مطلوب', 'ناوی تەواو پێویستە', 'Full name is required');
  static String get storeNameLabel =>
      _t('اسم المتجر', 'ناوی فرۆشگا', 'Store name');
  static String get storeNameHint => _t(
    'الاسم الذي يظهر على بوليصة الشحن',
    'ئەو ناوەی لەسەر پسوولەی گەیاندن دەردەکەوێت',
    'The name printed on the shipping label',
  );
  static String get storeNameRequired =>
      _t('اسم المتجر مطلوب', 'ناوی فرۆشگا پێویستە', 'Store name is required');
  static String get storeNameInfo => _t(
    'اسم متجرك يُطبع على بوليصة الشحن ليصل الطلب لزبونك باسمك.',
    'ناوی فرۆشگاکەت لەسەر پسوولەی گەیاندن چاپ دەکرێت بۆ ئەوەی داواکارییەکە بە ناوی تۆ بگاتە کڕیارەکەت.',
    'Your store name is printed on the shipping label so orders reach your customer under your name.',
  );
  static String get instagramLabel =>
      _t('رابط صفحة إنستغرام', 'لینکی پەیجی ئینستاگرام', 'Instagram page link');
  static String get instagramRequired => _t(
    'رابط إنستغرام مطلوب',
    'لینکی ئینستاگرام پێویستە',
    'Instagram link is required',
  );
  static String get instagramInvalid => _t(
    'اكتب اسم مستخدم إنستغرام أو رابط صفحة صحيح',
    'ناوی بەکارهێنەری ئینستاگرام یان لینکێکی دروست بنووسە',
    'Enter an Instagram username or a valid profile link',
  );
  static String policyVersion(String version) => _t(
    'نسخة الشروط: $version',
    'وەشانی مەرجەکان: $version',
    'Terms version: $version',
  );
  static String get phoneLabel =>
      _t('رقم الهاتف', 'ژمارەی مۆبایل', 'Phone number');
  static String get phoneLockedInfo => _t(
    'لتغيير الرقم تواصل مع الدعم',
    'بۆ گۆڕینی ژمارەکە پەیوەندی بە پشتگیرییەوە بکە',
    'Contact support to change your number',
  );
  static String get saveChanges =>
      _t('حفظ التغييرات', 'پاشەکەوتکردنی گۆڕانکارییەکان', 'Save changes');
  static String get changesSaved => _t(
    'تم حفظ التغييرات بنجاح',
    'گۆڕانکارییەکان بە سەرکەوتوویی پاشەکەوتکران',
    'Changes saved successfully',
  );
  static String get profilePhoto =>
      _t('صورة الملف الشخصي', 'وێنەی پرۆفایل', 'Profile photo');
  static String get profilePhotoHint => _t(
    'استخدم صورة JPG أو PNG أو WebP بحجم لا يتجاوز 5 ميغابايت.',
    'وێنەی JPG یان PNG یان WebP بە قەبارەی کەمتر لە 5 مێگابایت بەکاربهێنە.',
    'Use a JPG, PNG, or WebP image up to 5 MB.',
  );
  static String get choosePhoto =>
      _t('اختيار صورة', 'هەڵبژاردنی وێنە', 'Choose photo');
  static String get removePhoto =>
      _t('إزالة الصورة', 'سڕینەوەی وێنە', 'Remove photo');
  static String get avatarTooLarge => _t(
    'حجم الصورة أكبر من 5 ميغابايت. اختر صورة أصغر.',
    'قەبارەی وێنەکە لە 5 مێگابایت زیاترە. وێنەیەکی بچووکتر هەڵبژێرە.',
    'The image is larger than 5 MB. Choose a smaller image.',
  );
  static String get avatarUnsupported => _t(
    'صيغة الصورة غير مدعومة. استخدم JPG أو PNG أو WebP.',
    'جۆری وێنەکە پشتگیری ناکرێت. JPG یان PNG یان WebP بەکاربهێنە.',
    'Unsupported image type. Use JPG, PNG, or WebP.',
  );
  static String get avatarSelectionFailed => _t(
    'تعذر قراءة الصورة المختارة. حاول بصورة أخرى.',
    'خوێندنەوەی وێنە هەڵبژێردراوەکە سەرکەوتوو نەبوو. وێنەیەکی تر هەڵبژێرە.',
    'Could not read the selected image. Try another image.',
  );
}
