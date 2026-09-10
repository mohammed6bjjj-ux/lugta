import '../../data/app_settings.dart';

class EngagementStrings {
  EngagementStrings._();

  static String rewardTitle(String kind, double value) {
    final amount = value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
    return switch (kind) {
      'profit_percent' => t(
        '$amount٪ من ربح طلب الإحالة',
        '$amount٪ لە قازانجی داواکاریی بانگهێشت',
        '$amount% of referred order profit',
      ),
      'fixed_cash' => t(
        '$amount د.ع لكل طلب إحالة',
        '$amount د.ع بۆ هەر داواکاریی بانگهێشت',
        '$amount IQD per referred order',
      ),
      'delivery_credit' => t(
        'خصم توصيل حتى $amount د.ع لكل طلب إحالة',
        'داشکاندنی گەیاندن تا $amount د.ع بۆ هەر داواکاریی بانگهێشت',
        'Up to $amount IQD delivery discount per referred order',
      ),
      'points' => t(
        '$amount نقطة لكل طلب إحالة',
        '$amount خاڵ بۆ هەر داواکاریی بانگهێشت',
        '$amount points per referred order',
      ),
      _ => t('مكافآت الإحالة', 'پاداشتی بانگهێشت', 'Referral rewards'),
    };
  }

  static String get configuredRewardBody => t(
    'تظهر المكافأة معلّقة عند إنشاء طلب مؤهل، وتتاح بعد التسوية. تُلغى عند إلغاء الطلب أو إرجاعه. تغييرات البرنامج تخص الطلبات الجديدة فقط، ولا تُخصم المكافأة من ربح صاحب الطلب.',
    'پاداشت لە دروستکردنی داواکاریی شیاودا چاوەڕوانە و دوای یەکلاکردنەوە بەردەست دەبێت. لە هەڵوەشاندنەوە یان گەڕاندنەوەدا هەڵدەوەشێتەوە. گۆڕانکاری تەنها بۆ داواکاریی نوێیە و لە قازانجی خاوەن داواکاری کەم ناکرێتەوە.',
    'Rewards appear as pending on eligible order creation and become available after settlement. Cancellation or return reverses them. Program changes affect new orders only; rewards are not deducted from the referred seller’s profit.',
  );
  static String get pendingCash => t(
    'مكافآت نقدية معلّقة',
    'پاداشتی پارەی چاوەڕوان',
    'Pending cash rewards',
  );
  static String get pendingPoints =>
      t('نقاط معلّقة', 'خاڵی چاوەڕوان', 'Pending points');
  static String get pendingDelivery => t(
    'خصومات توصيل معلّقة',
    'داشکاندنی گەیاندنی چاوەڕوان',
    'Pending delivery discounts',
  );
  static String get releasedPoints => t(
    'نقاط مُنحت بعد التسوية',
    'خاڵی دراو دوای یەکلاکردنەوە',
    'Points awarded after settlement',
  );
  static String get releasedDelivery => t(
    'خصومات توصيل مُنحت بعد التسوية',
    'داشکاندنی گەیاندنی دراو دوای یەکلاکردنەوە',
    'Delivery discounts awarded after settlement',
  );
  static String get deliveryCreditHelp => t(
    'كل خصم توصيل يُستخدم مرة واحدة ضمن شروط قيمة الجملة، ولا يتحول إلى رصيد قابل للسحب. إجمالي الممنوح يشمل الخصومات المستخدمة سابقاً.',
    'هەر داشکاندنی گەیاندن جارێک بەکاردێت بە مەرجی کۆی نرخی کۆمەڵ و نابێتە پارەی ڕاکێشان. کۆی دراو داشکاندنی بەکارهاتووش دەگرێتەوە.',
    'Each delivery discount is single-use, subject to the wholesale threshold, and cannot be withdrawn as cash. Awarded totals include previously used discounts.',
  );

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
  static String get referralSignupTitle => t(
    'توصيل مجاني إضافي لصديقك',
    'گەیاندنێکی خۆڕایی زیادە بۆ هاوڕێکەت',
    'An extra free delivery for your friend',
  );
  static String get referralSignupBody => t(
    'اللي يكمل التسجيل برمزك ويؤكد رقمه يحصل على توصيل مجاني واحد إضافي فوق مكافأة الترحيب، بدون انتظار أول طلب. يُستخدم بعد تفعيل الحساب.',
    'ئەو کەسەی بە کۆدەکەت تۆمارکردن تەواو دەکات و ژمارەکەی پشتڕاست دەکاتەوە، گەیاندنێکی خۆڕایی زیادە لەسەر دیاریی بەخێرهاتن وەردەگرێت، بەبێ چاوەڕوانی یەکەم داواکاری. دوای چالاککردنی هەژمار بەکاردێت.',
    'Friends who complete registration with your code and verify their phone get one free delivery on top of their welcome reward. No first order required; usable once their account is activated.',
  );
  static String get referralSignupEarned => t(
    'استلمت هدية التسجيل بالإحالة',
    'دیاریی تۆمارکردن بە بانگهێشتت وەرگرت',
    'You received your referral signup gift',
  );
  static String get referralSignupPaused => t(
    'العرض متوقف حالياً. إذا بعدك ما استخدمت هدية التوصيل، تبقى محفوظة ضمن عروضك ومكافآتك.',
    'ئۆفەرەکە ئێستا ناچالاکە. ئەگەر دیاریی گەیاندنەکەت بەکارنەهێناوە، لە ئۆفەر و دیارییەکانت ماوەتەوە.',
    'This offer is paused. If you have not used your delivery gift, it remains in My offers & rewards.',
  );
  static String referralProfitTitle(int percent) => t(
    'اربح $percent٪ من أرباح أصدقائك',
    '$percent٪ لە قازانجی هاوڕێکانت وەربگرە',
    'Earn $percent% of your friends’ profits',
  );
  static String get referralProfitBody => t(
    'ادعُ صديقك للتسجيل برمزك. مع كل طلب مكتمل وتسوية ربحه أثناء العرض، تنضاف مكافأتك إلى محفظتك وتكدر تسحبها. المكافأة من التطبيق، وما تنقص من أرباح صديقك.',
    'هاوڕێکەت بانگهێشت بکە بە کۆدەکەت تۆمار بکات. دوای تەواوبوونی داواکاری و یەکلاییبوونەوەی قازانج، پاداشتەکەت دەخرێتە جزدانەکەت. لە قازانجی هاوڕێکەت کەم ناکرێتەوە.',
    'Invite a friend to register with your code. When their order and profit are finalized during the offer, your reward goes to your wallet, ready to withdraw. Lugta funds the bonus; your friend keeps their full profit.',
  );
  static String get referralProfitExample => t(
    'مثال: ربح صديقك ١٠٠٬٠٠٠ د.ع ← مكافأتك ١٬٠٠٠ د.ع. للإحالات المباشرة من بداية العرض فقط؛ لا تشمل الأرباح القديمة أو الطلبات الملغاة والمرتجعة. يُقرّب المبلغ إلى الدينار الأقل لكل طلب.',
    'نموونە: قازانجی هاوڕێکەت ١٠٠٬٠٠٠ د.ع ← پاداشتی تۆ ١٬٠٠٠ د.ع. تەنها بانگهێشتی ڕاستەوخۆ لە دەستپێکی ئۆفەرەکە؛ داواکارییە هەڵوەشاوە و گەڕاوەکان ناگرێتەوە.',
    'Example: 100,000 IQD profit earns you 1,000 IQD. Direct referrals only, from the offer start. No historical, cancelled or returned orders. Rounded down to whole IQD per order.',
  );
  static String get referralProfitEarned => t(
    'أرباحك من نسبة الإحالة',
    'قازانجت لە بانگهێشت',
    'Your profit-share rewards',
  );
  static String get referralProfitPaused => t(
    'العرض متوقف حالياً، وأرباحك السابقة محفوظة في محفظتك.',
    'ئۆفەرەکە ئێستا ناچالاکە، قازانجەکانی پێشووت لە جزدانەکەت ماونەتەوە.',
    'This offer is currently paused. Previously earned rewards stay in your wallet.',
  );
  static String get copy => t('نسخ', 'لەبەرگرتنەوە', 'Copy');
  static String get copied =>
      t('تم نسخ الرمز', 'کۆدەکە لەبەرگیرایەوە', 'Code copied');
  static String get share => t('مشاركة', 'بلاوکردنەوە', 'Share');
  static String shareMessage(String code) => t(
    'استخدم رمز دعوتي $code عند إنشاء حسابك في لكطة.',
    'لەکاتی دروستکردنی هەژماری لكطة کۆدی $code بەکاربهێنە.',
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
