import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import 'network_image_cache.dart';
import 'network_media_request.dart';

/// Outcome of a bulk save/share so the UI can report partial success honestly.
@immutable
class MediaTransferResult {
  const MediaTransferResult({
    required this.succeeded,
    required this.failed,
    this.permissionDenied = false,
    this.dismissed = false,
  });

  final int succeeded;
  final int failed;
  final bool permissionDenied;

  /// The platform sheet opened but the user closed it without picking a target.
  final bool dismissed;

  bool get isCompleteSuccess => failed == 0 && succeeded > 0;
  bool get isCompleteFailure => succeeded == 0 && failed > 0;
}

/// Downloads product media through the shared cache and hands the real files to
/// the gallery or the platform share sheet.
///
/// Product objects live behind `/object/authenticated/` URLs, so the bytes can
/// only be fetched with the seller's JWT attached. Sharing the URL itself would
/// hand customers a link that answers 401 for everyone but the seller, which is
/// why every path here materialises an actual file first.
abstract final class MediaTransfer {
  /// Fetches the object and returns a real file with a meaningful name.
  ///
  /// Reuses [appNetworkImageCacheManager], so media the seller just viewed is
  /// already on disk and costs no second download.
  static Future<File> materialize(MediaItem item) async {
    final url = item.url.trim();
    if (url.isEmpty) {
      throw const FormatException('Media item has no URL');
    }

    final cached = await appNetworkImageCacheManager.getSingleFile(
      url,
      key: appNetworkImageCacheKey(
        url,
        authenticatedScopeKey: NetworkMediaRequest.cacheScopeFor(url),
      ),
      headers: NetworkMediaRequest.headersFor(url),
    );

    // The cache stores opaque keys, so copy to a temp file whose name is what
    // the gallery and the receiving app will display.
    final directory = await getTemporaryDirectory();
    final exportDirectory = Directory('${directory.path}/shared-media');
    if (!exportDirectory.existsSync()) {
      await exportDirectory.create(recursive: true);
    }
    final target = File('${exportDirectory.path}/${_fileName(item)}');
    return cached.copy(target.path);
  }

  /// Saves every item to the device gallery.
  static Future<MediaTransferResult> saveToGallery(
    List<MediaItem> items,
  ) async {
    if (items.isEmpty) {
      return const MediaTransferResult(succeeded: 0, failed: 0);
    }

    if (!await Gal.hasAccess()) {
      if (!await Gal.requestAccess()) {
        return MediaTransferResult(
          succeeded: 0,
          failed: items.length,
          permissionDenied: true,
        );
      }
    }

    var succeeded = 0;
    var failed = 0;
    for (final item in items) {
      try {
        final file = await materialize(item);
        if (item.isVideo) {
          await Gal.putVideo(file.path);
        } else {
          await Gal.putImage(file.path);
        }
        succeeded++;
      } on GalException catch (error) {
        failed++;
        if (error.type == GalExceptionType.accessDenied) {
          return MediaTransferResult(
            succeeded: succeeded,
            failed: items.length - succeeded,
            permissionDenied: true,
          );
        }
      } catch (_) {
        failed++;
      }
    }
    return MediaTransferResult(succeeded: succeeded, failed: failed);
  }

  /// Opens the platform share sheet with the media attached as files.
  static Future<MediaTransferResult> share(
    List<MediaItem> items, {
    String? text,
  }) async {
    if (items.isEmpty) {
      return const MediaTransferResult(succeeded: 0, failed: 0);
    }

    final files = <XFile>[];
    var failed = 0;
    for (final item in items) {
      try {
        final file = await materialize(item);
        files.add(XFile(file.path, name: _fileName(item)));
      } catch (_) {
        failed++;
      }
    }
    if (files.isEmpty) {
      return MediaTransferResult(succeeded: 0, failed: failed);
    }

    final result = await SharePlus.instance.share(
      ShareParams(files: files, text: text),
    );
    return MediaTransferResult(
      succeeded: files.length,
      failed: failed,
      dismissed: result.status == ShareResultStatus.dismissed,
    );
  }

  static String _fileName(MediaItem item) {
    final safeId = item.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    final stem = safeId.isEmpty ? 'media' : safeId;
    return '$stem${_extension(item)}';
  }

  /// Gallery pickers and receiving apps route on the extension, so never leave
  /// it to chance: fall back to the media type when the object path has none.
  static String _extension(MediaItem item) {
    final path = Uri.tryParse(item.url)?.path ?? item.url;
    final lastSegment = path.split('/').last;
    final dot = lastSegment.lastIndexOf('.');
    if (dot > 0 && dot < lastSegment.length - 1) {
      final extension = lastSegment.substring(dot).toLowerCase();
      if (RegExp(r'^\.[a-z0-9]{2,5}$').hasMatch(extension)) return extension;
    }
    return item.isVideo ? '.mp4' : '.jpg';
  }
}
