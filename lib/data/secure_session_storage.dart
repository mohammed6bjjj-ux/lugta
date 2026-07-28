import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase session in Android Keystore / Apple Keychain backed
/// storage and migrates the legacy SharedPreferences session once.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required this.persistSessionKey,
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final String persistSessionKey;
  final FlutterSecureStorage _secureStorage;
  String get _secureKey => '${persistSessionKey}_secure_v1';

  @override
  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final legacy = preferences.getString(persistSessionKey);
    final existing = await _secureStorage.read(key: _secureKey);
    if (existing != null && existing.isNotEmpty) {
      // The secure copy was read successfully, so a stale plaintext copy is
      // no longer needed.
      await preferences.remove(persistSessionKey);
      return;
    }
    if (legacy == null || legacy.isEmpty) {
      await preferences.remove(persistSessionKey);
      return;
    }

    // Preserve existing signed-in users while moving the refresh token out of
    // the plaintext preferences used by older app builds. A successful write
    // acknowledgement is not enough: read the value back before deleting the
    // only recoverable copy.
    await _secureStorage.write(key: _secureKey, value: legacy);
    final migrated = await _secureStorage.read(key: _secureKey);
    if (migrated == legacy) {
      await preferences.remove(persistSessionKey);
    } else {
      throw StateError('Secure session migration could not be verified.');
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    final value = await _secureStorage.read(key: _secureKey);
    return value != null && value.isNotEmpty;
  }

  @override
  Future<String?> accessToken() => _secureStorage.read(key: _secureKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _secureStorage.write(key: _secureKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() =>
      _secureStorage.delete(key: _secureKey);
}
