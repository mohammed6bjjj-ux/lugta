import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/backend.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/repositories/supabase_repositories.dart';
import 'package:flutter_app/data/services/device_token_registrar.dart';
import 'package:flutter_app/features/auth/auth_strings.dart';
import 'package:flutter_app/features/auth/forgot_password_screen.dart';
import 'package:flutter_app/features/auth/login_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pendingRegistrationKey = 'pending_seller_registration_secure_v1';
  const recoveryGateKey = 'password_recovery_gate_secure_v1';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'registration does not send OTP until its encrypted draft is verified',
    () async {
      final auth = _FakeGoTrueClient();
      final client = _FakeSupabaseClient(auth);
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final repository = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: const _UnverifiableSecureStorage(),
      );

      await expectLater(
        repository.signUp(_registration()),
        throwsA(
          isA<BackendException>().having(
            (error) => error.code,
            'code',
            'registration_draft_persist_failed',
          ),
        ),
      );

      expect(auth.signUpCalls, 0);
    },
  );

  test(
    'ambiguous sign-up failure retains the encrypted registration draft',
    () async {
      const secureStorage = FlutterSecureStorage();
      final auth = _FakeGoTrueClient()
        ..signUpError = AuthRetryableFetchException(statusCode: '503');
      final client = _FakeSupabaseClient(auth);
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final repository = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: secureStorage,
      );

      await expectLater(
        repository.signUp(_registration()),
        throwsA(isA<BackendException>()),
      );

      expect(auth.signUpCalls, 1);
      expect(await secureStorage.read(key: pendingRegistrationKey), isNotEmpty);
    },
  );

  test(
    'registration draft persists the optional normalized referral code',
    () async {
      const secureStorage = FlutterSecureStorage();
      final auth = _FakeGoTrueClient();
      final client = _FakeSupabaseClient(auth);
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final repository = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: secureStorage,
      );

      await repository.signUp(_registration(referralCode: '  lugta-a2  '));

      final encoded = await secureStorage.read(key: pendingRegistrationKey);
      expect(encoded, isNotNull);
      final draft = Map<String, dynamic>.from(jsonDecode(encoded!) as Map);
      expect(draft['referral_code'], 'LUGTA-A2');
    },
  );

  test(
    'durable recovery gate signs out an interrupted recovery after restart',
    () async {
      const secureStorage = FlutterSecureStorage();
      final auth = _FakeGoTrueClient();
      final client = _FakeSupabaseClient(auth);
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final repository = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: secureStorage,
      );

      await repository.sendPasswordRecoveryOtp('07712345678');
      await repository.verifyOtp(
        phone: '07712345678',
        token: '123456',
        purpose: OtpPurpose.passwordRecovery,
      );

      expect(repository.hasSession, isFalse);
      expect(auth.currentSession, isNotNull);
      expect(await secureStorage.read(key: recoveryGateKey), isNotEmpty);
      await repository.updatePassword('new pass 123');
      expect(auth.updateUserCalls, 1);

      final restartedRepository = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: secureStorage,
      );
      await restartedRepository.abandonPasswordRecovery();

      expect(restartedRepository.hasSession, isFalse);
      expect(auth.signOutCalls, 1);
      expect(await secureStorage.read(key: recoveryGateKey), isNull);
    },
  );

  test(
    'abandon recovery never signs out an unrelated normal session',
    () async {
      final auth = _FakeGoTrueClient()..establishSession();
      final client = _FakeSupabaseClient(auth);
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final repository = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: const FlutterSecureStorage(),
      );

      await repository.abandonPasswordRecovery();

      expect(repository.hasSession, isTrue);
      expect(auth.signOutCalls, 0);
    },
  );

  test('starting recovery first closes an existing normal session', () async {
    const secureStorage = FlutterSecureStorage();
    final auth = _FakeGoTrueClient()..establishSession();
    final client = _FakeSupabaseClient(auth);
    addTearDown(() async {
      await client.dispose();
      auth.dispose();
    });
    final repository = SupabaseAuthRepository(
      client,
      const NoopDeviceTokenRegistrar(),
      secureStorage: secureStorage,
    );

    await repository.sendPasswordRecoveryOtp('07712345678');

    expect(auth.signOutCalls, 1);
    expect(auth.currentSession, isNull);
    expect(repository.hasSession, isFalse);
    expect(await secureStorage.read(key: recoveryGateKey), isNotEmpty);
  });

  test(
    'same OTP resend is deduplicated while the first request is in flight',
    () async {
      final barrier = Completer<void>();
      final auth = _FakeGoTrueClient()..resendBarrier = barrier;
      final client = _FakeSupabaseClient(auth);
      addTearDown(() async {
        if (!barrier.isCompleted) barrier.complete();
        await client.dispose();
        auth.dispose();
      });
      final repository = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: const FlutterSecureStorage(),
      );

      final first = repository.resendOtp(
        phone: '07712345678',
        purpose: OtpPurpose.registration,
      );
      final second = repository.resendOtp(
        phone: '07712345678',
        purpose: OtpPurpose.registration,
      );
      await Future<void>.delayed(Duration.zero);

      expect(auth.resendCalls, 1);
      barrier.complete();
      await Future.wait([first, second]);
      expect(auth.resendCalls, 1);
    },
  );

  test('different OTP resend requests are serialized', () async {
    final barrier = Completer<void>();
    final auth = _FakeGoTrueClient()..resendBarrier = barrier;
    final client = _FakeSupabaseClient(auth);
    addTearDown(() async {
      if (!barrier.isCompleted) barrier.complete();
      await client.dispose();
      auth.dispose();
    });
    final repository = SupabaseAuthRepository(
      client,
      const NoopDeviceTokenRegistrar(),
      secureStorage: const FlutterSecureStorage(),
    );

    final first = repository.resendOtp(
      phone: '07712345678',
      purpose: OtpPurpose.registration,
    );
    final second = repository.resendOtp(
      phone: '07812345678',
      purpose: OtpPurpose.registration,
    );
    await Future<void>.delayed(Duration.zero);

    expect(auth.resendCalls, 1);
    barrier.complete();
    await Future.wait([first, second]);
    expect(auth.resendCalls, 2);
  });

  test(
    'a normal session cannot be reused as a password-recovery session',
    () async {
      final auth = _FakeGoTrueClient()..establishSession();
      final client = _FakeSupabaseClient(auth);
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final repository = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: const FlutterSecureStorage(),
      );

      await expectLater(
        repository.updatePassword('new pass 123'),
        throwsA(
          isA<BackendException>().having(
            (error) => error.code,
            'code',
            'password_recovery_gate_missing',
          ),
        ),
      );

      expect(auth.updateUserCalls, 0);
      expect(repository.hasSession, isTrue);
    },
  );

  test(
    'repository rejects surrounding password whitespace before Auth',
    () async {
      final auth = _FakeGoTrueClient();
      final client = _FakeSupabaseClient(auth);
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final repository = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: const FlutterSecureStorage(),
      );

      await expectLater(
        repository.signIn(phone: '07712345678', password: ' secret'),
        throwsA(
          isA<BackendException>().having(
            (error) => error.code,
            'code',
            'password_surrounding_whitespace',
          ),
        ),
      );
      expect(auth.passwordSignInCalls, 0);
    },
  );

  testWidgets(
    'recovery compares passwords verbatim and back resets to a signed-out login',
    (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() async {
        if (appBackend.auth.hasSession) await appBackend.auth.signOut();
      });
      if (appBackend.auth.hasSession) await appBackend.auth.signOut();
      AppColors.p = AppPalette.light;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const ForgotPasswordScreen(),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '07712345678');
      await tester.tap(find.text(AuthStrings.sendCode));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(TextFormField), findsNWidgets(6));
      for (var index = 0; index < 6; index++) {
        await tester.enterText(
          find.byType(TextFormField).at(index),
          '${index + 1}',
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byKey(const ValueKey('step-password')), findsOneWidget);
      expect(appBackend.auth.hasSession, isFalse);

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(0), '1234 5678');
      await tester.enterText(passwordFields.at(1), '12345678');
      await tester.ensureVisible(find.text(AuthStrings.savePassword));
      await tester.tap(find.text(AuthStrings.savePassword));
      await tester.pump();
      expect(find.text(AuthStrings.passwordsDontMatch), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(appBackend.auth.hasSession, isFalse);
      expect(
        Navigator.of(tester.element(find.byType(LoginScreen))).canPop(),
        isFalse,
      );
    },
  );
}

RegistrationRequest _registration({String? referralCode}) =>
    RegistrationRequest(
      fullName: 'Test Seller',
      phone: '07712345678',
      password: 'safe pass',
      storeName: 'Test Store',
      governorateId: 'baghdad',
      termsVersion: 'v1',
      referralCode: referralCode,
    );

const _user = User(
  id: 'seller-a',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  phone: '+9647712345678',
  phoneConfirmedAt: '2026-07-21T00:00:00Z',
  createdAt: '2026-07-21T00:00:00Z',
);

Session _session() => Session(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  tokenType: 'bearer',
  user: _user,
);

class _FakeSupabaseClient extends SupabaseClient {
  _FakeSupabaseClient(this.fakeAuth)
    : super(
        'http://localhost',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

  final GoTrueClient fakeAuth;

  @override
  GoTrueClient get auth => fakeAuth;
}

class _FakeGoTrueClient extends GoTrueClient {
  _FakeGoTrueClient() : super(autoRefreshToken: false);

  User? _currentUser;
  Session? _currentSession;
  Object? signUpError;
  Completer<void>? resendBarrier;
  int signUpCalls = 0;
  int passwordSignInCalls = 0;
  int resendCalls = 0;
  int signOutCalls = 0;
  int updateUserCalls = 0;

  @override
  User? get currentUser => _currentUser;

  @override
  Session? get currentSession => _currentSession;

  void establishSession() {
    _currentUser = _user;
    _currentSession = _session();
  }

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    signUpCalls += 1;
    final error = signUpError;
    if (error != null) throw error;
    return AuthResponse(user: _user);
  }

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    passwordSignInCalls += 1;
    establishSession();
    return AuthResponse(session: _currentSession);
  }

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    String? emailRedirectTo,
    bool? shouldCreateUser,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {}

  @override
  Future<AuthResponse> verifyOTP({
    String? email,
    String? phone,
    String? token,
    required OtpType type,
    String? redirectTo,
    String? captchaToken,
    String? tokenHash,
  }) async {
    establishSession();
    return AuthResponse(session: _currentSession);
  }

  @override
  Future<ResendResponse> resend({
    String? email,
    String? phone,
    required OtpType type,
    String? emailRedirectTo,
    String? captchaToken,
  }) async {
    resendCalls += 1;
    final barrier = resendBarrier;
    if (barrier != null) await barrier.future;
    return ResendResponse();
  }

  @override
  Future<UserResponse> updateUser(
    UserAttributes attributes, {
    String? emailRedirectTo,
  }) async {
    updateUserCalls += 1;
    return UserResponse.fromJson(_user.toJson());
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    signOutCalls += 1;
    _currentUser = null;
    _currentSession = null;
  }
}

class _UnverifiableSecureStorage extends FlutterSecureStorage {
  const _UnverifiableSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}
}
