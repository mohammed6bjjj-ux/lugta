import 'dart:async';

import 'package:flutter_app/data/services/device_token_registrar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('push event accepts only explicit promotion and referral targets', () {
    final event = PushOpenEvent.fromData(const {
      'notification_id': 'notification-offer',
      'target_promotion_id': 'promotion-7',
      'target_type': 'referral',
      'deep_link': 'nawl://referrals',
      'route': '/admin',
    });

    expect(event.notificationId, 'notification-offer');
    expect(event.promotionId, 'promotion-7');
    expect(event.targetType, 'referral');
    expect(event.deepLink, 'nawl://referrals');
  });

  test('registers an authenticated permitted device', () async {
    final messaging = _FakeMessaging();
    final backend = _FakeBackend();
    final store = _FakeStore();
    final registrar = FirebaseDeviceTokenRegistrar(
      messaging: messaging,
      backend: backend,
      localStore: store,
      platform: 'android',
    );

    await registrar.initialize();
    await registrar.registerCurrentDevice();

    expect(messaging.presentationConfigured, isTrue);
    expect(messaging.permissionRequests, 1);
    expect(backend.registrations, [('device-1', 'android', 'token-1')]);
    expect(store.lastToken, 'token-1');
    expect(store.pendingDeletionToken, isNull);
    await registrar.dispose();
    await messaging.dispose();
  });

  test('does not request a token when permission is denied', () async {
    final messaging = _FakeMessaging()..permissionGranted = false;
    final backend = _FakeBackend();
    final registrar = FirebaseDeviceTokenRegistrar(
      messaging: messaging,
      backend: backend,
      localStore: _FakeStore(),
      platform: 'android',
    );

    await registrar.initialize();
    await registrar.registerCurrentDevice();

    expect(messaging.tokenRequests, 0);
    expect(backend.registrations, isEmpty);
    await registrar.dispose();
    await messaging.dispose();
  });

  test(
    're-registers refreshed tokens and surfaces foreground events',
    () async {
      final messaging = _FakeMessaging();
      final backend = _FakeBackend();
      final registrar = FirebaseDeviceTokenRegistrar(
        messaging: messaging,
        backend: backend,
        localStore: _FakeStore(),
        platform: 'ios',
      );
      await registrar.initialize();

      final foreground = expectLater(
        registrar.foregroundMessages,
        emits(
          isA<PushMessage>()
              .having((message) => message.title, 'title', 'New order')
              .having(
                (message) => message.openEvent.orderId,
                'order id',
                'order-1',
              ),
        ),
      );
      messaging.emitForeground();
      messaging.emitToken('token-refreshed');
      await foreground;
      await pumpEventQueue();

      expect(backend.registrations, [('device-1', 'ios', 'token-refreshed')]);
      await registrar.dispose();
      await messaging.dispose();
    },
  );

  test(
    'logout invalidates the local token even if backend cleanup fails',
    () async {
      final messaging = _FakeMessaging();
      final backend = _FakeBackend()..unregisterThrows = true;
      final store = _FakeStore()..lastToken = 'old-token';
      final registrar = FirebaseDeviceTokenRegistrar(
        messaging: messaging,
        backend: backend,
        localStore: store,
        platform: 'android',
      );

      await expectLater(
        registrar.unregisterCurrentDevice(),
        throwsA(isA<StateError>()),
      );

      expect(backend.unregistrations, ['old-token']);
      expect(messaging.deletedToken, isTrue);
      expect(store.lastToken, isNull);
      expect(store.pendingDeletionToken, isNull);
      await registrar.dispose();
      await messaging.dispose();
    },
  );

  test('preserves background and terminated notification targets', () async {
    final messaging = _FakeMessaging()
      ..initialOpen = const PushOpenEvent(
        notificationId: 'notification-initial',
        orderId: 'order-initial',
      );
    final registrar = FirebaseDeviceTokenRegistrar(
      messaging: messaging,
      backend: _FakeBackend(),
      localStore: _FakeStore(),
      platform: 'android',
    );

    await registrar.initialize();
    final initial = registrar.takePendingNotificationOpen();
    expect(initial?.notificationId, 'notification-initial');
    expect(initial?.orderId, 'order-initial');

    final opened = expectLater(
      registrar.notificationOpens,
      emits(
        isA<PushOpenEvent>()
            .having(
              (event) => event.notificationId,
              'notification id',
              'notification-background',
            )
            .having((event) => event.productId, 'product id', 'product-1'),
      ),
    );
    messaging.emitOpen(
      const PushOpenEvent(
        notificationId: 'notification-background',
        productId: 'product-1',
      ),
    );
    await opened;

    await registrar.dispose();
    await messaging.dispose();
  });

  test('a local notification tap enters the same open stream', () async {
    final messaging = _FakeMessaging();
    final registrar = FirebaseDeviceTokenRegistrar(
      messaging: messaging,
      backend: _FakeBackend(),
      localStore: _FakeStore(),
      platform: 'android',
    );
    await registrar.initialize();

    final opened = expectLater(
      registrar.notificationOpens,
      emits(
        isA<PushOpenEvent>().having(
          (event) => event.orderId,
          'order id',
          'local-order',
        ),
      ),
    );
    registrar.handleNotificationOpen(
      const PushOpenEvent(orderId: 'local-order'),
    );
    await opened;

    await registrar.dispose();
    await messaging.dispose();
  });

  test('android foreground presenter shows once and routes its tap', () async {
    final messaging = _FakeMessaging();
    final presenter = _FakeForegroundPresenter();
    final registrar = FirebaseDeviceTokenRegistrar(
      messaging: messaging,
      backend: _FakeBackend(),
      localStore: _FakeStore(),
      platform: 'android',
      foregroundPresenter: presenter,
    );
    await registrar.initialize();

    final message = PushMessage(
      title: 'Order updated',
      body: 'Open the order',
      data: const {'notification_id': 'notification-1', 'order_id': 'order-1'},
    );
    messaging.emitForeground(message);
    messaging.emitForeground(message);
    await pumpEventQueue();

    expect(presenter.initialized, isTrue);
    expect(presenter.shown, [same(message)]);

    final opened = expectLater(
      registrar.notificationOpens,
      emits(
        isA<PushOpenEvent>()
            .having(
              (event) => event.notificationId,
              'notification id',
              'notification-1',
            )
            .having((event) => event.orderId, 'order id', 'order-1'),
      ),
    );
    presenter.emitTap(message.openEvent);
    await opened;

    await registrar.dispose();
    expect(presenter.disposed, isTrue);
    await messaging.dispose();
  });

  test('foreground presenter is never initialized or shown on iOS', () async {
    final messaging = _FakeMessaging();
    final presenter = _FakeForegroundPresenter();
    final registrar = FirebaseDeviceTokenRegistrar(
      messaging: messaging,
      backend: _FakeBackend(),
      localStore: _FakeStore(),
      platform: 'ios',
      foregroundPresenter: presenter,
    );
    await registrar.initialize();

    messaging.emitForeground();
    await pumpEventQueue();

    expect(presenter.initialized, isFalse);
    expect(presenter.shown, isEmpty);
    await registrar.dispose();
    expect(presenter.disposed, isFalse);
    await messaging.dispose();
  });

  test('terminated local-notification tap is retained for the shell', () async {
    final messaging = _FakeMessaging();
    final presenter = _FakeForegroundPresenter()
      ..initialOpen = const PushOpenEvent(
        notificationId: 'local-launch',
        productId: 'product-launch',
      );
    final registrar = FirebaseDeviceTokenRegistrar(
      messaging: messaging,
      backend: _FakeBackend(),
      localStore: _FakeStore(),
      platform: 'android',
      foregroundPresenter: presenter,
    );

    await registrar.initialize();

    final pending = registrar.takePendingNotificationOpen();
    expect(pending?.notificationId, 'local-launch');
    expect(pending?.productId, 'product-launch');
    await registrar.dispose();
    await messaging.dispose();
  });

  test('local notification ids are stable and notification-specific', () {
    final first = PushMessage(
      title: 'A',
      body: 'B',
      data: const {'notification_id': 'same-id', 'order_id': 'order-1'},
    );
    final reordered = PushMessage(
      title: 'Different localized copy',
      data: const {'order_id': 'order-1', 'notification_id': 'same-id'},
    );
    final different = PushMessage(
      data: const {'notification_id': 'different-id'},
    );

    expect(reordered.presentationKey, first.presentationKey);
    expect(reordered.localNotificationId, first.localNotificationId);
    expect(different.localNotificationId, isNot(first.localNotificationId));
  });

  test('rich image participates in fallback presentation identity', () {
    final plain = PushMessage(title: 'A', body: 'B');
    final rich = PushMessage(
      title: 'A',
      body: 'B',
      imageUrl: 'https://example.test/product.webp',
    );

    expect(rich.imageUrl, 'https://example.test/product.webp');
    expect(rich.presentationKey, isNot(plain.presentationKey));
    expect(rich.localNotificationId, isNot(plain.localNotificationId));
  });

  test('failed Firebase deletion retains a durable retry marker', () async {
    final messaging = _FakeMessaging()..deleteThrows = true;
    final store = _FakeStore()..lastToken = 'old-token';
    final registrar = FirebaseDeviceTokenRegistrar(
      messaging: messaging,
      backend: _FakeBackend(),
      localStore: store,
      platform: 'android',
    );

    await expectLater(
      registrar.unregisterCurrentDevice(),
      throwsA(isA<StateError>()),
    );

    expect(store.lastToken, 'old-token');
    expect(store.pendingDeletionToken, 'old-token');
    expect(messaging.deleteRequests, 1);
    await registrar.dispose();
    await messaging.dispose();
  });

  test('unauthenticated startup retries a pending Firebase deletion', () async {
    final messaging = _FakeMessaging();
    final backend = _FakeBackend()..hasAuthenticatedUser = false;
    final store = _FakeStore()
      ..lastToken = 'old-token'
      ..pendingDeletionToken = 'old-token';
    final registrar = FirebaseDeviceTokenRegistrar(
      messaging: messaging,
      backend: backend,
      localStore: store,
      platform: 'android',
    );

    await registrar.initialize();

    expect(messaging.deleteRequests, 1);
    expect(store.lastToken, isNull);
    expect(store.pendingDeletionToken, isNull);
    await registrar.dispose();
    await messaging.dispose();
  });

  test('authenticated startup never deletes a newly active token', () async {
    final messaging = _FakeMessaging();
    final store = _FakeStore()
      ..lastToken = 'active-token'
      ..pendingDeletionToken = 'older-marker';
    final registrar = FirebaseDeviceTokenRegistrar(
      messaging: messaging,
      backend: _FakeBackend(),
      localStore: store,
      platform: 'android',
    );

    await registrar.initialize();
    expect(messaging.deleteRequests, 0);
    expect(store.pendingDeletionToken, 'older-marker');

    await registrar.registerCurrentDevice();
    expect(messaging.deleteRequests, 0);
    expect(store.lastToken, 'token-1');
    expect(store.pendingDeletionToken, isNull);
    await registrar.dispose();
    await messaging.dispose();
  });

  test('shared preferences keeps one stable installation id', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesDeviceTokenStore();

    final first = await store.getOrCreateDeviceId();
    final second = await store.getOrCreateDeviceId();

    expect(second, first);
    expect(first, matches(RegExp(r'^[0-9a-f-]{36}$')));
  });

  test(
    'optional registrar failure is cleaned up and falls back to no-op',
    () async {
      final failed = _LifecycleRegistrar(initializeThrows: true);
      var platformCleanupCalls = 0;

      final result = await initializeOptionalDeviceTokenRegistrar(
        () => failed,
        onFailure: () async => platformCleanupCalls++,
      );

      expect(result, isA<NoopDeviceTokenRegistrar>());
      expect(result, isNot(same(failed)));
      expect(failed.initializeCalls, 1);
      expect(failed.disposeCalls, 1);
      expect(platformCleanupCalls, 1);
    },
  );

  test('optional registrar returns the initialized implementation', () async {
    final candidate = _LifecycleRegistrar();

    final result = await initializeOptionalDeviceTokenRegistrar(
      () => candidate,
    );

    expect(result, same(candidate));
    expect(candidate.initializeCalls, 1);
    expect(candidate.disposeCalls, 0);
  });
}

class _LifecycleRegistrar extends NoopDeviceTokenRegistrar {
  _LifecycleRegistrar({this.initializeThrows = false});

  final bool initializeThrows;
  int initializeCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (initializeThrows) throw StateError('native setup failed');
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}

class _FakeMessaging implements PushMessagingClient {
  final _tokens = StreamController<String>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushOpenEvent>.broadcast();

  bool permissionGranted = true;
  bool presentationConfigured = false;
  bool deletedToken = false;
  bool deleteThrows = false;
  int deleteRequests = 0;
  int permissionRequests = 0;
  int tokenRequests = 0;
  PushOpenEvent? initialOpen;

  @override
  Stream<PushMessage> get foregroundMessages => _foreground.stream;

  @override
  Stream<PushOpenEvent> get openedMessages => _opened.stream;

  @override
  Stream<String> get tokenRefreshes => _tokens.stream;

  @override
  Future<void> configureForegroundPresentation() async {
    presentationConfigured = true;
  }

  @override
  Future<void> deleteToken() async {
    deleteRequests++;
    deletedToken = true;
    if (deleteThrows) throw StateError('firebase offline');
  }

  @override
  Future<PushOpenEvent?> getInitialNotificationOpen() async => initialOpen;

  @override
  Future<String?> getToken() async {
    tokenRequests++;
    return 'token-1';
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  void emitForeground([PushMessage? message]) => _foreground.add(
    message ??
        PushMessage(
          title: 'New order',
          body: 'Open the order',
          data: const {'order_id': 'order-1'},
        ),
  );

  void emitOpen(PushOpenEvent event) => _opened.add(event);

  void emitToken(String token) => _tokens.add(token);

  Future<void> dispose() async {
    await _tokens.close();
    await _foreground.close();
    await _opened.close();
  }
}

class _FakeForegroundPresenter implements ForegroundNotificationPresenter {
  bool initialized = false;
  bool disposed = false;
  final shown = <PushMessage>[];
  void Function(PushOpenEvent event)? _onNotificationOpen;
  PushOpenEvent? initialOpen;

  @override
  Future<void> initialize({
    required void Function(PushOpenEvent event) onNotificationOpen,
  }) async {
    initialized = true;
    _onNotificationOpen = onNotificationOpen;
    final launchOpen = initialOpen;
    if (launchOpen != null) onNotificationOpen(launchOpen);
  }

  @override
  Future<void> show(PushMessage message) async {
    shown.add(message);
  }

  void emitTap(PushOpenEvent event) => _onNotificationOpen?.call(event);

  @override
  Future<void> dispose() async {
    disposed = true;
    _onNotificationOpen = null;
  }
}

class _FakeBackend implements DeviceTokenBackend {
  @override
  bool hasAuthenticatedUser = true;
  bool unregisterThrows = false;
  final registrations = <(String, String, String)>[];
  final unregistrations = <String>[];

  @override
  Future<void> registerToken({
    required String deviceId,
    required String platform,
    required String token,
  }) async {
    registrations.add((deviceId, platform, token));
  }

  @override
  Future<void> unregisterToken(String token) async {
    unregistrations.add(token);
    if (unregisterThrows) throw StateError('offline');
  }
}

class _FakeStore implements DeviceTokenLocalStore {
  String deviceId = 'device-1';
  String? lastToken;
  String? pendingDeletionToken;

  @override
  Future<void> clearLastToken() async {
    lastToken = null;
  }

  @override
  Future<void> clearPendingDeletionToken() async {
    pendingDeletionToken = null;
  }

  @override
  Future<String> getOrCreateDeviceId() async => deviceId;

  @override
  Future<String?> readLastToken() async => lastToken;

  @override
  Future<String?> readPendingDeletionToken() async => pendingDeletionToken;

  @override
  Future<void> writeLastToken(String token) async {
    lastToken = token;
  }

  @override
  Future<void> writePendingDeletionToken(String token) async {
    pendingDeletionToken = token;
  }
}
