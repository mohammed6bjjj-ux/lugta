import '../../data/app_settings.dart';

class GuestStrings {
  GuestStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  static String get continueAsGuest =>
      _t('الدخول كضيف', 'چوونەژوورەوە وەک میوان', 'Continue as guest');
  static String get guestPreview =>
      _t('معاينة الضيف', 'پێشبینینی میوان', 'Guest preview');
  static String get guestBadge => _t('ضيف', 'میوان', 'Guest');
  static String get previewTitle => _t(
    'استكشف لكطة قبل التسجيل',
    'پێش تۆمارکردن لکطة بگەڕێ',
    'Explore Lugta before signing up',
  );
  static String get previewBody => _t(
    'تقدر تتصفح المنتجات والتصنيفات والأسعار والصور الحالية وتجرب السلة. إنشاء الطلبات والمحفظة وبيانات الحساب تحتاج حساب بائع موافق عليه.',
    'دەتوانیت بەرهەم و پۆل و نرخ و وێنە ڕاستەوخۆکان ببینیت و سەبەتە تاقی بکەیتەوە. دروستکردنی داواکاری و جزدان و زانیاری هەژمار پێویستی بە هەژماری فرۆشیاری پەسەندکراو هەیە.',
    'Browse the current products, categories, prices, and media, and try the cart. Orders, wallet, and account data require an approved seller account.',
  );
  static String get liveDataNotice => _t(
    'هذه معاينة حقيقية ومحدثة للكتالوج. الطلبات والأرباح وبيانات الحساب تبقى محمية إلى أن تسجل الدخول.',
    'ئەمە پێشبینینێکی ڕاستەقینە و نوێکراوەی کاتالۆگە. داواکاری و قازانج و زانیاری هەژمار تا چوونەژوورەوە پارێزراون.',
    'This is a live catalog preview. Orders, earnings, and account data stay protected until you sign in.',
  );
  static String get signInRequiredTitle => _t(
    'سجل الدخول حتى تكمل',
    'بچۆ ژوورەوە بۆ تەواوکردن',
    'Sign in to continue',
  );
  static String get signInRequiredBody => _t(
    'هذه الخطوة مرتبطة بطلباتك وأرباحك، لذلك تحتاج حساب بائع حقيقي.',
    'ئەم هەنگاوە بە داواکاری و قازانجەکانتەوە بەستراوە، بۆیە هەژماری فرۆشیاری ڕاستەقینە پێویستە.',
    'This action is tied to your orders and earnings, so it requires a real seller account.',
  );
  static String get createSellerAccount => _t(
    'إنشاء حساب بائع',
    'دروستکردنی هەژماری فرۆشیار',
    'Create seller account',
  );
  static String get signIn => _t('تسجيل الدخول', 'چوونەژوورەوە', 'Sign in');
  static String get backToPreview =>
      _t('الرجوع للمعاينة', 'گەڕانەوە بۆ پێشبینین', 'Back to preview');
}
