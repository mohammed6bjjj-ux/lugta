import '../../data/app_settings.dart';
import '../../data/models.dart';

class LoyaltyStrings {
  LoyaltyStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  static String get title =>
      _t('المستويات والمكافآت', 'ئاست و خەڵاتەکان', 'Levels & rewards');
  static String get profileTitle =>
      _t('مستواي ومكافآتي', 'ئاست و خەڵاتەکانم', 'My level & rewards');
  static String get profileSubtitle => _t(
    'اجمع نقاطاً مع كل قطعة مباعة',
    'لەگەڵ هەر پارچەیەکی فرۆشراو خاڵ کۆبکەوە',
    'Earn points for every sold item',
  );
  static String get currentLevel =>
      _t('مستواك الحالي', 'ئاستی ئێستات', 'Your current level');
  static String get totalPoints =>
      _t('إجمالي النقاط', 'کۆی خاڵەکان', 'Total points');
  static String get soldUnits =>
      _t('القطع المكتملة', 'پارچە تەواوبووەکان', 'Completed units');
  static String get point => _t('نقطة', 'خاڵ', 'points');
  static String pointsPerUnit(int value) => _t(
    '$value نقطة لكل قطعة مكتملة',
    '$value خاڵ بۆ هەر پارچەیەکی تەواوبوو',
    '$value points per completed item',
  );
  static String pointsRemaining(int value, String tier) => _t(
    'باقي $value نقطة للوصول إلى $tier',
    '$value خاڵ ماوە بۆ گەیشتن بە $tier',
    '$value points to reach $tier',
  );
  static String get highestLevel => _t(
    'وصلت إلى أعلى مستوى',
    'گەیشتوویتە بەرزترین ئاست',
    'You reached the highest level',
  );
  static String get levels =>
      _t('مسار المستويات', 'ڕێڕەوی ئاستەکان', 'Level path');
  static String get recentActivity =>
      _t('آخر حركة نقاط', 'دوایین جووڵەی خاڵەکان', 'Recent points activity');
  static String get myBenefits =>
      _t('مميزات مستواي', 'تایبەتمەندییەکانی ئاستەکەم', 'My tier benefits');
  static String get benefitRequests =>
      _t('طلباتي الخاصة', 'داواکارییە تایبەتەکانم', 'My special requests');
  static String get productSourcing => _t(
    'طلب توفير منتج خاص',
    'داوای دابینکردنی بەرهەمێکی تایبەت',
    'Request a special product',
  );
  static String get customPhotography => _t(
    'طلب تصوير خاص للمنتج',
    'داوای وێنە یان ڤیدیۆی تایبەت بۆ بەرهەم',
    'Request custom product content',
  );
  static String requestsRemaining(int remaining, int total) => _t(
    'متبقي $remaining من $total هذا الشهر',
    '$remaining لە $total داواکاری ئەم مانگە ماوە',
    '$remaining of $total requests left this month',
  );
  static String maxUnits(int value) => _t(
    'لغاية $value قطعة في الطلب',
    'تا $value پارچە لە داواکارییەکدا',
    'Up to $value items per request',
  );
  static String maxPhotos(int value) => _t(
    'لغاية $value صورة في الطلب',
    'تا $value وێنە لە داواکارییەکدا',
    'Up to $value photos per request',
  );
  static String get submitRequest =>
      _t('إرسال الطلب', 'ناردنی داواکاری', 'Send request');
  static String get requestSent => _t(
    'تم إرسال طلبك إلى الإدارة',
    'داواکارییەکەت بۆ بەڕێوەبەرایەتی نێردرا',
    'Your request was sent to the admin team',
  );
  static String get itemName => _t(
    'اسم المنتج المطلوب',
    'ناوی بەرهەمی داواکراو',
    'Requested product name',
  );
  static String get chooseProduct =>
      _t('اختر المنتج', 'بەرهەم هەڵبژێرە', 'Choose a product');
  static String get requestDetails =>
      _t('تفاصيل إضافية', 'وردەکاری زیاتر', 'Additional details');
  static String get quantity => _t('الكمية', 'بڕ', 'Quantity');
  static String get photoCount =>
      _t('عدد الصور', 'ژمارەی وێنەکان', 'Photo count');
  static String get videoCount =>
      _t('عدد مقاطع الفيديو', 'ژمارەی ڤیدیۆکان', 'Video count');
  static String get contentType =>
      _t('نوع المحتوى المطلوب', 'جۆری ناوەڕۆکی داواکراو', 'Content type');
  static String get photos => _t('صور', 'وێنە', 'Photos');
  static String get video => _t('فيديو', 'ڤیدیۆ', 'Video');
  static String get referenceImage => _t(
    'صورة المنتج المطلوبة',
    'وێنەی بەرهەمی داواکراو',
    'Product reference image',
  );
  static String get addReferenceImage => _t(
    'أضف صورة واضحة من جهازك',
    'وێنەیەکی ڕوون لە ئامێرەکەت زیاد بکە',
    'Add a clear photo from your device',
  );
  static String get changeReferenceImage =>
      _t('تغيير الصورة', 'گۆڕینی وێنە', 'Change image');
  static String get referenceImageRequired => _t(
    'أضف صورة للمنتج الذي تريد توفيره',
    'وێنەی ئەو بەرهەمە زیاد بکە کە دەتەوێت دابین بکرێت',
    'Add a reference image for the product',
  );
  static String get referenceImageInvalid => _t(
    'تعذر قراءة الصورة. استخدم JPG أو PNG أو WebP بحجم أقل من 8 ميغابايت.',
    'نەتوانرا وێنەکە بخوێندرێتەوە. JPG، PNG یان WebP بە قەبارەی کەمتر لە 8MB بەکاربهێنە.',
    'Could not read the image. Use JPG, PNG, or WebP under 8 MB.',
  );
  static String get stockReservationTitle => _t(
    'حجز مخزون المستوى الماسي',
    'حجزکردنی کۆگای ئاستی ئەڵماسی',
    'Diamond stock reservation',
  );
  static String get stockReservationSubtitle => _t(
    'احجز القطع المطلوبة قبل نفادها، ثم استخدمها عند إنشاء الطلب.',
    'پارچە پێویستەکان پێش تەواوبوونیان حجز بکە و لە کاتی دروستکردنی داواکاری بەکاریانبهێنە.',
    'Hold the items you need before they sell out, then use them when placing an order.',
  );
  static String reservedUnits(int active, int maximum) => _t(
    'محجوز $active من أصل $maximum قطعة',
    '$active پارچە لە کۆی $maximum پارچە حجزکراوە',
    '$active of $maximum items reserved',
  );
  static String reservationRemaining(int value) => _t(
    'متاح لك حجز $value قطعة إضافية',
    'دەتوانیت $value پارچەی تر حجز بکەیت',
    'You can reserve $value more items',
  );
  static String maxPerReservation(int value) => _t(
    'الحد لكل عملية حجز: $value قطعة',
    'سنووری هەر حجزێک: $value پارچە',
    'Maximum per reservation: $value items',
  );
  static String reservationHoldHours(int value) => _t(
    'مدة الحجز: $value ساعة',
    'ماوەی حجز: $value کاتژمێر',
    'Hold duration: $value hours',
  );
  static String get reserveStock =>
      _t('احجز من المخزون', 'لە کۆگا حجز بکە', 'Reserve stock');
  static String get reservationLimitReached => _t(
    'استخدم أو ألغِ أحد حجوزاتك الحالية لتتمكن من حجز قطع جديدة.',
    'یەکێک لە حجزە ئێستاکانت بەکاربهێنە یان هەڵیوەشێنەوە بۆ حجزکردنی پارچەی نوێ.',
    'Use or release an active reservation before reserving more items.',
  );
  static String get chooseReservationProduct =>
      _t('اختر المنتج', 'بەرهەم هەڵبژێرە', 'Choose product');
  static String get chooseReservationVariant =>
      _t('اختر الخيار', 'جۆر هەڵبژێرە', 'Choose option');
  static String get chooseReservationProductHint => _t(
    'اختر منتجاً متوفراً للحجز',
    'بەرهەمێکی بەردەست بۆ حجزکردن هەڵبژێرە',
    'Choose a product available to reserve',
  );
  static String get noReservableProducts => _t(
    'لا توجد منتجات متاحة للحجز حالياً',
    'ئێستا هیچ بەرهەمێک بۆ حجزکردن بەردەست نییە',
    'No products are available to reserve now',
  );
  static String get variantRequired => _t(
    'اختر الخيار أولاً',
    'سەرەتا جۆرەکە هەڵبژێرە',
    'Choose an option first',
  );
  static String get reservationQuantity =>
      _t('عدد القطع', 'ژمارەی پارچەکان', 'Number of items');
  static String availableToReserve(int value) => _t(
    '$value قطعة متاحة للحجز الآن',
    '$value پارچە ئێستا بۆ حجزکردن بەردەستە',
    '$value items available to reserve now',
  );
  static String get confirmReservation =>
      _t('تأكيد الحجز', 'پشتڕاستکردنەوەی حجز', 'Confirm reservation');
  static String get reservationCreated => _t(
    'تم حجز القطع لك بنجاح',
    'پارچەکان بە سەرکەوتوویی بۆت حجزکران',
    'Items reserved successfully',
  );
  static String get reservationFailed => _t(
    'تعذر إكمال الحجز. حدّث البيانات وحاول مرة أخرى.',
    'حجزکردن تەواو نەبوو. زانیارییەکان نوێ بکەرەوە و دووبارە هەوڵبدەرەوە.',
    'Could not complete the reservation. Refresh and try again.',
  );
  static String get myStockReservations =>
      _t('حجوزات المخزون', 'حجزەکانی کۆگا', 'Stock reservations');
  static String get noStockReservations => _t(
    'لا توجد حجوزات مخزون بعد',
    'هێشتا هیچ حجزێکی کۆگا نییە',
    'No stock reservations yet',
  );
  static String get releaseReservation =>
      _t('إلغاء الحجز', 'هەڵوەشاندنەوەی حجز', 'Release reservation');
  static String get releaseReservationTitle => _t(
    'إلغاء حجز القطع؟',
    'حجزی پارچەکان هەڵبوەشێنرێتەوە؟',
    'Release reserved items?',
  );
  static String get releaseReservationBody => _t(
    'ستعود القطع المتبقية إلى المخزون العام فوراً، ولا يمكن التراجع عن هذا الإجراء.',
    'پارچە ماوەکان دەستبەجێ دەگەڕێنەوە بۆ کۆگای گشتی و ناتوانرێت ئەم کردارە پاشگەز بکرێتەوە.',
    'Remaining items return to public stock immediately. This cannot be undone.',
  );
  static String get keepReservation =>
      _t('الاحتفاظ بالحجز', 'هێشتنەوەی حجز', 'Keep reservation');
  static String get reservationReleased => _t(
    'تم إلغاء الحجز وإعادة القطع المتبقية إلى المخزون',
    'حجزەکە هەڵوەشێندرایەوە و پارچە ماوەکان گەڕێندرانەوە بۆ کۆگا',
    'Reservation released and remaining items returned to stock',
  );
  static String reservationNumber(String value) =>
      _t('حجز $value', 'حجز $value', 'Reservation $value');
  static String reservedQuantity(int value) =>
      _t('$value قطعة', '$value پارچە', '$value items');
  static String reservationUsed(int value) =>
      _t('استُخدم $value', '$value بەکارهاتووە', '$value used');
  static String reservationExpires(String value) =>
      _t('ينتهي $value', '$value کۆتایی دێت', 'Expires $value');
  static String reservationStatus(StockReservationStatus status) =>
      switch (status) {
        StockReservationStatus.active => _t('فعال', 'چالاک', 'Active'),
        StockReservationStatus.consumed => _t(
          'استُخدم بالكامل',
          'بە تەواوی بەکارهاتووە',
          'Fully used',
        ),
        StockReservationStatus.released => _t(
          'ملغي',
          'هەڵوەشاوەتەوە',
          'Released',
        ),
        StockReservationStatus.expired => _t('منتهي', 'بەسەرچووە', 'Expired'),
      };
  static String get noBenefits => _t(
    'لا توجد مميزات طلب مفعلة لهذا المستوى حالياً',
    'ئێستا هیچ تایبەتمەندییەکی داواکاری بۆ ئەم ئاستە چالاک نییە',
    'No request benefits are enabled for this tier yet',
  );
  static String get requestBenefit =>
      _t('استخدم الميزة', 'تایبەتمەندییەکە بەکاربهێنە', 'Use benefit');
  static String get quotaFinished => _t(
    'اكتمل حد هذا الشهر',
    'سنووری ئەم مانگە تەواو بوو',
    'Monthly limit reached',
  );
  static String requestNumber(int value) =>
      _t('طلب #$value', 'داواکاری #$value', 'Request #$value');
  static String get chooseProductHint => _t(
    'اختر منتجاً من منتجات لكطة',
    'بەرهەمێک لە بەرهەمەکانی لکطة هەڵبژێرە',
    'Choose a Lugta product',
  );
  static String get itemNameRequired => _t(
    'اكتب اسم المنتج الذي تريد توفيره',
    'ناوی ئەو بەرهەمە بنووسە کە دەتەوێت دابین بکرێت',
    'Enter the product you want sourced',
  );
  static String get productRequired => _t(
    'اختر المنتج أولاً',
    'سەرەتا بەرهەم هەڵبژێرە',
    'Choose a product first',
  );
  static String get close => _t('إغلاق', 'داخستن', 'Close');
  static String get adminReply =>
      _t('رد الإدارة', 'وەڵامی بەڕێوەبەرایەتی', 'Admin response');
  static String get noBenefitRequests => _t(
    'لم ترسل طلبات ميزات بعد',
    'هێشتا داواکاری تایبەتمەندیت نەناردووە',
    'No benefit requests yet',
  );
  static String get requestUnavailable => _t(
    'هذه الميزة غير متاحة حالياً',
    'ئەم تایبەتمەندییە ئێستا بەردەست نییە',
    'This benefit is not available now',
  );
  static String requestStatus(LoyaltyBenefitRequestStatus status) =>
      switch (status) {
        LoyaltyBenefitRequestStatus.pending => _t(
          'بانتظار المراجعة',
          'چاوەڕوانی پێداچوونەوە',
          'Pending review',
        ),
        LoyaltyBenefitRequestStatus.approved => _t(
          'مقبول',
          'پەسەندکراو',
          'Approved',
        ),
        LoyaltyBenefitRequestStatus.inProgress => _t(
          'قيد التنفيذ',
          'لە جێبەجێکردندایە',
          'In progress',
        ),
        LoyaltyBenefitRequestStatus.completed => _t(
          'مكتمل',
          'تەواوبوو',
          'Completed',
        ),
        LoyaltyBenefitRequestStatus.rejected => _t(
          'مرفوض',
          'ڕەتکراوەتەوە',
          'Rejected',
        ),
        LoyaltyBenefitRequestStatus.cancelled => _t(
          'ملغي',
          'هەڵوەشاوەتەوە',
          'Cancelled',
        ),
      };
  static String get noActivity => _t(
    'لا توجد حركات نقاط بعد',
    'هێشتا جووڵەی خاڵ نییە',
    'No points activity yet',
  );
  static String get disabledTitle => _t(
    'برنامج المستويات متوقف حالياً',
    'پرۆگرامی ئاستەکان ئێستا وەستاوە',
    'The levels program is currently paused',
  );
  static String get disabledBody => _t(
    'ستظهر نقاطك ومستوياتك هنا عند تفعيل البرنامج.',
    'کاتێک پرۆگرامەکە چالاک بکرێت خاڵ و ئاستەکانت لێرە دەردەکەون.',
    'Your points and levels will appear here when the program is enabled.',
  );
  static String get loadError => _t(
    'تعذر تحميل المستويات',
    'بارکردنی ئاستەکان سەرکەوتوو نەبوو',
    'Could not load levels',
  );
  static String get retry => _t('إعادة المحاولة', 'هەوڵدانەوە', 'Try again');
  static String get currentBadge => _t('الحالي', 'ئێستا', 'Current');
  static String threshold(int value) => _t(
    'يبدأ من $value نقطة',
    'لە $value خاڵەوە دەست پێ دەکات',
    'Starts at $value points',
  );
  static String get reward =>
      _t('مكافأة المستوى', 'خەڵاتی ئاست', 'Level reward');
  static String freeDeliveryReward(int count) => _t(
    '$count توصيل مجاني',
    '$count گەیاندنی بەخۆڕایی',
    '$count free deliveries',
  );
  static String walletReward(String amount) => _t(
    '$amount رصيد محفظة',
    '$amount باڵانسی جزدان',
    '$amount wallet credit',
  );
  static String percentReward(int value) =>
      _t('خصم $value%', 'داشکاندنی $value%', '$value% discount');
  static String validDays(int value) => _t(
    'صالحة $value يوماً',
    'بۆ $value ڕۆژ بەردەستە',
    'Valid for $value days',
  );
  static String get noReward =>
      _t('بدون مكافأة مفعلة', 'هیچ خەڵاتێک چالاک نییە', 'No active reward');
  static String get orderCompleted =>
      _t('طلب مكتمل', 'داواکاری تەواوبوو', 'Completed order');
  static String get orderReversed => _t(
    'إلغاء نقاط طلب',
    'هەڵوەشاندنەوەی خاڵی داواکاری',
    'Order points reversed',
  );
  static String get positiveAdjustment =>
      _t('إضافة نقاط', 'زیادکردنی خاڵ', 'Points added');
  static String get negativeAdjustment =>
      _t('خصم نقاط', 'کەمکردنەوەی خاڵ', 'Points deducted');
  static String entryType(String type) => switch (type) {
    'order_completed' => orderCompleted,
    'order_reversed' => orderReversed,
    'positive_adjustment' => positiveAdjustment,
    'negative_adjustment' => negativeAdjustment,
    _ => _t('حركة نقاط', 'جووڵەی خاڵ', 'Points activity'),
  };
}
