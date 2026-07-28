import 'dart:async';

typedef NetworkMediaHeadersProvider = Map<String, String> Function();
typedef NetworkMediaScopeProvider = String? Function();
typedef NetworkMediaAuthorizationRefresh = Future<void> Function();

/// Supplies short-lived authentication headers to image and video requests.
///
/// Private Supabase objects use a stable `/object/authenticated/` URL. The
/// current JWT is attached only when the request starts, so it is never stored
/// in product models, SharedPreferences, cache keys, or signed URLs.
abstract final class NetworkMediaRequest {
  static NetworkMediaHeadersProvider _headersProvider = () =>
      const <String, String>{};
  static NetworkMediaScopeProvider _scopeProvider = () => null;
  static NetworkMediaAuthorizationRefresh? _authorizationRefresh;
  static Future<void>? _refreshInFlight;

  static void configure({
    required NetworkMediaHeadersProvider headersProvider,
    required NetworkMediaScopeProvider scopeProvider,
    NetworkMediaAuthorizationRefresh? refreshAuthorization,
  }) {
    _headersProvider = headersProvider;
    _scopeProvider = scopeProvider;
    _authorizationRefresh = refreshAuthorization;
    _refreshInFlight = null;
  }

  static void reset() {
    _headersProvider = () => const <String, String>{};
    _scopeProvider = () => null;
    _authorizationRefresh = null;
    _refreshInFlight = null;
  }

  static Map<String, String> headersFor(String url) {
    if (!isAuthenticatedSupabaseStorageUrl(url)) {
      return const <String, String>{};
    }
    return Map<String, String>.unmodifiable(_headersProvider());
  }

  /// Separates private disk entries belonging to different signed-in users.
  static String? cacheScopeFor(String url) {
    if (!isAuthenticatedSupabaseStorageUrl(url)) return null;
    final value = _scopeProvider()?.trim();
    return value == null || value.isEmpty ? 'signed-out' : value;
  }

  /// Coalesces simultaneous 401 recoveries from a grid of images into one
  /// Supabase session refresh.
  static Future<void> refreshAuthorization() {
    final refresh = _authorizationRefresh;
    if (refresh == null) return Future<void>.value();
    final current = _refreshInFlight;
    if (current != null) return current;

    late final Future<void> next;
    next = Future<void>.sync(refresh).whenComplete(() {
      if (identical(_refreshInFlight, next)) _refreshInFlight = null;
    });
    _refreshInFlight = next;
    return next;
  }
}

bool isAuthenticatedSupabaseStorageUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return false;
  }
  final host = uri.host.toLowerCase();
  final officialHost =
      host.endsWith('.supabase.co') ||
      host.endsWith('.supabase.in') ||
      host.endsWith('.supabase.red');
  final authenticatedPath =
      uri.path.startsWith('/storage/v1/object/authenticated/') ||
      (host.contains('.storage.supabase.') &&
          uri.path.startsWith('/v1/object/authenticated/'));
  return officialHost && authenticatedPath;
}
