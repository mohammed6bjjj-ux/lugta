import '../data/app_settings.dart';

class DeliveryContributionStrings {
  DeliveryContributionStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  static String get title => _t(
    'من يتحمل أجرة التوصيل؟',
    'کێ کرێی گەیاندن دەدات؟',
    'Who covers delivery?',
  );

  static String get subtitle => _t(
    'اختَر المبلغ الذي تريد خصمه من ربحك بدل أن يدفعه الزبون.',
    'ئەو بڕە دیاری بکە کە دەتەوێت لە قازانجەکەت کەم بکرێتەوە لەبری کڕیار.',
    'Choose how much to deduct from your profit instead of charging the customer.',
  );

  static String get customerPays =>
      _t('الزبون يدفع', 'کڕیار دەیدات', 'Customer pays');

  static String get split => _t('نتقاسمها', 'دابەشی دەکەین', 'Split it');

  static String get sellerPays =>
      _t('أتحملها كلها', 'هەمووی دەدەم', 'I cover all');

  static String get customAmount =>
      _t('حدد حصتك', 'بەشەکەت دیاری بکە', 'Choose your share');

  static String sellerCovers(String amount) =>
      _t('أنت تتحمل $amount', 'تۆ $amount دەدەیت', 'You cover $amount');

  static String customerCovers(String amount) => _t(
    'الزبون يتحمل $amount',
    'کڕیار $amount دەدات',
    'Customer covers $amount',
  );

  static String netProfit(String amount) =>
      _t('ربحك الصافي $amount', 'قازانجی پاکت $amount', 'Net profit $amount');

  static String get freeByOfferTitle => _t(
    'التوصيل مجاني من العرض',
    'گەیاندن بەهۆی ئۆفەرەکەوە بەخۆڕاییە',
    'Delivery is free from the offer',
  );

  static String get freeByOfferBody => _t(
    'ما راح ينخصم أي مبلغ من ربحك.',
    'هیچ بڕێک لە قازانجەکەت کەم ناکرێتەوە.',
    'Nothing will be deducted from your profit.',
  );

  static String get noProfitAvailable => _t(
    'ربح الطلب لا يسمح بتحمل جزء من التوصيل.',
    'قازانجی داواکارییەکە ڕێگە بە بەشداری لە کرێی گەیاندن نادات.',
    'This order has no profit available to cover delivery.',
  );

  static String get cannotCoverAll => _t(
    'ربح الطلب أقل من أجرة التوصيل؛ تقدر تتحمل جزء منها فقط.',
    'قازانجی داواکارییەکە لە کرێی گەیاندن کەمترە؛ تەنها بەشێکی دەدەیت.',
    'Order profit is lower than delivery; you can cover only part of it.',
  );
}
