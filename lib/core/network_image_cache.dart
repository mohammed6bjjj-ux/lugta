import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'network_media_request.dart';

const _cacheName = 'nawl-network-images-v1';
const _diskDimensionBuckets = <int>[320, 640, 960, 1280, 1600];

/// Shared on-disk cache for remote images rendered by the application.
///
/// Product media uses immutable object paths, so a moderately long stale
/// period avoids downloading the same image whenever a page is recreated.
/// Weak mobile connections routinely half-open a socket: no bytes, no error.
/// The default [HttpFileService] sets no deadline, so such a request never
/// resolves — the placeholder shimmer then spins forever and no retry is ever
/// scheduled, because nothing ever fails.
const _requestTimeout = Duration(seconds: 20);

class _TimeoutHttpFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) =>
      super.get(url, headers: headers).timeout(_requestTimeout);
}

CacheManager? _appNetworkImageCacheManager;

/// A plain [CacheManager] does not implement [ImageCacheManager], and
/// cached_network_image asserts on that combination as soon as a disk resize
/// is requested — which would fail every JPEG/PNG in debug builds and silently
/// drop the resize in release. Mixing the capability in keeps both working.
class _AppImageCacheManager extends CacheManager with ImageCacheManager {
  _AppImageCacheManager(super.config);
}

CacheManager get appNetworkImageCacheManager =>
    _appNetworkImageCacheManager ??= _AppImageCacheManager(
      Config(
        _cacheName,
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 500,
        fileService: _TimeoutHttpFileService(),
      ),
    );

/// Empties the shared store, but only when it was actually created.
///
/// Merely reading [appNetworkImageCacheManager] builds a [Config], which
/// resolves the cache directory through path_provider and fails asynchronously
/// on hosts without plugins. If nothing ever instantiated it, nothing was
/// cached and there is nothing to clear.
Future<void> clearAppNetworkImageCacheIfCreated() async {
  final manager = _appNetworkImageCacheManager;
  if (manager == null) return;
  await manager.emptyCache();
}

/// Returns a stable disk/memory cache key for a remote image.
///
/// Supabase signed Storage URLs rotate their `token` query parameter even when
/// they still reference the exact same immutable object. Only that parameter
/// is removed. Stable authenticated URLs are additionally scoped per user so
/// a private on-disk object is never reused by another account on the device.
/// Transformation parameters remain part of the key.
String appNetworkImageCacheKey(String url, {String? authenticatedScopeKey}) {
  final uri = Uri.tryParse(url);
  var stableUrl = url;
  if (uri != null &&
      _isOfficialSupabaseStorageUri(uri) &&
      uri.queryParametersAll.containsKey('token')) {
    final queryParameters = <String, dynamic>{
      for (final entry in uri.queryParametersAll.entries)
        if (entry.key != 'token') entry.key: entry.value,
    };
    stableUrl = uri
        .replace(
          // An empty map clears the query. Passing null would preserve the old
          // signed token according to Uri.replace semantics.
          queryParameters: queryParameters,
        )
        .toString();
  }

  final scope = authenticatedScopeKey?.trim();
  if (scope == null ||
      scope.isEmpty ||
      !isAuthenticatedSupabaseStorageUrl(stableUrl)) {
    return stableUrl;
  }
  return '$stableUrl|auth-scope:$scope';
}

/// Quantizes device/layout-specific sizes so the same image does not create a
/// different persistent file for every phone width or orientation.
int? appNetworkImageDiskDimension(int? pixels) {
  if (pixels == null || pixels <= 0) return null;
  for (final bucket in _diskDimensionBuckets) {
    if (pixels <= bucket) return bucket;
  }
  return _diskDimensionBuckets.last;
}

/// flutter_cache_manager 3.x only persists resized derivatives for these
/// decoder extensions. Passing resize arguments for WebP/AVIF repeatedly
/// enters the resize path but returns the original file every time.
bool appNetworkImageSupportsDiskResize(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  return const [
    '.jpg',
    '.jpeg',
    '.png',
    '.tga',
    '.cur',
    '.ico',
  ].any(path.endsWith);
}

/// Mirrors flutter_cache_manager's resized-entry key so a failed/corrupt
/// derivative can be evicted together with its original before retrying.
String appNetworkImageResizedCacheKey(
  String baseKey, {
  int? maxWidth,
  int? maxHeight,
}) {
  if (maxWidth == null && maxHeight == null) return baseKey;
  final buffer = StringBuffer('resized');
  if (maxWidth != null) buffer.write('_w$maxWidth');
  if (maxHeight != null) buffer.write('_h$maxHeight');
  buffer.write('_$baseKey');
  return buffer.toString();
}

bool _isOfficialSupabaseStorageUri(Uri uri) {
  if (uri.scheme != 'https' && uri.scheme != 'http') return false;
  final host = uri.host.toLowerCase();
  final officialHost =
      host.endsWith('.supabase.co') ||
      host.endsWith('.supabase.in') ||
      host.endsWith('.supabase.red');
  final storagePath =
      uri.path.startsWith('/storage/v1/object/') ||
      (host.contains('.storage.supabase.') &&
          uri.path.startsWith('/v1/object/'));
  return officialHost && storagePath;
}
