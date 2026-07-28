import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/ckb_localizations.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/config/app_config.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/auth/onboarding_screen.dart';
import 'package:flutter_app/features/catalog/products_screen.dart';
import 'package:flutter_app/features/order_wizard/order_success_screen.dart';
import 'package:flutter_app/features/order_wizard/order_wizard_screen.dart';
import 'package:flutter_app/features/orders/orders_screen.dart';
import 'package:flutter_app/features/profile/notifications_screen.dart';
import 'package:flutter_app/features/profile/profile_screen.dart';
import 'package:flutter_app/features/shell/main_shell.dart';
import 'package:flutter_app/features/wallet/wallet_screen.dart';
import 'package:flutter_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  AppConfig.forceDemo = true;

  testWidgets('seller can complete onboarding and log in', (tester) async {
    app.main();

    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(OnboardingScreen), findsOneWidget);

    final nextButton = find.byKey(const ValueKey('onboarding_next_button'));
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('onboarding_login_button')));
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const ValueKey('login_submit_button'));
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.text(validateIraqiPhone('')!), findsOneWidget);
    expect(find.text(validatePassword('')!), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('login_phone_field')),
      '07712345678',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login_password_field')),
      '123456',
    );
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('products_nav_tab')));
    await tester.pumpAndSettle();
    expect(find.byType(ProductsScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('orders_nav_tab')));
    await tester.pumpAndSettle();
    expect(find.byType(OrdersScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('wallet_nav_tab')));
    await tester.pumpAndSettle();
    expect(find.byType(WalletScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile_nav_tab')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    final notificationsItem = find.byKey(
      const ValueKey('profile_notifications_item'),
    );
    await tester.scrollUntilVisible(
      notificationsItem,
      300,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('profile_scroll_view')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(notificationsItem);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(NotificationsScreen), findsOneWidget);

    expect(session.unreadNotificationsCount, greaterThan(0));
    await tester.tap(find.byKey(const ValueKey('notifications_mark_all_read')));
    await tester.pumpAndSettle();
    expect(session.unreadNotificationsCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seller can create a complete order', (tester) async {
    if (!session.isConfigured || !session.isDemo) {
      await session.configure(createDemoRepositories());
    }
    if (!session.isAuthenticated) {
      await session.auth.signIn(
        phone: '07712345678',
        password: 'test-password',
      );
    }
    await session.refreshAuthenticatedData();
    final product = MockData.products.first;
    final governorate = MockData.governorates[1];
    final ordersBefore = session.orders.length;

    await tester.pumpWidget(_orderTestApp(OrderWizardScreen(product: product)));
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(
      find.byKey(
        ValueKey<String>('variant_increment_${product.variants.first.id}'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final nextButton = find.byKey(const ValueKey('order_wizard_next_button'));
    await tester.tap(nextButton);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(
      find.byKey(const ValueKey('order_sale_price_field')),
      product.suggestedPrice.toString(),
    );
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.byKey(const ValueKey('order_customer_name_field')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('order_customer_name_field')),
      'زبون الاختبار',
    );
    await tester.enterText(
      find.byKey(const ValueKey('order_customer_phone_field')),
      '07712345678',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));

    final governorateField = find.byKey(
      const ValueKey('order_governorate_field'),
    );
    final customerScrollable = find.byKey(
      const ValueKey('order_customer_scrollable'),
    );
    expect(customerScrollable, findsOneWidget);
    await tester.drag(customerScrollable, const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 500));
    expect(governorateField.hitTestable(), findsOneWidget);
    await tester.tap(governorateField.hitTestable());
    await tester.pump(const Duration(milliseconds: 500));
    final governorateOption = find.byKey(
      ValueKey<String>('order_governorate_option_label_${governorate.id}'),
    );
    expect(governorateOption, findsOneWidget);
    await tester.ensureVisible(governorateOption);
    await tester.pump(const Duration(milliseconds: 300));
    expect(governorateOption.hitTestable(), findsOneWidget);
    await tester.tap(governorateOption.hitTestable());
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(ValueKey<String>('order_region_field_${governorate.id}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey<String>('fee-${governorate.id}')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('order_address_field')),
      'بغداد، شارع الاختبار، بناية 10',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(nextButton);
    await tester.pump(const Duration(milliseconds: 1450));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(OrderSuccessScreen), findsOneWidget);
    expect(session.orders.length, ordersBefore + 1);
    expect(tester.takeException(), isNull);
  });
}

Widget _orderTestApp(Widget home) {
  AppColors.p = AppPalette.light;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('ckb'), Locale('en')],
    localizationsDelegates: const [
      CkbMaterialLocalizationsDelegate(),
      CkbWidgetsLocalizationsDelegate(),
      CkbCupertinoLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    onGenerateRoute: AppRouter.onGenerateRoute,
    home: home,
  );
}
