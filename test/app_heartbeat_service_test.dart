import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/data/services/app_heartbeat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesHeartbeatInstallationStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('persists one anonymous RFC 4122 version-4 UUID', () async {
      final firstStore = SharedPreferencesHeartbeatInstallationStore();
      final first = await firstStore.getOrCreateInstallationId();
      final second = await SharedPreferencesHeartbeatInstallationStore()
          .getOrCreateInstallationId();

      expect(second, first);
      expect(
        first,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('replaces malformed persisted identifiers', () async {
      SharedPreferences.setMockInitialValues({
        'app_heartbeat_installation_id_v1': 'phone-name-or-invalid-id',
      });

      final value = await SharedPreferencesHeartbeatInstallationStore()
          .getOrCreateInstallationId();

      expect(value, isNot('phone-name-or-invalid-id'));
      expect(value, hasLength(36));
    });
  });

  group('SessionHeartbeatService', () {
    test('sends immediately on auth and then on each periodic tick', () async {
      final backend = _FakeBackend();
      final timers = _FakeTimerFactory();
      final service = _service(backend: backend, timers: timers);
      await service.initialize();

      service.authenticatedUserChanged('user-1');
      await pumpEventQueue();

      expect(backend.payloads, hasLength(1));
      expect(backend.payloads.single.foreground, isTrue);
      expect(backend.payloads.single.installationId, _installationId);
      expect(backend.payloads.single.platform, 'ios');
      expect(backend.payloads.single.appVersion, '0.1.10');
      expect(backend.payloads.single.appBuild, '12');
      expect(backend.payloads.single.toRpcParams(), {
        'p_installation_id': _installationId,
        'p_platform': 'ios',
        'p_app_version': '0.1.10',
        'p_app_build': '12',
        'p_foreground': true,
      });
      expect(timers.activeCount, 1);
      expect(timers.intervals, [const Duration(seconds: 60)]);

      timers.latest.fire();
      await pumpEventQueue();
      expect(backend.payloads.map((item) => item.foreground), [true, true]);

      await service.dispose();
    });

    test(
      'waits for resume when authentication appears in background',
      () async {
        final backend = _FakeBackend();
        final timers = _FakeTimerFactory();
        final service = _service(
          backend: backend,
          timers: timers,
          initiallyForeground: false,
        );
        await service.initialize();

        service.authenticatedUserChanged('user-1');
        await pumpEventQueue();
        expect(backend.payloads, isEmpty);
        expect(timers.activeCount, 0);

        service.appResumed();
        await pumpEventQueue();
        expect(backend.payloads.single.foreground, isTrue);
        expect(timers.activeCount, 1);
        await service.dispose();
      },
    );

    test('same auth and duplicate resume never double-start a timer', () async {
      final backend = _FakeBackend();
      final timers = _FakeTimerFactory();
      final service = _service(backend: backend, timers: timers);
      await service.initialize();

      service.authenticatedUserChanged('user-1');
      service.authenticatedUserChanged('user-1');
      service.appResumed();
      service.appResumed();
      await pumpEventQueue();

      expect(backend.payloads, hasLength(1));
      expect(timers.createdCount, 1);
      expect(timers.activeCount, 1);

      await service.dispose();
    });

    test(
      'pause reports false once and resume reports true immediately',
      () async {
        final backend = _FakeBackend();
        final timers = _FakeTimerFactory();
        final service = _service(backend: backend, timers: timers);
        await service.initialize();
        service.authenticatedUserChanged('user-1');
        await pumpEventQueue();

        service.appPaused();
        service.appPaused();
        await pumpEventQueue();
        expect(backend.payloads.map((item) => item.foreground), [true, false]);
        expect(timers.activeCount, 0);

        service.appResumed();
        service.appResumed();
        await pumpEventQueue();
        expect(backend.payloads.map((item) => item.foreground), [
          true,
          false,
          true,
        ]);
        expect(timers.createdCount, 2);
        expect(timers.activeCount, 1);

        await service.dispose();
      },
    );

    test('coalesces ticks while a heartbeat request is in flight', () async {
      final backend = _FakeBackend()..blockNextRequest();
      final timers = _FakeTimerFactory();
      final service = _service(backend: backend, timers: timers);
      await service.initialize();

      service.authenticatedUserChanged('user-1');
      await pumpEventQueue();
      expect(backend.payloads, hasLength(1));

      timers.latest
        ..fire()
        ..fire()
        ..fire();
      await pumpEventQueue();
      expect(backend.payloads, hasLength(1));

      backend.releaseBlockedRequest();
      await pumpEventQueue();
      expect(backend.payloads, hasLength(2));

      await service.dispose();
    });

    test('preserves a rapid pause and resume behind a slow request', () async {
      final backend = _FakeBackend()..blockNextRequest();
      final timers = _FakeTimerFactory();
      final service = _service(backend: backend, timers: timers);
      await service.initialize();

      service.authenticatedUserChanged('user-1');
      await pumpEventQueue();
      service.appPaused();
      service.appResumed();
      await pumpEventQueue();
      expect(backend.payloads, hasLength(1));

      backend.releaseBlockedRequest();
      await pumpEventQueue();
      expect(backend.payloads.map((item) => item.foreground), [
        true,
        false,
        true,
      ]);

      await service.dispose();
    });

    test(
      'sign-out reports false and never propagates backend failure',
      () async {
        final backend = _FakeBackend();
        final timers = _FakeTimerFactory();
        final service = _service(backend: backend, timers: timers);
        await service.initialize();
        service.authenticatedUserChanged('user-1');
        await pumpEventQueue();
        backend.throwOnSend = true;

        await service.beforeSignOut();

        expect(backend.payloads.map((item) => item.foreground), [true, false]);
        expect(timers.activeCount, 0);
        await service.dispose();
      },
    );

    test(
      'auth loss and dispose cancel ticks without sending stale work',
      () async {
        final backend = _FakeBackend();
        final timers = _FakeTimerFactory();
        final service = _service(backend: backend, timers: timers);
        await service.initialize();
        service.authenticatedUserChanged('user-1');
        await pumpEventQueue();

        final firstTimer = timers.latest;
        service.authenticatedUserChanged(null);
        firstTimer.fire();
        await pumpEventQueue();
        expect(backend.payloads, hasLength(1));
        expect(timers.activeCount, 0);

        service.authenticatedUserChanged('user-2');
        await pumpEventQueue();
        final secondTimer = timers.latest;
        await service.dispose();
        secondTimer.fire();
        await pumpEventQueue();
        expect(backend.payloads, hasLength(2));
        expect(timers.activeCount, 0);
      },
    );
  });

  group('AppSession heartbeat integration', () {
    test(
      'reports sign-out before the authenticated session is removed',
      () async {
        final heartbeat = _RecordingAppHeartbeat(
          hasSession: () => session.auth.hasSession,
        );
        await session.configure(
          createDemoRepositories(),
          heartbeat: heartbeat,
          loadInitialData: false,
        );
        await session.auth.signIn(
          phone: '+9647700000000',
          password: 'password',
        );
        await pumpEventQueue();

        await session.signOut();

        expect(heartbeat.beforeSignOutCalls, 1);
        expect(heartbeat.hadSessionBeforeSignOut, isTrue);
        expect(heartbeat.authenticatedUsers.last, isNull);
        expect(session.auth.hasSession, isFalse);
        await session.configure(
          createDemoRepositories(),
          loadInitialData: false,
        );
      },
    );

    test('forwards pause and resume to the configured heartbeat', () async {
      final heartbeat = _RecordingAppHeartbeat(
        hasSession: () => session.auth.hasSession,
      );
      await session.configure(
        createDemoRepositories(),
        heartbeat: heartbeat,
        loadInitialData: false,
      );

      session.appPaused();
      expect(heartbeat.pauseCalls, 1);
      session.appResumed();
      expect(heartbeat.resumeCalls, 1);

      await session.configure(createDemoRepositories(), loadInitialData: false);
    });
  });
}

const _installationId = '7f7e86a8-c55b-40cf-9253-6c0adc421b21';

SessionHeartbeatService _service({
  required _FakeBackend backend,
  required _FakeTimerFactory timers,
  bool initiallyForeground = true,
}) => SessionHeartbeatService(
  backend: backend,
  installationStore: const _FakeInstallationStore(),
  buildMetadata: const _FakeBuildMetadata(),
  platform: 'ios',
  initiallyForeground: initiallyForeground,
  timerFactory: timers.create,
);

class _FakeInstallationStore implements HeartbeatInstallationStore {
  const _FakeInstallationStore();

  @override
  Future<String> getOrCreateInstallationId() async => _installationId;
}

class _FakeBuildMetadata implements AppBuildMetadata {
  const _FakeBuildMetadata();

  @override
  Future<AppBuildInfo> load() async =>
      const AppBuildInfo(version: '0.1.10', buildNumber: '12');
}

class _FakeBackend implements AppHeartbeatBackend {
  final payloads = <AppHeartbeatPayload>[];
  Completer<void>? _nextBlockedRequest;
  Completer<void>? _activeBlockedRequest;
  bool throwOnSend = false;

  void blockNextRequest() => _nextBlockedRequest = Completer<void>();

  void releaseBlockedRequest() => _activeBlockedRequest?.complete();

  @override
  Future<void> sendHeartbeat(AppHeartbeatPayload payload) async {
    payloads.add(payload);
    final blockedRequest = _nextBlockedRequest;
    _nextBlockedRequest = null;
    _activeBlockedRequest = blockedRequest;
    if (blockedRequest != null) {
      await blockedRequest.future;
      _activeBlockedRequest = null;
    }
    if (throwOnSend) throw StateError('offline');
  }
}

class _FakeTimerFactory {
  final timers = <_FakeTimer>[];
  final intervals = <Duration>[];

  int get createdCount => timers.length;
  int get activeCount => timers.where((timer) => timer.isActive).length;
  _FakeTimer get latest => timers.last;

  AppHeartbeatPeriodicTimer create(
    Duration interval,
    void Function() callback,
  ) {
    intervals.add(interval);
    final timer = _FakeTimer(callback);
    timers.add(timer);
    return timer;
  }
}

class _FakeTimer implements AppHeartbeatPeriodicTimer {
  _FakeTimer(this._callback);

  final void Function() _callback;
  bool isActive = true;

  void fire() {
    if (isActive) _callback();
  }

  @override
  void cancel() => isActive = false;
}

class _RecordingAppHeartbeat implements AppHeartbeat {
  _RecordingAppHeartbeat({required this.hasSession});

  final bool Function() hasSession;
  final authenticatedUsers = <String?>[];
  int pauseCalls = 0;
  int resumeCalls = 0;
  int beforeSignOutCalls = 0;
  bool hadSessionBeforeSignOut = false;

  @override
  void appPaused() => pauseCalls++;

  @override
  void appResumed() => resumeCalls++;

  @override
  void authenticatedUserChanged(String? userId) {
    authenticatedUsers.add(userId);
  }

  @override
  Future<void> beforeSignOut() async {
    beforeSignOutCalls++;
    hadSessionBeforeSignOut = hasSession();
  }

  @override
  Future<void> dispose() async {}
}
