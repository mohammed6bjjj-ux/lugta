import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/backend.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/auth/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() async {
    appBackend.repositories = createDemoRepositories();
    await session.configure(appBackend.repositories, loadInitialData: false);
  });

  Future<void> configure(WidgetTester tester, _Profile profile) async {
    final demo = createDemoRepositories();
    appBackend.repositories = AppRepositories(
      auth: _StaleDraftAuth(),
      profile: profile,
      catalog: demo.catalog,
      orders: demo.orders,
      wallet: demo.wallet,
      notifications: demo.notifications,
      promotions: demo.promotions,
      loyalty: demo.loyalty,
      isDemo: false,
    );
    await tester.runAsync(
      () => session.configure(appBackend.repositories, loadInitialData: false),
    );
  }

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const SplashScreen(),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: Text('ROUTE:${settings.name}')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  for (final (status, route) in [
    (AccountStatus.pending, Routes.pendingApproval),
    (AccountStatus.blocked, Routes.accountBlocked),
    (AccountStatus.rejected, Routes.accountBlocked),
    (AccountStatus.deleted, Routes.accountDeleted),
    (AccountStatus.approved, Routes.shell),
  ]) {
    testWidgets('stale completion uses authoritative profile: $status', (
      tester,
    ) async {
      final profile = _Profile(status);
      await configure(tester, profile);
      await show(tester);
      expect(find.text('ROUTE:$route'), findsOneWidget);
      expect(profile.reads, greaterThan(0));
      expect(find.byKey(const Key('startup-retry')), findsNothing);
      if (status != AccountStatus.approved) {
        expect(find.text('ROUTE:${Routes.shell}'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('profile failure remains fail-closed with retry', (tester) async {
    final profile = _Profile(AccountStatus.pending)..failRead = true;
    await configure(tester, profile);
    await show(tester);
    expect(find.byKey(const Key('startup-retry')), findsOneWidget);
    expect(find.text('ROUTE:${Routes.shell}'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cached approval does not bypass a newly blocked profile', (
    tester,
  ) async {
    final profile = _Profile(AccountStatus.approved);
    await configure(tester, profile);
    await tester.runAsync(() => session.refreshCurrentProfile());
    expect(session.seller.status, AccountStatus.approved);
    profile.status = AccountStatus.blocked;
    await show(tester);
    expect(find.text('ROUTE:${Routes.accountBlocked}'), findsOneWidget);
    expect(find.text('ROUTE:${Routes.shell}'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _StaleDraftAuth extends DemoAuthRepository {
  @override
  bool get hasSession => true;
  @override
  String? get currentUserId => 'draft-seller';
  @override
  Future<bool> completePendingRegistration() async =>
      throw const BackendException('terms outdated', code: '23514');
}

class _Profile implements ProfileRepository {
  _Profile(this.status);
  AccountStatus status;
  bool failRead = false;
  int reads = 0;
  @override
  Future<Seller> fetchCurrentProfile() async {
    reads++;
    if (failRead) throw const BackendException('offline');
    return Seller(
      id: 'draft-seller',
      name: '',
      phone: '+9647712345678',
      storeName: '',
      instagramUrl: '',
      governorateId: '',
      status: status,
      joinedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<void> touchLastActive() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
