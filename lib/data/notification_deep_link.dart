enum NotificationDeepLinkKind {
  notifications,
  products,
  product,
  promotions,
  referrals,
  order,
}

class NotificationDeepLinkTarget {
  const NotificationDeepLinkTarget(this.kind, {this.entityId});

  final NotificationDeepLinkKind kind;
  final String? entityId;
}

/// Parses only the internal routes that notifications are allowed to open.
///
/// The server may send either an app path (`/promotions`) or the legacy custom
/// scheme (`nawl://products/<id>`). Web URLs and arbitrary application routes
/// are intentionally rejected; callers must fall back to the notifications
/// screen when this returns null.
NotificationDeepLinkTarget? parseTrustedNotificationDeepLink(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty || value.length > 512) return null;

  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.userInfo.isNotEmpty) {
    return null;
  }

  late final List<String> segments;
  final scheme = uri.scheme.toLowerCase();
  if (scheme.isEmpty) {
    if (!value.startsWith('/') || uri.host.isNotEmpty) return null;
    segments = uri.pathSegments;
  } else if (scheme == 'nawl' || scheme == 'lugta') {
    if (uri.host.isEmpty || uri.hasPort) return null;
    segments = <String>[uri.host.toLowerCase(), ...uri.pathSegments];
  } else {
    return null;
  }

  if (segments.isEmpty || segments.any((segment) => segment.isEmpty)) {
    return null;
  }

  final root = segments.first.toLowerCase();
  if (segments.length == 1) {
    return switch (root) {
      'notifications' => const NotificationDeepLinkTarget(
        NotificationDeepLinkKind.notifications,
      ),
      'products' => const NotificationDeepLinkTarget(
        NotificationDeepLinkKind.products,
      ),
      'promotions' => const NotificationDeepLinkTarget(
        NotificationDeepLinkKind.promotions,
      ),
      'referrals' => const NotificationDeepLinkTarget(
        NotificationDeepLinkKind.referrals,
      ),
      _ => null,
    };
  }

  if (segments.length != 2 || !_isSafeEntityId(segments[1])) return null;
  final id = segments[1];
  return switch (root) {
    'product' || 'products' => NotificationDeepLinkTarget(
      NotificationDeepLinkKind.product,
      entityId: id,
    ),
    'order' || 'orders' => NotificationDeepLinkTarget(
      NotificationDeepLinkKind.order,
      entityId: id,
    ),
    'promotions' => NotificationDeepLinkTarget(
      NotificationDeepLinkKind.promotions,
      entityId: id,
    ),
    _ => null,
  };
}

bool _isSafeEntityId(String value) =>
    value.length <= 128 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);
