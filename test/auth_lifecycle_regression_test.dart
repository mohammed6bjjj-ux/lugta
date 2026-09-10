import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/backend.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/auth/login_screen.dart';
import 'package:flutter_app/features/auth/otp_verification_screen.dart';
import 'package:flutter_app/features/auth/widgets/otp_code_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> configure(
    AuthRepository auth, {
    WalletRepository? wallet,
  }) async {
    final demo = createDemoRepositories();
    final repositories = AppRepositories(
      auth: auth,
      profile: demo.profile,
      catalog: demo.catalog,
      orders: demo.orders,
      wallet: wallet ?? demo.wallet,
      notifications: demo.notifications,
      promotions: demo.promotions,
      loyalty: demo.loyalty,
      isDemo: false,
    );
    appBackend.repositories = repositories;
    await session.configure(repositories, loadInitialData: false);
  }

  tearDown(() async {
    appBackend.repositories = createDemoRepositories();
    await session.configure(appBackend.repositories, loadInitialData: false);
  });

  Future<void> loginForm(
    WidgetTester tester, {
    void Function(RouteSettings)? onRoute,
  }) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const LoginScreen(),
        onGenerateRoute: (settings) {
          onRoute?.call(settings);
          return MaterialPageRoute<void>(
            builder: (_) => Scaffold(body: Text('ROUTE:${settings.name}')),
          );
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(
      find.byKey(const ValueKey('login_phone_field')),
      '07712345678',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login_password_field')),
      'validPassword1',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('login_submit_button')),
    );
    await tester.tap(find.byKey(const ValueKey('login_submit_button')));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('valid login routes successfully even when wallet read fails', (
    tester,
  ) async {
    final wallet = _UnavailableWallet();
    await tester.runAsync(
      () => configure(DemoAuthRepository(), wallet: wallet),
    );
    await loginForm(tester);
    expect(find.text('ROUTE:/shell'), findsOneWidget);
    expect(appBackend.auth.hasSession, isTrue);
    expect(wallet.calls, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unconfirmed password login resumes OTP instead of trapping the user',
    (tester) async {
      final auth = _UnconfirmedAuth();
      await tester.runAsync(() => configure(auth));
      RouteSettings? destination;
      await loginForm(tester, onRoute: (settings) => destination = settings);
      expect(find.text('ROUTE:/otp'), findsOneWidget);
      expect(auth.resends, 1);
      expect(destination?.arguments, {
        'phone': '07712345678',
        'purpose': 'register',
      });
      expect(appBackend.auth.hasSession, isFalse);
    },
  );

  testWidgets('queued OTP completion cannot race an in-flight resend', (
    tester,
  ) async {
    final auth = _BarrierAuth();
    await tester.runAsync(() => configure(auth));
    var now = DateTime.utc(2026, 9, 6);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OtpVerificationScreen(
          phone: '07712345678',
          purpose: 'register',
          now: () => now,
        ),
      ),
    );
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.byKey(const ValueKey('resend')));
    await tester.tap(find.byKey(const ValueKey('resend')));
    await tester.pump();
    final input = tester.widget<OtpCodeInput>(find.byType(OtpCodeInput));
    expect(input.enabled, isFalse);
    input.onCompleted('123456'); // callback queued before the rebuild
    await tester.pump();
    expect(auth.verifications, 0);
    auth.resendBarrier.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _UnavailableWallet implements WalletRepository {
  int calls = 0;
  @override
  Future<WalletSnapshot> fetchWallet() async {
    calls++;
    throw const BackendException('wallet offline');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnconfirmedAuth extends DemoAuthRepository {
  int resends = 0;
  @override
  Future<void> signIn({
    required String phone,
    required String password,
  }) async => throw const BackendException(
    'phone not confirmed',
    code: 'phone_not_confirmed',
  );
  @override
  Future<void> resendOtp({
    required String phone,
    required OtpPurpose purpose,
  }) async {
    resends++;
  }
}

class _BarrierAuth extends DemoAuthRepository {
  final resendBarrier = Completer<void>();
  int verifications = 0;
  @override
  Future<void> resendOtp({
    required String phone,
    required OtpPurpose purpose,
  }) => resendBarrier.future;
  @override
  Future<void> verifyOtp({
    required String phone,
    required String token,
    required OtpPurpose purpose,
  }) async {
    verifications++;
  }
}
