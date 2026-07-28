import 'dart:convert';

import 'package:flutter_app/data/repositories/supabase_repositories.dart';
import 'package:flutter_app/data/services/device_token_registrar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pendingKey = 'pending_seller_registration_secure_v1';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('successful password sign-in clears a pending registration', () async {
    FlutterSecureStorage.setMockInitialValues({
      pendingKey: jsonEncode(_draft(phone: '+9647712345678')),
    });
    const storage = FlutterSecureStorage();
    final auth = _FakeGoTrueClient();
    final client = _FakeSupabaseClient(auth);
    addTearDown(() async {
      await client.dispose();
      auth.dispose();
    });
    final repository = SupabaseAuthRepository(
      client,
      const NoopDeviceTokenRegistrar(),
      secureStorage: storage,
    );

    await repository.signIn(phone: '07712345678', password: '123456');

    expect(auth.signInCalls, 1);
    expect(await storage.read(key: pendingKey), isNull);
  });

  test('phone mismatch silently clears the stale draft', () async {
    FlutterSecureStorage.setMockInitialValues({
      pendingKey: jsonEncode(_draft(phone: '+9647812345678')),
    });
    const storage = FlutterSecureStorage();
    final auth = _FakeGoTrueClient(
      user: const User(
        id: 'seller-a',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        phone: '+9647712345678',
        phoneConfirmedAt: '2026-07-21T00:00:00Z',
        createdAt: '2026-07-21T00:00:00Z',
      ),
    );
    final client = _FakeSupabaseClient(auth);
    addTearDown(() async {
      await client.dispose();
      auth.dispose();
    });
    final repository = SupabaseAuthRepository(
      client,
      const NoopDeviceTokenRegistrar(),
      secureStorage: storage,
    );

    expect(await repository.completePendingRegistration(), isFalse);

    expect(await storage.read(key: pendingKey), isNull);
  });
}

Map<String, dynamic> _draft({required String phone}) => {
  'phone': phone,
  'full_name': 'Test Seller',
  'store_name': 'Test Store',
  'governorate_id': 'baghdad',
  'terms_version': 'v1',
  'locale': 'ar',
  'created_at': DateTime.now().toUtc().toIso8601String(),
  'instagram_handle': null,
};

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
  _FakeGoTrueClient({this.user}) : super(autoRefreshToken: false);

  final User? user;
  int signInCalls = 0;

  @override
  User? get currentUser => user;

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    signInCalls += 1;
    return AuthResponse(user: user);
  }
}
