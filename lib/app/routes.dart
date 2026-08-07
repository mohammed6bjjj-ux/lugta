/// أسماء المسارات الموحّدة — كل التنقل يمر عبر Navigator.pushNamed بهذه الثوابت.
///
/// تمرير البيانات عبر arguments:
/// - [productDetail] و [orderWizard]: كائن Product
/// - [categoryProducts]: كائن Category
/// - [orderDetail] و [orderSuccess]: كائن Order
/// - [mediaViewer]: Map بالمفاتيح `{'media': List<MediaItem>, 'initialIndex': int}`
/// - [otp]: Map بالمفاتيح {'phone': String, 'purpose': String} حيث purpose إما
///   'register' أو 'resetPassword'
/// - [accountBlocked]: Map بالمفاتيح {'isRejected': bool, 'reason': String}
abstract class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const forgotPassword = '/forgot-password';
  static const pendingApproval = '/pending-approval';
  static const accountBlocked = '/account-blocked';
  static const accountDeleted = '/account-deleted';

  /// الحاوية الرئيسية بعد الدخول
  /// (تبويبات: الرئيسية، المنتجات، الطلبات، المحفظة، حسابي)
  static const shell = '/shell';

  static const products = '/products';
  static const categoryProducts = '/category-products';
  static const search = '/search';
  static const favorites = '/favorites';
  static const productDetail = '/product-detail';
  static const mediaViewer = '/media-viewer';
  static const cart = '/cart';

  static const orderWizard = '/order-wizard';
  static const orderSuccess = '/order-success';
  static const orderDetail = '/order-detail';

  static const withdrawRequest = '/withdraw-request';
  static const withdrawalsHistory = '/withdrawals-history';
  static const payoutAccounts = '/payout-accounts';

  static const notifications = '/notifications';
  static const promotions = '/promotions';
  static const referrals = '/referrals';
  static const editProfile = '/edit-profile';
  static const support = '/support';
  static const policies = '/policies';
  static const about = '/about';
  static const settings = '/settings';
}
