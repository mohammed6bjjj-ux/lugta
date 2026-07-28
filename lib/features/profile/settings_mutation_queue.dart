import 'dart:async';

typedef PersistSettingsSnapshot =
    Future<SettingsSnapshot> Function(SettingsSnapshot snapshot);

class SettingsSnapshot {
  SettingsSnapshot({
    required this.locale,
    required Map<String, bool> notificationPreferences,
  }) : notificationPreferences = Map<String, bool>.unmodifiable(
         notificationPreferences,
       );

  final String locale;
  final Map<String, bool> notificationPreferences;

  SettingsSnapshot withLocale(String value) => SettingsSnapshot(
    locale: value,
    notificationPreferences: notificationPreferences,
  );

  SettingsSnapshot withNotification(String key, bool value) {
    final patched = Map<String, bool>.from(notificationPreferences);
    patched[key] = value;
    return SettingsSnapshot(locale: locale, notificationPreferences: patched);
  }
}

class SettingsMutationResult {
  const SettingsMutationResult._({
    required this.confirmed,
    required this.succeeded,
    required this.shouldRollback,
    required this.ignored,
    required this.isLatest,
    this.error,
    this.stackTrace,
  });

  factory SettingsMutationResult.success(
    SettingsSnapshot confirmed, {
    required bool isLatest,
  }) => SettingsMutationResult._(
    confirmed: confirmed,
    succeeded: true,
    shouldRollback: false,
    ignored: false,
    isLatest: isLatest,
  );

  factory SettingsMutationResult.failure(
    SettingsSnapshot confirmed, {
    required bool shouldRollback,
    required Object error,
    required StackTrace stackTrace,
  }) => SettingsMutationResult._(
    confirmed: confirmed,
    succeeded: false,
    shouldRollback: shouldRollback,
    ignored: false,
    isLatest: shouldRollback,
    error: error,
    stackTrace: stackTrace,
  );

  factory SettingsMutationResult.ignored(SettingsSnapshot confirmed) =>
      SettingsMutationResult._(
        confirmed: confirmed,
        succeeded: false,
        shouldRollback: false,
        ignored: true,
        isLatest: false,
      );

  final SettingsSnapshot confirmed;
  final bool succeeded;
  final bool shouldRollback;
  final bool ignored;
  final bool isLatest;
  final Object? error;
  final StackTrace? stackTrace;
}

/// Serializes remote settings updates and makes rollback local to the field
/// that failed. Resetting the queue invalidates every in-flight completion,
/// which prevents one account's response from changing another account's UI.
class SettingsMutationQueue {
  factory SettingsMutationQueue({
    required SettingsSnapshot initial,
    required PersistSettingsSnapshot persist,
  }) => SettingsMutationQueue._(initial, persist);

  SettingsMutationQueue._(this._confirmed, this._persist);

  final PersistSettingsSnapshot _persist;
  SettingsSnapshot _confirmed;
  Future<void> _tail = Future<void>.value();
  final Map<String, int> _notificationGenerations = {};
  int _localeGeneration = 0;
  int _nextGeneration = 0;
  int _scopeGeneration = 0;
  bool _disposed = false;
  final Map<int, int> _pendingOperationsByScope = {};

  SettingsSnapshot get confirmed => _confirmed;

  Future<void> get settled => _tail;

  bool get hasPending => (_pendingOperationsByScope[_scopeGeneration] ?? 0) > 0;

  Future<SettingsMutationResult> setNotification(String key, bool value) {
    final mutationGeneration = ++_nextGeneration;
    _notificationGenerations[key] = mutationGeneration;
    final scopeGeneration = _scopeGeneration;
    return _enqueue(() async {
      if (!_isCurrent(scopeGeneration)) {
        return SettingsMutationResult.ignored(_confirmed);
      }
      final candidate = _confirmed.withNotification(key, value);
      try {
        final persisted = await _persist(candidate);
        if (!_isCurrent(scopeGeneration)) {
          return SettingsMutationResult.ignored(_confirmed);
        }
        _confirmed = persisted;
        return SettingsMutationResult.success(
          _confirmed,
          isLatest: _notificationGenerations[key] == mutationGeneration,
        );
      } catch (error, stackTrace) {
        if (!_isCurrent(scopeGeneration)) {
          return SettingsMutationResult.ignored(_confirmed);
        }
        return SettingsMutationResult.failure(
          _confirmed,
          shouldRollback: _notificationGenerations[key] == mutationGeneration,
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<SettingsMutationResult> setLocale(String locale) {
    final mutationGeneration = ++_nextGeneration;
    _localeGeneration = mutationGeneration;
    final scopeGeneration = _scopeGeneration;
    return _enqueue(() async {
      if (!_isCurrent(scopeGeneration)) {
        return SettingsMutationResult.ignored(_confirmed);
      }
      final candidate = _confirmed.withLocale(locale);
      try {
        final persisted = await _persist(candidate);
        if (!_isCurrent(scopeGeneration)) {
          return SettingsMutationResult.ignored(_confirmed);
        }
        _confirmed = persisted;
        return SettingsMutationResult.success(
          _confirmed,
          isLatest: _localeGeneration == mutationGeneration,
        );
      } catch (error, stackTrace) {
        if (!_isCurrent(scopeGeneration)) {
          return SettingsMutationResult.ignored(_confirmed);
        }
        return SettingsMutationResult.failure(
          _confirmed,
          shouldRollback: _localeGeneration == mutationGeneration,
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
  }

  void reset(SettingsSnapshot snapshot) {
    if (_disposed) return;
    _scopeGeneration++;
    _confirmed = snapshot;
    _notificationGenerations.clear();
    _localeGeneration = 0;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _scopeGeneration++;
    _notificationGenerations.clear();
  }

  bool _isCurrent(int scopeGeneration) =>
      !_disposed && scopeGeneration == _scopeGeneration;

  Future<SettingsMutationResult> _enqueue(
    Future<SettingsMutationResult> Function() operation,
  ) {
    final pendingScope = _scopeGeneration;
    _pendingOperationsByScope.update(
      pendingScope,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    final completer = Completer<SettingsMutationResult>();
    final previous = _tail;
    _tail = () async {
      try {
        await previous;
      } catch (_) {
        // The result completer carries operation failures; keep the queue live.
      }
      try {
        try {
          completer.complete(await operation());
        } catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      } finally {
        final remaining = (_pendingOperationsByScope[pendingScope] ?? 1) - 1;
        if (remaining <= 0) {
          _pendingOperationsByScope.remove(pendingScope);
        } else {
          _pendingOperationsByScope[pendingScope] = remaining;
        }
      }
    }();
    return completer.future;
  }
}
