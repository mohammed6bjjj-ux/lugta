import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import 'network_image_cache.dart';
import 'network_media_request.dart';

/// Native DownloadManager owns bytes/progress/retries, independently of Flutter.
abstract final class BackgroundMediaDownloads {
  static const channel = MethodChannel('lugta/media_downloads');
  static final _pending = <String, Future<String>>{};

  static Future<bool> supported() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await channel.invokeMethod<bool>('supported') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> openDownloads() => channel.invokeMethod('openDownloads');

  static Future<String> enqueue(MediaItem item, String name) {
    final url = item.url.trim();
    final key = appNetworkImageCacheKey(
      url,
      authenticatedScopeKey: NetworkMediaRequest.cacheScopeFor(url),
    );
    return _pending.putIfAbsent(
      key,
      () => _enqueue(item, name, key).whenComplete(() {
        _pending.remove(key);
      }),
    );
  }

  static Future<String> _enqueue(
    MediaItem item,
    String name,
    String key,
  ) async {
    final previous = await channel.invokeMapMethod<String, dynamic>('lookup', {
      'key': key,
    });
    if (previous?['state'] == 'queued' || previous?['state'] == 'saved') {
      return previous!['state'] as String;
    }
    final url = await NetworkMediaRequest.backgroundDownloadUrl(
      item.url.trim(),
    ).timeout(const Duration(seconds: 25));
    final response = await channel.invokeMapMethod<String, dynamic>('enqueue', {
      'key': key,
      'url': url,
      'name': name,
      'video': item.isVideo,
    });
    final state = response?['state'];
    if (state != 'queued' && state != 'saved') {
      throw StateError('Download was not accepted');
    }
    return state as String;
  }
}
