import '../data/app_settings.dart';
import '../data/backend.dart';
import '../data/session.dart';

/// Wires local settings and backend services without downloading page data.
///
/// This runs while the Flutter splash is already visible. Catalog, orders,
/// wallet, and notifications are deliberately loaded after routing so a slow
/// network can never hold the first frame on Android's blank launch window.
class AppBootstrap {
  Future<void>? _inFlight;
  bool _isReady = false;

  Future<void> initialize() {
    if (_isReady) return Future<void>.value();
    final current = _inFlight;
    if (current != null) return current;

    late final Future<void> next;
    next = _initialize()
        .then<void>((_) {
          _isReady = true;
        })
        .whenComplete(() {
          if (identical(_inFlight, next)) _inFlight = null;
        });
    _inFlight = next;
    return next;
  }

  Future<void> _initialize() async {
    await Future.wait<void>([
      appSettings.initialize(),
      appBackend.initialize(),
    ]);
    await session.configure(
      appBackend.repositories,
      deviceTokens: appBackend.deviceTokens,
      loadInitialData: false,
    );
  }
}

final AppBootstrap appBootstrap = AppBootstrap();
