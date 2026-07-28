import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/external_actions.dart';
import '../../core/phone_number.dart';
import '../app_settings.dart';
import '../content_parser.dart';
import '../models.dart';
import '../wallet_ledger_mapper.dart';
import '../services/device_token_registrar.dart';
import 'repositories.dart';
import 'transient_read_retry.dart';

AppRepositories createSupabaseRepositories(
  SupabaseClient client, {
  DeviceTokenRegistrar deviceTokens = const NoopDeviceTokenRegistrar(),
}) {
  return AppRepositories(
    auth: SupabaseAuthRepository(client, deviceTokens),
    profile: SupabaseProfileRepository(client),
    catalog: SupabaseCatalogRepository(client),
    orders: SupabaseOrdersRepository(client),
    wallet: SupabaseWalletRepository(client),
    notifications: SupabaseNotificationsRepository(client),
    isDemo: false,
  );
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._client,
    this._deviceTokens, {
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _pendingRegistrationKey = 'pending_seller_registration_v1';
  static const _securePendingRegistrationKey =
      'pending_seller_registration_secure_v1';
  static const _pendingRegistrationLifetime = Duration(hours: 24);
  static const _passwordRecoveryGateKey = 'password_recovery_gate_secure_v1';
  static const _passwordRecoveryLifetime = Duration(minutes: 30);

  final SupabaseClient _client;
  final DeviceTokenRegistrar _deviceTokens;
  final FlutterSecureStorage _secureStorage;
  _PendingRegistrationDraft? _pendingRegistration;
  bool _passwordRecoveryActive = false;
  Future<void> _resendOtpTail = Future<void>.value();
  final Map<String, Future<void>> _resendOtpInFlight = {};

  @override
  bool get hasSession =>
      !_passwordRecoveryActive && _client.auth.currentSession != null;

  @override
  String? get currentUserId => hasSession ? _client.auth.currentUser?.id : null;

  @override
  Stream<String?> get userIdChanges => _client.auth.onAuthStateChange
      .map((_) => !hasSession ? null : _client.auth.currentUser?.id)
      .distinct();

  @override
  Future<void> signIn({required String phone, required String password}) async {
    _requireOpaquePassword(password);
    // Remove any interrupted recovery-only session before creating a normal
    // password session. Doing this first avoids reporting a failed login after
    // Auth has already accepted the credentials.
    await abandonPasswordRecovery();
    await _guard(() async {
      await _client.auth.signInWithPassword(
        phone: normalizeIraqiPhone(phone),
        password: password,
      );
    });
    await _clearPendingRegistration();
    await _registerDeviceBestEffort();
  }

  @override
  Future<void> signUp(RegistrationRequest request) async {
    _requireOpaquePassword(request.password, minimumLength: 8);
    if (request.termsVersion.trim().isEmpty) {
      throw const BackendException(
        'تعذر تحميل النسخة الحالية من الشروط. حدّث الصفحة وحاول مجدداً.',
      );
    }
    await abandonPasswordRecovery();
    final normalizedPhone = normalizeIraqiPhone(request.phone);
    final rawInstagram = request.instagramUrl?.trim();
    final normalizedInstagram = rawInstagram == null || rawInstagram.isEmpty
        ? null
        : normalizeInstagramProfile(rawInstagram);
    if (rawInstagram != null &&
        rawInstagram.isNotEmpty &&
        normalizedInstagram == null) {
      throw const BackendException(
        'رابط إنستغرام غير صالح. استخدم اسم المستخدم أو رابط الصفحة فقط.',
        code: 'invalid_instagram_profile',
      );
    }
    // Keep only the non-credential registration fields. Authorization and
    // role/status assignment happen exclusively inside the server RPC after
    // phone confirmation; raw_user_meta_data is intentionally not trusted.
    final draft = _PendingRegistrationDraft.fromRequest(
      request,
      normalizedPhone: normalizedPhone,
      locale: appSettings.language.name,
      instagramHandle: normalizedInstagram,
    );
    await _writePendingRegistration(draft);
    _pendingRegistration = draft;
    try {
      await _guard(() async {
        await _client.auth.signUp(
          phone: normalizedPhone,
          password: request.password,
          channel: OtpChannel.sms,
        );
      });
    } catch (_) {
      // The request may have reached Auth even when the response was lost.
      // Keeping the verified encrypted draft makes retrying or completing the
      // already-sent OTP safe; it expires automatically after 24 hours.
      rethrow;
    }
  }

  @override
  Future<bool> completePendingRegistration() async {
    final draft = await _readPendingRegistration();
    if (draft == null) return false;

    final user = _client.auth.currentUser;
    if (user == null || user.phoneConfirmedAt == null) return false;
    final authenticatedPhone = user.phone;
    if (authenticatedPhone == null ||
        normalizeIraqiPhone(authenticatedPhone) != draft.phone) {
      await _clearPendingRegistration();
      return false;
    }

    final profile = await _guard(() async {
      final value = await _client
          .from('profiles')
          .select('status')
          .eq('id', user.id)
          .maybeSingle();
      return value == null ? null : _map(value);
    });
    final status = profile == null ? '' : _text(profile['status']);
    if (status.isNotEmpty &&
        status != 'pending_phone' &&
        status != 'pending_approval') {
      await _clearPendingRegistration();
      return false;
    }

    await _guard(() async {
      await _client.rpc(
        'complete_seller_registration',
        params: {
          'p_full_name': draft.fullName,
          'p_store_name': draft.storeName,
          'p_governorate_id': draft.governorateId,
          'p_terms_version': draft.termsVersion,
          'p_instagram_handle': draft.instagramHandle,
          'p_locale': draft.locale,
        },
      );
    });
    await _clearPendingRegistration();
    return true;
  }

  @override
  Future<void> verifyOtp({
    required String phone,
    required String token,
    required OtpPurpose purpose,
  }) async {
    final normalizedPhone = normalizeIraqiPhone(phone);
    _PasswordRecoveryGate? recoveryGate;
    if (purpose == OtpPurpose.passwordRecovery) {
      recoveryGate = await _requirePasswordRecoveryGate(normalizedPhone);
    }
    if (purpose == OtpPurpose.registration) {
      final user = _client.auth.currentUser;
      if (user?.phoneConfirmedAt != null &&
          user?.phone != null &&
          normalizeIraqiPhone(user!.phone!) == normalizedPhone) {
        final completed = await completePendingRegistration();
        if (!completed) {
          throw const BackendException(
            'تعذر العثور على بيانات التسجيل. ارجع وأعد إرسال الطلب.',
            code: 'registration_draft_missing',
          );
        }
        await _registerDeviceBestEffort();
        return;
      }
    }

    await _guard(() async {
      await _client.auth.verifyOTP(
        phone: normalizedPhone,
        token: token,
        type: purpose == OtpPurpose.phoneChange
            ? OtpType.phoneChange
            : OtpType.sms,
      );
    });
    if (purpose == OtpPurpose.passwordRecovery) {
      final authenticatedPhone = _client.auth.currentUser?.phone;
      if (authenticatedPhone == null ||
          normalizeIraqiPhone(authenticatedPhone) != recoveryGate!.phone) {
        await abandonPasswordRecovery();
        throw const BackendException(
          'تعذر مطابقة جلسة استعادة كلمة المرور. أعد المحاولة.',
          code: 'password_recovery_phone_mismatch',
        );
      }
      // A password-recovery OTP creates a real Supabase session. Keep it
      // recovery-only: do not register push tokens or expose app data.
      return;
    }
    if (purpose == OtpPurpose.registration) {
      final completed = await completePendingRegistration();
      if (!completed) {
        throw const BackendException(
          'تم تأكيد الرقم، لكن تعذر إكمال بيانات التسجيل. حاول مرة أخرى.',
          code: 'registration_completion_failed',
        );
      }
    }
    await _registerDeviceBestEffort();
  }

  Future<void> _writePendingRegistration(
    _PendingRegistrationDraft draft,
  ) async {
    final encoded = jsonEncode(draft.toJson());
    await _writeSecureValueVerified(
      key: _securePendingRegistrationKey,
      value: encoded,
      failureMessage:
          'تعذر حفظ بيانات التسجيل بأمان. أعد المحاولة قبل طلب الرمز.',
      failureCode: 'registration_draft_persist_failed',
    );
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_pendingRegistrationKey);
    } catch (_) {
      // The verified encrypted copy is authoritative; legacy cleanup can be
      // retried later without blocking OTP delivery.
    }
  }

  bool _isPendingRegistrationExpired(_PendingRegistrationDraft draft) {
    final age = DateTime.now().toUtc().difference(draft.createdAt);
    return age.isNegative || age > _pendingRegistrationLifetime;
  }

  Future<String?> _readEncodedPendingRegistration() async {
    final encrypted = await _readSecureValue(
      key: _securePendingRegistrationKey,
      failureMessage: 'تعذر قراءة بيانات التسجيل المحفوظة بأمان.',
      failureCode: 'registration_draft_read_failed',
    );
    if (encrypted != null && encrypted.isNotEmpty) return encrypted;

    // Migrate unfinished registrations created by older app versions.
    final preferences = await SharedPreferences.getInstance();
    final legacy = preferences.getString(_pendingRegistrationKey);
    if (legacy == null || legacy.isEmpty) return null;
    await _writeSecureValueVerified(
      key: _securePendingRegistrationKey,
      value: legacy,
      failureMessage: 'تعذر نقل بيانات التسجيل إلى التخزين الآمن.',
      failureCode: 'registration_draft_migration_failed',
    );
    await preferences.remove(_pendingRegistrationKey);
    return legacy;
  }

  Future<void> _deletePendingRegistrationFromDisk() async {
    try {
      await _secureStorage.delete(key: _securePendingRegistrationKey);
    } catch (_) {
      // Continue clearing the legacy copy if secure storage is unavailable.
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_pendingRegistrationKey);
    } catch (_) {
      // Cleanup must never prevent authentication recovery.
    }
  }

  Future<_PendingRegistrationDraft?> _readPendingRegistration() async {
    if (_pendingRegistration case final draft?) {
      if (!_isPendingRegistrationExpired(draft)) return draft;
      await _clearPendingRegistration();
      return null;
    }
    final encoded = await _readEncodedPendingRegistration();
    if (encoded == null) return null;
    late final _PendingRegistrationDraft draft;
    try {
      draft = _PendingRegistrationDraft.fromJson(
        Map<String, dynamic>.from(jsonDecode(encoded) as Map),
      );
    } catch (_) {
      await _deletePendingRegistrationFromDisk();
      return null;
    }
    if (_isPendingRegistrationExpired(draft)) {
      await _clearPendingRegistration();
      return null;
    }
    _pendingRegistration = draft;
    // Re-save legacy drafts with their generated creation timestamp. If the
    // secure store fails here the existing disk copy is intentionally kept.
    await _writePendingRegistration(draft);
    return draft;
  }

  Future<void> _clearPendingRegistration() async {
    _pendingRegistration = null;
    await _deletePendingRegistrationFromDisk();
  }

  @override
  Future<void> resendOtp({required String phone, required OtpPurpose purpose}) {
    final normalized = normalizeIraqiPhone(phone);
    final key = '${purpose.name}:$normalized';
    final existing = _resendOtpInFlight[key];
    if (existing != null) return existing;

    final operation = _resendOtpTail.then<void>(
      (_) => _performResendOtp(phone: normalized, purpose: purpose),
    );
    late final Future<void> tracked;
    tracked = operation.whenComplete(() {
      if (identical(_resendOtpInFlight[key], tracked)) {
        _resendOtpInFlight.remove(key);
      }
    });
    _resendOtpInFlight[key] = tracked;
    _resendOtpTail = tracked.then<void>((_) {}, onError: (_, _) {});
    return tracked;
  }

  Future<void> _performResendOtp({
    required String phone,
    required OtpPurpose purpose,
  }) async {
    if (purpose == OtpPurpose.passwordRecovery) {
      await _requirePasswordRecoveryGate(phone);
      await _writePasswordRecoveryGate(phone);
    }
    await _guard(() async {
      switch (purpose) {
        case OtpPurpose.registration:
          await _client.auth.resend(phone: phone, type: OtpType.sms);
        case OtpPurpose.passwordRecovery:
          await _client.auth.signInWithOtp(
            phone: phone,
            shouldCreateUser: false,
            channel: OtpChannel.sms,
          );
        case OtpPurpose.phoneChange:
          await _client.auth.resend(phone: phone, type: OtpType.phoneChange);
      }
    });
  }

  @override
  Future<void> sendPasswordRecoveryOtp(String phone) async {
    final normalizedPhone = normalizeIraqiPhone(phone);
    await abandonPasswordRecovery();
    if (_client.auth.currentSession != null) {
      await signOut();
    }
    await _writePasswordRecoveryGate(normalizedPhone);
    await _guard(() async {
      await _client.auth.signInWithOtp(
        phone: normalizedPhone,
        shouldCreateUser: false,
        channel: OtpChannel.sms,
      );
    });
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    _requireOpaquePassword(newPassword, minimumLength: 8);
    final userPhone = _client.auth.currentUser?.phone;
    if (userPhone == null) {
      throw const BackendException(
        'انتهت جلسة استعادة كلمة المرور. أعد طلب الرمز.',
        code: 'password_recovery_session_missing',
      );
    }
    await _requirePasswordRecoveryGate(normalizeIraqiPhone(userPhone));
    await _guard(() async {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    });
  }

  @override
  Future<void> abandonPasswordRecovery() async {
    final encoded = await _readSecureValue(
      key: _passwordRecoveryGateKey,
      failureMessage: 'تعذر إنهاء جلسة استعادة كلمة المرور بأمان.',
      failureCode: 'password_recovery_gate_read_failed',
    );
    if (encoded == null || encoded.isEmpty) return;
    _passwordRecoveryActive = true;

    Object? signOutError;
    StackTrace? signOutStack;
    try {
      if (_client.auth.currentSession != null) {
        await _client.auth.signOut(scope: SignOutScope.local);
      }
    } catch (error, stackTrace) {
      signOutError = error;
      signOutStack = stackTrace;
    }

    if (_client.auth.currentSession == null) {
      await _deletePasswordRecoveryGate();
      return;
    }
    Error.throwWithStackTrace(
      BackendException(
        'تعذر إنهاء جلسة استعادة كلمة المرور. حاول مجدداً.',
        code: 'password_recovery_sign_out_failed',
        cause: signOutError,
      ),
      signOutStack ?? StackTrace.current,
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _deviceTokens.unregisterCurrentDevice();
    } catch (_) {
      // Logout must still complete if push cleanup cannot reach the backend.
    }
    try {
      await _guard(() => _client.auth.signOut());
    } finally {
      if (_client.auth.currentSession == null) {
        await _deletePasswordRecoveryGate();
      }
    }
  }

  Future<void> _writePasswordRecoveryGate(String normalizedPhone) async {
    final gate = _PasswordRecoveryGate(
      phone: normalizedPhone,
      createdAt: DateTime.now().toUtc(),
    );
    await _writeSecureValueVerified(
      key: _passwordRecoveryGateKey,
      value: jsonEncode(gate.toJson()),
      failureMessage: 'تعذر بدء استعادة كلمة المرور بأمان. أعد المحاولة.',
      failureCode: 'password_recovery_gate_persist_failed',
    );
    _passwordRecoveryActive = true;
  }

  Future<_PasswordRecoveryGate> _requirePasswordRecoveryGate(
    String normalizedPhone,
  ) async {
    final encoded = await _readSecureValue(
      key: _passwordRecoveryGateKey,
      failureMessage: 'تعذر قراءة جلسة استعادة كلمة المرور بأمان.',
      failureCode: 'password_recovery_gate_read_failed',
    );
    if (encoded == null || encoded.isEmpty) {
      throw const BackendException(
        'انتهت جلسة استعادة كلمة المرور. أعد طلب الرمز.',
        code: 'password_recovery_gate_missing',
      );
    }
    _passwordRecoveryActive = true;

    late final _PasswordRecoveryGate gate;
    try {
      gate = _PasswordRecoveryGate.fromJson(
        Map<String, dynamic>.from(jsonDecode(encoded) as Map),
      );
    } catch (_) {
      await abandonPasswordRecovery();
      throw const BackendException(
        'جلسة استعادة كلمة المرور غير صالحة. أعد طلب الرمز.',
        code: 'password_recovery_gate_invalid',
      );
    }
    final age = DateTime.now().toUtc().difference(gate.createdAt);
    if (age.isNegative || age > _passwordRecoveryLifetime) {
      await abandonPasswordRecovery();
      throw const BackendException(
        'انتهت جلسة استعادة كلمة المرور. أعد طلب الرمز.',
        code: 'password_recovery_gate_expired',
      );
    }
    if (gate.phone != normalizedPhone) {
      await abandonPasswordRecovery();
      throw const BackendException(
        'رقم الهاتف لا يطابق جلسة استعادة كلمة المرور.',
        code: 'password_recovery_gate_phone_mismatch',
      );
    }
    return gate;
  }

  Future<String?> _readSecureValue({
    required String key,
    required String failureMessage,
    required String failureCode,
  }) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (error) {
      throw BackendException(failureMessage, code: failureCode, cause: error);
    }
  }

  Future<void> _writeSecureValueVerified({
    required String key,
    required String value,
    required String failureMessage,
    required String failureCode,
  }) async {
    try {
      await _secureStorage.write(key: key, value: value);
      final verified = await _secureStorage.read(key: key);
      if (verified != value) {
        throw StateError('Secure write verification failed');
      }
    } catch (error) {
      throw BackendException(failureMessage, code: failureCode, cause: error);
    }
  }

  Future<void> _deletePasswordRecoveryGate() async {
    try {
      await _secureStorage.delete(key: _passwordRecoveryGateKey);
      _passwordRecoveryActive = false;
    } catch (error) {
      throw BackendException(
        'تعذر إنهاء جلسة استعادة كلمة المرور بأمان.',
        code: 'password_recovery_gate_delete_failed',
        cause: error,
      );
    }
  }

  Future<void> _registerDeviceBestEffort() async {
    try {
      await _deviceTokens.registerCurrentDevice();
    } catch (_) {
      // Push registration is secondary to authentication and durable in-app
      // notifications remain available through Supabase.
    }
  }
}

class _PendingRegistrationDraft {
  const _PendingRegistrationDraft({
    required this.phone,
    required this.fullName,
    required this.storeName,
    required this.governorateId,
    required this.termsVersion,
    required this.locale,
    required this.createdAt,
    this.instagramHandle,
  });

  factory _PendingRegistrationDraft.fromRequest(
    RegistrationRequest request, {
    required String normalizedPhone,
    required String locale,
    required String? instagramHandle,
  }) => _PendingRegistrationDraft(
    phone: normalizedPhone,
    fullName: request.fullName,
    storeName: request.storeName,
    governorateId: request.governorateId,
    termsVersion: request.termsVersion,
    locale: locale,
    createdAt: DateTime.now().toUtc(),
    instagramHandle: instagramHandle,
  );

  factory _PendingRegistrationDraft.fromJson(Map<String, dynamic> json) {
    final rawInstagram = json['instagram_handle'] as String?;
    final normalizedInstagram =
        rawInstagram == null || rawInstagram.trim().isEmpty
        ? null
        : normalizeInstagramProfile(rawInstagram);
    if (rawInstagram != null &&
        rawInstagram.trim().isNotEmpty &&
        normalizedInstagram == null) {
      throw const FormatException('Invalid Instagram profile');
    }
    return _PendingRegistrationDraft(
      phone: json['phone'] as String,
      fullName: json['full_name'] as String,
      storeName: json['store_name'] as String,
      governorateId: json['governorate_id'] as String,
      termsVersion: json['terms_version'] as String,
      locale: json['locale'] as String,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      instagramHandle: normalizedInstagram,
    );
  }

  final String phone;
  final String fullName;
  final String storeName;
  final String governorateId;
  final String termsVersion;
  final String locale;
  final DateTime createdAt;
  final String? instagramHandle;

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'full_name': fullName,
    'store_name': storeName,
    'governorate_id': governorateId,
    'terms_version': termsVersion,
    'locale': locale,
    'created_at': createdAt.toIso8601String(),
    'instagram_handle': instagramHandle,
  };
}

class _PasswordRecoveryGate {
  const _PasswordRecoveryGate({required this.phone, required this.createdAt});

  factory _PasswordRecoveryGate.fromJson(Map<String, dynamic> json) {
    final phone = json['phone'];
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    if (phone is! String || phone.isEmpty || createdAt == null) {
      throw const FormatException('Invalid password recovery gate');
    }
    return _PasswordRecoveryGate(phone: phone, createdAt: createdAt.toUtc());
  }

  final String phone;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'created_at': createdAt.toIso8601String(),
  };
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Seller> fetchCurrentProfile() async => _guard(() async {
    final userId = _requireUserId(_client);
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return _sellerFromJson(_map(row));
  });

  @override
  Future<Seller> updateCurrentProfile({
    required String name,
    required String storeName,
    required String instagramUrl,
  }) async => _guard(() async {
    final normalizedInstagram = instagramUrl.trim().isEmpty
        ? ''
        : normalizeInstagramProfile(instagramUrl);
    if (normalizedInstagram == null) {
      throw const BackendException(
        'رابط إنستغرام غير صالح. استخدم اسم المستخدم أو رابط الصفحة فقط.',
        code: 'invalid_instagram_profile',
      );
    }
    final userId = _requireUserId(_client);
    final row = await _client
        .from('profiles')
        .update({
          'full_name': name,
          'store_name': storeName,
          'instagram_handle': normalizedInstagram.isEmpty
              ? null
              : normalizedInstagram,
          'locale': appSettings.language.name,
        })
        .eq('id', userId)
        .select()
        .single();
    return _sellerFromJson(_map(row));
  });

  @override
  Future<Seller> updateSettings({
    required String locale,
    required Map<String, bool> notificationPreferences,
  }) async => _guard(() async {
    final userId = _requireUserId(_client);
    final row = await _client
        .from('profiles')
        .update({
          'locale': locale,
          'notification_preferences': notificationPreferences,
        })
        .eq('id', userId)
        .select()
        .single();
    return _sellerFromJson(_map(row));
  });

  @override
  Future<AccountDeletionRequest?> fetchLatestAccountDeletionRequest() async =>
      _guard(() async {
        final value = await _client
            .from('account_deletion_requests')
            .select()
            .order('requested_at', ascending: false)
            .limit(1)
            .maybeSingle();
        return value == null ? null : _accountDeletionFromJson(_map(value));
      });

  @override
  Future<AccountDeletionRequest> requestAccountDeletion({
    required String reason,
    required String clientRequestId,
  }) async => _guard(() async {
    final value = await _client.rpc(
      'request_account_deletion',
      params: {'p_reason': reason, 'p_idempotency_key': clientRequestId},
    );
    return _accountDeletionFromJson(_singleMap(value));
  });

  @override
  Future<AccountDeletionRequest> cancelAccountDeletion({
    required String requestId,
    required String clientRequestId,
  }) async => _guard(() async {
    final value = await _client.rpc(
      'cancel_account_deletion',
      params: {'p_request_id': requestId, 'p_idempotency_key': clientRequestId},
    );
    return _accountDeletionFromJson(_singleMap(value));
  });

  @override
  Future<void> touchLastActive() async {
    await _guard(() async {
      await _client
          .from('profiles')
          .update({'last_active_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', _requireUserId(_client));
    });
  }
}

class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._client);

  static const _catalogPageSize = 200;
  static const _relatedPageSize = 500;
  static const _productIdChunkSize = 40;
  static const _productColumns = '''
    id, category_id, name_ar, name_ckb, name_en,
    description_ar, description_ckb, description_en, specifications,
    wholesale_price, old_wholesale_price, suggested_price,
    min_sale_price, max_sale_price, is_new, created_at
  ''';
  static const _variantColumns = '''
    id, product_id, sku, name_ar, name_ckb, name_en,
    stock_on_hand, stock_reserved, wholesale_price_override,
    suggested_price_override, sort_order
  ''';
  static const _mediaColumns = '''
    id, product_id, variant_id, bucket_name, object_path,
    media_type, is_cover, sort_order
  ''';

  final SupabaseClient _client;
  final TransientReadRetry _readRetry = TransientReadRetry();

  @override
  Future<List<Category>> fetchCategories() async => _guard(() async {
    final rows = _maps(
      await _readRetry.run(
        () => _client
            .from('categories')
            .select()
            .eq('is_active', true)
            .order('sort_order')
            .retry(enabled: false),
      ),
    );
    final imageRows = rows
        .where((row) => _text(row['image_path']).isNotEmpty)
        .map(
          (row) => <String, dynamic>{
            'bucket_name': 'catalog-media',
            'object_path': row['image_path'],
          },
        );
    final urls = _resolveAuthenticatedMediaUrls(_client, imageRows);
    return [
      for (final row in rows)
        Category(
          id: _text(row['id']),
          nameAr: _text(row['name_ar']),
          nameCkb: _nullableText(row['name_ckb']),
          nameEn: _nullableText(row['name_en']),
          icon: _categoryIcon(_text(row['slug'])),
          imageUrl: urls['catalog-media|${_text(row['image_path'])}'] ?? '',
        ),
    ];
  });

  @override
  Future<List<Product>> fetchProducts() async => _guard(() async {
    final productRows = await _fetchActiveProductRows();
    if (productRows.isEmpty) return <Product>[];
    final ids = productRows.map((row) => _text(row['id'])).toList();
    final relatedRows = await Future.wait<List<Map<String, dynamic>>>([
      _fetchActiveVariantRows(ids),
      _fetchProductMediaRows(ids),
    ]);
    final variantRows = relatedRows[0];
    final mediaRows = relatedRows[1];
    final mediaUrls = _resolveAuthenticatedMediaUrls(_client, mediaRows);

    final variantsByProduct = <String, List<Map<String, dynamic>>>{};
    for (final row in variantRows) {
      variantsByProduct
          .putIfAbsent(_text(row['product_id']), () => [])
          .add(row);
    }
    final mediaByProduct = <String, List<Map<String, dynamic>>>{};
    for (final row in mediaRows) {
      mediaByProduct.putIfAbsent(_text(row['product_id']), () => []).add(row);
    }

    return [
      for (final row in productRows)
        _productFromJson(
          row,
          variantsByProduct[_text(row['id'])] ?? const [],
          mediaByProduct[_text(row['id'])] ?? const [],
          mediaUrls,
        ),
    ];
  });

  Future<List<Map<String, dynamic>>> _fetchActiveProductRows() async {
    final result = <Map<String, dynamic>>[];
    for (var offset = 0; ; offset += _catalogPageSize) {
      final page = _maps(
        await _readRetry.run(
          () => _client
              .from('products')
              .select(_productColumns)
              .eq('status', 'active')
              .order('created_at', ascending: false)
              .order('id')
              .range(offset, offset + _catalogPageSize - 1)
              .retry(enabled: false),
        ),
      );
      result.addAll(page);
      if (page.length < _catalogPageSize) break;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchActiveVariantRows(
    List<String> productIds,
  ) => _fetchRelatedRows(
    table: 'product_variants',
    columns: _variantColumns,
    productIds: productIds,
    activeOnly: true,
  );

  Future<List<Map<String, dynamic>>> _fetchProductMediaRows(
    List<String> productIds,
  ) => _fetchRelatedRows(
    table: 'product_media',
    columns: _mediaColumns,
    productIds: productIds,
  );

  Future<List<Map<String, dynamic>>> _fetchRelatedRows({
    required String table,
    required String columns,
    required List<String> productIds,
    bool activeOnly = false,
  }) async {
    final result = <Map<String, dynamic>>[];
    for (
      var chunkStart = 0;
      chunkStart < productIds.length;
      chunkStart += _productIdChunkSize
    ) {
      final chunkEnd = min(chunkStart + _productIdChunkSize, productIds.length);
      final chunk = productIds.sublist(chunkStart, chunkEnd);
      for (var offset = 0; ; offset += _relatedPageSize) {
        final page = _maps(
          await _readRetry.run(() {
            var query = _client
                .from(table)
                .select(columns)
                .inFilter('product_id', chunk);
            if (activeOnly) query = query.eq('is_active', true);
            return query
                .order('product_id')
                .order('sort_order')
                .order('id')
                .range(offset, offset + _relatedPageSize - 1)
                .retry(enabled: false);
          }),
        );
        result.addAll(page);
        if (page.length < _relatedPageSize) break;
      }
    }
    return result;
  }

  @override
  Future<Product> fetchProduct(String productId) async => _guard(() async {
    final row = _map(
      await _readRetry.run(
        () => _client
            .from('products')
            .select(_productColumns)
            .eq('id', productId)
            .eq('status', 'active')
            .single()
            .retry(enabled: false),
      ),
    );
    final relatedRows = await Future.wait<Object>([
      _readRetry.run(
        () => _client
            .from('product_variants')
            .select(_variantColumns)
            .eq('product_id', productId)
            .eq('is_active', true)
            .order('sort_order')
            .retry(enabled: false),
      ),
      _readRetry.run(
        () => _client
            .from('product_media')
            .select(_mediaColumns)
            .eq('product_id', productId)
            .order('sort_order')
            .retry(enabled: false),
      ),
    ]);
    final variantRows = _maps(relatedRows[0]);
    final mediaRows = _maps(relatedRows[1]);
    final mediaUrls = _resolveAuthenticatedMediaUrls(_client, mediaRows);
    return _productFromJson(row, variantRows, mediaRows, mediaUrls);
  });

  @override
  Stream<void> watchCatalogChanges() {
    late RealtimeChannel channel;
    late final StreamController<void> controller;

    void emitChange(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    controller = StreamController<void>.broadcast(
      onListen: () {
        channel = _client
            .channel('phone-catalog-${DateTime.now().microsecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'products',
              callback: emitChange,
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'product_variants',
              callback: emitChange,
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'product_media',
              callback: emitChange,
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'categories',
              callback: emitChange,
            )
            .subscribe();
      },
      onCancel: () async {
        await _client.removeChannel(channel);
      },
    );

    return controller.stream;
  }

  @override
  Future<List<Governorate>> fetchDeliveryZones() async => _guard(() async {
    final rows = _maps(
      await _readRetry.run(
        () => _client
            .from('delivery_zones')
            .select()
            .eq('zone_type', 'governorate')
            .eq('is_active', true)
            .order('sort_order')
            .retry(enabled: false),
      ),
    );
    return [
      for (final row in rows)
        Governorate(
          id: _text(row['id']),
          nameAr: _text(row['name_ar']),
          nameCkb: _nullableText(row['name_ckb']),
          nameEn: _nullableText(row['name_en']),
          deliveryFee: _int(row['delivery_fee']),
        ),
    ];
  });

  @override
  Future<PublicContentSnapshot> fetchPublicContent() async => _guard(() async {
    final now = DateTime.now();
    final rows =
        _maps(
          await _readRetry.run(
            () => _client
                .from('content_entries')
                .select()
                .eq('is_active', true)
                .order('sort_order')
                .retry(enabled: false),
          ),
        ).where((row) {
          final from = _dateOrNull(row['publish_from']);
          final until = _dateOrNull(row['publish_until']);
          return (from == null || !from.isAfter(now)) &&
              (until == null || until.isAfter(now));
        }).toList();

    final banners = <PromoBanner>[];
    final faq = <FaqItem>[];
    final policyContent = parsePolicyContent(
      rows,
      language: appSettings.language,
    );
    final policies = policyContent.combinedText;
    var supportPhone = '';
    var supportWhatsapp = '';
    final termsVersion = policyContent.termsVersion;
    for (final row in rows) {
      final kind = _text(row['kind']);
      final payload = _jsonMap(row['payload']);
      if (kind == 'banner') {
        final bucket = _text(payload['bucket'], fallback: 'public-content');
        final path = _text(payload['object_path']);
        final target = parseContentTarget(payload);
        banners.add(
          PromoBanner(
            id: _text(row['id']),
            imageUrl: path.isEmpty
                ? _text(payload['image_url'])
                : _client.storage.from(bucket).getPublicUrl(path),
            title: _text(row['title_ar']),
            titleCkb: _nullableText(row['title_ckb']),
            titleEn: _nullableText(row['title_en']),
            subtitle: _nullableText(row['body_ar']),
            subtitleCkb: _nullableText(row['body_ckb']),
            subtitleEn: _nullableText(row['body_en']),
            targetProductId: target.productId,
            targetCategoryId: target.categoryId,
          ),
        );
      } else if (kind == 'faq') {
        faq.add(
          FaqItem(
            question: _localized(row, 'title'),
            answer: _localized(row, 'body'),
          ),
        );
      } else if (kind == 'support_contact') {
        supportPhone = _text(payload['phone'], fallback: supportPhone);
        supportWhatsapp = _text(payload['whatsapp'], fallback: supportWhatsapp);
      }
    }
    return PublicContentSnapshot(
      banners: banners,
      faq: faq,
      policiesText: policies,
      supportPhone: supportPhone,
      supportWhatsapp: supportWhatsapp,
      termsVersion: termsVersion,
    );
  });

  @override
  Future<Set<String>> fetchFavoriteProductIds() =>
      _preferenceIds('is_favorite');

  @override
  Future<Set<String>> fetchStockAlertProductIds() =>
      _preferenceIds('notify_back_in_stock');

  Future<Set<String>> _preferenceIds(String flag) async => _guard(() async {
    final rows = _maps(
      await _readRetry.run(
        () => _client
            .from('seller_product_preferences')
            .select('product_id,$flag')
            .eq(flag, true)
            .retry(enabled: false),
      ),
    );
    return rows.map((row) => _text(row['product_id'])).toSet();
  });

  @override
  Future<void> setFavorite(String productId, {required bool enabled}) =>
      _setPreference(productId, 'is_favorite', enabled);

  @override
  Future<void> setStockAlert(String productId, {required bool enabled}) =>
      _setPreference(productId, 'notify_back_in_stock', enabled);

  Future<void> _setPreference(String productId, String flag, bool value) async {
    await _guard(() async {
      await _client.from('seller_product_preferences').upsert({
        'seller_id': _requireUserId(_client),
        'product_id': productId,
        flag: value,
      }, onConflict: 'seller_id,product_id');
    });
  }
}

class SupabaseOrdersRepository implements OrdersRepository {
  SupabaseOrdersRepository(this._client);

  final SupabaseClient _client;

  static const _orderSelect = '''
    *,
    order_items(*),
    order_events(*)
  ''';

  @override
  Future<List<Order>> fetchOrders() async => _guard(() async {
    final rows = _maps(
      await _client
          .from('orders')
          .select(_orderSelect)
          .order('created_at', ascending: false)
          .limit(250),
    );
    final itemRows = rows.expand(
      (row) => _maps(row['order_items'] ?? const <Object>[]),
    );
    final mediaUrls = _resolveAuthenticatedMediaUrls(
      _client,
      itemRows.map(
        (item) => {
          'bucket_name': item['cover_bucket_snapshot'],
          'object_path': item['cover_path_snapshot'],
        },
      ),
    );
    return [for (final row in rows) _orderFromJson(row, mediaUrls)];
  });

  @override
  Future<Order> fetchOrder(String orderId) async =>
      _guard(() => _fetchOrder(orderId));

  @override
  Future<Order> createOrder(CreateOrderRequest request) async => _guard(
    () async {
      final result = await _client.rpc(
        'create_order',
        params: {
          'p_client_request_id': request.clientRequestId,
          'p_delivery_zone_id': request.governorate.id,
          'p_customer_name': request.customerName,
          'p_customer_phone': normalizeIraqiPhone(request.customerPhone),
          'p_address_line': request.addressDetails,
          'p_items': [
            for (final item in request.items)
              {
                'variant_id': item.variant.id,
                'quantity': item.quantity,
                'unit_sale_price': request.unitSalePrice,
              },
          ],
          'p_customer_alt_phone': request.customerPhone2?.trim().isEmpty == true
              ? null
              : request.customerPhone2 == null
              ? null
              : normalizeIraqiPhone(request.customerPhone2!),
          'p_landmark': null,
          'p_delivery_notes': request.notes,
        },
      );
      final resultRow = _singleMap(result);
      final id = _text(resultRow['id']);
      if (id.isEmpty) {
        throw const BackendException('لم يُرجع الخادم معرف الطلب.');
      }
      return _fetchOrder(id);
    },
  );

  Future<Order> _fetchOrder(String id) async {
    final row = _map(
      await _client.from('orders').select(_orderSelect).eq('id', id).single(),
    );
    final itemRows = _maps(row['order_items'] ?? const <Object>[]);
    final urls = _resolveAuthenticatedMediaUrls(
      _client,
      itemRows.map(
        (item) => {
          'bucket_name': item['cover_bucket_snapshot'],
          'object_path': item['cover_path_snapshot'],
        },
      ),
    );
    return _orderFromJson(row, urls);
  }

  @override
  Future<void> cancelOrder(
    String orderId, {
    required String clientRequestId,
  }) async {
    await _guard(() async {
      await _client.rpc(
        'cancel_order',
        params: {
          'p_order_id': orderId,
          'p_idempotency_key': clientRequestId,
          'p_reason': 'seller_cancelled_before_confirmation',
        },
      );
    });
  }

  @override
  Future<void> submitChangeRequest({
    required String orderId,
    required OrderChangeRequestType type,
    required String reason,
    required Map<String, dynamic> proposedChanges,
    required String clientRequestId,
  }) async {
    final normalizedChanges = Map<String, dynamic>.from(proposedChanges);
    if (normalizedChanges['customer_phone'] case final String phone) {
      normalizedChanges['customer_phone'] = normalizeIraqiPhone(phone);
    }
    if (normalizedChanges['customer_alt_phone'] case final String altPhone) {
      normalizedChanges['customer_alt_phone'] = altPhone.trim().isEmpty
          ? null
          : normalizeIraqiPhone(altPhone);
    }
    await _guard(() async {
      await _client.rpc(
        'submit_order_change_request',
        params: {
          'p_order_id': orderId,
          'p_request_type': type.name,
          'p_idempotency_key': clientRequestId,
          'p_proposed_changes': type == OrderChangeRequestType.edit
              ? normalizedChanges
              : <String, dynamic>{},
          'p_reason': reason,
        },
      );
    });
  }
}

class SupabaseWalletRepository implements WalletRepository {
  SupabaseWalletRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<WalletSnapshot> fetchWallet() async => _guard(() async {
    final results = await Future.wait<Object?>([
      _client.from('seller_wallet_summary').select().maybeSingle(),
      _client
          .from('seller_wallet_ledger')
          .select()
          .order('created_at', ascending: false)
          .limit(300),
      _client
          .from('withdrawal_requests')
          .select()
          .order('requested_at', ascending: false)
          .limit(100),
      _client
          .from('seller_account_statement')
          .select()
          .order('order_created_at', ascending: false)
          .limit(500),
      _client
          .from('withdrawal_sources')
          .select()
          .order('created_at', ascending: false)
          .limit(500),
      fetchPayoutAccounts(),
      _walletConfiguration(),
    ]);
    final summaryValue = results[0];
    final summary = summaryValue == null
        ? <String, dynamic>{}
        : _map(summaryValue);
    final ledgerRows = _maps(results[1]);
    final withdrawalRows = _maps(results[2]);
    final statementRows = _maps(results[3]);
    final sourceRows = _maps(results[4]);
    final payoutAccounts = results[5]! as List<PayoutAccount>;
    final walletConfiguration =
        results[6]! as ({int minimumWithdrawal, Map<String, int> transferFees});
    return WalletSnapshot(
      available: _int(summary['available_balance']),
      pending: _int(summary['pending_balance']),
      totalEarned: _int(summary['total_earned']),
      minimumWithdrawal: walletConfiguration.minimumWithdrawal,
      withdrawalFees: walletConfiguration.transferFees,
      transactions: walletTransactionsFromLedgerRows(ledgerRows),
      withdrawals: withdrawalRows.map(_withdrawalFromJson).toList(),
      payoutAccounts: payoutAccounts,
      statementLines: statementRows.map(_statementLineFromJson).toList(),
      withdrawalSources: sourceRows.map(_withdrawalSourceFromJson).toList(),
    );
  });

  @override
  Stream<void> watchWalletChanges() {
    final sellerId = _client.auth.currentUser?.id;
    if (sellerId == null) return const Stream<void>.empty();

    late RealtimeChannel channel;
    late final StreamController<void> controller;

    void emitChange(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    final sellerFilter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'seller_id',
      value: sellerId,
    );

    controller = StreamController<void>.broadcast(
      onListen: () {
        channel = _client
            .channel('phone-wallet-${DateTime.now().microsecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'wallet_ledger_entries',
              filter: sellerFilter,
              callback: emitChange,
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'withdrawal_requests',
              filter: sellerFilter,
              callback: emitChange,
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'payout_accounts',
              filter: sellerFilter,
              callback: emitChange,
            )
            .subscribe();
      },
      onCancel: () async {
        await _client.removeChannel(channel);
      },
    );

    return controller.stream;
  }

  @override
  Future<List<PayoutAccount>> fetchPayoutAccounts() async => _guard(() async {
    final rows = _maps(
      await _client
          .from('payout_accounts')
          .select()
          .order('is_default', ascending: false)
          .order('created_at', ascending: false),
    );
    return rows.map(_payoutAccountFromJson).toList();
  });

  @override
  Future<PayoutAccount> upsertPayoutAccount(
    SavePayoutAccountRequest request,
  ) async {
    try {
      return await _guard(() async {
        final value = await _client.rpc(
          'upsert_payout_account',
          params: {
            'p_account_id': request.accountId,
            'p_provider': _providerCode(request.provider),
            'p_account_holder_name': request.accountHolderName,
            'p_account_identifier': request.accountIdentifier,
            'p_make_default': request.makeDefault,
          },
        );
        return _payoutAccountFromJson(_singleMap(value));
      });
    } on BackendException catch (_) {
      // A transport failure can happen after the insert committed. A retry of
      // this logical upsert would then hit the unique provider/identifier key.
      // Recover only an exact match so a different account is never mistaken
      // for the requested mutation.
      if (request.accountId == null) {
        try {
          final provider = _providerCode(request.provider);
          final identifier = request.accountIdentifier.trim();
          final holder = request.accountHolderName.trim();
          final accounts = await fetchPayoutAccounts();
          for (final account in accounts) {
            final defaultMatches = !request.makeDefault || account.isDefault;
            if (account.provider == provider &&
                account.accountIdentifier.trim() == identifier &&
                account.accountHolderName.trim() == holder &&
                defaultMatches) {
              return account;
            }
          }
        } catch (_) {
          // Preserve the original mutation error if recovery cannot read.
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> deletePayoutAccount(String accountId) async {
    await _guard(() async {
      await _client.rpc(
        'delete_payout_account',
        params: {'p_account_id': accountId},
      );
    });
  }

  Future<({int minimumWithdrawal, Map<String, int> transferFees})>
  _walletConfiguration() async {
    final row = await _client
        .from('content_entries')
        .select('payload')
        .eq('kind', 'platform_config')
        .eq('key', 'wallet')
        .eq('is_active', true)
        .order('version', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) {
      return (
        minimumWithdrawal: 10000,
        transferFees: const <String, int>{'zain_cash': 0, 'superqi': 0},
      );
    }
    final payload = _jsonMap(_map(row)['payload']);
    final configured = _int(
      payload['minimum_withdrawal_amount'],
      fallback: 10000,
    );
    final rawFees = _jsonMap(payload['transfer_fees']);
    int fee(String provider) {
      final value = _int(rawFees[provider]);
      return value < 0 ? 0 : value;
    }

    return (
      minimumWithdrawal: configured > 0 ? configured : 10000,
      transferFees: <String, int>{
        'zain_cash': fee('zain_cash'),
        'superqi': fee('superqi'),
      },
    );
  }

  @override
  Future<Withdrawal> requestWithdrawal(CreateWithdrawalRequest request) async =>
      _guard(() async {
        final payoutId = request.payoutAccountId;
        if (payoutId == null || payoutId.isEmpty) {
          throw const BackendException(
            'اختر حساب استلام موثق. أضف الحساب أولاً وانتظر موافقة الإدارة.',
          );
        }
        final value = await _client.rpc(
          'request_withdrawal',
          params: {
            'p_amount': request.amount,
            'p_payout_account_id': payoutId,
            'p_idempotency_key': request.clientRequestId,
          },
        );
        return _withdrawalFromJson(_singleMap(value));
      });

  @override
  Future<Withdrawal> cancelWithdrawal(
    String withdrawalId, {
    required String clientRequestId,
  }) async => _guard(() async {
    final value = await _client.rpc(
      'cancel_withdrawal',
      params: {
        'p_withdrawal_id': withdrawalId,
        'p_idempotency_key': clientRequestId,
      },
    );
    return _withdrawalFromJson(_singleMap(value));
  });
}

class SupabaseNotificationsRepository implements NotificationsRepository {
  SupabaseNotificationsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AppNotification>> fetchNotifications() async => _guard(() async {
    final rows = _maps(
      await _client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(200),
    );
    return rows.map(_notificationFromJson).toList();
  });

  @override
  Future<void> markRead(String notificationId) async {
    await _guard(() async {
      await _client
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', notificationId);
    });
  }

  @override
  Future<void> markAllRead() async {
    await _guard(() async {
      await _client
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('recipient_id', _requireUserId(_client))
          .isFilter('read_at', null);
    });
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    late RealtimeChannel channel;
    late final StreamController<List<AppNotification>> controller;
    var loading = false;
    var refreshQueued = false;

    Future<void> emitLatest() async {
      if (loading) {
        refreshQueued = true;
        return;
      }
      loading = true;
      try {
        do {
          refreshQueued = false;
          try {
            final latest = await fetchNotifications();
            if (!controller.isClosed) controller.add(latest);
          } catch (error, stackTrace) {
            if (!controller.isClosed) controller.addError(error, stackTrace);
          }
        } while (refreshQueued && !controller.isClosed);
      } finally {
        loading = false;
      }
    }

    controller = StreamController<List<AppNotification>>.broadcast(
      onListen: () {
        channel = _client
            .channel(
              'phone-notifications-${DateTime.now().microsecondsSinceEpoch}',
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'recipient_id',
                value: userId,
              ),
              callback: (_) => unawaited(emitLatest()),
            )
            .subscribe();
      },
      onCancel: () async {
        await _client.removeChannel(channel);
      },
    );
    return controller.stream;
  }
}

Seller _sellerFromJson(Map<String, dynamic> row) => Seller(
  id: _text(row['id']),
  name: _text(row['full_name']),
  phone: _text(row['display_phone']),
  storeName: _text(row['store_name']),
  instagramUrl: _text(row['instagram_handle']),
  governorateId: _text(row['governorate']),
  status: _accountStatus(_text(row['status'])),
  joinedAt: _date(row['created_at']),
  statusReason: _nullableText(row['review_reason']),
  locale: _text(row['locale'], fallback: 'ar'),
  notificationPreferences: _jsonMap(
    row['notification_preferences'],
  ).map((key, value) => MapEntry(key, _bool(value))),
);

AccountDeletionRequest _accountDeletionFromJson(Map<String, dynamic> row) =>
    AccountDeletionRequest(
      id: _text(row['id']),
      status: switch (_text(row['status'])) {
        'approved' => AccountDeletionStatus.approved,
        'rejected' => AccountDeletionStatus.rejected,
        'cancelled' => AccountDeletionStatus.cancelled,
        _ => AccountDeletionStatus.pending,
      },
      reason: _text(row['reason']),
      decisionReason: _nullableText(row['decision_reason']),
      requestedAt: _date(row['requested_at']),
      decidedAt: _dateOrNull(row['decided_at']),
      cancelledAt: _dateOrNull(row['cancelled_at']),
    );

Product _productFromJson(
  Map<String, dynamic> row,
  List<Map<String, dynamic>> variants,
  List<Map<String, dynamic>> media,
  Map<String, String> mediaUrls,
) {
  final imageRows =
      media.where((item) => _text(item['media_type']) == 'image').toList()
        ..sort((a, b) {
          final coverCompare = _bool(a['is_cover']) == _bool(b['is_cover'])
              ? 0
              : (_bool(a['is_cover']) ? -1 : 1);
          return coverCompare != 0
              ? coverCompare
              : _int(a['sort_order']).compareTo(_int(b['sort_order']));
        });
  final productThumbnailUrl = imageRows.isEmpty
      ? null
      : mediaUrls['${_text(imageRows.first['bucket_name'])}|${_text(imageRows.first['object_path'])}'];
  final mappedMedia = [
    for (final item in media)
      MediaItem(
        id: _text(item['id']),
        type: _text(item['media_type']) == 'video'
            ? MediaType.video
            : MediaType.image,
        url:
            mediaUrls['${_text(item['bucket_name'])}|${_text(item['object_path'])}'] ??
            '',
        thumbnailUrl: _text(item['media_type']) == 'video'
            ? productThumbnailUrl
            : null,
      ),
  ];
  mappedMedia.sort((a, b) {
    final aRow = media.firstWhere((row) => _text(row['id']) == a.id);
    final bRow = media.firstWhere((row) => _text(row['id']) == b.id);
    final aCover = _bool(aRow['is_cover']);
    final bCover = _bool(bRow['is_cover']);
    final coverCompare = aCover == bCover ? 0 : (aCover ? -1 : 1);
    return coverCompare != 0
        ? coverCompare
        : _int(aRow['sort_order']).compareTo(_int(bRow['sort_order']));
  });
  return Product(
    id: _text(row['id']),
    nameAr: _text(row['name_ar']),
    nameCkb: _nullableText(row['name_ckb']),
    nameEn: _nullableText(row['name_en']),
    categoryId: _text(row['category_id']),
    description: _text(row['description_ar']),
    descriptionCkb: _nullableText(row['description_ckb']),
    descriptionEn: _nullableText(row['description_en']),
    specs: _jsonMap(
      row['specifications'],
    ).map((key, value) => MapEntry(key, value?.toString() ?? '')),
    media: mappedMedia,
    variants: [
      for (final item in variants)
        ProductVariant(
          id: _text(item['id']),
          sku: _nullableText(item['sku']),
          nameAr: _text(item['name_ar']),
          nameCkb: _nullableText(item['name_ckb']),
          nameEn: _nullableText(item['name_en']),
          imageUrl: _variantImage(item, media, mediaUrls),
          stock: (_int(item['stock_on_hand']) - _int(item['stock_reserved']))
              .clamp(0, 1 << 31),
          wholesalePriceOverride: _intOrNull(item['wholesale_price_override']),
          suggestedPriceOverride: _intOrNull(item['suggested_price_override']),
        ),
    ],
    wholesalePrice: _int(row['wholesale_price']),
    oldWholesalePrice: _intOrNull(row['old_wholesale_price']),
    suggestedPrice: _int(row['suggested_price']),
    minSalePrice: _intOrNull(row['min_sale_price']),
    maxSalePrice: _intOrNull(row['max_sale_price']),
    isNew: _bool(row['is_new']),
    createdAt: _date(row['created_at']),
  );
}

String _variantImage(
  Map<String, dynamic> variant,
  List<Map<String, dynamic>> media,
  Map<String, String> urls,
) {
  final variantId = _text(variant['id']);
  Map<String, dynamic>? selected;
  for (final item in media) {
    if (_text(item['variant_id']) == variantId &&
        _text(item['media_type']) == 'image') {
      selected = item;
      if (_bool(item['is_cover'])) break;
    }
  }
  if (selected == null) return '';
  return urls['${_text(selected['bucket_name'])}|${_text(selected['object_path'])}'] ??
      '';
}

Order _orderFromJson(Map<String, dynamic> row, Map<String, String> mediaUrls) {
  final itemRows = _maps(row['order_items'] ?? const <Object>[]);
  final eventRows = _maps(row['order_events'] ?? const <Object>[])
    ..sort((a, b) => _date(a['created_at']).compareTo(_date(b['created_at'])));
  final items = [
    for (final item in itemRows)
      OrderItem(
        variantId: _text(item['variant_id']),
        variantName: _localized(item, 'variant_name'),
        imageUrl:
            mediaUrls['${_text(item['cover_bucket_snapshot'])}|'
                '${_text(item['cover_path_snapshot'])}'] ??
            '',
        quantity: _int(item['quantity']),
        wholesaleUnitPrice: _int(item['unit_wholesale_price']),
        saleUnitPrice: _int(item['unit_sale_price']),
      ),
  ];
  final firstItem = itemRows.isEmpty ? <String, dynamic>{} : itemRows.first;
  return Order(
    id: _text(row['id']),
    code: _text(row['order_number']),
    productId: _text(firstItem['product_id']),
    productName: _localized(firstItem, 'product_name'),
    productImage: items.isEmpty ? '' : items.first.imageUrl,
    items: items,
    wholesalePrice: _int(
      firstItem['unit_wholesale_price'],
      fallback: items.isEmpty ? 0 : items.first.wholesaleUnitPrice ?? 0,
    ),
    unitSalePrice: _int(
      firstItem['unit_sale_price'],
      fallback: items.isEmpty ? 0 : items.first.saleUnitPrice ?? 0,
    ),
    deliveryFee: _int(row['delivery_fee']),
    customerName: _text(row['customer_name']),
    customerPhone: _text(row['customer_phone']),
    customerPhone2: _nullableText(row['customer_alt_phone']),
    governorateName: _text(
      row['governorate_name_snapshot'],
      fallback: _text(row['governorate_name']),
    ),
    regionName: _text(row['area_name_snapshot']),
    addressDetails: _text(row['address_line']),
    landmark: _nullableText(row['landmark']),
    notes: _nullableText(row['delivery_notes']),
    deliveryCompany: _nullableText(row['delivery_company']),
    trackingNumber: _nullableText(row['tracking_number']),
    status: _orderStatus(_text(row['status'])),
    statusHistory: [
      for (final event in eventRows)
        OrderStatusEntry(
          status: _orderStatus(_text(event['to_status'])),
          at: _date(event['created_at']),
          note: _nullableText(event['description']),
        ),
    ],
    failReason: _nullableText(row['failure_reason']),
    createdAt: _date(row['created_at']),
    storeNameSnapshot: _text(row['store_name_snapshot']),
    sellerPhoneSnapshot: _text(row['seller_phone_snapshot']),
  );
}

Withdrawal _withdrawalFromJson(Map<String, dynamic> row) => Withdrawal(
  id: _text(row['id']),
  amount: _int(row['amount']),
  method: _providerLabel(_text(row['provider_snapshot'])),
  accountDetail: _text(row['account_identifier_snapshot']),
  transferFee: _int(row['transfer_fee']),
  status: switch (_text(row['status'])) {
    'approved' => WithdrawalStatus.approved,
    'paid' => WithdrawalStatus.paid,
    'rejected' => WithdrawalStatus.rejected,
    'cancelled' => WithdrawalStatus.cancelled,
    _ => WithdrawalStatus.pending,
  },
  requestedAt: _date(row['requested_at']),
  processedAt:
      _dateOrNull(row['paid_at']) ??
      _dateOrNull(row['rejected_at']) ??
      _dateOrNull(row['reviewed_at']),
  rejectReason: _nullableText(row['decision_note']),
);

PayoutAccount _payoutAccountFromJson(Map<String, dynamic> row) => PayoutAccount(
  id: _text(row['id']),
  provider: _text(row['provider']),
  accountHolderName: _text(row['account_holder_name']),
  accountIdentifier: _text(row['account_identifier']),
  identifierLast4: _text(row['identifier_last4']),
  isVerified: _bool(row['is_verified']),
  isDefault: _bool(row['is_default']),
);

AccountStatementLine _statementLineFromJson(Map<String, dynamic> row) =>
    AccountStatementLine(
      orderItemId: _text(row['order_item_id']),
      orderId: _text(row['order_id']),
      orderCode: _text(row['order_number']),
      orderStatus: _orderStatus(_text(row['order_status'])),
      orderCreatedAt: _date(row['order_created_at']),
      completedAt: _dateOrNull(row['completed_at']),
      productNameAr: _text(row['product_name_ar']),
      productNameCkb: _nullableText(row['product_name_ckb']),
      productNameEn: _nullableText(row['product_name_en']),
      variantNameAr: _text(row['variant_name_ar']),
      variantNameCkb: _nullableText(row['variant_name_ckb']),
      variantNameEn: _nullableText(row['variant_name_en']),
      sku: _nullableText(row['sku_snapshot']),
      quantity: _int(row['quantity']),
      unitWholesalePrice: _int(row['unit_wholesale_price']),
      unitSalePrice: _int(row['unit_sale_price']),
      unitProfit: _int(row['unit_profit']),
      lineWholesaleTotal: _int(row['line_wholesale_total']),
      lineSaleTotal: _int(row['line_sale_total']),
      lineProfitTotal: _int(row['line_profit_total']),
    );

WithdrawalSourceLine _withdrawalSourceFromJson(Map<String, dynamic> row) =>
    WithdrawalSourceLine(
      withdrawalId: _text(row['withdrawal_id']),
      sourceEntryId: _text(row['source_entry_id']),
      allocatedAmount: _int(row['allocated_amount']),
      orderId: _text(row['order_id']),
      orderCode: _text(row['order_number']),
      productNameAr: _text(row['product_name_ar']),
      productNameCkb: _nullableText(row['product_name_ckb']),
      productNameEn: _nullableText(row['product_name_en']),
      variantNameAr: _text(row['variant_name_ar']),
      variantNameCkb: _nullableText(row['variant_name_ckb']),
      variantNameEn: _nullableText(row['variant_name_en']),
      quantity: _int(row['quantity']),
      unitWholesalePrice: _int(row['unit_wholesale_price']),
      unitSalePrice: _int(row['unit_sale_price']),
      lineProfitTotal: _int(row['line_profit_total']),
      createdAt: _date(row['created_at']),
    );

AppNotification _notificationFromJson(Map<String, dynamic> row) {
  final payload = _jsonMap(row['payload']);
  return AppNotification(
    id: _text(row['id']),
    title: _localized(row, 'title'),
    body: _localized(row, 'body'),
    type: switch (_text(row['notification_type'])) {
      final type when type.contains('order') => NotificationType.order,
      final type when type.contains('wallet') || type.contains('withdrawal') =>
        NotificationType.wallet,
      final type when type.contains('product') || type.contains('stock') =>
        NotificationType.product,
      _ => NotificationType.system,
    },
    at: _date(row['created_at']),
    isRead: row['read_at'] != null,
    targetOrderId:
        _nullableText(row['order_id']) ?? _nullableText(payload['order_id']),
    targetProductId: _nullableText(payload['product_id']),
  );
}

Map<String, String> _resolveAuthenticatedMediaUrls(
  SupabaseClient client,
  Iterable<Map<String, dynamic>> rows,
) {
  final urls = <String, String>{};
  for (final row in rows) {
    final bucket = _text(row['bucket_name']);
    final path = _text(row['object_path']);
    if (bucket.isEmpty || path.isEmpty) continue;
    urls['$bucket|$path'] = _authenticatedStorageObjectUrl(
      client,
      bucket,
      path,
    );
  }
  return urls;
}

String _authenticatedStorageObjectUrl(
  SupabaseClient client,
  String bucket,
  String path,
) {
  // getPublicUrl performs the Storage client's segment-by-segment encoding.
  // Replacing only the access route yields the documented stable private URL;
  // AppNetworkImage/ProductVideoPlayer attach the current JWT at request time.
  return client.storage
      .from(bucket)
      .getPublicUrl(path)
      .replaceFirst('/object/public/', '/object/authenticated/');
}

AccountStatus _accountStatus(String value) => switch (value) {
  'active' || 'approved' => AccountStatus.approved,
  'rejected' => AccountStatus.rejected,
  'blocked' => AccountStatus.blocked,
  'deleted' => AccountStatus.deleted,
  _ => AccountStatus.pending,
};

OrderStatus _orderStatus(String value) => switch (value) {
  'confirmed' => OrderStatus.confirmed,
  'shipped' => OrderStatus.shipped,
  'delivered' => OrderStatus.delivered,
  'completed' => OrderStatus.completed,
  'delivery_failed' => OrderStatus.deliveryFailed,
  'returning' => OrderStatus.returning,
  'returned' => OrderStatus.returned,
  'rejected' => OrderStatus.rejected,
  'cancelled' => OrderStatus.cancelled,
  _ => OrderStatus.pendingReview,
};

IconData _categoryIcon(String slug) {
  if (slug.contains('watch') || slug.contains('ساع')) return Icons.watch;
  if (slug.contains('glass') || slug.contains('نظر')) {
    return Icons.visibility_outlined;
  }
  if (slug.contains('access')) return Icons.diamond_outlined;
  return Icons.category_outlined;
}

String _providerCode(String label) {
  final value = label.toLowerCase();
  if (value.contains('زين') || value.contains('zain')) return 'zain_cash';
  if (value.contains('سوبر') || value.contains('super')) return 'superqi';
  if (value.contains('ماستر') || value.contains('master')) return 'mastercard';
  return 'other';
}

String _providerLabel(String value) => switch (value) {
  'zain_cash' => 'زين كاش',
  'superqi' => 'سوبر كي',
  'mastercard' => 'ماستر كارد',
  _ => value,
};

String _localized(Map<String, dynamic> row, String prefix) {
  final preferred = switch (appSettings.language) {
    AppLanguage.ar => row['${prefix}_ar'],
    AppLanguage.ckb => row['${prefix}_ckb'],
    AppLanguage.en => row['${prefix}_en'],
  };
  return _text(preferred, fallback: _text(row['${prefix}_ar']));
}

String _requireUserId(SupabaseClient client) {
  final id = client.auth.currentUser?.id;
  if (id == null) {
    throw const BackendException('انتهت الجلسة. سجل الدخول مجدداً.');
  }
  return id;
}

Map<String, dynamic> _map(Object? value) => value is Map<String, dynamic>
    ? value
    : Map<String, dynamic>.from(value! as Map);

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value.map((item) => _map(item)).toList()
    : const <Map<String, dynamic>>[];

Map<String, dynamic> _singleMap(Object? value) {
  if (value is List) {
    if (value.isEmpty) return <String, dynamic>{};
    return _map(value.first);
  }
  return _map(value);
}

Map<String, dynamic> _jsonMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(Object? value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

int _int(Object? value, {int fallback = 0}) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String text => int.tryParse(text) ?? fallback,
  _ => fallback,
};

int? _intOrNull(Object? value) => value == null ? null : _int(value);

bool _bool(Object? value) => value == true || value == 1 || value == 'true';

DateTime _date(Object? value) =>
    _dateOrNull(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

DateTime? _dateOrNull(Object? value) => value is DateTime
    ? value.toLocal()
    : DateTime.tryParse(value?.toString() ?? '')?.toLocal();

void _requireOpaquePassword(String password, {int? minimumLength}) {
  if (password.isEmpty) {
    throw const BackendException(
      'كلمة المرور مطلوبة.',
      code: 'password_required',
    );
  }
  if (password != password.trim()) {
    throw const BackendException(
      'لا تضع مسافة في بداية أو نهاية كلمة المرور.',
      code: 'password_surrounding_whitespace',
    );
  }
  if (minimumLength != null && password.length < minimumLength) {
    throw BackendException(
      'كلمة المرور يجب أن تكون $minimumLength خانات على الأقل.',
      code: 'password_too_short',
    );
  }
}

Future<T> _guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on BackendException {
    rethrow;
  } on AuthException catch (error) {
    throw BackendException(
      _authMessage(error.message),
      code: error.code ?? error.statusCode,
      cause: error,
    );
  } on PostgrestException catch (error) {
    throw BackendException(
      _postgrestMessage(error),
      code: error.code,
      cause: error,
    );
  } on StorageException catch (error) {
    throw BackendException(
      'تعذر تحميل ملفات المنتج. حاول مرة أخرى.',
      cause: error,
    );
  } catch (error) {
    throw BackendException(
      'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.',
      cause: error,
    );
  }
}

String _postgrestMessage(PostgrestException error) {
  final message = error.message.toLowerCase();
  const messages = <String, String>{
    'authentication required': 'انتهت الجلسة. سجل الدخول مجدداً.',
    'active seller account required':
        'الحساب غير مفعّل للبيع حالياً. راجع حالة حسابك.',
    'registration fields are required': 'أكمل جميع بيانات التسجيل المطلوبة.',
    'verified phone is required': 'يجب تأكيد رقم الهاتف أولاً.',
    'active governorate is required':
        'المحافظة المختارة غير متاحة حالياً. اختر محافظة أخرى.',
    'registration cannot be completed from current state':
        'لا يمكن إكمال التسجيل بحالة الحساب الحالية.',
    'seller account cannot request deletion from its current state':
        'لا يمكن طلب حذف الحساب بحالته الحالية.',
    'account deletion request not found': 'طلب حذف الحساب غير موجود.',
    'only a pending deletion request can be cancelled':
        'يمكن إلغاء طلب حذف الحساب عندما يكون قيد المراجعة فقط.',
    'account holder and identifier are required':
        'اسم صاحب الحساب ورقم الحساب مطلوبان.',
    'payout account not found or already used':
        'لا يمكن حذف حساب الاستلام لأنه غير موجود أو مرتبط بسحب سابق.',
    'payout account not found': 'حساب الاستلام غير موجود.',
    'verified payout account is required':
        'يجب أن توافق الإدارة على حساب الاستلام قبل طلب السحب.',
    'withdrawals are temporarily disabled':
        'طلبات السحب متوقفة مؤقتاً. حاول لاحقاً.',
    'withdrawal amount is below the configured minimum':
        'المبلغ أقل من الحد الأدنى المسموح للسحب.',
    'insufficient available balance': 'الرصيد المتاح لا يكفي لهذا السحب.',
    'withdrawal not found': 'طلب السحب غير موجود.',
    'only a pending withdrawal can be cancelled':
        'يمكن إلغاء طلب السحب عندما يكون قيد المراجعة فقط.',
    'customer name and address are required':
        'اسم الزبون والعنوان التفصيلي مطلوبان.',
    'active delivery area is required':
        'المحافظة المختارة غير متاحة حالياً. اختر محافظة أخرى.',
    'a variant may appear only once per order':
        'لا يمكن تكرار نفس خيار المنتج داخل الطلب.',
    'one or more variants do not exist':
        'أحد خيارات المنتج لم يعد موجوداً. حدّث المنتجات وحاول مجدداً.',
    'item quantity must be positive': 'يجب أن تكون كمية المنتج أكبر من صفر.',
    'product or variant is not active': 'المنتج أو الخيار لم يعد متاحاً للبيع.',
    'insufficient stock for variant':
        'الكمية المطلوبة غير متوفرة حالياً. قلّل الكمية وحاول مجدداً.',
    'sale price is outside the allowed range':
        'سعر البيع خارج الحدود التي حددتها الإدارة.',
    'order not found': 'الطلب غير موجود أو لا تملك صلاحية الوصول إليه.',
    'seller can directly cancel only a pending-review order':
        'الإلغاء المباشر متاح فقط قبل تأكيد الطلب.',
    'order can no longer be changed or cancelled':
        'لم يعد بالإمكان تعديل هذا الطلب أو إلغاؤه.',
    'edit request needs proposed changes':
        'أدخل التعديلات المطلوبة قبل إرسال الطلب.',
    'cancellation reason is required': 'اكتب سبب إلغاء الطلب.',
    'idempotency key is required': 'تعذر تأمين العملية. حاول مرة أخرى.',
    'client request id was already used with another order payload':
        'هذا الطلب أُرسل سابقاً ببيانات مختلفة. راجع سجل الطلبات قبل إنشاء طلب جديد.',
    'idempotency key was already used with another withdrawal payload':
        'طلب السحب أُرسل سابقاً ببيانات مختلفة. حدّث سجل السحوبات وتأكد من الطلب السابق.',
    'idempotency key was already used with another change request payload':
        'تم إرسال طلب تعديل سابق ببيانات مختلفة. حدّث الطلب وتأكد من نتيجة الإرسال قبل المحاولة مجدداً.',
    'idempotency key was already used with another deletion request payload':
        'تم إرسال طلب حذف سابق ببيانات مختلفة. حدّث حالة الحساب قبل المحاولة مجدداً.',
    'idempotency key was already used with another request payload':
        'تم تنفيذ محاولة سابقة ببيانات مختلفة. حدّث الصفحة وتأكد من النتيجة قبل المحاولة مجدداً.',
  };
  for (final entry in messages.entries) {
    if (message.contains(entry.key)) return entry.value;
  }
  if (error.code == '42501') {
    return 'ليست لديك صلاحية لتنفيذ هذه العملية بحالة الحساب الحالية.';
  }
  if (error.code == '23514' || error.code == '22023') {
    return 'بعض البيانات غير مقبولة. راجع الحقول وحاول مرة أخرى.';
  }
  if (error.code == 'PGRST116' || error.code == 'P0002') {
    return 'لم يتم العثور على السجل المطلوب.';
  }
  return 'تعذر تنفيذ العملية على الخادم. حاول مرة أخرى.';
}

String _authMessage(String message) {
  final normalized = message.toLowerCase();
  if (normalized.contains('invalid login credentials')) {
    return 'رقم الهاتف أو كلمة المرور غير صحيحة.';
  }
  if (normalized.contains('otp') || normalized.contains('token')) {
    return 'رمز التحقق غير صحيح أو انتهت صلاحيته.';
  }
  if (normalized.contains('already registered')) {
    return 'رقم الهاتف مسجل مسبقاً.';
  }
  if (normalized.contains('rate limit')) {
    return 'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.';
  }
  return 'تعذر إكمال المصادقة. حاول مرة أخرى.';
}
