import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/request_id.dart';

/// App-wide session presence reporting, independent from Supabase Realtime.
abstract interface class AppHeartbeat {
  void authenticatedUserChanged(String? userId);

  void appResumed();

  void appPaused();

  Future<void> beforeSignOut();

  Future<void> dispose();
}

class NoopAppHeartbeat implements AppHeartbeat {
  const NoopAppHeartbeat();

  @override
  void appPaused() {}

  @override
  void appResumed() {}

  @override
  void authenticatedUserChanged(String? userId) {}

  @override
  Future<void> beforeSignOut() async {}

  @override
  Future<void> dispose() async {}
}

class AppBuildInfo {
  const AppBuildInfo({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;
}

abstract interface class AppBuildMetadata {
  Future<AppBuildInfo> load();
}

class PackageInfoAppBuildMetadata implements AppBuildMetadata {
  const PackageInfoAppBuildMetadata();

  @override
  Future<AppBuildInfo> load() async {
    final info = await PackageInfo.fromPlatform();
    return AppBuildInfo(
      version: info.version.trim(),
      buildNumber: info.buildNumber.trim(),
    );
  }
}

abstract interface class HeartbeatInstallationStore {
  Future<String> getOrCreateInstallationId();
}

class SharedPreferencesHeartbeatInstallationStore
    implements HeartbeatInstallationStore {
  static const _installationIdKey = 'app_heartbeat_installation_id_v1';
  static final _uuidV4Pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  Future<String>? _installationId;

  @override
  Future<String> getOrCreateInstallationId() =>
      _installationId ??= _loadOrCreateInstallationId();

  Future<String> _loadOrCreateInstallationId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_installationIdKey)?.trim();
    if (existing != null && _uuidV4Pattern.hasMatch(existing)) {
      return existing.toLowerCase();
    }
    final created = newUuidV4();
    final persisted = await preferences.setString(_installationIdKey, created);
    if (!persisted) {
      throw StateError('Unable to persist the app installation identifier.');
    }
    return created;
  }
}

class AppHeartbeatPayload {
  const AppHeartbeatPayload({
    required this.installationId,
    required this.platform,
    required this.appVersion,
    required this.appBuild,
    required this.foreground,
  });

  final String installationId;
  final String platform;
  final String appVersion;
  final String appBuild;
  final bool foreground;

  Map<String, dynamic> toRpcParams() => {
    'p_installation_id': installationId,
    'p_platform': platform,
    'p_app_version': appVersion,
    'p_app_build': appBuild,
    'p_foreground': foreground,
  };
}

abstract interface class AppHeartbeatBackend {
  Future<void> sendHeartbeat(AppHeartbeatPayload payload);
}

class SupabaseAppHeartbeatBackend implements AppHeartbeatBackend {
  SupabaseAppHeartbeatBackend(this._client);

  final SupabaseClient _client;

  @override
  Future<void> sendHeartbeat(AppHeartbeatPayload payload) async {
    // The service is activated only from AppSession's accepted Auth identity.
    // Recheck the SDK session here as well so a queued tick cannot run after
    // local sign-out has already completed.
    if (_client.auth.currentSession == null) return;
    await _client
        .schema('public')
        .rpc('mobile_app_session_heartbeat', params: payload.toRpcParams());
  }
}

abstract interface class AppHeartbeatPeriodicTimer {
  void cancel();
}

typedef AppHeartbeatTimerFactory =
    AppHeartbeatPeriodicTimer Function(
      Duration interval,
      void Function() callback,
    );

class SessionHeartbeatService implements AppHeartbeat {
  SessionHeartbeatService({
    required this.backend,
    required this.installationStore,
    required this.buildMetadata,
    required this.platform,
    bool initiallyForeground = true,
    this.interval = const Duration(seconds: 60),
    this.signOutWait = const Duration(seconds: 2),
    AppHeartbeatTimerFactory? timerFactory,
  }) : _isForeground = initiallyForeground,
       _timerFactory = timerFactory ?? _createPeriodicTimer;

  final AppHeartbeatBackend backend;
  final HeartbeatInstallationStore installationStore;
  final AppBuildMetadata buildMetadata;
  final AppHeartbeatTimerFactory _timerFactory;
  final String platform;
  final Duration interval;
  final Duration signOutWait;

  AppHeartbeatPeriodicTimer? _timer;
  String? _installationId;
  AppBuildInfo? _buildInfo;
  String? _authenticatedUserId;
  _HeartbeatRequest? _pendingRequest;
  _HeartbeatRequest? _followingRequest;
  Future<void>? _drainFuture;
  int _authGeneration = 0;
  bool _isForeground;
  bool? _lastRequestedForeground;
  bool _isInitialized = false;
  bool _isDisposed = false;

  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;
    final values = await Future.wait<Object>([
      installationStore.getOrCreateInstallationId(),
      buildMetadata.load(),
    ]);
    final installationId = (values[0] as String).trim();
    final buildInfo = values[1] as AppBuildInfo;
    if (installationId.isEmpty ||
        buildInfo.version.isEmpty ||
        buildInfo.buildNumber.isEmpty) {
      throw StateError(
        'Heartbeat identity and build metadata must be present.',
      );
    }
    _installationId = installationId;
    _buildInfo = buildInfo;
    _isInitialized = true;
  }

  @override
  void authenticatedUserChanged(String? userId) {
    if (!_isInitialized || _isDisposed) return;
    final normalized = userId?.trim();
    final nextUserId = normalized == null || normalized.isEmpty
        ? null
        : normalized;
    if (nextUserId == _authenticatedUserId) return;

    _cancelTimer();
    _authGeneration += 1;
    _authenticatedUserId = nextUserId;
    _pendingRequest = null;
    _followingRequest = null;
    _lastRequestedForeground = null;
    if (nextUserId == null || !_isForeground) return;

    _requestHeartbeat(foreground: true);
    _ensureTimer();
  }

  @override
  void appResumed() {
    if (!_isInitialized || _isDisposed) return;
    if (_isForeground) {
      _ensureTimer();
      return;
    }
    _isForeground = true;
    if (_authenticatedUserId == null) return;
    _requestHeartbeat(foreground: true);
    _ensureTimer();
  }

  @override
  void appPaused() {
    if (!_isInitialized || _isDisposed || !_isForeground) return;
    _isForeground = false;
    _cancelTimer();
    if (_authenticatedUserId != null) {
      _requestHeartbeat(foreground: false);
    }
  }

  @override
  Future<void> beforeSignOut() async {
    if (!_isInitialized || _isDisposed || _authenticatedUserId == null) return;
    _isForeground = false;
    _cancelTimer();
    final send = _lastRequestedForeground == false
        ? _drainFuture ?? Future<void>.value()
        : _requestHeartbeat(foreground: false);
    try {
      await send.timeout(signOutWait);
    } catch (_) {
      // Presence is advisory. Logout must never be held hostage by telemetry.
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _cancelTimer();
    _authGeneration += 1;
    _authenticatedUserId = null;
    _pendingRequest = null;
    _followingRequest = null;
  }

  void _ensureTimer() {
    if (_timer != null ||
        !_isInitialized ||
        _isDisposed ||
        !_isForeground ||
        _authenticatedUserId == null) {
      return;
    }
    _timer = _timerFactory(interval, () {
      if (!_isForeground || _authenticatedUserId == null || _isDisposed) {
        return;
      }
      _requestHeartbeat(foreground: true);
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _requestHeartbeat({required bool foreground}) {
    final userId = _authenticatedUserId;
    if (!_isInitialized || _isDisposed || userId == null) {
      return Future<void>.value();
    }
    _lastRequestedForeground = foreground;
    final request = _HeartbeatRequest(
      userId: userId,
      authGeneration: _authGeneration,
      foreground: foreground,
    );
    final pending = _pendingRequest;
    if (pending == null) {
      _pendingRequest = request;
    } else if (pending.hasSameState(request)) {
      _pendingRequest = request;
    } else {
      final following = _followingRequest;
      if (following == null || following.hasSameState(request)) {
        _followingRequest = request;
      } else {
        // Keep only the two newest state transitions while a request is slow.
        // Periodic foreground ticks therefore cannot grow an unbounded queue.
        _pendingRequest = following;
        _followingRequest = request;
      }
    }
    return _startDrain();
  }

  Future<void> _startDrain() {
    final current = _drainFuture;
    if (current != null) return current;

    final completer = Completer<void>();
    _drainFuture = completer.future;
    unawaited(() async {
      try {
        await _drainPendingRequests();
      } finally {
        _drainFuture = null;
        completer.complete();
        if ((_pendingRequest != null || _followingRequest != null) &&
            !_isDisposed) {
          _startDrain();
        }
      }
    }());
    return completer.future;
  }

  Future<void> _drainPendingRequests() async {
    while (!_isDisposed) {
      final request = _pendingRequest;
      _pendingRequest = _followingRequest;
      _followingRequest = null;
      if (request == null) return;
      if (request.authGeneration != _authGeneration ||
          request.userId != _authenticatedUserId) {
        continue;
      }
      final installationId = _installationId;
      final buildInfo = _buildInfo;
      if (installationId == null || buildInfo == null) continue;
      try {
        await backend.sendHeartbeat(
          AppHeartbeatPayload(
            installationId: installationId,
            platform: platform,
            appVersion: buildInfo.version,
            appBuild: buildInfo.buildNumber,
            foreground: request.foreground,
          ),
        );
      } catch (_) {
        // A later periodic tick/resume retries. Presence is never business data.
      }
    }
  }
}

class _HeartbeatRequest {
  const _HeartbeatRequest({
    required this.userId,
    required this.authGeneration,
    required this.foreground,
  });

  final String userId;
  final int authGeneration;
  final bool foreground;

  bool hasSameState(_HeartbeatRequest other) =>
      userId == other.userId &&
      authGeneration == other.authGeneration &&
      foreground == other.foreground;
}

class _DartAppHeartbeatPeriodicTimer implements AppHeartbeatPeriodicTimer {
  _DartAppHeartbeatPeriodicTimer(Duration interval, void Function() callback)
    : _timer = Timer.periodic(interval, (_) => callback());

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

AppHeartbeatPeriodicTimer _createPeriodicTimer(
  Duration interval,
  void Function() callback,
) => _DartAppHeartbeatPeriodicTimer(interval, callback);

String? get mobileHeartbeatPlatform {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => null,
  };
}

Future<AppHeartbeat> createAppHeartbeat(SupabaseClient client) async {
  final platform = mobileHeartbeatPlatform;
  if (platform == null) return const NoopAppHeartbeat();
  final lifecycleState = WidgetsBinding.instance.lifecycleState;
  final service = SessionHeartbeatService(
    backend: SupabaseAppHeartbeatBackend(client),
    installationStore: SharedPreferencesHeartbeatInstallationStore(),
    buildMetadata: const PackageInfoAppBuildMetadata(),
    platform: platform,
    initiallyForeground:
        lifecycleState == null || lifecycleState == AppLifecycleState.resumed,
  );
  try {
    await service.initialize();
    return service;
  } catch (_) {
    await service.dispose();
    // Optional presence reporting cannot make a healthy app fail startup.
    return const NoopAppHeartbeat();
  }
}
