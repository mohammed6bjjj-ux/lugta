import '../../data/app_settings.dart';

/// نصوص واجهات المصادقة (Splash، Onboarding، Login، Register، OTP،
/// انتظار الموافقة، الحساب المحظور، استعادة كلمة المرور) بثلاث لغات.
class AuthStrings {
  AuthStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  // ── شاشة البداية ──
  static String get splashTagline => _t(
    'كل يوم لكطة جديدة',
    'هەموو ڕۆژێک لكطةیەکی نوێ',
    'A new find every day',
  );
  static String get startupFailed => _t(
    'تعذر إكمال بدء التطبيق. تأكد من الإنترنت وأعد المحاولة.',
    'نەتوانرا دەستپێکردنی ئەپەکە تەواو بکرێت. ئینتەرنێت بپشکنە و دووبارە هەوڵ بدەوە.',
    'Could not finish starting the app. Check your connection and try again.',
  );
  static String get retryStartup =>
      _t('إعادة المحاولة', 'دووبارە هەوڵدانەوە', 'Try again');

  // ── شاشات التعريف ──
  static String get skip => _t('تخطّي', 'تێپەڕاندن', 'Skip');
  static String get next => _t('التالي', 'دواتر', 'Next');
  static String get onboardTitle1 => _t(
    'اختر منتجاً من كتالوجنا',
    'بەرهەمێک لە کەتەلۆگەکەمان هەڵبژێرە',
    'Pick a product from our catalog',
  );
  static String get onboardBody1 => _t(
    'تشكيلة ساعات ونظارات وإكسسوارات بأسعار جملة حصرية، '
        'ومخزون جاهز للشحن — بدون أن تشتري أي قطعة مقدماً.',
    'کۆمەڵێک کاتژمێر و چاویلکە و ئێکسسوار بە نرخی کۆمەڵی تایبەت، '
        'و کۆگایەکی ئامادە بۆ ناردن — بەبێ ئەوەی پێشوەخت هیچ دانەیەک بکڕیت.',
    'Watches, glasses, and accessories at exclusive wholesale prices, '
        'with stock ready to ship — no upfront buying.',
  );
  static String get onboardTitle2 => _t(
    'سوّقه على صفحتك كأنه منتجك',
    'لە پەیجەکەتدا بازاڕگەری بۆ بکە وەک بەرهەمی خۆت',
    'Market it on your page as your own',
  );
  static String get onboardBody2 => _t(
    'حمّل الصور والفيديوهات الجاهزة وانشرها على صفحتك '
        'بالسعر الذي تحدده أنت، والطلب يصل زبونك باسم متجرك.',
    'وێنە و ڤیدیۆ ئامادەکان دابگرە و لە پەیجەکەتدا بڵاویان بکەرەوە '
        'بەو نرخەی خۆت دیاری دەکەیت، داواکارییەکەش بە ناوی فرۆشگاکەت '
        'دەگاتە کڕیارەکەت.',
    'Download ready photos and videos, post them at your own price, '
        'and orders reach your customer under your store name.',
  );
  static String get onboardTitle3 => _t(
    'أنشئ الطلب واربح فرق السعر',
    'داواکارییەکە دروست بکە و جیاوازی نرخەکە قازانج بکە',
    'Create the order, earn the margin',
  );
  static String get onboardBody3 => _t(
    'أدخل طلب زبونك ونحن نجهّز ونوصّل ونستلم الدفع عند الاستلام، '
        'وربحك يتحول إلى محفظتك بعد نجاح التوصيل.',
    'داواکاری کڕیارەکەت تۆمار بکە، ئێمە ئامادەی دەکەین و دەیگەیەنین '
        'و پارەکە لە کاتی وەرگرتندا وەردەگرین، قازانجەکەشت دوای '
        'سەرکەوتنی گەیاندن دەچێتە جزدانەکەت.',
    "Enter your customer's order — we prepare, deliver, and collect "
        'cash on delivery, and your profit lands in your wallet once '
        'delivered.',
  );

  // ── تسجيل الدخول ──
  static String get loginTitle => _t('تسجيل الدخول', 'چوونەژوورەوە', 'Log in');
  static String get welcomeBack =>
      _t('أهلاً بعودتك', 'بەخێربێیتەوە', 'Welcome back');
  static String get loginSubtitle => _t(
    'سجّل دخولك لمتابعة طلباتك وأرباحك',
    'بچۆرە ژوورەوە بۆ بەدواداچوونی داواکاری و قازانجەکانت',
    'Log in to track your orders and profits',
  );
  static String get phoneLabel =>
      _t('رقم الهاتف', 'ژمارەی مۆبایل', 'Phone number');
  static String get passwordLabel =>
      _t('كلمة المرور', 'وشەی نهێنی', 'Password');
  static String get showPassword =>
      _t('إظهار كلمة المرور', 'پیشاندانی وشەی نهێنی', 'Show password');
  static String get hidePassword =>
      _t('إخفاء كلمة المرور', 'شاردنەوەی وشەی نهێنی', 'Hide password');
  static String get forgotPasswordQ =>
      _t('نسيت كلمة المرور؟', 'وشەی نهێنیت لەبیرچووە؟', 'Forgot password?');
  static String get noAccountQ =>
      _t('ليس لديك حساب؟', 'هەژمارت نییە؟', "Don't have an account?");
  static String get newAccount => _t('حساب جديد', 'هەژماری نوێ', 'Sign up');

  // ── إنشاء الحساب ──
  static String get createAccount =>
      _t('إنشاء حساب', 'دروستکردنی هەژمار', 'Create account');
  static String get haveAccount =>
      _t('لدي حساب', 'هەژمارم هەیە', 'I have an account');
  static String get startJourney => _t(
    'ابدأ رحلتك كبائع',
    'دەست بکە بە گەشتەکەت وەک فرۆشیار',
    'Start your seller journey',
  );
  static String get registerSubtitle => _t(
    'أكمل بياناتك وسيراجع فريقنا طلبك خلال 24 ساعة عمل.',
    'زانیارییەکانت تەواو بکە، تیمەکەمان لە ماوەی ٢٤ کاتژمێری کاردا '
        'داواکارییەکەت پێداچوونەوەی بۆ دەکات.',
    'Complete your details — our team reviews your application within '
        '24 business hours.',
  );
  static String get personalInfo =>
      _t('بياناتك الشخصية', 'زانیارییە کەسییەکانت', 'Personal details');
  static String get fullNameLabel =>
      _t('الاسم الكامل', 'ناوی تەواو', 'Full name');
  static String get fullNameHint => _t(
    'مثال: أحمد علي حسين',
    'نموونە: ئەحمەد عەلی حسێن',
    'e.g. Ahmed Ali Hussein',
  );
  static String get fullNameRequired =>
      _t('الاسم الكامل مطلوب', 'ناوی تەواو پێویستە', 'Full name is required');
  static String get passwordHintMin => _t(
    '8 خانات على الأقل',
    'بەلایەنی کەمەوە ٨ خانە',
    'At least 8 characters',
  );
  static String get storeInfo =>
      _t('بيانات متجرك', 'زانیاری فرۆشگاکەت', 'Store details');
  static String get storeNameLabel =>
      _t('اسم المتجر / الصفحة', 'ناوی فرۆشگا / پەیج', 'Store / page name');
  static String get storeNameHint => _t(
    'الاسم الذي سيظهر على بوليصة الشحن',
    'ئەو ناوەی لەسەر پسوولەی گەیاندن دەردەکەوێت',
    'The name shown on the shipping label',
  );
  static String get storeNameRequired =>
      _t('اسم المتجر مطلوب', 'ناوی فرۆشگا پێویستە', 'Store name is required');
  static String get instagramLabel => _t(
    'رابط صفحة إنستغرام (اختياري)',
    'لینکی پەیجی ئینستاگرام (ئارەزوومەندانە)',
    'Instagram page link (optional)',
  );
  static String get referralCodeLabel => _t(
    'رمز الدعوة (اختياري)',
    'کۆدی بانگهێشت (ئارەزوومەندانە)',
    'Referral code (optional)',
  );
  static String get referralCodeHint => _t(
    'أدخل الرمز الذي أرسله لك صديقك',
    'کۆدەکەی هاوڕێکەت بنووسە',
    'Enter the code a friend shared',
  );
  static String get governorate => _t('المحافظة', 'پارێزگا', 'Governorate');
  static String get governorateHint =>
      _t('اختر محافظتك', 'پارێزگاکەت هەڵبژێرە', 'Select your governorate');
  static String get governorateRequired =>
      _t('اختر المحافظة', 'پارێزگا هەڵبژێرە', 'Select a governorate');
  static String get agreeTo => _t('أوافق على ', 'ڕازیم بە ', 'I agree to the ');
  static String get termsAndPolicies => _t(
    'الشروط وسياسات المنصة',
    'مەرج و سیاسەتەکانی پلاتفۆرم',
    'platform terms and policies',
  );
  static String get termsRequiredSnack => _t(
    'يجب الموافقة على الشروط والسياسات أولاً',
    'پێویستە سەرەتا ڕازی بیت بە مەرج و سیاسەتەکان',
    'You must accept the terms and policies first',
  );
  static String get termsRequiredInline => _t(
    'الموافقة على الشروط إلزامية لإكمال التسجيل',
    'ڕازیبوون بە مەرجەکان پێویستە بۆ تەواوکردنی تۆمارکردن',
    'Accepting the terms is required to complete registration',
  );
  static String get termsUnavailable => _t(
    'تعذر تحميل النسخة الحالية من الشروط. تحقق من الإنترنت وحاول مجدداً.',
    'نەتوانرا وەشانی ئێستای مەرجەکان باربکرێت. ئینتەرنێت بپشکنە و دووبارە هەوڵ بدەرەوە.',
    'The current terms could not be loaded. Check your connection and try again.',
  );
  static String get createAccountAction =>
      _t('إنشاء الحساب', 'دروستکردنی هەژمارەکە', 'Create account');
  static String get alreadyHaveAccountQ => _t(
    'لديك حساب بالفعل؟',
    'پێشتر هەژمارت هەیە؟',
    'Already have an account?',
  );

  // ── رمز التحقق OTP ──
  static String get otpTitle =>
      _t('رمز التحقق', 'کۆدی پشتڕاستکردنەوە', 'Verification code');
  static String get enterOtp => _t(
    'أدخل رمز التحقق',
    'کۆدی پشتڕاستکردنەوە بنووسە',
    'Enter the verification code',
  );
  static String get otpSentToPhone => _t(
    'أرسلنا رمزاً من 6 أرقام عبر واتساب إلى الرقم',
    'کۆدێکی ٦ ژمارەییمان لە ڕێگەی واتساپەوە ناردووە بۆ ژمارە',
    'We sent a 6-digit code via WhatsApp to',
  );
  static String newOtpSentTo(String phone) => _t(
    'تم إرسال رمز تحقق جديد عبر واتساب إلى $phone',
    'کۆدی پشتڕاستکردنەوەی نوێ لە ڕێگەی واتساپەوە نێردرا بۆ $phone',
    'A new verification code was sent via WhatsApp to $phone',
  );
  static String get verifyingCode => _t(
    'جاري التحقق من الرمز...',
    'کۆدەکە پشتڕاست دەکرێتەوە...',
    'Verifying code...',
  );
  static String resendCountdown(String seconds) => _t(
    'يمكنك طلب رمز جديد بعد $seconds ثانية',
    'دەتوانیت دوای $seconds چرکە کۆدی نوێ داوا بکەیت',
    'Request a new code in $seconds s',
  );
  static String get resendCode =>
      _t('إعادة إرسال الرمز', 'دووبارە ناردنەوەی کۆدەکە', 'Resend code');

  // ── انتظار الموافقة ──
  static String get stillUnderReviewSnack => _t(
    'ما زال حسابك قيد المراجعة — سنشعرك فور الموافقة',
    'هەژمارەکەت هێشتا لە پێداچوونەوەدایە — هەر کە پەسەند کرا '
        'ئاگادارت دەکەینەوە',
    'Your account is still under review — we will notify you once '
        'approved',
  );
  static String contactSupportWhatsapp(String number) => _t(
    'تواصل مع الدعم عبر واتساب: $number',
    'لە ڕێگەی واتسئاپەوە پەیوەندی بە پشتگیرییەوە بکە: $number',
    'Contact support on WhatsApp: $number',
  );
  static String get contactAppUnavailable => _t(
    'تعذر فتح واتساب على هذا الجهاز.',
    'نەتوانرا واتسئاپ لەم ئامێرە بکرێتەوە.',
    'Could not open WhatsApp on this device.',
  );
  static String get copy => _t('نسخ', 'کۆپی', 'Copy');
  static String get requestUnderReview => _t(
    'طلبك قيد المراجعة',
    'داواکارییەکەت لە پێداچوونەوەدایە',
    'Your application is under review',
  );
  static String get pendingBody => _t(
    'استلمنا بيانات حسابك وفريقنا يراجعها الآن. '
        'تستغرق المراجعة عادةً أقل من 24 ساعة عمل، وسيصلك إشعار فور الموافقة.\n'
        'اسحب الشاشة للأسفل لإعادة فحص الحالة.',
    'زانیاری هەژمارەکەتمان وەرگرت و تیمەکەمان ئێستا پێداچوونەوەی بۆ دەکات. '
        'پێداچوونەوەکە زۆربەی کات کەمتر لە ٢٤ کاتژمێری کار دەخایەنێت، '
        'و هەر کە پەسەند کرا ئاگادارکردنەوەیەکت بۆ دێت.\n'
        'شاشەکە بۆ خوارەوە ڕابکێشە بۆ دووبارە پشکنینی دۆخەکە.',
    'We received your details and our team is reviewing them now. '
        'Review usually takes less than 24 business hours, and you will '
        'be notified once approved.\n'
        'Pull down to refresh the status.',
  );
  static String get stepReceived => _t(
    'تم استلام طلب التسجيل',
    'داواکاری تۆمارکردن وەرگیرا',
    'Application received',
  );
  static String get stepReviewing => _t(
    'مراجعة بيانات المتجر جارية',
    'پێداچوونەوەی زانیاری فرۆشگا بەردەوامە',
    'Store details under review',
  );
  static String get stepActivate => _t(
    'تفعيل الحساب والبدء بالبيع',
    'چالاککردنی هەژمار و دەستپێکردنی فرۆشتن',
    'Account activation and start selling',
  );
  static String get contactSupport =>
      _t('تواصل مع الدعم', 'پەیوەندی بە پشتگیرییەوە بکە', 'Contact support');
  static String get logout => _t('تسجيل الخروج', 'چوونەدەرەوە', 'Log out');
  static String get previewApprovedLogin => _t(
    '(معاينة) الدخول كحساب موافَق عليه',
    '(پێشبینین) چوونەژوورەوە وەک هەژمارێکی پەسەندکراو',
    '(Preview) Enter as an approved account',
  );

  // ── الحساب المرفوض/المحظور ──
  static String get rejectedTitle =>
      _t('طلبك مرفوض', 'داواکارییەکەت ڕەتکرایەوە', 'Application rejected');
  static String get rejectedSubtitle => _t(
    'نأسف — لم نتمكن من الموافقة على طلب تسجيلك في الوقت الحالي. '
        'يمكنك مراجعة السبب أدناه والتواصل مع الدعم لإعادة النظر.',
    'ببورە — لە ئێستادا نەمانتوانی داواکاری تۆمارکردنەکەت پەسەند بکەین. '
        'دەتوانیت هۆکارەکە لە خوارەوە ببینیت و پەیوەندی بە پشتگیرییەوە '
        'بکەیت بۆ پێداچوونەوە.',
    'Sorry — we could not approve your application at this time. '
        'See the reason below and contact support to appeal.',
  );
  static String get blockedTitle =>
      _t('حسابك محظور', 'هەژمارەکەت ڕاگیراوە', 'Account blocked');
  static String get blockedSubtitle => _t(
    'تم إيقاف حسابك من قبل إدارة المنصة. '
        'راجع السبب أدناه وتواصل مع الدعم إن كنت تعتقد أن هناك خطأ.',
    'هەژمارەکەت لەلایەن بەڕێوەبەرایەتی پلاتفۆرمەوە ڕاگیراوە. '
        'هۆکارەکە لە خوارەوە ببینە و پەیوەندی بە پشتگیرییەوە بکە '
        'ئەگەر پێت وایە هەڵەیەک هەیە.',
    'Your account was suspended by the platform team. Review the reason '
        'below and contact support if you believe this is a mistake.',
  );
  static String get reasonTitle => _t('السبب', 'هۆکار', 'Reason');
  static String get deletedTitle =>
      _t('تم حذف حسابك', 'هەژمارەکەت سڕایەوە', 'Account deleted');
  static String get deletedSubtitle => _t(
    'تم تنفيذ طلب حذف الحساب وتسجيل خروجك بأمان. لم يعد هذا الحساب متاحاً للاستخدام.',
    'داواکاری سڕینەوەی هەژمار جێبەجێ کرا و بە سەلامەتی چوویتە دەرەوە. ئەم هەژمارە چیتر بەردەست نییە.',
    'Your deletion request was completed and you were signed out securely. This account is no longer available.',
  );
  static String get returnToLogin =>
      _t('العودة لتسجيل الدخول', 'گەڕانەوە بۆ چوونەژوورەوە', 'Return to login');

  // ── استعادة كلمة المرور ──
  static String get forgotTitle =>
      _t('استعادة كلمة المرور', 'گەڕاندنەوەی وشەی نهێنی', 'Reset password');
  static String get stepPhone => _t('الهاتف', 'مۆبایل', 'Phone');
  static String codeSentTo(String phone) => _t(
    'أرسلنا رمز تحقق عبر واتساب إلى $phone',
    'کۆدی پشتڕاستکردنەوەمان لە ڕێگەی واتساپەوە نارد بۆ $phone',
    'We sent a verification code via WhatsApp to $phone',
  );
  static String newCodeSentTo(String phone) => _t(
    'تم إرسال رمز جديد عبر واتساب إلى $phone',
    'کۆدی نوێ لە ڕێگەی واتساپەوە نێردرا بۆ $phone',
    'A new code was sent via WhatsApp to $phone',
  );
  static String get passwordsDontMatch => _t(
    'كلمتا المرور غير متطابقتين',
    'هەردوو وشە نهێنییەکە وەک یەک نین',
    'Passwords do not match',
  );
  static String get passwordChangedSnack => _t(
    'تم تغيير كلمة المرور بنجاح — سجّل دخولك الآن',
    'وشەی نهێنی بە سەرکەوتوویی گۆڕدرا — ئێستا بچۆرە ژوورەوە',
    'Password changed — log in now',
  );
  static String get enterYourPhone => _t(
    'أدخل رقم هاتفك',
    'ژمارەی مۆبایلەکەت بنووسە',
    'Enter your phone number',
  );
  static String get phoneStepSubtitle => _t(
    'سنرسل رمز تحقق عبر واتساب إلى رقمك المسجل لدينا.',
    'کۆدی پشتڕاستکردنەوە لە ڕێگەی واتساپەوە دەنێرین بۆ ژمارە تۆمارکراوەکەت.',
    'We will send a verification code via WhatsApp to your registered number.',
  );
  static String get sendCode =>
      _t('إرسال رمز التحقق', 'ناردنی کۆدی پشتڕاستکردنەوە', 'Send code');
  static String get otpSentToShort => _t(
    'أرسلنا رمزاً من 6 أرقام عبر واتساب إلى',
    'کۆدێکی ٦ ژمارەییمان لە ڕێگەی واتساپەوە ناردووە بۆ',
    'We sent a 6-digit code via WhatsApp to',
  );
  static String get editPhone =>
      _t('تعديل رقم الهاتف', 'گۆڕینی ژمارەی مۆبایل', 'Change phone number');
  static String get newPasswordTitle =>
      _t('كلمة المرور الجديدة', 'وشەی نهێنی نوێ', 'New password');
  static String get newPasswordSubtitle => _t(
    'اختر كلمة مرور جديدة من 8 خانات على الأقل.',
    'وشەی نهێنییەکی نوێ هەڵبژێرە کە بەلایەنی کەمەوە ٨ خانە بێت.',
    'Choose a new password of at least 8 characters.',
  );
  static String get confirmPasswordLabel =>
      _t('تأكيد كلمة المرور', 'پشتڕاستکردنەوەی وشەی نهێنی', 'Confirm password');
  static String get confirmPasswordHint => _t(
    'أعد كتابة كلمة المرور',
    'وشەی نهێنییەکە دووبارە بنووسەرەوە',
    'Re-enter your password',
  );
  static String get savePassword =>
      _t('حفظ كلمة المرور', 'پاشەکەوتکردنی وشەی نهێنی', 'Save password');
}
