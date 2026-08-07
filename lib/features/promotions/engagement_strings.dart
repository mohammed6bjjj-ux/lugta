import '../../data/app_settings.dart';

class EngagementStrings {
  EngagementStrings._();

  static String t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  static String get referrals =>
      t('دعوة الأصدقاء', 'بانگهێشتی هاوڕێیان', 'Invite friends');
  static String get referralSubtitle => t(
    'شارك رمزك، وتابع الدعوات المؤهلة ومكافآتك.',
    'کۆدەکەت بلاو بکەرەوە و بانگهێشت و دیارییەکانت ببینە.',
    'Share your code and track qualified invites and rewards.',
  );
  static String get yourCode =>
      t('رمز دعوتك', 'کۆدی بانگهێشتت', 'Your referral code');
  static String get copy => t('نسخ', 'لەبەرگرتنەوە', 'Copy');
  static String get copied =>
      t('تم نسخ الرمز', 'کۆدەکە لەبەرگیرایەوە', 'Code copied');
  static String get share => t('مشاركة', 'بلاوکردنەوە', 'Share');
  static String shareMessage(String code) => t(
    'استخدم رمز دعوتي $code عند إنشاء حسابك في لكطة.',
    'لەکاتی دروستکردنی هەژماری لُگطة کۆدی $code بەکاربهێنە.',
    'Use my referral code $code when creating your Lugta account.',
  );
  static String get invited => t('المدعوون', 'بانگهێشتکراوەکان', 'Invited');
  static String get qualified => t('المؤهلون', 'شیاوەکان', 'Qualified');
  static String get rewarded => t('المكافآت', 'دیارییەکان', 'Rewarded');
  static String get completedReferredOrders => t(
    'طلبات المدعوين المكتملة',
    'داواکارییە تەواوبووەکانی بانگهێشتکراوان',
    'Completed referred orders',
  );
  static String get availableFreeDeliveries => t(
    'توصيل مجاني متاح',
    'گەیاندنی خۆڕایی بەردەست',
    'Free deliveries available',
  );
  static String get walletRewardsEarned =>
      t('مكافآت المحفظة', 'دیارییەکانی جزدان', 'Wallet rewards earned');
  static String get referralUnavailable => t(
    'رمز الدعوة غير متاح حالياً',
    'کۆدی بانگهێشت ئێستا بەردەست نییە',
    'Referral code is not available yet',
  );
  static String get retry => t('إعادة المحاولة', 'هەوڵدانەوە', 'Try again');
  static String get loadFailed => t(
    'تعذر تحميل البيانات',
    'بارکردنی زانیارییەکان سەرکەوتوو نەبوو',
    'Could not load data',
  );

  static String get promotions =>
      t('عروضي ومكافآتي', 'ئۆفەر و دیارییەکانم', 'My offers & rewards');
  static String get promotionsEmpty =>
      t('لا توجد مكافآت حالياً', 'ئێستا هیچ دیارییەک نییە', 'No rewards yet');
  static String get promotionsEmptyBody => t(
    'ستظهر مكافآتك هنا عند استحقاقها.',
    'کاتێک دیارییەک بەدەستدێنیت لێرە دەردەکەوێت.',
    'Earned rewards will appear here.',
  );
  static String get available => t('متاحة', 'بەردەستە', 'Available');
  static String get used => t('مستخدمة', 'بەکارهاتووە', 'Used');
  static String get expired => t('منتهية', 'بەسەرچووە', 'Expired');
  static String get validUntil =>
      t('صالحة لغاية', 'بەردەستە هەتا', 'Valid until');
  static String get noExpiry =>
      t('بدون تاريخ انتهاء', 'بێ بەرواری بەسەرچوون', 'No expiry');
  static String get freeDelivery =>
      t('توصيل مجاني', 'گەیاندنی بەخۆڕایی', 'Free delivery');
  static String percent(int value) => '$value%';
  static String get viewOffer =>
      t('عرض المكافآت', 'دیارییەکان ببینە', 'View rewards');
  static String get viewReferrals =>
      t('عرض الدعوات', 'بانگهێشتەکان ببینە', 'View referrals');
  static String get close => t('لاحقاً', 'دواتر', 'Later');
}
