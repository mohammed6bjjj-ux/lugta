import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/models.dart';
import '../data/session.dart';
import '../l10n/core_strings.dart';
import '../features/auth/account_blocked_screen.dart';
import '../features/auth/account_deleted_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/otp_verification_screen.dart';
import '../features/auth/pending_approval_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/catalog/category_products_screen.dart';
import '../features/catalog/favorites_screen.dart';
import '../features/catalog/products_screen.dart';
import '../features/catalog/search_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/order_wizard/order_success_screen.dart';
import '../features/order_wizard/order_wizard_screen.dart';
import '../features/orders/order_detail_screen.dart';
import '../features/product/media_viewer_screen.dart';
import '../features/product/product_detail_screen.dart';
import '../features/profile/about_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/notifications_screen.dart';
import '../features/profile/policies_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/profile/support_screen.dart';
import '../features/promotions/promotions_screen.dart';
import '../features/referrals/referral_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/wallet/withdraw_request_screen.dart';
import '../features/wallet/withdrawals_history_screen.dart';
import '../features/wallet/payout_accounts_screen.dart';
import 'routes.dart';

/// الراوتر المركزي — كل التنقل يمر من هنا.
///
/// كل شاشة تُغلَّف بمستمع على [appSettings] مع مفتاح ببصمة الإعدادات:
/// أي تغيير في اللغة أو الوضع الداكن يعيد بناء كل الشاشات المفتوحة
/// في المكدس فوراً وبالكامل (حتى الأجزاء الثابتة const) دون فقدان التنقل.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) => KeyedSubtree(
          key: ValueKey(appSettings.stamp),
          child: _guardIfProtected(settings.name, _screenFor(settings)),
        ),
      ),
    );
  }

  static Widget _guardIfProtected(String? routeName, Widget child) {
    final requiresApprovedSession = switch (routeName) {
      Routes.shell ||
      Routes.products ||
      Routes.categoryProducts ||
      Routes.search ||
      Routes.favorites ||
      Routes.productDetail ||
      Routes.mediaViewer ||
      Routes.cart ||
      Routes.orderWizard ||
      Routes.orderSuccess ||
      Routes.orderDetail ||
      Routes.withdrawRequest ||
      Routes.withdrawalsHistory ||
      Routes.payoutAccounts ||
      Routes.notifications ||
      Routes.promotions ||
      Routes.referrals ||
      Routes.editProfile ||
      Routes.settings => true,
      _ => false,
    };
    return requiresApprovedSession ? _ApprovedSessionGate(child: child) : child;
  }

  static Widget _screenFor(RouteSettings settings) {
    final args = settings.arguments;

    return switch (settings.name) {
      Routes.splash => const SplashScreen(),
      Routes.onboarding => const OnboardingScreen(),
      Routes.login => const LoginScreen(),
      Routes.register => const RegisterScreen(),
      Routes.otp => _otp(args),
      Routes.forgotPassword => const ForgotPasswordScreen(),
      Routes.pendingApproval => const PendingApprovalScreen(),
      Routes.accountBlocked => _blocked(args),
      Routes.accountDeleted => const AccountDeletedScreen(),
      Routes.shell => const MainShell(),
      Routes.products => const ProductsScreen(),
      Routes.categoryProducts =>
        args is Category
            ? CategoryProductsScreen(category: args)
            : const _UnknownRouteScreen(),
      Routes.search => const SearchScreen(),
      Routes.favorites => const FavoritesScreen(),
      Routes.productDetail =>
        args is Product
            ? ProductDetailScreen(product: args)
            : const _UnknownRouteScreen(),
      Routes.mediaViewer => _mediaViewer(args),
      Routes.cart => const CartScreen(),
      Routes.orderWizard =>
        args is Product
            ? OrderWizardScreen(product: args)
            : const _UnknownRouteScreen(),
      Routes.orderSuccess =>
        args is Order
            ? OrderSuccessScreen(order: args)
            : const _UnknownRouteScreen(),
      Routes.orderDetail =>
        args is Order
            ? OrderDetailScreen(order: args)
            : const _UnknownRouteScreen(),
      Routes.withdrawRequest => const WithdrawRequestScreen(),
      Routes.withdrawalsHistory => const WithdrawalsHistoryScreen(),
      Routes.payoutAccounts => const PayoutAccountsScreen(),
      Routes.notifications => const NotificationsScreen(),
      Routes.promotions => const PromotionsScreen(),
      Routes.referrals => const ReferralScreen(),
      Routes.editProfile => const EditProfileScreen(),
      Routes.support => const SupportScreen(),
      Routes.policies => const PoliciesScreen(),
      Routes.about => const AboutScreen(),
      Routes.settings => const SettingsScreen(),
      _ => const _UnknownRouteScreen(),
    };
  }

  static Widget _otp(Object? args) {
    if (args is! Map) return const _UnknownRouteScreen();
    final phone = args['phone'];
    final purpose = args['purpose'];
    if (phone is! String || purpose is! String) {
      return const _UnknownRouteScreen();
    }
    return OtpVerificationScreen(phone: phone, purpose: purpose);
  }

  static Widget _blocked(Object? args) {
    if (args is! Map) return const _UnknownRouteScreen();
    final isRejected = args['isRejected'];
    final reason = args['reason'];
    if (isRejected is! bool || reason is! String) {
      return const _UnknownRouteScreen();
    }
    return AccountBlockedScreen(isRejected: isRejected, reason: reason);
  }

  static Widget _mediaViewer(Object? args) {
    if (args is! Map) return const _UnknownRouteScreen();
    final rawMedia = args['media'];
    final initialIndex = args['initialIndex'];
    if (rawMedia is! List ||
        rawMedia.isEmpty ||
        !rawMedia.every((item) => item is MediaItem) ||
        initialIndex is! int ||
        initialIndex < 0 ||
        initialIndex >= rawMedia.length) {
      return const _UnknownRouteScreen();
    }
    return MediaViewerScreen(
      media: rawMedia.cast<MediaItem>(),
      initialIndex: initialIndex,
    );
  }
}

/// Declarative access gate shared by every protected route.
///
/// Auth events and profile-status refreshes notify [session], so an already
/// open detail screen is replaced immediately when the local session is lost
/// or the backend changes the seller to pending/blocked/deleted.
class _ApprovedSessionGate extends StatelessWidget {
  const _ApprovedSessionGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        // Never render the requested child before bootstrap has replaced the
        // placeholder repositories. Android can supply an initial route through
        // an explicit intent, so showing [child] here would briefly expose the
        // bundled design/demo state before the real session boundary exists.
        if (!session.isConfigured) {
          return const _SessionInitializationScreen();
        }
        // Configured demo sessions remain useful for widget/integration tests.
        // AppConfig separately makes demo mode impossible in release builds.
        if (session.isDemo && !session.isAuthenticated) {
          return child;
        }
        if (!session.isAuthenticated) return const LoginScreen();
        return switch (session.destination) {
          SessionDestination.shell => child,
          SessionDestination.pendingApproval => const PendingApprovalScreen(),
          SessionDestination.rejected => AccountBlockedScreen(
            isRejected: true,
            reason: session.seller.statusReason ?? 'تم رفض طلب التسجيل.',
          ),
          SessionDestination.blocked => AccountBlockedScreen(
            isRejected: false,
            reason: session.seller.statusReason ?? 'تم إيقاف الحساب مؤقتاً.',
          ),
          SessionDestination.deleted => const AccountDeletedScreen(),
          SessionDestination.onboarding => const LoginScreen(),
        };
      },
    );
  }
}

class _SessionInitializationScreen extends StatelessWidget {
  const _SessionInitializationScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: CircularProgressIndicator(
          key: ValueKey('session_initializing_gate'),
        ),
      ),
    ),
  );
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(CoreStrings.unknownRouteTitle)),
      body: Center(child: Text(CoreStrings.unknownRouteBody)),
    );
  }
}
