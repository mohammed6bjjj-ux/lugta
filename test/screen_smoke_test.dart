import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/ckb_localizations.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/features/auth/account_blocked_screen.dart';
import 'package:flutter_app/features/auth/account_deleted_screen.dart';
import 'package:flutter_app/features/auth/forgot_password_screen.dart';
import 'package:flutter_app/features/auth/login_screen.dart';
import 'package:flutter_app/features/auth/onboarding_screen.dart';
import 'package:flutter_app/features/auth/otp_verification_screen.dart';
import 'package:flutter_app/features/auth/pending_approval_screen.dart';
import 'package:flutter_app/features/auth/register_screen.dart';
import 'package:flutter_app/features/cart/cart_screen.dart';
import 'package:flutter_app/features/catalog/category_products_screen.dart';
import 'package:flutter_app/features/catalog/favorites_screen.dart';
import 'package:flutter_app/features/catalog/products_screen.dart';
import 'package:flutter_app/features/catalog/search_screen.dart';
import 'package:flutter_app/features/order_wizard/order_success_screen.dart';
import 'package:flutter_app/features/order_wizard/order_wizard_screen.dart';
import 'package:flutter_app/features/orders/order_detail_screen.dart';
import 'package:flutter_app/features/orders/orders_screen.dart';
import 'package:flutter_app/features/product/media_viewer_screen.dart';
import 'package:flutter_app/features/product/product_detail_screen.dart';
import 'package:flutter_app/features/profile/about_screen.dart';
import 'package:flutter_app/features/profile/edit_profile_screen.dart';
import 'package:flutter_app/features/profile/notifications_screen.dart';
import 'package:flutter_app/features/profile/profile_screen.dart';
import 'package:flutter_app/features/profile/policies_screen.dart';
import 'package:flutter_app/features/profile/legal/legal_document_screen.dart';
import 'package:flutter_app/features/profile/legal/legal_documents.dart';
import 'package:flutter_app/features/profile/settings_screen.dart';
import 'package:flutter_app/features/profile/support_screen.dart';
import 'package:flutter_app/features/promotions/promotions_screen.dart';
import 'package:flutter_app/features/referrals/referral_screen.dart';
import 'package:flutter_app/features/loyalty/loyalty_screen.dart';
import 'package:flutter_app/features/shell/main_shell.dart';
import 'package:flutter_app/features/wallet/withdraw_request_screen.dart';
import 'package:flutter_app/features/wallet/withdrawals_history_screen.dart';
import 'package:flutter_app/features/wallet/payout_accounts_screen.dart';
import 'package:flutter_app/features/wallet/wallet_screen.dart';

typedef ScreenFactory = Widget Function();

class _Scenario {
  const _Scenario(
    this.name, {
    required this.size,
    this.language = AppLanguage.ar,
    this.darkMode = false,
    this.textScale = 1,
  });

  final String name;
  final Size size;
  final AppLanguage language;
  final bool darkMode;
  final double textScale;
}

void main() {
  final product = MockData.products.first;
  final order = MockData.orders.first;

  final screens = <String, ScreenFactory>{
    'onboarding': () => const OnboardingScreen(),
    'login': () => const LoginScreen(),
    'register': () => const RegisterScreen(),
    'OTP verification': () =>
        const OtpVerificationScreen(phone: '07712345678', purpose: 'register'),
    'forgot password': () => const ForgotPasswordScreen(),
    'pending approval': () => const PendingApprovalScreen(),
    'blocked account': () => const AccountBlockedScreen(
      isRejected: false,
      reason: 'تم إيقاف الحساب مؤقتاً',
    ),
    'deleted account': () => const AccountDeletedScreen(),
    'main shell': () => const MainShell(),
    'products': () => const ProductsScreen(),
    'category products': () =>
        CategoryProductsScreen(category: MockData.categories.first),
    'search': () => const SearchScreen(),
    'favorites': () => const FavoritesScreen(),
    'product details': () => ProductDetailScreen(product: product),
    'media viewer': () =>
        MediaViewerScreen(media: product.media, initialIndex: 0),
    'order wizard': () => OrderWizardScreen(product: product),
    'order success': () => OrderSuccessScreen(order: order),
    'order details': () => OrderDetailScreen(order: order),
    'orders': () => const OrdersScreen(),
    'cart': () => const CartScreen(),
    'withdraw request': () => const WithdrawRequestScreen(),
    'withdrawals history': () => const WithdrawalsHistoryScreen(),
    'payout accounts': () => const PayoutAccountsScreen(),
    'wallet': () => const WalletScreen(),
    'notifications': () => const NotificationsScreen(),
    'promotions': () => const PromotionsScreen(),
    'referrals': () => const ReferralScreen(),
    'loyalty': () => const LoyaltyScreen(),
    'edit profile': () => const EditProfileScreen(),
    'profile': () => const ProfileScreen(),
    'support': () => const SupportScreen(),
    'policies': () => const PoliciesScreen(),
    'long legal document': () =>
        LegalDocumentScreen(document: LegalDocuments.privacy),
    'about': () => const AboutScreen(),
    'settings': () => const SettingsScreen(),
  };

  const scenarios = [
    _Scenario('Arabic compact', size: Size(320, 568)),
    _Scenario(
      'Kurdish compact',
      size: Size(320, 568),
      language: AppLanguage.ckb,
    ),
    _Scenario(
      'English compact',
      size: Size(320, 568),
      language: AppLanguage.en,
    ),
    _Scenario('dark compact', size: Size(320, 568), darkMode: true),
    _Scenario('200% text', size: Size(360, 640), textScale: 2),
    _Scenario('landscape', size: Size(568, 320)),
    _Scenario('desktop web', size: Size(1280, 720), language: AppLanguage.en),
  ];

  for (final entry in screens.entries) {
    for (final scenario in scenarios) {
      testWidgets('${entry.key} renders in ${scenario.name}', (tester) async {
        tester.view.physicalSize = scenario.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(() {
          appSettings.language = AppLanguage.ar;
          appSettings.darkMode = false;
          AppColors.p = AppPalette.light;
        });

        await tester.pumpWidget(_testApp(entry.value(), scenario));
        await tester.pump(const Duration(milliseconds: 800));

        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} must not throw or overflow in ${scenario.name}',
        );
      });
    }
  }
}

Widget _testApp(Widget home, _Scenario scenario) {
  appSettings.language = scenario.language;
  appSettings.darkMode = scenario.darkMode;
  AppColors.p = scenario.darkMode ? AppPalette.dark : AppPalette.light;

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: scenario.darkMode ? AppTheme.dark() : AppTheme.light(),
    locale: scenario.language.locale,
    supportedLocales: const [Locale('ar'), Locale('ckb'), Locale('en')],
    localizationsDelegates: const [
      CkbMaterialLocalizationsDelegate(),
      CkbWidgetsLocalizationsDelegate(),
      CkbCupertinoLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(scenario.textScale),
        ),
        child: child!,
      );
    },
    onGenerateRoute: AppRouter.onGenerateRoute,
    home: home,
  );
}
