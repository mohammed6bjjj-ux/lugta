import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'storefront_models.dart';

abstract interface class StorefrontDraftStore {
  Future<StorefrontDraft?> read();
  Future<void> write(StorefrontDraft draft);
  Future<void> clear();
  Future<void> setPickerPending(bool pending);
  Future<bool> isPickerPending();
}

/// Only brand configuration is persisted, never auth tokens or customer data.
/// A user's setup cannot be restored into another authenticated account.
class PreferencesStorefrontDraftStore implements StorefrontDraftStore {
  PreferencesStorefrontDraftStore(String userId)
    : _key = 'lugta.storefront.draft.v1.$userId';
  final String _key;
  Future<void> _tail = Future<void>.value();

  @override
  Future<StorefrontDraft?> read() async {
    await _tail;
    final value = (await SharedPreferences.getInstance()).getString(_key);
    if (value == null) return null;
    try {
      return StorefrontDraft.fromJson(
        Map<String, dynamic>.from(jsonDecode(value) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(StorefrontDraft draft) => _enqueue((prefs) async {
    await prefs.setString(_key, jsonEncode(draft.toJson()));
  });

  @override
  Future<void> clear() => _enqueue((prefs) async {
    await prefs.remove(_key);
    await prefs.remove('$_key.picker');
  });

  @override
  Future<void> setPickerPending(bool pending) => _enqueue((prefs) async {
    if (pending) {
      await prefs.setBool('$_key.picker', true);
    } else {
      await prefs.remove('$_key.picker');
    }
  });

  @override
  Future<bool> isPickerPending() async {
    await _tail;
    return (await SharedPreferences.getInstance()).getBool('$_key.picker') ??
        false;
  }

  Future<void> _enqueue(Future<void> Function(SharedPreferences) operation) {
    final future = _tail.then(
      (_) async => operation(await SharedPreferences.getInstance()),
    );
    _tail = future.catchError((Object _) {});
    return future;
  }
}
