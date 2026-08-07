import '../../data/app_settings.dart';
import '../../data/models.dart';

/// نصوص ميزة الطلبات (قائمة الطلبات + تفاصيل الطلب) بثلاث لغات.
class OrdersStrings {
  OrdersStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  // ── شاشة قائمة الطلبات: الرأس ──
  static String ordersCount(String count) =>
      _t('$count طلب', '$count داواکاری', '$count orders');
  static String get listRefreshed => _t(
    'تم تحديث قائمة الطلبات',
    'لیستی داواکارییەکان نوێکرایەوە',
    'Orders list updated',
  );

  // ── الفلاتر ──
  static String get filterAll => _t('الكل', 'هەموو', 'All');
  static String get filterActive =>
      _t('قيد التنفيذ', 'لە جێبەجێکردندایە', 'In progress');
  static String get filterCompleted => _t('مكتملة', 'تەواوبوو', 'Completed');
  static String get filterReturned => _t('راجعة', 'گەڕاوە', 'Returned');
  static String get filterCancelled => _t('ملغاة', 'هەڵوەشاوە', 'Cancelled');

  // ── الحالات الفارغة ──
  static String get emptyAllTitle =>
      _t('لا توجد طلبات بعد', 'هێشتا هیچ داواکارییەک نییە', 'No orders yet');
  static String get emptyActiveTitle => _t(
    'لا توجد طلبات قيد التنفيذ',
    'هیچ داواکارییەک لە جێبەجێکردندا نییە',
    'No active orders',
  );
  static String get emptyCompletedTitle => _t(
    'لا توجد طلبات مكتملة بعد',
    'هێشتا هیچ داواکارییەکی تەواوبوو نییە',
    'No completed orders yet',
  );
  static String get emptyReturnedTitle => _t(
    'لا توجد طلبات راجعة',
    'هیچ داواکارییەکی گەڕاوە نییە',
    'No returned orders',
  );
  static String get emptyCancelledTitle => _t(
    'لا توجد طلبات ملغاة',
    'هیچ داواکارییەکی هەڵوەشاوە نییە',
    'No cancelled orders',
  );
  static String get emptyAllSubtitle => _t(
    'ابدأ بتسويق المنتجات لزبائنك، وعند وصول أول طلب أدخله من صفحة المنتج وستجده هنا.',
    'دەست بکە بە بازاڕگەری بەرهەمەکان بۆ کڕیارەکانت، کاتێک یەکەم داواکاریت گەیشت لە پەڕەی بەرهەمەکەوە تۆماری بکە و لێرە دەیبینیتەوە.',
    'Start marketing products to your customers. When your first order arrives, submit it from the product page and it will show up here.',
  );
  static String get emptyActiveSubtitle => _t(
    'الطلبات قيد المراجعة أو التجهيز أو التوصيل ستظهر في هذا التبويب.',
    'ئەو داواکارییانەی لە پێداچوونەوە یان ئامادەکردن یان گەیاندندان لەم بەشەدا دەردەکەون.',
    'Orders under review, being prepared, or out for delivery appear in this tab.',
  );
  static String get emptyCompletedSubtitle => _t(
    'عند اكتمال توصيل طلباتك وتسويتها ستظهر هنا مع أرباحها.',
    'کاتێک گەیاندنی داواکارییەکانت تەواو دەبێت و یەکلایی دەکرێنەوە، لێرە لەگەڵ قازانجەکانیان دەردەکەون.',
    'Once your orders are delivered and settled, they appear here with their profits.',
  );
  static String get emptyReturnedSubtitle => _t(
    'ممتاز! لا توجد لديك طلبات فاشلة أو مرتجعة حالياً.',
    'نایاب! لە ئێستادا هیچ داواکارییەکی سەرنەکەوتوو یان گەڕاوەت نییە.',
    'Great! You have no failed or returned orders right now.',
  );
  static String get emptyCancelledSubtitle => _t(
    'لم تقم بإلغاء أي طلب حتى الآن.',
    'تا ئێستا هیچ داواکارییەکت هەڵنەوەشاندووەتەوە.',
    'You have not cancelled any orders yet.',
  );

  // ── شريط الربح ──
  static String profitPending(String amount) => _t(
    'ربح معلق +$amount',
    'قازانجی هەڵواسراو +$amount',
    'Pending profit +$amount',
  );
  static String profitYours(String amount) =>
      _t('ربحك +$amount', 'قازانجی تۆ +$amount', 'Your profit +$amount');
  static String get noProfitNoCharges => _t(
    'بلا ربح — لا خصومات عليك',
    'بێ قازانج — هیچ لێبڕینێک لەسەر تۆ نییە',
    'No profit — nothing charged to you',
  );
  static String totalAmount(String amount) =>
      _t('الإجمالي $amount', 'کۆی گشتی $amount', 'Total $amount');

  // ── شاشة التفاصيل: وصف الحالة ──
  static String statusDescription(OrderStatus s) => switch (s) {
    OrderStatus.pendingReview => _t(
      'استلمنا طلبك وهو قيد مراجعة الإدارة. عادةً تكتمل المراجعة خلال ساعات قليلة وسيصلك إشعار فور التأكيد.',
      'داواکارییەکەتمان وەرگرت و لە پێداچوونەوەی بەڕێوەبەرایەتیدایە. بە زۆری پێداچوونەوەکە لە چەند کاتژمێرێکدا تەواو دەبێت و هەر کە پەسەند کرا ئاگادارکردنەوەت بۆ دێت.',
      'We received your order and it is under admin review. Reviews usually finish within a few hours, and you will be notified once confirmed.',
    ),
    OrderStatus.confirmed => _t(
      'تم تأكيد الطلب وجاري تجهيزه وتغليفه باسم متجرك قبل تسليمه لشركة التوصيل.',
      'داواکارییەکە پەسەند کرا و ئێستا بە ناوی فرۆشگاکەتەوە ئامادە و پاکێج دەکرێت پێش ئەوەی بدرێتە کۆمپانیای گەیاندن.',
      'Order confirmed. It is being prepared and packed under your store name before handover to the delivery company.',
    ),
    OrderStatus.shipped => _t(
      'الطلب مع شركة التوصيل وبطريقه إلى زبونك. سيتواصل المندوب مع الزبون قبل التسليم.',
      'داواکارییەکە لەگەڵ کۆمپانیای گەیاندنە و لە ڕێگادایە بۆ لای کڕیارەکەت. پەیک پێش گەیاندن پەیوەندی بە کڕیارەوە دەکات.',
      'The order is with the delivery company, on its way to your customer. The courier will contact them before delivery.',
    ),
    OrderStatus.delivered => _t(
      'استلم زبونك الطلب ودفع المبلغ. بانتظار التسوية مع شركة التوصيل ليتحول ربحك إلى الرصيد المتاح.',
      'کڕیارەکەت داواکارییەکەی وەرگرت و پارەکەی دا. چاوەڕوانی یەکلاییکردنەوە لەگەڵ کۆمپانیای گەیاندن دەکرێت بۆ ئەوەی قازانجەکەت ببێتە باڵانسی بەردەست.',
      'Your customer received the order and paid. Awaiting settlement with the delivery company so your profit moves to your available balance.',
    ),
    OrderStatus.completed => _t(
      'اكتمل الطلب وتمت التسوية — ربحك أصبح ضمن رصيدك المتاح للسحب. عمل رائع!',
      'داواکارییەکە تەواو بوو و یەکلایی کرایەوە — قازانجەکەت چووە ناو باڵانسی بەردەستت بۆ ڕاکێشان. کارێکی نایاب!',
      'Order completed and settled — your profit is now in your withdrawable balance. Great work!',
    ),
    OrderStatus.deliveryFailed => _t(
      'تعذر توصيل الطلب إلى زبونك. راجع السبب أدناه، وإن كان لديك حل تواصل مع الدعم بأسرع وقت.',
      'گەیاندنی داواکارییەکە بۆ کڕیارەکەت سەرنەکەوت. هۆکارەکە لە خوارەوە ببینە، ئەگەر چارەسەرت هەیە بە زووترین کات پەیوەندی بە پشتگیرییەوە بکە.',
      'The order could not be delivered to your customer. Check the reason below, and if you have a fix, contact support as soon as possible.',
    ),
    OrderStatus.returning => _t(
      'الطلب بطريق الإرجاع إلى مخزن المنصة وسيُعاد للمخزون فور وصوله.',
      'داواکارییەکە لە ڕێی گەڕانەوەدایە بۆ کۆگای پلاتفۆرم و هەر کە گەیشت دەگەڕێتەوە ناو کۆگا.',
      'The order is on its way back to the platform warehouse and will be restocked on arrival.',
    ),
    OrderStatus.returned => _t(
      'وصل الطلب راجعاً وأُعيد إلى المخزون. لا توجد أي مستحقات عليك.',
      'داواکارییەکە گەڕایەوە و خرایەوە ناو کۆگا. هیچ پارەیەک لەسەر تۆ نییە.',
      'The order came back and was restocked. You owe nothing.',
    ),
    OrderStatus.rejected => _t(
      'رفضت الإدارة هذا الطلب. راجع السبب أدناه أو تواصل مع الدعم لمزيد من التفاصيل.',
      'بەڕێوەبەرایەتی ئەم داواکارییەی ڕەت کردەوە. هۆکارەکە لە خوارەوە ببینە یان بۆ وردەکاری زیاتر پەیوەندی بە پشتگیرییەوە بکە.',
      'The admin rejected this order. Check the reason below or contact support for more details.',
    ),
    OrderStatus.cancelled => _t(
      'تم إلغاء هذا الطلب ولن تتم معالجته.',
      'ئەم داواکارییە هەڵوەشێنرایەوە و جێبەجێ ناکرێت.',
      'This order was cancelled and will not be processed.',
    ),
  };

  // ── بطاقة الحالة ──
  static String failReason(String reason) => _t(
    'سبب الفشل: $reason',
    'هۆکاری سەرنەکەوتن: $reason',
    'Failure reason: $reason',
  );
  static String get noFeesOnReturns => _t(
    'لا تُخصم أي أجور من محفظتك للطلبات الراجعة.',
    'هیچ کرێیەک لە جزدانەکەت نابڕدرێت بۆ داواکارییە گەڕاوەکان.',
    'No fees are deducted from your wallet for returned orders.',
  );

  // ── عناوين الأقسام ──
  static String get timelineTitle =>
      _t('الخط الزمني للطلب', 'هێڵی کاتی داواکاری', 'Order timeline');
  static String get productItemsTitle =>
      _t('المنتج والعناصر', 'بەرهەم و بڕگەکان', 'Product & items');
  static String additionalProducts(String count) => _t(
    '+ $count منتجات أخرى',
    '+ $count بەرهەمی تر',
    '+ $count more products',
  );
  static String get customerInfoTitle =>
      _t('معلومات الزبون', 'زانیاری کڕیار', 'Customer info');

  // ── الخط الزمني ──
  static String get expectedStep =>
      _t('خطوة متوقعة', 'هەنگاوی چاوەڕوانکراو', 'Expected step');

  // ── المنتج والعناصر ──
  static String totalQuantity(String qty) => _t(
    'إجمالي الكمية: $qty قطعة',
    'کۆی بڕ: $qty دانە',
    'Total quantity: $qty pcs',
  );

  // ── معلومات الزبون ──
  static String get customerNameLabel =>
      _t('اسم الزبون', 'ناوی کڕیار', 'Customer name');
  static String get phoneLabel =>
      _t('رقم الهاتف', 'ژمارەی تەلەفۆن', 'Phone number');
  static String get altPhoneLabel =>
      _t('رقم بديل', 'ژمارەی یەدەگ', 'Alternate number');
  static String get governorateLabel =>
      _t('المحافظة', 'پارێزگا', 'Governorate');
  static String get addressLabel =>
      _t('العنوان التفصيلي', 'ناونیشانی ورد', 'Full address');
  static String get landmarkLabel =>
      _t('أقرب نقطة دالة', 'نزیکترین شوێنی ناسراو', 'Nearest landmark');
  static String get deliveryCompanyLabel =>
      _t('شركة التوصيل', 'کۆمپانیای گەیاندن', 'Delivery company');
  static String get trackingNumberLabel =>
      _t('رقم التتبع', 'ژمارەی بەدواداچوون', 'Tracking number');
  static String get notesLabel => _t('ملاحظات', 'تێبینییەکان', 'Notes');
  static String callingCustomer(String phone) => _t(
    'جارٍ الاتصال بالزبون على الرقم $phone...',
    'پەیوەندی بە کڕیارەوە دەکرێت لەسەر ژمارە $phone...',
    'Calling customer at $phone...',
  );
  static String callingAltPhone(String phone) => _t(
    'جارٍ الاتصال بالرقم البديل $phone...',
    'پەیوەندی بە ژمارە یەدەگەکەوە دەکرێت $phone...',
    'Calling alternate number $phone...',
  );

  // ── تنويه اسم المتجر ──
  static String get arrivesUnderName => _t(
    'هذا الطلب يصل زبونك باسم: ',
    'ئەم داواکارییە بەم ناوەوە دەگاتە کڕیارەکەت: ',
    'This order reaches your customer under the name: ',
  );

  // ── شريط الإجراءات ──
  static String get cancelOrder =>
      _t('إلغاء الطلب', 'هەڵوەشاندنەوەی داواکاری', 'Cancel order');
  static String get requestChangeOrCancel => _t(
    'طلب تعديل / إلغاء',
    'داوای گۆڕانکاری / هەڵوەشاندنەوە',
    'Request change / cancel',
  );
  static String get contactSupportAboutOrder => _t(
    'تواصل مع الدعم بخصوص الطلب',
    'دەربارەی داواکارییەکە پەیوەندی بە پشتگیرییەوە بکە',
    'Contact support about this order',
  );
  static String get addComplaintOrReport => _t(
    'إضافة شكوى أو بلاغ',
    'زیادکردنی سکاڵا یان ڕاپۆرت',
    'Add complaint or report',
  );
  static String get complaintsTitle =>
      _t('الشكاوى والبلاغات', 'سکاڵا و ڕاپۆرتەکان', 'Complaints & reports');
  static String get complaintKind => _t('شكوى', 'سکاڵا', 'Complaint');
  static String get reportKind => _t('بلاغ', 'ڕاپۆرت', 'Report');
  static String get freePackaging => _t('مجانية', 'خۆڕایی', 'Free');
  static String get complaintSubject =>
      _t('عنوان مختصر', 'ناونیشانی کورت', 'Short subject');
  static String get complaintDetails =>
      _t('التفاصيل', 'وردەکارییەکان', 'Details');
  static String get complaintDetailsHint => _t(
    'اكتب المشكلة بوضوح حتى يستطيع فريق الإدارة متابعتها.',
    'کێشەکە بە ڕوونی بنووسە بۆ ئەوەی تیمی بەڕێوەبەرایەتی بتوانێت بەدواداچوونی بۆ بکات.',
    'Describe the issue clearly so the admin team can follow it up.',
  );
  static String get submitComplaint =>
      _t('إرسال للإدارة', 'ناردن بۆ بەڕێوەبەرایەتی', 'Send to admin');
  static String get complaintSent => _t(
    'وصلت الشكوى أو البلاغ إلى الإدارة',
    'سکاڵا یان ڕاپۆرتەکە گەیشتە بەڕێوەبەرایەتی',
    'Your complaint or report reached the admin team',
  );
  static String get adminResponse =>
      _t('رد الإدارة', 'وەڵامی بەڕێوەبەرایەتی', 'Admin response');
  static String complaintStatus(OrderComplaintStatus status) =>
      switch (status) {
        OrderComplaintStatus.open => _t('جديدة', 'نوێ', 'Open'),
        OrderComplaintStatus.inReview => _t(
          'قيد المراجعة',
          'لە پێداچوونەوەدایە',
          'In review',
        ),
        OrderComplaintStatus.resolved => _t(
          'تم الحل',
          'چارەسەرکرا',
          'Resolved',
        ),
        OrderComplaintStatus.rejected => _t('مرفوضة', 'ڕەتکراوە', 'Rejected'),
      };
  static String supportChatOpened(String code) => _t(
    'تم فتح محادثة مع الدعم بخصوص الطلب $code',
    'گفتوگۆ لەگەڵ پشتگیری کرایەوە دەربارەی داواکاری $code',
    'Support chat opened for order $code',
  );
  static String supportMessage(String code) => _t(
    'مرحباً، أحتاج مساعدة بخصوص الطلب $code',
    'سڵاو، پێویستم بە یارمەتییە دەربارەی داواکاری $code',
    'Hello, I need help with order $code',
  );
  static String get contactAppUnavailable => _t(
    'تعذر فتح تطبيق الاتصال على هذا الجهاز.',
    'نەتوانرا ئەپی پەیوەندی لەم ئامێرە بکرێتەوە.',
    'Could not open the contact app on this device.',
  );

  // ── حوار الإلغاء ──
  static String cancelOrderConfirm(String code) => _t(
    'هل أنت متأكد من إلغاء الطلب $code؟\nلا يمكن التراجع عن الإلغاء بعد تأكيده.',
    'دڵنیایت لە هەڵوەشاندنەوەی داواکاری $code؟\nدوای پشتڕاستکردنەوە ناتوانیت پاشگەز ببیتەوە.',
    'Are you sure you want to cancel order $code?\nThis cannot be undone.',
  );
  static String get dismiss => _t('تراجع', 'گەڕانەوە', 'Back');
  static String get confirmCancelYes => _t(
    'نعم، إلغاء الطلب',
    'بەڵێ، داواکارییەکە هەڵبوەشێنەوە',
    'Yes, cancel order',
  );
  static String orderCancelled(String code) => _t(
    'تم إلغاء الطلب $code',
    'داواکاری $code هەڵوەشێنرایەوە',
    'Order $code cancelled',
  );

  // ── ورقة طلب التعديل / الإلغاء ──
  static String changeRequestTitle(String code) => _t(
    'طلب تعديل / إلغاء — $code',
    'داوای گۆڕانکاری / هەڵوەشاندنەوە — $code',
    'Change / cancel request — $code',
  );
  static String get changeRequestBody => _t(
    'الطلب مؤكد لدى الإدارة، لذلك سيُراجع فريقنا طلبك ويرد عليك بأقرب وقت.',
    'داواکارییەکە لای بەڕێوەبەرایەتی پەسەندکراوە، بۆیە تیمەکەمان داواکەت پێداچوونەوەی بۆ دەکات و بە زووترین کات وەڵامت دەداتەوە.',
    'This order is already confirmed, so our team will review your request and get back to you shortly.',
  );
  static String get editOrder =>
      _t('تعديل الطلب', 'گۆڕانکاری لە داواکاری', 'Edit order');
  static String get cancelReasonLabel =>
      _t('سبب الإلغاء', 'هۆکاری هەڵوەشاندنەوە', 'Cancellation reason');
  static String get editDetailsLabel => _t(
    'تفاصيل التعديل المطلوب',
    'وردەکاری گۆڕانکارییە داواکراوەکە',
    'Requested change details',
  );
  static String get cancelReasonHint => _t(
    'مثال: الزبون غيّر رأيه وطلب الإلغاء',
    'نموونە: کڕیار بیری گۆڕی و داوای هەڵوەشاندنەوەی کرد',
    'e.g. Customer changed their mind and asked to cancel',
  );
  static String get editDetailsHint => _t(
    'مثال: تغيير اللون إلى بني، أو تعديل العنوان',
    'نموونە: گۆڕینی ڕەنگ بۆ قاوەیی، یان گۆڕینی ناونیشان',
    'e.g. Change the color to brown, or update the address',
  );
  static String get reasonRequired => _t(
    'يرجى كتابة السبب ليتمكن فريقنا من المساعدة',
    'تکایە هۆکارەکە بنووسە بۆ ئەوەی تیمەکەمان بتوانێت یارمەتیت بدات',
    'Please write the reason so our team can help',
  );
  static String get changeRequestSent => _t(
    'أُرسل طلبك للإدارة وسيتم الرد قريباً',
    'داواکەت نێردرا بۆ بەڕێوەبەرایەتی و بەم زووانە وەڵام دەدرێتەوە',
    'Your request was sent to admin — you will hear back soon',
  );
  static String get sendToAdmin => _t(
    'إرسال الطلب للإدارة',
    'ناردنی داواکە بۆ بەڕێوەبەرایەتی',
    'Send request to admin',
  );
}
