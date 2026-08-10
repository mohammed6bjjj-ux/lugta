import '../../data/app_settings.dart';

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
