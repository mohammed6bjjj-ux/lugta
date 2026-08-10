import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/routes.dart';
import 'package:flutter_app/data/models.dart' as data;
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/auth/guest_access_screen.dart';
import 'package:flutter_app/features/auth/login_screen.dart';
import 'package:flutter_app/features/auth/register_screen.dart';
import 'package:flutter_app/features/shell/main_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await session.leaveGuestMode();
    await session.configure(_signedOutProductionLikeRepositories());
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await session.leaveGuestMode();
  });

  for (final platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    testWidgets('guest entry is available on ${platform.name}', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const LoginScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final guestButton = find.byKey(const ValueKey('login_guest_button'));
      await tester.drag(find.byType(ListView), const Offset(0, -520));
      await tester.pump(const Duration(milliseconds: 300));
      expect(guestButton, findsOneWidget);
      await tester.tap(guestButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(session.isGuest, isTrue);
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byKey(const ValueKey('home_nav_tab')), findsOneWidget);
      expect(find.byKey(const ValueKey('products_nav_tab')), findsOneWidget);
      expect(find.byKey(const ValueKey('guest_nav_tab')), findsOneWidget);
      expect(find.byKey(const ValueKey('orders_nav_tab')), findsNothing);
      expect(find.byKey(const ValueKey('wallet_nav_tab')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('guest_nav_tab')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GuestAccessScreen), findsOneWidget);
      final createAccount = find.byKey(
        const ValueKey('guest_create_account_button'),
      );
      await tester.ensureVisible(createAccount);
      await tester.tap(createAccount);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(session.isGuest, isFalse);
      expect(find.byType(RegisterScreen), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('guest-only account routes stay behind the real auth boundary', (
    tester,
  ) async {
    await session.enterGuestMode();
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: Routes.notifications,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(GuestAccessScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('guest_create_account_button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('guest_sign_in_button')), findsOneWidget);
    expect(session.orders, isEmpty);
    expect(session.transactions, isEmpty);
    expect(session.notifications, isEmpty);
  });

  testWidgets('guest auth wall fits a small Android screen at 200% text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const GuestAccessScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  test('guest preview is restored after a cold session configure', () async {
    await session.enterGuestMode();
    await session.configure(_signedOutProductionLikeRepositories());

    expect(session.isGuest, isTrue);
    expect(session.products, isNotEmpty);
    expect(session.orders, isEmpty);
  });

  test(
    'guest preview loads the repository catalog instead of bundled data',
    () async {
      final catalog = _GuestLiveCatalogRepository();
      await session.configure(
        _signedOutProductionLikeRepositories(catalog: catalog),
        loadInitialData: false,
      );

      await session.enterGuestMode();

      expect(catalog.categoryFetches, 1);
      expect(catalog.productFetches, 1);
      expect(catalog.packagingFetches, 1);
      expect(session.categories, hasLength(1));
      expect(session.products, hasLength(1));
      expect(session.packagingBoxes, isNotEmpty);
      expect(session.governorates, isEmpty);
      expect(session.banners, isEmpty);
      expect(session.faq, isEmpty);
      expect(session.orders, isEmpty);
      expect(session.transactions, isEmpty);
    },
  );
}

AppRepositories _signedOutProductionLikeRepositories({
  CatalogRepository? catalog,
}) {
  final base = createDemoRepositories();
  return AppRepositories(
    auth: base.auth,
    profile: base.profile,
    catalog: catalog ?? base.catalog,
    orders: base.orders,
    wallet: base.wallet,
    notifications: base.notifications,
    promotions: base.promotions,
    loyalty: base.loyalty,
    isDemo: false,
  );
}

class _GuestLiveCatalogRepository extends DemoCatalogRepository {
  int categoryFetches = 0;
  int productFetches = 0;
  int packagingFetches = 0;

  @override
  Future<List<data.Category>> fetchCategories() async {
    categoryFetches += 1;
    final items = await super.fetchCategories();
    return items.take(1).toList(growable: false);
  }

  @override
  Future<List<data.Product>> fetchProducts() async {
    productFetches += 1;
    final items = await super.fetchProducts();
    return items.take(1).toList(growable: false);
  }

  @override
  Future<List<data.PackagingBox>> fetchPackagingBoxes() async {
    packagingFetches += 1;
    return super.fetchPackagingBoxes();
  }
}
