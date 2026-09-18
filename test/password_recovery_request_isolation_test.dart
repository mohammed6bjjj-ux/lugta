import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/backend.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/auth/auth_strings.dart';
import 'package:flutter_app/features/auth/forgot_password_screen.dart';
import 'package:flutter_app/features/auth/widgets/otp_code_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() async {
    appBackend.repositories = createDemoRepositories();
    await session.configure(appBackend.repositories, loadInitialData: false);
  });

  Future<void> show(WidgetTester tester, _RecoveryAuth auth) async {
    final demo = createDemoRepositories();
    appBackend.repositories = AppRepositories(
      auth: auth,
      profile: demo.profile,
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
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const ForgotPasswordScreen()),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(find.byType(TextFormField), '07712345678');
    await tester.tap(find.text(AuthStrings.sendCode));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('queued autofill cannot verify during recovery resend', (
    tester,
  ) async {
    final auth = _RecoveryAuth();
    await show(tester, auth);
    for (var i = 0; i < 61; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    final queuedAutofill = tester
        .widget<TextFormField>(
          find
              .descendant(
                of: find.byType(OtpCodeInput),
                matching: find.byType(TextFormField),
              )
              .first,
        )
        .onChanged!;
    await tester.ensureVisible(find.text(AuthStrings.resendCode));
    await tester.tap(find.text(AuthStrings.resendCode));
    expect(auth.resends, 1);
    queuedAutofill('123456');
    await tester.pump();
    expect(auth.verifiedPhones, isEmpty);
    auth.resendBarrier.complete();
    await tester.pump();
    tester
        .widget<OtpCodeInput>(find.byType(OtpCodeInput))
        .onCompleted('654321');
    await tester.pump();
    expect(auth.verifiedPhones, ['07712345678']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'send locks phone and later verification keeps submitted target',
    (tester) async {
      final auth = _RecoveryAuth(sendBarrier: Completer<void>());
      await show(tester, auth);
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isFalse);
      // Also emulate an already queued platform/controller edit: the submitted
      // identity must stay fixed even before the disabled field can rebuild.
      field.controller!.text = '07812345678';
      auth.sendBarrier!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('07712345678'), findsOneWidget);
      tester
          .widget<OtpCodeInput>(find.byType(OtpCodeInput))
          .onCompleted('123456');
      await tester.pump();
      expect(auth.sentPhones, ['07712345678']);
      expect(auth.verifiedPhones, auth.sentPhones);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('queued verification cannot race editing the recovery phone', (
    tester,
  ) async {
    final auth = _RecoveryAuth(abandonBarrier: Completer<void>());
    await show(tester, auth);
    final queuedCompletion = tester
        .widget<OtpCodeInput>(find.byType(OtpCodeInput))
        .onCompleted;
    await tester.tap(find.byKey(const ValueKey('recovery-edit-phone')));
    queuedCompletion('123456');
    await tester.pump();
    expect(auth.verifiedPhones, isEmpty);
    auth.abandonBarrier!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('step-phone')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _RecoveryAuth extends DemoAuthRepository {
  _RecoveryAuth({this.sendBarrier, this.abandonBarrier});
  final Completer<void>? sendBarrier;
  final Completer<void>? abandonBarrier;
  final resendBarrier = Completer<void>();
  final sentPhones = <String>[];
  final verifiedPhones = <String>[];
  int resends = 0;
  @override
  Future<void> sendPasswordRecoveryOtp(String phone) async {
    sentPhones.add(phone);
    await sendBarrier?.future;
  }

  @override
  Future<void> resendOtp({required String phone, required OtpPurpose purpose}) {
    resends++;
    return resendBarrier.future;
  }

  @override
  Future<void> verifyOtp({
    required String phone,
    required String token,
    required OtpPurpose purpose,
  }) async {
    verifiedPhones.add(phone);
  }

  @override
  Future<void> abandonPasswordRecovery() async => abandonBarrier?.future;
}
