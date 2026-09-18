import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import '../data/product_links.dart';

/// Holds a cold-start link while existing onboarding/auth/approval runs.
/// Only MainShell consumes it; no link can bypass those access gates.
class ProductLinkInbox extends ChangeNotifier {
  String? _pending;
  String? get pending => _pending;
  String? _last;
  DateTime? _lastAt;
  StreamSubscription<Uri>? _subscription;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    try {
      _subscription = AppLinks().uriLinkStream.listen(
        accept,
        onError: (Object _) {},
      );
    } catch (_) {
      // Unsupported platform/preview must not prevent application startup.
    }
  }

  void accept(Uri uri) {
    final id = ProductLinks.parse(uri);
    if (id == null) return; // Leave OAuth and all other link types untouched.
    final now = DateTime.now();
    if (_last == id &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 2)) {
      return;
    }
    _last = id;
    _lastAt = now;
    _pending = id; // Latest explicit tap wins while waiting for authentication.
    notifyListeners();
  }

  String? take() {
    final id = _pending;
    _pending = null;
    return id;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

final productLinkInbox = ProductLinkInbox();
