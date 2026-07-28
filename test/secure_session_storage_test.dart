import 'package:flutter_app/data/secure_session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const persistKey = 'sb-test-auth-token';
  const secureKey = '${persistKey}_secure_v1';

  test(
    'migrates a legacy session into secure storage and removes it',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({persistKey: 'legacy-session'});
      const secureStorage = FlutterSecureStorage();
      final storage = SecureSessionStorage(
        persistSessionKey: persistKey,
        secureStorage: secureStorage,
      );

      await storage.initialize();

      expect(await secureStorage.read(key: secureKey), 'legacy-session');
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey(persistKey), isFalse);
    },
  );

  test(
    'retains the legacy session when secure write verification fails',
    () async {
      SharedPreferences.setMockInitialValues({persistKey: 'legacy-session'});
      final storage = SecureSessionStorage(
        persistSessionKey: persistKey,
        secureStorage: const _UnverifiableSecureStorage(),
      );

      await expectLater(storage.initialize(), throwsStateError);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(persistKey), 'legacy-session');
    },
  );

  test(
    'keeps the secure session and still removes a stale legacy copy',
    () async {
      FlutterSecureStorage.setMockInitialValues({secureKey: 'secure-session'});
      SharedPreferences.setMockInitialValues({persistKey: 'stale-session'});
      const secureStorage = FlutterSecureStorage();
      final storage = SecureSessionStorage(
        persistSessionKey: persistKey,
        secureStorage: secureStorage,
      );

      await storage.initialize();

      expect(await secureStorage.read(key: secureKey), 'secure-session');
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey(persistKey), isFalse);
    },
  );
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
