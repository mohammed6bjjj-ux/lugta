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
import 'package:flutter_app/features/auth/otp_verification_screen.dart';
import 'package:flutter_app/features/auth/widgets/otp_code_input.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
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
    'obfuscated duplicate phone response is rejected and clears the draft',
    () async {
      const secureStorage = FlutterSecureStorage();
      final auth = _FakeGoTrueClient()..signUpUser = _duplicateSignUpUser;
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
        throwsA(
          isA<BackendException>()
              .having((error) => error.code, 'code', 'phone_already_registered')
              .having(
                (error) => error.message,
                'message',
                contains('مسجل مسبقاً'),
              ),
        ),
      );

      expect(auth.signUpCalls, 1);
      expect(await secureStorage.read(key: pendingRegistrationKey), isNull);
    },
  );

  test(
    'an older unconfirmed phone is rejected instead of reused as a new account',
    () async {
      const secureStorage = FlutterSecureStorage();
      final auth = _FakeGoTrueClient()
        ..signUpUser = _olderUnconfirmedSignUpUser;
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
        throwsA(
          isA<BackendException>().having(
            (error) => error.code,
            'code',
            'phone_already_registered',
          ),
        ),
      );

      expect(await secureStorage.read(key: pendingRegistrationKey), isNull);
    },
  );

  test(
    'a new phone response carries the matching registration attempt',
    () async {
      const secureStorage = FlutterSecureStorage();
      final auth = _FakeGoTrueClient()
        ..signUpUserFactory = _newSignUpUserWithAttempt;
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

      await repository.signUp(_registration());

      expect(auth.lastSignUpData?['registration_attempt_id'], isNotEmpty);
      expect(auth.lastSignUpData?['registration_protocol'], 2);
      expect(await secureStorage.read(key: pendingRegistrationKey), isNotEmpty);
    },
  );

  for (final duplicateCode in const ['user_already_exists', 'phone_exists']) {
    test(
      '$duplicateCode rejects the duplicate phone and clears the draft',
      () async {
        const secureStorage = FlutterSecureStorage();
        final auth = _FakeGoTrueClient()
          ..signUpError = AuthException(
            'A user with this identifier already exists',
            code: duplicateCode,
          );
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
          throwsA(
            isA<BackendException>()
                .having(
                  (error) => error.code,
                  'code',
                  'phone_already_registered',
                )
                .having(
                  (error) => error.message,
                  'message',
                  contains('مسجل مسبقاً'),
                ),
          ),
        );

        expect(await secureStorage.read(key: pendingRegistrationKey), isNull);
      },
    );
  }

  test('an already-active profile is treated as completed registration '
      'without calling the completion RPC again', () async {
    const secureStorage = FlutterSecureStorage();
    final auth = _FakeGoTrueClient();
    var rpcCalls = 0;
    final rest = http_testing.MockClient((request) async {
      if (request.url.path.contains('/rpc/complete_seller_registration')) {
        rpcCalls += 1;
        return http.Response('{}', 404, request: request);
      }
      if (request.url.path.endsWith('/profiles')) {
        // The phone-confirmation trigger already completed this seller.
        return http.Response(
          '{"status":"active"}',
          200,
          request: request,
          headers: const {'content-type': 'application/json'},
        );
      }
      return http.Response(
        '[]',
        200,
        request: request,
        headers: const {'content-type': 'application/json'},
      );
    });
    final client = _FakeSupabaseClient(auth, httpClient: rest);
    addTearDown(() async {
      await client.dispose();
      auth.dispose();
    });
    final repository = SupabaseAuthRepository(
      client,
      const NoopDeviceTokenRegistrar(),
      secureStorage: secureStorage,
    );

    await repository.signUp(_registration());
    expect(await secureStorage.read(key: pendingRegistrationKey), isNotEmpty);
    auth.establishSession();

    final completed = await repository.completePendingRegistration();

    expect(completed, isTrue);
    expect(rpcCalls, 0);
    expect(await secureStorage.read(key: pendingRegistrationKey), isNull);
  });

  // 'active' covers auto-approval; 'pending_approval' covers the
  // trigger-completed registration when auto-approval is disabled.
  for (final completedStatus in const ['active', 'pending_approval']) {
    test('OTP verification succeeds when the draft is gone but the backend '
        'already completed the registration ($completedStatus)', () async {
      const secureStorage = FlutterSecureStorage();
      final auth = _FakeGoTrueClient();
      final rest = http_testing.MockClient((request) async {
        if (request.url.path.endsWith('/profiles')) {
          return http.Response(
            '{"status":"$completedStatus"}',
            200,
            request: request,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '[]',
          200,
          request: request,
          headers: const {'content-type': 'application/json'},
        );
      });
      final client = _FakeSupabaseClient(auth, httpClient: rest);
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final repository = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: secureStorage,
      );

      // No local draft exists (fresh storage) and the fake user carries no
      // seller_registration metadata, yet the backend already completed
      // this registration.
      auth.establishSession();

      await repository.verifyOtp(
        phone: '07712345678',
        token: '123456',
        purpose: OtpPurpose.registration,
      );
    });
  }

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

  test(
    'manual completion survives a lost reply and restart with referral intact',
    () async {
      const storage = FlutterSecureStorage();
      final auth = _FakeGoTrueClient()..establishSession();
      var fail = true;
      final paths = <String>[];
      final client = _FakeSupabaseClient(
        auth,
        httpClient: http_testing.MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/profiles')) {
            return http.Response(
              '{"status":"pending_phone"}',
              200,
              request: request,
              headers: const {'content-type': 'application/json'},
            );
          }
          final body = jsonDecode(request.body) as Map;
          expect(body['p_referral_code'], 'TESTCODE01');
          return fail
              ? http.Response(
                  '{"code":"08006","message":"connection lost"}',
                  503,
                  request: request,
                  headers: const {'content-type': 'application/json'},
                )
              : http.Response(
                  '{}',
                  200,
                  request: request,
                  headers: const {'content-type': 'application/json'},
                );
        }),
      );
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final first = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: storage,
      );
      await expectLater(
        first.completeRegistration(
          const RegistrationCompletionRequest(
            fullName: 'Test',
            storeName: 'Store',
            governorateId: 'test',
            termsVersion: '1',
            referralCode: ' testcode01 ',
          ),
        ),
        throwsA(isA<BackendException>()),
      );
      expect(paths, ['/rest/v1/rpc/complete_seller_registration_v2']);
      final draft = await storage.read(key: pendingRegistrationKey);
      expect(draft, contains('TESTCODE01'));
      expect(draft, isNot(contains('password')));
      fail = false;
      final restarted = SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
        secureStorage: storage,
      );
      expect(await restarted.completePendingRegistration(), isTrue);
      expect(paths.last, '/rest/v1/rpc/complete_seller_registration_v2');
      expect(await storage.read(key: pendingRegistrationKey), isNull);
    },
  );

  test(
    'v2 falls back only for missing endpoint and retains all seven legacy parameters',
    () async {
      final auth = _FakeGoTrueClient()..establishSession();
      final calls = <String>[];
      final client = _FakeSupabaseClient(
        auth,
        httpClient: http_testing.MockClient((request) async {
          calls.add(request.url.path);
          final body = jsonDecode(request.body) as Map;
          expect(body['p_referral_code'], 'TESTCODE01');
          expect(body.length, 7);
          return request.url.path.endsWith('_v2')
              ? http.Response(
                  '{"code":"PGRST202","message":"missing function"}',
                  404,
                  request: request,
                  headers: const {'content-type': 'application/json'},
                )
              : http.Response(
                  '{}',
                  200,
                  request: request,
                  headers: const {'content-type': 'application/json'},
                );
        }),
      );
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      await SupabaseAuthRepository(
        client,
        const NoopDeviceTokenRegistrar(),
      ).completeRegistration(
        const RegistrationCompletionRequest(
          fullName: 'Test',
          storeName: 'Store',
          governorateId: 'test',
          termsVersion: '1',
          referralCode: 'TESTCODE01',
        ),
      );
      expect(calls, [
        '/rest/v1/rpc/complete_seller_registration_v2',
        '/rest/v1/rpc/complete_seller_registration',
      ]);
    },
  );

  testWidgets('OTP cooldown catches up after app resume', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('countdown')), findsOneWidget);
    now = now.add(const Duration(minutes: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('resend')), findsOneWidget);
    expect(
      tester.widget<OtpCodeInput>(find.byType(OtpCodeInput)).enabled,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
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

const _duplicateSignUpUser = User(
  id: 'obfuscated-user',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  phone: '+9647712345678',
  confirmationSentAt: '2026-08-07T00:00:00Z',
  createdAt: '2026-08-07T00:00:00Z',
  identities: <UserIdentity>[],
);

const _phoneIdentity = UserIdentity(
  id: 'phone-identity',
  userId: 'seller-a',
  identityData: {},
  identityId: 'phone-identity',
  provider: 'phone',
  createdAt: '2026-07-21T00:00:00Z',
  lastSignInAt: null,
);

const _olderUnconfirmedSignUpUser = User(
  id: 'seller-a',
  appMetadata: {},
  userMetadata: {'registration_attempt_id': 'an-older-attempt'},
  aud: 'authenticated',
  phone: '+9647712345678',
  createdAt: '2026-07-21T00:00:00Z',
  identities: <UserIdentity>[_phoneIdentity],
);

User _newSignUpUserWithAttempt(Map<String, dynamic>? data) => User(
  id: 'new-seller',
  appMetadata: const {},
  userMetadata: data,
  aud: 'authenticated',
  phone: '+9647712345678',
  createdAt: '2026-08-07T00:00:00Z',
  identities: const <UserIdentity>[_phoneIdentity],
);

Session _session() => Session(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  tokenType: 'bearer',
  user: _user,
);

class _FakeSupabaseClient extends SupabaseClient {
  _FakeSupabaseClient(this.fakeAuth, {http.Client? httpClient})
    : super(
        'http://localhost',
        'test-key',
        httpClient: httpClient,
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
  User signUpUser = _user;
  User Function(Map<String, dynamic>? data)? signUpUserFactory;
  Map<String, dynamic>? lastSignUpData;
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
    lastSignUpData = data;
    final error = signUpError;
    if (error != null) throw error;
    return AuthResponse(user: signUpUserFactory?.call(data) ?? signUpUser);
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
