import '../../data/app_settings.dart';

class AssistantStrings {
  static String t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };
  static String get title =>
      t('مساعد لكطة', 'یاریدەدەری لکطە', 'Lugta assistant');
  static String get subtitle => t(
    'اسأل عن التطبيق واكتشف منتجات تناسبك',
    'دەربارەی ئەپەکە بپرسە و بەرهەم بدۆزەوە',
    'Ask about the app and discover products',
  );
  static String get disclosure => t(
    'هذا مساعد آلي يستخدم DeepSeek. عند الإرسال، تنرسل رسالتك وآخر رسائل هالمحادثة ومعلومات المنتجات المقترحة إلى DeepSeek حتى يجاوبك. لا ترسل كلمات مرور أو رموز تحقق أو بيانات زبائن. الرد ممكن يخطئ؛ تأكد من التفاصيل بصفحة المنتج. ما يغيّر طلباتك أو فلوسك. المحادثة تنمسح من هالصفحة عند إغلاقها، لكن السؤال اللي ما يعرف جوابه قد ينحفظ عند الإدارة للمراجعة وتحسين معرفته. ما تنحفظ المحادثة الكاملة بقائمة المراجعة.',
    'ئەم یاریدەدەرە DeepSeek بەکاردەهێنێت. نامەکان و زانیاری بەرهەمە پێشنیارکراوەکان بۆ DeepSeek دەنێردرێن. وشەی نهێنی، کۆدی پشتڕاستکردنەوە یان زانیاری کڕیار مەنووسە. وەڵامەکان دەکرێت هەڵە بن؛ وردەکاری بەرهەم بپشکنە. داواکاری و پارە ناگۆڕێت. بە داخستنی لاپەڕە گفتوگۆ لێرە دەسڕێتەوە، بەڵام پرسیاری بێ وەڵام دەکرێت لای بەڕێوەبەرایەتی بۆ پێداچوونەوە پاشەکەوت بکرێت، نەک هەموو گفتوگۆکە.',
    'This AI assistant uses DeepSeek. Sending shares your message, recent conversation and suggested catalog details with DeepSeek. Do not send passwords, verification codes or customer details. Answers may be wrong; check product details. It cannot change orders or money. Closing clears this screen, but unanswered questions may be saved for admin review and knowledge improvements. The review queue does not store the full conversation.',
  );
  static String get start => t(
    'موافق، ابدأ المحادثة',
    'ڕازیم، گفتوگۆ دەست پێ بکە',
    'Agree and start chatting',
  );
  static String get hint =>
      t('اكتب سؤالك…', 'پرسیارەکەت بنووسە…', 'Ask a question…');
  static String get send => t('إرسال', 'ناردن', 'Send');
  static String get thinking => t(
    'مساعد لكطة يحضّر الجواب…',
    'وەڵام ئامادە دەکرێت…',
    'Preparing an answer…',
  );
  static String get welcome => t(
    'هلا بيك! شنو تحب تعرف؟ أكدر أشرحلك التطبيق أو أساعدك تختار منتج وتسوقه.',
    'بەخێربێیت! دەتوانم ئەپەکە ڕوون بکەمەوە یان یارمەتیت بدەم بەرهەم هەڵبژێریت.',
    'Welcome! I can explain the app or help you choose and market a product.',
  );
  static String get discover => t(
    'اقترحلي منتجات أبدي بيها',
    'بەرهەم بۆ دەستپێکردن پێشنیار بکە',
    'Suggest products to start with',
  );
  static String get profit => t(
    'شلون أحسب ربحي؟',
    'چۆن قازانجم هەژمار بکەم؟',
    'How do I calculate profit?',
  );
  static String get support =>
      t('فتح الدعم', 'کردنەوەی پشتگیری', 'Open support');
  static String get openProduct =>
      t('عرض المنتج', 'پیشاندانی بەرهەم', 'View product');
  static String get wholesale =>
      t('سعر الجملة', 'نرخی کۆمەڵ', 'Wholesale price');
  static String get error => t(
    'ما وصل الجواب. سؤالك محفوظ بالخانة؛ جرّب الإرسال بعد شوية.',
    'وەڵام نەگەیشت. پرسیارەکەت ماوەتەوە؛ دواتر هەوڵ بدەوە.',
    'No answer received. Your draft is kept; try sending again shortly.',
  );
  static String get limited => t(
    'عندك رسالة قيد المعالجة أو وصلت حد الرسائل. انتظر شوية وحاول.',
    'نامەیەک لە چارەسەردایە یان گەیشتوویتە سنوور. کەمێک چاوەڕێ بکە.',
    'A message is processing or the message limit was reached. Please wait before trying again.',
  );
  static String get unavailable => t(
    'هذا المنتج ما متاح حالياً. جرّب صفحة المنتجات.',
    'ئەم بەرهەمە ئێستا بەردەست نییە.',
    'This product is not available right now.',
  );
}
