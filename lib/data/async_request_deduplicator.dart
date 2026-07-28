/// Keeps one asynchronous request in flight and shares its result with every
/// caller until it completes.
class AsyncRequestDeduplicator {
  Future<void>? _inFlight;

  bool get isRunning => _inFlight != null;

  /// The shared request, when one is currently running.
  ///
  /// Coordinators with differently strong refresh modes can join or sequence
  /// against the existing work without starting a duplicate request.
  Future<void>? get inFlight => _inFlight;

  Future<void> run(Future<void> Function() operation) {
    final current = _inFlight;
    if (current != null) return current;

    late final Future<void> next;
    next = Future<void>.sync(operation).whenComplete(() {
      if (identical(_inFlight, next)) _inFlight = null;
    });
    _inFlight = next;
    return next;
  }
}
