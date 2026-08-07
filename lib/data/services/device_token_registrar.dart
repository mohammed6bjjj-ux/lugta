import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/request_id.dart';

void _pushDebug(String message) {
  if (kDebugMode) debugPrint('[Push] $message');
}

abstract interface class DeviceTokenRegistrar {
  /// Full foreground payload used by the in-app refresh listener today and by
  /// a platform local-notification presenter in the future.
  Stream<PushMessage> get foregroundMessages;

  /// Emits notification taps received while the app was in the background.
  ///
  /// A tap that launches a terminated app is retained until the authenticated
  /// shell is ready and calls [takePendingNotificationOpen].
  Stream<PushOpenEvent> get notificationOpens;

  PushOpenEvent? takePendingNotificationOpen();

  /// Feeds a local-notification tap into the same navigation path as an FCM
  /// background/terminated tap.
  void handleNotificationOpen(PushOpenEvent event);

  Future<void> initialize();

  Future<void> registerCurrentDevice();

  Future<void> unregisterCurrentDevice();

  Future<void> dispose();
}

class NoopDeviceTokenRegistrar implements DeviceTokenRegistrar {
  const NoopDeviceTokenRegistrar();

  @override
  Stream<PushMessage> get foregroundMessages => const Stream.empty();

  @override
  Stream<PushOpenEvent> get notificationOpens => const Stream.empty();

  @override
  PushOpenEvent? takePendingNotificationOpen() => null;

  @override
  void handleNotificationOpen(PushOpenEvent event) {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> registerCurrentDevice() async {}

  @override
  Future<void> unregisterCurrentDevice() async {}

  @override
  Future<void> dispose() async {}
}

abstract interface class PushMessagingClient {
  Stream<String> get tokenRefreshes;

  Stream<PushMessage> get foregroundMessages;

  Stream<PushOpenEvent> get openedMessages;

  Future<PushOpenEvent?> getInitialNotificationOpen();

  Future<bool> requestPermission();

  Future<String?> getToken();

  Future<void> deleteToken();

  Future<void> configureForegroundPresentation();
}

abstract interface class ForegroundNotificationPresenter {
  Future<void> initialize({
    required void Function(PushOpenEvent event) onNotificationOpen,
  });

  Future<void> show(PushMessage message);

  Future<void> dispose();
}

class NoopForegroundNotificationPresenter
    implements ForegroundNotificationPresenter {
  const NoopForegroundNotificationPresenter();

  @override
  Future<void> initialize({
    required void Function(PushOpenEvent event) onNotificationOpen,
  }) async {}

  @override
  Future<void> show(PushMessage message) async {}

  @override
  Future<void> dispose() async {}
}

abstract interface class DeviceTokenBackend {
  bool get hasAuthenticatedUser;

  Future<void> registerToken({
    required String deviceId,
    required String platform,
    required String token,
  });

  Future<void> unregisterToken(String token);
}

abstract interface class DeviceTokenLocalStore {
  Future<String> getOrCreateDeviceId();

  Future<String?> readLastToken();

  Future<void> writeLastToken(String token);

  Future<void> clearLastToken();

  Future<String?> readPendingDeletionToken();

  Future<void> writePendingDeletionToken(String token);

  Future<void> clearPendingDeletionToken();
}

/// The trusted subset of an FCM data payload used for in-app navigation.
///
/// IDs are resolved against the current authenticated session before opening a
/// screen, so a push payload can never inject a route or an arbitrary object.
class PushOpenEvent {
  const PushOpenEvent({
    this.notificationId,
    this.orderId,
    this.productId,
    this.promotionId,
    this.targetType,
    this.deepLink,
  });

  factory PushOpenEvent.fromData(Map<String, dynamic> data) => PushOpenEvent(
    notificationId: _firstPayloadText(data, const ['notification_id']),
    orderId: _firstPayloadText(data, const ['order_id', 'target_order_id']),
    productId: _firstPayloadText(data, const [
      'product_id',
      'target_product_id',
    ]),
    promotionId: _firstPayloadText(data, const [
      'promotion_id',
      'target_promotion_id',
    ]),
    targetType: _firstPayloadText(data, const ['target_type']),
    deepLink: _firstPayloadText(data, const ['deep_link']),
  );

  final String? notificationId;
  final String? orderId;
  final String? productId;
  final String? promotionId;
  final String? targetType;
  final String? deepLink;
}

/// Platform-neutral message data for foreground presentation.
class PushMessage {
  PushMessage({this.title, this.body, Map<String, dynamic> data = const {}})
    : data = Map<String, dynamic>.unmodifiable(data);

  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  PushOpenEvent get openEvent => PushOpenEvent.fromData(data);

  String get presentationKey {
    final notificationId = openEvent.notificationId;
    if (notificationId != null) return 'notification:$notificationId';
    final canonicalData = SplayTreeMap<String, String>();
    canonicalData.addEntries(
      data.entries.map(
        (entry) => MapEntry(entry.key, entry.value?.toString() ?? 'null'),
      ),
    );
    return jsonEncode({
      'title': title?.trim(),
      'body': body?.trim(),
      'data': canonicalData,
    });
  }

  int get localNotificationId => _stablePositiveHash(presentationKey);
}

int _stablePositiveHash(String value) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

String? _firstPayloadText(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is! String) continue;
    final normalized = value.trim();
    if (normalized.isNotEmpty) return normalized;
  }
  return null;
}

class FirebaseDeviceTokenRegistrar implements DeviceTokenRegistrar {
  factory FirebaseDeviceTokenRegistrar({
    required PushMessagingClient messaging,
    required DeviceTokenBackend backend,
    required DeviceTokenLocalStore localStore,
    required String platform,
    ForegroundNotificationPresenter foregroundPresenter =
        const NoopForegroundNotificationPresenter(),
  }) => FirebaseDeviceTokenRegistrar._(
    messaging,
    backend,
    localStore,
    platform,
    foregroundPresenter,
  );

  FirebaseDeviceTokenRegistrar._(
    this._messaging,
    this._backend,
    this._localStore,
    this.platform,
    this._foregroundPresenter,
  );

  final PushMessagingClient _messaging;
  final DeviceTokenBackend _backend;
  final DeviceTokenLocalStore _localStore;
  final ForegroundNotificationPresenter _foregroundPresenter;
  final String platform;
  final StreamController<PushMessage> _foregroundController =
      StreamController<PushMessage>.broadcast();
  final StreamController<PushOpenEvent> _openController =
      StreamController<PushOpenEvent>.broadcast();
  final List<PushOpenEvent> _pendingOpens = [];
  final LinkedHashSet<String> _presentedForegroundMessages = LinkedHashSet();

  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _initialized = false;
  bool _foregroundPresenterReady = false;

  @override
  Stream<PushMessage> get foregroundMessages => _foregroundController.stream;

  @override
  Stream<PushOpenEvent> get notificationOpens => _openController.stream;

  @override
  PushOpenEvent? takePendingNotificationOpen() {
    if (_pendingOpens.isEmpty) return null;
    return _pendingOpens.removeAt(0);
  }

  @override
  void handleNotificationOpen(PushOpenEvent event) {
    _emitOpen(event);
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _retryPendingTokenDeletionIfSafe();
    if (platform == 'android') {
      try {
        await _foregroundPresenter.initialize(
          onNotificationOpen: handleNotificationOpen,
        );
        _foregroundPresenterReady = true;
      } catch (_) {
        // Push registration and durable in-app notifications must remain
        // available even when an OEM rejects local-notification setup.
      }
    }
    await _messaging.configureForegroundPresentation();
    _subscriptions
      ..add(
        _messaging.tokenRefreshes.listen((token) {
          unawaited(_registerTokenBestEffort(token));
        }),
      )
      ..add(
        _messaging.foregroundMessages.listen((message) {
          if (!_foregroundController.isClosed) {
            _foregroundController.add(message);
          }
          unawaited(_presentForegroundMessageBestEffort(message));
        }),
      )
      ..add(
        _messaging.openedMessages.listen((event) {
          _emitOpen(event);
        }),
      );
    try {
      final initialOpen = await _messaging.getInitialNotificationOpen();
      if (initialOpen != null) {
        _emitOpen(initialOpen);
      }
    } catch (_) {
      // Failure to recover one launch payload must not disable push token
      // registration or prevent the rest of the application from starting.
    }
  }

  Future<void> _presentForegroundMessageBestEffort(PushMessage message) async {
    if (platform != 'android' || !_foregroundPresenterReady) return;
    final key = message.presentationKey;
    if (!_presentedForegroundMessages.add(key)) return;
    if (_presentedForegroundMessages.length > 64) {
      _presentedForegroundMessages.remove(_presentedForegroundMessages.first);
    }
    try {
      await _foregroundPresenter.show(message);
    } catch (_) {
      // A transient local-notification failure should be retryable if FCM
      // redelivers the message during this process lifetime.
      _presentedForegroundMessages.remove(key);
    }
  }

  void _emitOpen(PushOpenEvent event) {
    if (_openController.isClosed) return;
    if (_openController.hasListener) {
      _openController.add(event);
      return;
    }
    // In practice only the terminated-state launch is queued. Keep a small
    // bound so malformed platform integrations cannot grow memory indefinitely.
    if (_pendingOpens.length == 5) _pendingOpens.removeAt(0);
    _pendingOpens.add(event);
  }

  Future<void> _retryPendingTokenDeletionIfSafe() async {
    // Supabase restores its local session before this registrar is created. An
    // authenticated session may already have reactivated the current FCM token,
    // so never delete it here. A successful registration clears stale markers.
    if (_backend.hasAuthenticatedUser) return;
    final pending =
        await _localStore.readPendingDeletionToken() ??
        await _localStore.readLastToken();
    if (pending == null || pending.trim().isEmpty) return;
    try {
      await _messaging.deleteToken();
      await _localStore.clearLastToken();
      await _localStore.clearPendingDeletionToken();
    } catch (_) {
      // Keep the durable marker. A later unauthenticated startup retries it.
    }
  }

  @override
  Future<void> registerCurrentDevice() async {
    if (!_backend.hasAuthenticatedUser) {
      _pushDebug('Skipped registration because no authenticated user exists.');
      return;
    }
    final permitted = await _messaging.requestPermission();
    if (!permitted) {
      _pushDebug('Notification permission is not authorized.');
      return;
    }
    _pushDebug('Notification permission is authorized.');
    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) {
      _pushDebug('FCM token is not available yet.');
      return;
    }
    _pushDebug('FCM token is available; registering it with the backend.');
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    if (!_backend.hasAuthenticatedUser) return;
    final deviceId = await _localStore.getOrCreateDeviceId();
    await _backend.registerToken(
      deviceId: deviceId,
      platform: platform,
      token: token,
    );
    await _localStore.writeLastToken(token);
    // Registration makes this installation token intentionally active for the
    // current account. Never let an older deletion marker remove it later.
    await _localStore.clearPendingDeletionToken();
    _pushDebug('Device token registered with the backend.');
  }

  Future<void> _registerTokenBestEffort(String token) async {
    try {
      await _registerToken(token);
    } catch (_) {
      // Token refresh must never interrupt the signed-in app session.
    }
  }

  @override
  Future<void> unregisterCurrentDevice() async {
    final token =
        await _localStore.readLastToken() ??
        await _localStore.readPendingDeletionToken();
    if (token == null || token.isEmpty) return;
    await _localStore.writePendingDeletionToken(token);
    Object? backendError;
    StackTrace? backendStackTrace;
    try {
      if (_backend.hasAuthenticatedUser) {
        await _backend.unregisterToken(token);
      }
    } catch (error, stackTrace) {
      backendError = error;
      backendStackTrace = stackTrace;
    }

    // Invalidate the Firebase installation token even if backend cleanup was
    // offline. Local state is cleared only after Firebase confirms deletion;
    // otherwise startup has a durable retry marker.
    await _messaging.deleteToken();
    await _localStore.clearLastToken();
    await _localStore.clearPendingDeletionToken();
    if (backendError != null) {
      Error.throwWithStackTrace(backendError, backendStackTrace!);
    }
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _foregroundController.close();
    await _openController.close();
    _pendingOpens.clear();
    _presentedForegroundMessages.clear();
    if (platform == 'android') {
      await _foregroundPresenter.dispose();
    }
  }
}

class AndroidForegroundNotificationPresenter
    implements ForegroundNotificationPresenter {
  AndroidForegroundNotificationPresenter({
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'nawl_orders',
    'إشعارات الطلبات والحساب',
    description: 'تحديثات الطلبات والسحوبات والحساب',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'nawl_orders',
      'إشعارات الطلبات والحساب',
      channelDescription: 'تحديثات الطلبات والسحوبات والحساب',
      icon: 'ic_stat_notification',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
  );
  static const _maxTapPayloadCharacters = 8 * 1024;
  static const _maxTapValueCharacters = 256;
  static const _allowedTapKeys = {
    'notification_id',
    'order_id',
    'target_order_id',
    'product_id',
    'target_product_id',
    'promotion_id',
    'target_promotion_id',
    'target_type',
    'deep_link',
  };

  final FlutterLocalNotificationsPlugin _notifications;
  void Function(PushOpenEvent event)? _onNotificationOpen;
  bool _initialized = false;

  @override
  Future<void> initialize({
    required void Function(PushOpenEvent event) onNotificationOpen,
  }) async {
    if (_initialized) {
      _onNotificationOpen = onNotificationOpen;
      return;
    }
    _onNotificationOpen = onNotificationOpen;
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notification'),
      ),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    _initialized = true;
    try {
      final launchDetails = await _notifications
          .getNotificationAppLaunchDetails();
      final response = launchDetails?.notificationResponse;
      if (launchDetails?.didNotificationLaunchApp == true && response != null) {
        _handleNotificationResponse(response);
      }
    } catch (_) {
      // A stale or malformed launch intent must not disable later foreground
      // notifications or push-token registration.
    }
  }

  @override
  Future<void> show(PushMessage message) async {
    if (!_initialized) return;
    final title = message.title?.trim();
    final body = message.body?.trim();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }
    await _notifications.show(
      id: message.localNotificationId,
      title: title == null || title.isEmpty ? null : title,
      body: body == null || body.isEmpty ? null : body,
      notificationDetails: _details,
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null ||
        payload.trim().isEmpty ||
        payload.length > _maxTapPayloadCharacters) {
      return;
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final trustedTargets = <String, dynamic>{};
      for (final key in _allowedTapKeys) {
        final value = decoded[key];
        if (value is String &&
            value.trim().isNotEmpty &&
            value.length <= _maxTapValueCharacters) {
          trustedTargets[key] = value;
        }
      }
      if (trustedTargets.isEmpty) return;
      _onNotificationOpen?.call(PushOpenEvent.fromData(trustedTargets));
    } catch (_) {
      // Ignore malformed OS payloads rather than routing an untrusted target.
    }
  }

  @override
  Future<void> dispose() async {
    _onNotificationOpen = null;
  }
}

class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get foregroundMessages => FirebaseMessaging.onMessage.map(
    (message) => PushMessage(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
    ),
  );

  @override
  Stream<PushOpenEvent> get openedMessages => FirebaseMessaging
      .onMessageOpenedApp
      .map((message) => PushOpenEvent.fromData(message.data));

  @override
  Future<PushOpenEvent?> getInitialNotificationOpen() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : PushOpenEvent.fromData(message.data);
  }

  @override
  Future<void> configureForegroundPresentation() =>
      _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken;
      for (var attempt = 0; attempt < 20; attempt++) {
        apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null && apnsToken.trim().isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (apnsToken == null || apnsToken.trim().isEmpty) {
        _pushDebug('APNs token was not available after waiting.');
        return null;
      }
      _pushDebug('APNs token is available.');
    }
    return _messaging.getToken(
      vapidKey: kIsWeb && AppConfig.firebaseWebVapidKey.isNotEmpty
          ? AppConfig.firebaseWebVapidKey
          : null,
    );
  }

  @override
  Future<void> deleteToken() => _messaging.deleteToken();
}

class SupabaseDeviceTokenBackend implements DeviceTokenBackend {
  SupabaseDeviceTokenBackend(this._client);

  final SupabaseClient _client;

  @override
  bool get hasAuthenticatedUser => _client.auth.currentSession != null;

  @override
  Future<void> registerToken({
    required String deviceId,
    required String platform,
    required String token,
  }) async {
    if (!hasAuthenticatedUser) return;
    await _client.rpc(
      'register_device_token',
      params: {
        'p_device_id': deviceId,
        'p_platform': platform,
        'p_fcm_token': token,
      },
    );
  }

  @override
  Future<void> unregisterToken(String token) async {
    if (!hasAuthenticatedUser) return;
    await _client.rpc(
      'unregister_device_token',
      params: {'p_fcm_token': token},
    );
  }
}

class SharedPreferencesDeviceTokenStore implements DeviceTokenLocalStore {
  static const _deviceIdKey = 'push_device_id_v1';
  static const _lastTokenKey = 'push_last_fcm_token_v1';
  static const _pendingDeletionTokenKey = 'push_pending_delete_fcm_token_v1';

  @override
  Future<String> getOrCreateDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_deviceIdKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final created = newUuidV4();
    await preferences.setString(_deviceIdKey, created);
    return created;
  }

  @override
  Future<String?> readLastToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_lastTokenKey);
  }

  @override
  Future<void> writeLastToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastTokenKey, token);
  }

  @override
  Future<void> clearLastToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_lastTokenKey);
  }

  @override
  Future<String?> readPendingDeletionToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_pendingDeletionTokenKey);
  }

  @override
  Future<void> writePendingDeletionToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pendingDeletionTokenKey, token);
  }

  @override
  Future<void> clearPendingDeletionToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingDeletionTokenKey);
  }
}

FirebaseOptions get _firebaseOptions => FirebaseOptions(
  apiKey: AppConfig.firebaseApiKey,
  appId:
      defaultTargetPlatform == TargetPlatform.iOS &&
          AppConfig.firebaseIosAppId.isNotEmpty
      ? AppConfig.firebaseIosAppId
      : AppConfig.firebaseAppId,
  messagingSenderId: AppConfig.firebaseMessagingSenderId,
  projectId: AppConfig.firebaseProjectId,
  authDomain: AppConfig.firebaseAuthDomain.isEmpty
      ? null
      : AppConfig.firebaseAuthDomain,
  storageBucket: AppConfig.firebaseStorageBucket.isEmpty
      ? null
      : AppConfig.firebaseStorageBucket,
  iosBundleId: AppConfig.firebaseIosBundleId.isEmpty
      ? null
      : AppConfig.firebaseIosBundleId,
);

Future<FirebaseApp> _initializeFirebaseApp() {
  if (AppConfig.usesBundledFirebaseConfiguration) {
    return Firebase.initializeApp();
  }
  return Firebase.initializeApp(options: _firebaseOptions);
}

String? get _devicePlatform {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.windows => 'windows',
    _ => null,
  };
}

Future<DeviceTokenRegistrar> createDeviceTokenRegistrar(
  SupabaseClient client,
) async {
  final platform = _devicePlatform;
  // firebase_messaging does not currently support a Windows client. Keep the
  // database enum future-ready without calling an unsupported native plugin.
  if (!AppConfig.fcmEnabled || platform == null || platform == 'windows') {
    return const NoopDeviceTokenRegistrar();
  }
  FirebaseApp? firebaseApp;
  var initializedFirebaseHere = false;
  Future<void> cleanupFirebaseApp() async {
    if (!initializedFirebaseHere || firebaseApp == null) return;
    try {
      await firebaseApp.delete();
    } catch (_) {
      // Best-effort native cleanup; returning the no-op registrar is safe.
    } finally {
      initializedFirebaseHere = false;
    }
  }

  try {
    if (Firebase.apps.isEmpty) {
      firebaseApp = await _initializeFirebaseApp();
      initializedFirebaseHere = true;
    } else {
      firebaseApp = Firebase.app();
    }
    _pushDebug('Firebase initialized for $platform.');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    return await initializeOptionalDeviceTokenRegistrar(
      () => FirebaseDeviceTokenRegistrar(
        messaging: FirebasePushMessagingClient(FirebaseMessaging.instance),
        backend: SupabaseDeviceTokenBackend(client),
        localStore: SharedPreferencesDeviceTokenStore(),
        platform: platform,
        foregroundPresenter: platform == 'android'
            ? AndroidForegroundNotificationPresenter()
            : const NoopForegroundNotificationPresenter(),
      ),
      onFailure: cleanupFirebaseApp,
    );
  } catch (error) {
    _pushDebug('Firebase push initialization failed: $error');
    // Notifications are an optional capability. A missing/invalid Firebase
    // installation must never turn a healthy Supabase session into a startup
    // failure. Delete only the Firebase app created by this attempt.
    await cleanupFirebaseApp();
    return const NoopDeviceTokenRegistrar();
  }
}

/// Initializes an optional push registrar and disposes partially initialized
/// resources before falling back to a no-op implementation.
///
/// Kept platform-neutral so the failure path can be covered by unit tests
/// without loading Firebase plugins.
Future<DeviceTokenRegistrar> initializeOptionalDeviceTokenRegistrar(
  DeviceTokenRegistrar Function() create, {
  Future<void> Function()? onFailure,
}) async {
  DeviceTokenRegistrar? registrar;
  try {
    registrar = create();
    await registrar.initialize();
    return registrar;
  } catch (_) {
    if (registrar != null) {
      try {
        await registrar.dispose();
      } catch (_) {
        // Cleanup is best effort; the failed registrar is never exposed.
      }
    }
    if (onFailure != null) {
      try {
        await onFailure();
      } catch (_) {
        // Optional cleanup cannot be allowed to reintroduce startup failure.
      }
    }
    return const NoopDeviceTokenRegistrar();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!AppConfig.fcmEnabled) return;
  if (Firebase.apps.isEmpty) {
    await _initializeFirebaseApp();
  }
}
