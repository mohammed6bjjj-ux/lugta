import '../../data/app_settings.dart';

/// نصوص ميزة المحفظة (شاشة المحفظة، طلب السحب، سجل السحوبات، بطاقة السحب)
/// بثلاث لغات — بنفس نمط CoreStrings.
class WalletStrings {
  WalletStrings._();

  static String _t(String ar, String ckb, String en) =>
      switch (appSettings.language) {
        AppLanguage.ar => ar,
        AppLanguage.ckb => ckb,
        AppLanguage.en => en,
      };

  // ── شاشة المحفظة ──
  static String get withdrawalsHistory =>
      _t('سجل السحوبات', 'مێژووی ڕاکێشانەکان', 'Withdrawal history');
  static String get availableBalance => _t(
    'الرصيد المتاح للسحب',
    'باڵانسی بەردەست بۆ ڕاکێشان',
    'Available balance',
  );
  static String get pendingProfit =>
      _t('الربح المعلق', 'قازانجی هەڵواسراو', 'Pending profit');
  static String get totalEarned =>
      _t('إجمالي أرباحك', 'کۆی قازانجەکانت', 'Total earnings');
  static String get withdrawRequest =>
      _t('طلب سحب', 'داواکاری ڕاکێشان', 'Request withdrawal');
  static String get pendingAutoReleaseHint => _t(
    'الربح المعلق يتحول تلقائياً إلى متاح بعد نجاح التوصيل والتسوية.',
    'قازانجی هەڵواسراو دوای سەرکەوتنی گەیاندن و یەکلاییکردنەوە خۆکارانە دەبێتە بەردەست.',
    'Pending profit becomes available automatically once delivery is completed and settled.',
  );
  static String minWithdrawalHint(String amount) => _t(
    'الحد الأدنى للسحب $amount — الربح المعلق يتحول إلى متاح بعد نجاح التوصيل.',
    'کەمترین بڕی ڕاکێشان $amount — قازانجی هەڵواسراو دوای سەرکەوتنی گەیاندن دەبێتە بەردەست.',
    'Minimum withdrawal is $amount — pending profit becomes available after successful delivery.',
  );
  static String get transactionsTab => _t('الحركات', 'جوڵەکان', 'Transactions');
  static String get withdrawalsTab =>
      _t('السحوبات', 'ڕاکێشانەکان', 'Withdrawals');
  static String get noTransactionsTitle =>
      _t('لا توجد حركات بعد', 'هێشتا هیچ جوڵەیەک نییە', 'No transactions yet');
  static String get noTransactionsSubtitle => _t(
    'كل حركة على محفظتك — أرباح وتسويات وسحوبات — ستظهر هنا.',
    'هەموو جوڵەیەکی جزدانەکەت — قازانج و یەکلاییکردنەوە و ڕاکێشان — لێرە دەردەکەوێت.',
    'Every wallet movement — profits, settlements, withdrawals — will appear here.',
  );
  static String get noWithdrawalsTitle => _t(
    'لا توجد طلبات سحب بعد',
    'هێشتا هیچ داواکارییەکی ڕاکێشان نییە',
    'No withdrawal requests yet',
  );
  static String get noWithdrawalsSubtitle => _t(
    'عند تقديمك طلب سحب سيظهر هنا مع حالته وتفاصيل تحويله.',
    'کاتێک داواکاری ڕاکێشان پێشکەش دەکەیت، لێرە لەگەڵ دۆخ و وردەکاری گواستنەوەکەی دەردەکەوێت.',
    'When you submit a withdrawal request, it will appear here with its status and transfer details.',
  );
  static String get salesStatement => _t(
    'كشف المبيعات والأرباح',
    'ڕاپۆرتی فرۆشتن و قازانج',
    'Sales & profit statement',
  );
  static String get salesStatementSubtitle => _t(
    'تفصيل كل منتج، رقم الطلب، الكمية، سعر الشراء والبيع والربح المحفوظ وقت الطلب.',
    'وردەکاری هەر بەرهەمێک، ژمارەی داواکاری، بڕ، نرخی کڕین و فرۆشتن و قازانجی تۆمارکراو.',
    'Every product, order number, quantity, buy/sale price, and snapshotted profit.',
  );
  static String get productsSold =>
      _t('قطع الطلبات', 'پارچەی داواکراو', 'Ordered units');
  static String get salesValue =>
      _t('قيمة المبيعات', 'بەهای فرۆشتن', 'Sales value');
  static String get netProfit =>
      _t('الربح المسجل', 'قازانجی تۆمارکراو', 'Recorded profit');
  static String get noStatementLines => _t(
    'لا توجد أسطر طلبات في كشف الحساب بعد.',
    'هێشتا هیچ دێڕێکی داواکاری لە ڕاپۆرتەکە نییە.',
    'No order lines are available in the statement yet.',
  );
  static String quantityValue(int value) =>
      _t('الكمية $value', 'بڕ $value', 'Qty $value');
  static String buyPrice(String value) =>
      _t('شراء $value', 'کڕین $value', 'Buy $value');
  static String salePrice(String value) =>
      _t('بيع $value', 'فرۆشتن $value', 'Sale $value');

  // ── طرق الاستلام ──
  static String get methodZainCash => _t('زين كاش', 'زەین کاش', 'ZainCash');
  static String get methodSuperQi => _t('سوبر كي', 'سوپەر کی', 'SuperQi');
  static String get savedPayoutAccounts => _t(
    'حسابات الاستلام المحفوظة',
    'هەژمارە پاشەکەوتکراوەکانی وەرگرتن',
    'Saved payout accounts',
  );
  static String get useNewPayoutAccount =>
      _t('استخدام حساب جديد', 'بەکارهێنانی هەژمارێکی نوێ', 'Use a new account');
  static String get managePayoutAccounts => _t(
    'إدارة حسابات الاستلام',
    'بەڕێوەبردنی هەژمارەکانی وەرگرتن',
    'Manage payout accounts',
  );
  static String get managePayoutAccountsHint => _t(
    'اختر حساباً للاستخدام، أو اجعله افتراضياً، أو احذفه إذا لم يعد مطلوباً.',
    'هەژمارێک هەڵبژێرە بۆ بەکارهێنان، یان بیکە بە بنەڕەت، یان بیسڕەوە.',
    'Choose an account, make it the default, or remove it when no longer needed.',
  );
  static String get payoutAccountsSettingsSubtitle => _t(
    'أضف زين كاش أو سوبر كي بالاسم المسجل فعلياً والرقم، ثم تابع حالة توثيقه من الإدارة.',
    'زەین کاش یان سوپەر کی بە ناوی تۆمارکراوی ڕاستەقینە و ژمارەکە زیاد بکە، پاشان دۆخی پشتڕاستکردنەوەکەی ببینە.',
    'Add ZainCash or SuperQi with the registered holder name and number, then track admin verification.',
  );
  static String get payoutVerificationInfo => _t(
    'حساب الاستلام لا يُستخدم للسحب إلا بعد أن تراجعه الإدارة وتوثقه. لا ترسل رمزاً سرياً أو رمز OTP أبداً.',
    'هەژماری وەرگرتن تەنها دوای پێداچوونەوە و پشتڕاستکردنەوەی بەڕێوەبەرایەتی بەکاردێت. هەرگیز وشەی نهێنی یان کۆدی OTP مەنووسە.',
    'A payout account can be used only after admin verification. Never enter a PIN, password, or OTP.',
  );
  static String get addPayoutAccount => _t(
    'إضافة حساب استلام',
    'زیادکردنی هەژماری وەرگرتن',
    'Add payout account',
  );
  static String get editPayoutAccount => _t(
    'تعديل حساب الاستلام',
    'دەستکاریکردنی هەژماری وەرگرتن',
    'Edit payout account',
  );
  static String get payoutProvider =>
      _t('نوع الحساب', 'جۆری هەژمار', 'Account type');
  static String get accountHolderRegisteredName => _t(
    'الاسم المسجل في الحساب أو البطاقة',
    'ناوی تۆمارکراو لە هەژمار یان کارت',
    'Registered account or card holder name',
  );
  static String get accountHolderHint => _t(
    'اكتب الاسم كما يظهر لدى شركة الدفع',
    'ناوەکە وەک لای کۆمپانیای پارەدان دیارە بنووسە',
    'Enter the name exactly as registered',
  );
  static String get accountHolderRequired => _t(
    'اكتب الاسم المسجل من 3 أحرف على الأقل',
    'ناوی تۆمارکراو بە لایەنی کەم ٣ پیت بنووسە',
    'Enter the registered name (at least 3 characters)',
  );
  static String get savePayoutAccount => _t(
    'حفظ وإرسال للتوثيق',
    'پاشەکەوتکردن و ناردن بۆ پشتڕاستکردنەوە',
    'Save and submit for verification',
  );
  static String get savePayoutAccountChanges =>
      _t('حفظ التعديلات', 'پاشەکەوتکردنی گۆڕانکارییەکان', 'Save changes');
  static String get verifiedPayoutAccount => _t(
    'موثق وجاهز للسحب',
    'پشتڕاستکراو و ئامادەی ڕاکێشان',
    'Verified and ready',
  );
  static String get payoutAccountSavedPending => _t(
    'تم إرسال الحساب إلى الإدارة وبانتظار التوثيق.',
    'هەژمارەکە نێردرا بۆ بەڕێوەبەرایەتی و چاوەڕوانی پشتڕاستکردنەوەیە.',
    'The account was sent to admin and is awaiting verification.',
  );
  static String get payoutAccountUpdated => _t(
    'تم تحديث حساب الاستلام.',
    'هەژماری وەرگرتن نوێکرایەوە.',
    'Payout account updated.',
  );
  static String get payoutEditVerificationWarning => _t(
    'تغيير الاسم أو الرقم أو النوع يلغي التوثيق الحالي ويرسل الحساب للمراجعة من جديد.',
    'گۆڕینی ناو یان ژمارە یان جۆر پشتڕاستکردنەوەی ئێستا هەڵدەوەشێنێتەوە و دووبارە بۆ پێداچوونەوە دەنێردرێت.',
    'Changing the name, number, or type resets verification and resubmits the account.',
  );
  static String get noPayoutAccountsTitle => _t(
    'لا يوجد حساب استلام',
    'هەژماری وەرگرتن نییە',
    'No payout account yet',
  );
  static String get noPayoutAccountsBody => _t(
    'أضف زين كاش أو سوبر كي حتى تقدر تستخدمه بعد التوثيق عند طلب السحب.',
    'زەین کاش یان سوپەر کی زیاد بکە تا دوای پشتڕاستکردنەوە بۆ ڕاکێشان بەکاری بهێنیت.',
    'Add ZainCash or SuperQi so you can use it for withdrawals after verification.',
  );
  static String get noSavedPayoutAccounts => _t(
    'لا توجد حسابات محفوظة. سيُحفظ الحساب الجديد عند أول طلب سحب.',
    'هیچ هەژمارێکی پاشەکەوتکراو نییە. هەژماری نوێ لە یەکەم ڕاکێشان پاشەکەوت دەکرێت.',
    'No saved accounts. A new one is saved with the first withdrawal request.',
  );
  static String get defaultPayoutAccount =>
      _t('الحساب الافتراضي', 'هەژماری بنەڕەت', 'Default account');
  static String get payoutVerificationPendingTitle => _t(
    'تم حفظ حساب الاستلام',
    'هەژماری وەرگرتن پاشەکەوت کرا',
    'Payout account saved',
  );
  static String get payoutVerificationPendingBody => _t(
    'أرسلنا الحساب إلى الإدارة للمراجعة. بعد الموافقة عليه يمكنك تقديم طلب السحب بهذا الحساب.',
    'هەژمارەکە بۆ پێداچوونەوە نێردرا. دوای پەسەندکردن دەتوانیت بەو هەژمارە داواکاری ڕاکێشان بکەیت.',
    'The account is awaiting admin review. Once approved, you can use it for a withdrawal.',
  );
  static String get payoutAccountUnavailable => _t(
    'حساب الاستلام المختار لم يعد متاحاً. اختر حساباً آخر.',
    'هەژماری وەرگرتنی هەڵبژێردراو چیتر بەردەست نییە. هەژمارێکی تر هەڵبژێرە.',
    'The selected payout account is no longer available. Choose another account.',
  );
  static String get awaitingVerification =>
      _t('بانتظار الموافقة', 'لە چاوەڕوانی پەسەندکردن', 'Awaiting approval');
  static String get makePayoutDefault =>
      _t('جعله افتراضياً', 'بیکە بە بنەڕەت', 'Make default');
  static String get deletePayoutAccount =>
      _t('حذف الحساب', 'سڕینەوەی هەژمار', 'Delete account');
  static String get deletePayoutAccountConfirm => _t(
    'هل تريد حذف حساب الاستلام هذا؟ لا يمكن حذف حساب مرتبط بطلب سحب جارٍ.',
    'دەتەوێت ئەم هەژمارەی وەرگرتنە بسڕیتەوە؟ هەژماری بەستراو بە ڕاکێشانی چالاک ناسڕێتەوە.',
    'Delete this payout account? An account linked to an active withdrawal cannot be removed.',
  );
  static String get keepAccount =>
      _t('إبقاء الحساب', 'هێشتنەوەی هەژمار', 'Keep account');
  static String get zainWalletNumberLabel => _t(
    'رقم محفظة زين كاش',
    'ژمارەی جزدانی زەین کاش',
    'ZainCash wallet number',
  );
  static String get zainWalletNumberHint =>
      _t('07XXXXXXXXX', '07XXXXXXXXX', '07XXXXXXXXX');
  static String get superQiNumberLabel => _t(
    'رقم حساب سوبر كي',
    'ژمارەی هەژماری سوپەر کی',
    'SuperQi account number',
  );
  static String get superQiNumberHint => _t(
    'أدخل رقم حساب سوبر كي',
    'ژمارەی هەژماری سوپەر کی بنووسە',
    'Enter the SuperQi account number',
  );
  static String get methodCard => _t(
    'ماستر كارد (كي/آسيا)',
    'ماستەرکارد (کی/ئاسیا)',
    'Mastercard (Qi/Asia)',
  );
  static String get cardNumberLabel =>
      _t('رقم البطاقة', 'ژمارەی کارت', 'Card number');
  static String get cardNumberHint => _t(
    'أدخل رقم البطاقة (16 رقماً)',
    'ژمارەی کارتەکە بنووسە (16 ژمارە)',
    'Enter the 16-digit card number',
  );

  // ── شاشة طلب السحب ──
  static String get amountLabel =>
      _t('مبلغ السحب (د.ع)', 'بڕی ڕاکێشان (د.ع)', 'Withdrawal amount (IQD)');
  static String amountExample(String example) =>
      _t('مثال: $example', 'نموونە: $example', 'e.g. $example');
  static String get withdrawAll =>
      _t('سحب الكل', 'هەمووی ڕابکێشە', 'Withdraw all');
  static String minWithdrawal(String amount) => _t(
    'الحد الأدنى للسحب $amount',
    'کەمترین بڕی ڕاکێشان $amount',
    'Minimum withdrawal: $amount',
  );
  static String get amountRequired =>
      _t('أدخل مبلغ السحب', 'بڕی ڕاکێشان بنووسە', 'Enter a withdrawal amount');
  static String minWithdrawalError(String amount) => _t(
    'الحد الأدنى للسحب هو $amount',
    'کەمترین بڕی ڕاکێشان بریتییە لە $amount',
    'Minimum withdrawal is $amount',
  );
  static String amountExceedsBalance(String balance) => _t(
    'المبلغ أكبر من رصيدك المتاح ($balance)',
    'بڕەکە زیاترە لە باڵانسی بەردەستت ($balance)',
    'Amount exceeds your available balance ($balance)',
  );
  static String get cardNumberRequired =>
      _t('رقم البطاقة مطلوب', 'ژمارەی کارت پێویستە', 'Card number is required');
  static String get superQiNumberRequired => _t(
    'رقم حساب سوبر كي مطلوب',
    'ژمارەی هەژماری سوپەر کی پێویستە',
    'SuperQi account number is required',
  );
  static String get cardNumberInvalid => _t(
    'أدخل رقم بطاقة صحيحاً (16 رقماً)',
    'ژمارەیەکی دروستی کارت بنووسە (16 ژمارە)',
    'Enter a valid 16-digit card number',
  );
  static String get receiveMethod =>
      _t('طريقة الاستلام', 'شێوازی وەرگرتن', 'Payout method');
  static String get requestSummary =>
      _t('ملخص الطلب', 'پوختەی داواکاری', 'Request summary');
  static String get amount => _t('المبلغ', 'بڕ', 'Amount');
  static String get transferFee =>
      _t('أجور التحويل', 'کرێی گواستنەوە', 'Transfer fee');
  static String get netPayout =>
      _t('المبلغ الذي سيصلك', 'بڕی گەیشتوو', 'You will receive');
  static String get balanceAfterWithdrawal => _t(
    'الرصيد المتبقي بعد السحب',
    'باڵانسی ماوە دوای ڕاکێشان',
    'Balance after withdrawal',
  );
  static String get submitWithdrawRequest => _t(
    'إرسال طلب السحب',
    'ناردنی داواکاری ڕاکێشان',
    'Submit withdrawal request',
  );
  static String get withdrawalPolicyNotice => _t(
    'أجور التحويل مبينة في الملخص وتُخصم من مبلغ السحب. المعالجة عادة من يوم إلى يومي عمل.',
    'کرێی گواستنەوە لە پوختەکەدا دیارە و لە بڕی ڕاکێشان کەم دەکرێتەوە. جێبەجێکردن بە زۆری یەک تا دوو ڕۆژی کاری دەخایەنێت.',
    'The transfer fee is shown in the summary and deducted from the requested amount. Processing usually takes one to two business days.',
  );
  static String get readWithdrawalPolicy => _t(
    'اقرأ سياسة الأرباح والسحوبات',
    'سیاسەتی قازانج و ڕاکێشان بخوێنەوە',
    'Read the earnings and withdrawals policy',
  );
  static String get requestReceivedTitle =>
      _t('تم استلام طلبك', 'داواکارییەکەت وەرگیرا', 'Request received');
  static String requestReceivedBody(
    String amount,
    String method, {
    String? fee,
    String? netAmount,
  }) {
    final feeLine = fee == null || netAmount == null
        ? ''
        : _t(
            '\nأجور التحويل: $fee — المبلغ الذي سيصلك: $netAmount.',
            '\nکرێی گواستنەوە: $fee — بڕی گەیشتوو: $netAmount.',
            '\nTransfer fee: $fee — you will receive: $netAmount.',
          );
    return _t(
      'استلمنا طلب سحب $amount عبر $method وسيُحوَّل خلال يوم إلى يومي عمل.$feeLine',
      'داواکاری ڕاکێشانی $amount بە $method وەرگیرا و لە ماوەی یەک تا دوو ڕۆژی کاریدا دەگوازرێتەوە.$feeLine',
      'We received your request to withdraw $amount via $method. It will be transferred within one to two business days.$feeLine',
    );
  }

  static String get ok => _t('حسناً', 'باشە', 'OK');

  // ── سجل السحوبات ──
  static String get totalWithdrawn =>
      _t('إجمالي المسحوب', 'کۆی ڕاکێشراو', 'Total withdrawn');
  static String get inProgress =>
      _t('قيد المعالجة', 'لە جێبەجێکردندایە', 'Processing');

  // ── بطاقة السحب ──
  static String get requestDate =>
      _t('تاريخ الطلب', 'بەرواری داواکاری', 'Requested on');
  static String get processedDate =>
      _t('تاريخ المعالجة', 'بەرواری جێبەجێکردن', 'Processed on');
  static String rejectReason(String reason) => _t(
    'سبب الرفض: $reason',
    'هۆکاری ڕەتکردنەوە: $reason',
    'Rejection reason: $reason',
  );
  static String get withdrawalSourcesTitle =>
      _t('مصادر مبلغ السحب', 'سەرچاوەکانی بڕی ڕاکێشان', 'Withdrawal sources');
  static String get withdrawalSourcesSubtitle => _t(
    'الطلبات والمنتجات التي كوّنت هذا المبلغ، مع الجزء المحجوز من كل ربح.',
    'ئەو داواکاری و بەرهەمانەی ئەم بڕەیان پێکهێناوە، لەگەڵ بەشی گیراو لە هەر قازانجێک.',
    'Orders and products funding this amount, with the allocation from each profit.',
  );
  static String get noWithdrawalSources => _t(
    'لا توجد تخصيصات ظاهرة لهذا الطلب بعد.',
    'هێشتا هیچ دابەشکردنێک بۆ ئەم داواکارییە دیار نییە.',
    'No source allocations are visible for this request yet.',
  );
  static String get cancelWithdrawal =>
      _t('إلغاء طلب السحب', 'هەڵوەشاندنەوەی ڕاکێشان', 'Cancel withdrawal');
  static String get cancelWithdrawalConfirm => _t(
    'سيعود المبلغ المحجوز إلى رصيدك المتاح. هل تريد المتابعة؟',
    'بڕە گیراوەکە دەگەڕێتەوە بۆ باڵانسی بەردەستت. بەردەوام دەبیت؟',
    'The held amount will return to your available balance. Continue?',
  );
  static String get keepWithdrawal =>
      _t('إبقاء الطلب', 'هێشتنەوەی داواکاری', 'Keep request');
}
