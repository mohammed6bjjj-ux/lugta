import 'dart:async';

import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/repositories/supabase_repositories.dart';
import 'package:flutter_app/data/services/device_token_registrar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<
    ({
      SupabaseAuthRepository auth,
      SupabaseDeviceTokenBackend backend,
      FirebaseDeviceTokenRegistrar registrar,
      _Messaging messaging,
      SharedPreferencesDeviceTokenStore store,
      List<String> paths,
      _Auth transport,
    })
  >
  setup() async {
    final transport = _Auth();
    final paths = <String>[];
    final client = _Client(
      transport,
      MockClient((request) async {
        paths.add(request.url.path);
        return http.Response(
          '{}',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final messaging = _Messaging();
    final store = SharedPreferencesDeviceTokenStore();
    late SupabaseAuthRepository auth;
    final backend = SupabaseDeviceTokenBackend(
      client,
      hasNormalSession: () => auth.hasSession,
    );
    final registrar = FirebaseDeviceTokenRegistrar(
      messaging: messaging,
      backend: backend,
      localStore: store,
      platform: 'android',
    );
    auth = SupabaseAuthRepository(client, registrar);
    addTearDown(() async {
      await registrar.dispose();
      await messaging.tokens.close();
      await client.dispose();
      transport.dispose();
    });
    await registrar.initialize();
    return (
      auth: auth,
      backend: backend,
      registrar: registrar,
      messaging: messaging,
      store: store,
      paths: paths,
      transport: transport,
    );
  }

  test(
    'recovery OTP never authorizes device registration or token refresh',
    () async {
      final fixture = await setup();
      await fixture.auth.sendPasswordRecoveryOtp('07712345678');
      await fixture.auth.verifyOtp(
        phone: '07712345678',
        token: '123456',
        purpose: OtpPurpose.passwordRecovery,
      );
      expect(fixture.transport.currentSession, isNotNull);
      expect(fixture.auth.hasSession, isFalse);
      expect(fixture.backend.hasAuthenticatedUser, isFalse);
      await fixture.registrar.registerCurrentDevice();
      fixture.messaging.tokens.add('recovery-token');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(fixture.paths, isEmpty);
      expect(await fixture.store.readLastToken(), isNull);
    },
  );

  test('abandon recovery invalidates tokens left by older clients', () async {
    final fixture = await setup();
    await fixture.auth.sendPasswordRecoveryOtp('07712345678');
    await fixture.auth.verifyOtp(
      phone: '07712345678',
      token: '123456',
      purpose: OtpPurpose.passwordRecovery,
    );
    await fixture.store.writeLastToken('legacy-recovery-token');
    await fixture.auth.abandonPasswordRecovery();
    expect(fixture.transport.currentSession, isNull);
    expect(fixture.messaging.deletions, 1);
    expect(await fixture.store.readLastToken(), isNull);
    expect(await fixture.store.readPendingDeletionToken(), isNull);
    expect(fixture.paths, isEmpty);
  });

  test('ordinary authenticated device registration still works', () async {
    final fixture = await setup();
    await fixture.transport.verifyOTP(type: OtpType.sms, token: '123456');
    expect(fixture.auth.hasSession, isTrue);
    await fixture.registrar.registerCurrentDevice();
    expect(fixture.paths, ['/rest/v1/rpc/register_device_token']);
    expect(await fixture.store.readLastToken(), 'normal-token');
    await fixture.auth.abandonPasswordRecovery();
    expect(fixture.transport.currentSession, isNotNull);
    expect(fixture.messaging.deletions, 0);
  });
}

class _Client extends SupabaseClient {
  _Client(this.fakeAuth, http.Client transport)
    : super(
        'http://localhost',
        'test-key',
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
  final GoTrueClient fakeAuth;
  @override
  GoTrueClient get auth => fakeAuth;
}

class _Auth extends GoTrueClient {
  _Auth() : super(autoRefreshToken: false);
  Session? session;
  @override
  Session? get currentSession => session;
  @override
  User? get currentUser => session?.user;
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
    session = Session(
      accessToken: 'test-access',
      tokenType: 'bearer',
      refreshToken: 'test-refresh',
      user: const User(
        id: 'seller',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        phone: '+9647712345678',
        phoneConfirmedAt: '2026-09-12T00:00:00Z',
        createdAt: '2026-09-12T00:00:00Z',
      ),
    );
    return AuthResponse(session: session);
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    session = null;
  }
}

class _Messaging implements PushMessagingClient {
  final tokens = StreamController<String>.broadcast();
  int deletions = 0;
  @override
  Stream<String> get tokenRefreshes => tokens.stream;
  @override
  Stream<PushMessage> get foregroundMessages => const Stream.empty();
  @override
  Stream<PushOpenEvent> get openedMessages => const Stream.empty();
  @override
  Future<void> configureForegroundPresentation() async {}
  @override
  Future<PushOpenEvent?> getInitialNotificationOpen() async => null;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<String?> getToken() async => 'normal-token';
  @override
  Future<void> deleteToken() async {
    deletions++;
  }
}
