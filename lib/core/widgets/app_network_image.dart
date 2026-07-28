import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../app/theme.dart';
import '../../l10n/core_strings.dart';
import '../network_image_cache.dart';
import '../network_media_request.dart';
import 'shimmer.dart';

/// Cache-first remote image with bounded recovery for weak connections.
class AppNetworkImage extends StatefulWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.watch_outlined,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  static const _maxRetries = 2;
  static const _maxCachedDimension = 1600;

  Timer? _retryTimer;
  int _retryAttempt = 0;
  // Remounting is driven by this counter rather than by [_retryAttempt]: a
  // non-retryable failure pins the attempt number, so reusing it would leave
  // the key unchanged and every manual retry after the first would be a no-op.
  int _renderGeneration = 0;
  bool _retrying = false;
  int? _lastDiskWidth;
  int? _lastDiskHeight;
  Object? _lastError;

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryAttempt = 0;
    _retrying = false;
    _lastError = null;
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleRetry(Object error) {
    _lastError = error;
    if (_retryAttempt >= _maxRetries ||
        _retryTimer != null ||
        _retrying ||
        !appNetworkImageFailureIsRetryable(error)) {
      return;
    }

    final nextAttempt = _retryAttempt + 1;
    final delay = switch (nextAttempt) {
      1 => const Duration(milliseconds: 500),
      _ => const Duration(milliseconds: 1500),
    };
    final failedUrl = widget.url;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (!mounted || failedUrl != widget.url) return;
      _retrying = true;
      unawaited(_retry(failedUrl, nextAttempt, error));
    });
  }

  Future<void> _retry(String failedUrl, int nextAttempt, Object error) async {
    try {
      await _recoverAndRemount(failedUrl, nextAttempt, error);
    } finally {
      // Never strand the guard: both _scheduleRetry and _retryManually bail out
      // while it is set, so leaking it would disable retrying for good.
      _retrying = false;
    }
  }

  Future<void> _recoverAndRemount(
    String failedUrl,
    int nextAttempt,
    Object error,
  ) async {
    final cacheKey = appNetworkImageCacheKey(
      failedUrl,
      authenticatedScopeKey: NetworkMediaRequest.cacheScopeFor(failedUrl),
    );
    try {
      if (appNetworkImageFailureStatus(error) == 401) {
        await NetworkMediaRequest.refreshAuthorization();
      }

      // Offline/DNS/5xx errors do not prove that a cached file is bad. Keep
      // the last valid bytes and only purge files after a decoder failure.
      if (appNetworkImageFailureIsCorrupt(error)) {
        final resizedKey = appNetworkImageResizedCacheKey(
          cacheKey,
          maxWidth: _lastDiskWidth,
          maxHeight: _lastDiskHeight,
        );
        if (resizedKey != cacheKey) {
          await appNetworkImageCacheManager.removeFile(resizedKey);
        }
        await appNetworkImageCacheManager.removeFile(cacheKey);
      }

      await CachedNetworkImageProvider(
        failedUrl,
        headers: NetworkMediaRequest.headersFor(failedUrl),
        cacheKey: cacheKey,
        cacheManager: appNetworkImageCacheManager,
        maxWidth: _lastDiskWidth,
        maxHeight: _lastDiskHeight,
      ).evict();
    } catch (_) {
      // Cache/auth recovery is best-effort; the bounded render retry remains.
    }
    if (!mounted || failedUrl != widget.url || widget.url.isEmpty) return;
    setState(() {
      _retryAttempt = nextAttempt;
      _renderGeneration++;
    });
  }

  void _retryManually() {
    if (_retrying || widget.url.isEmpty) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryAttempt = 0;
    _retrying = true;
    unawaited(
      _retry(
        widget.url,
        1,
        _lastError ?? TimeoutException('Manual image retry'),
      ),
    );
  }

  int? _pixelDimension(double? explicit, double constrained, double ratio) {
    final logical = explicit != null && explicit.isFinite
        ? explicit
        : (constrained.isFinite ? constrained : null);
    if (logical == null || !logical.isFinite || logical <= 0) return null;
    return (logical * ratio).ceil().clamp(1, _maxCachedDimension);
  }

  @override
  Widget build(BuildContext context) {
    // A Container that has a child ignores BoxConstraints.expand and shrinks to
    // that child, so without an explicit size the placeholder collapsed to the
    // 34px icon — in the fullscreen viewer that read as a thin band floating on
    // black. Fall back to the incoming constraints whenever they are bounded.
    Widget fallback(BoxConstraints constraints, {bool canRetry = false}) {
      final width =
          widget.width ??
          (constraints.hasBoundedWidth ? constraints.maxWidth : null);
      final height =
          widget.height ??
          (constraints.hasBoundedHeight ? constraints.maxHeight : null);
      final shortestSide = [
        if (width != null && width.isFinite) width,
        if (height != null && height.isFinite) height,
      ].fold<double>(double.infinity, (value, side) => min(value, side));
      final compact = shortestSide < 120;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canRetry ? _retryManually : null,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.goldSoft, AppColors.surfaceAlt],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.fallbackIcon,
                    size: compact ? 28 : 44,
                    color: AppColors.goldDark.withValues(alpha: .5),
                  ),
                  // A tile too small for a label keeps the corner glyph below.
                  if (canRetry && !compact) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      CoreStrings.imageUnavailableTapToRetry,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDark.withValues(alpha: .85),
                      ),
                    ),
                  ],
                ],
              ),
              if (canRetry && compact)
                PositionedDirectional(
                  end: 8,
                  bottom: 8,
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppColors.goldDark.withValues(alpha: .78),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    Widget buildImage(BoxConstraints constraints) {
      if (widget.url.isEmpty) return fallback(constraints);
      final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
      final boxWidth = _pixelDimension(
        widget.width,
        constraints.maxWidth,
        pixelRatio,
      );
      final boxHeight = _pixelDimension(
        widget.height,
        constraints.maxHeight,
        pixelRatio,
      );
      // Supplying BOTH axes makes ResizeImage fall into ResizeImagePolicy.exact
      // and decode straight to the box, which destroys the source aspect ratio
      // and leaves BoxFit nothing to crop or letterbox. Constrain the longer
      // edge only so the decoder keeps the proportions.
      final int? memoryWidth;
      final int? memoryHeight;
      if (boxWidth != null && boxHeight != null) {
        final constrainWidth = boxWidth >= boxHeight;
        memoryWidth = constrainWidth ? boxWidth : null;
        memoryHeight = constrainWidth ? null : boxHeight;
      } else {
        memoryWidth = boxWidth;
        memoryHeight = boxHeight;
      }
      final supportsDiskResize = appNetworkImageSupportsDiskResize(widget.url);
      // At most one of these is non-null, so the stored derivative keeps the
      // aspect ratio too.
      final diskWidth = supportsDiskResize
          ? appNetworkImageDiskDimension(memoryWidth)
          : null;
      final diskHeight = supportsDiskResize
          ? appNetworkImageDiskDimension(memoryHeight)
          : null;
      _lastDiskWidth = diskWidth;
      _lastDiskHeight = diskHeight;
      final cacheKey = appNetworkImageCacheKey(
        widget.url,
        authenticatedScopeKey: NetworkMediaRequest.cacheScopeFor(widget.url),
      );

      return CachedNetworkImage(
        key: ValueKey((widget.url, _renderGeneration)),
        imageUrl: widget.url,
        httpHeaders: NetworkMediaRequest.headersFor(widget.url),
        cacheKey: cacheKey,
        cacheManager: appNetworkImageCacheManager,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        memCacheWidth: memoryWidth,
        memCacheHeight: memoryHeight,
        maxWidthDiskCache: diskWidth,
        maxHeightDiskCache: diskHeight,
        fadeInDuration: AppDurations.base,
        fadeOutDuration: AppDurations.fast,
        useOldImageOnUrlChange: true,
        placeholder: (context, url) =>
            ShimmerBox(width: widget.width, height: widget.height),
        errorWidget: (context, url, error) {
          _scheduleRetry(error);
          return fallback(
            constraints,
            canRetry:
                _retryAttempt >= _maxRetries ||
                !appNetworkImageFailureIsRetryable(error),
          );
        },
      );
    }

    Widget image = LayoutBuilder(
      builder: (context, constraints) {
        return buildImage(constraints);
      },
    );
    if (widget.borderRadius != null) {
      image = ClipRRect(borderRadius: widget.borderRadius!, child: image);
    }
    return image;
  }
}

int? appNetworkImageFailureStatus(Object error) =>
    error is HttpExceptionWithStatus ? error.statusCode : null;

bool appNetworkImageFailureIsCorrupt(Object error) {
  final type = error.runtimeType.toString().toLowerCase();
  final message = error.toString().toLowerCase();
  return type.contains('imagecodecexception') ||
      message.contains('invalid image data') ||
      message.contains('failed to decode image') ||
      message.contains('could not instantiate image codec');
}

bool appNetworkImageFailureIsRetryable(Object error) {
  if (appNetworkImageFailureIsCorrupt(error) || error is TimeoutException) {
    return true;
  }

  final status = appNetworkImageFailureStatus(error);
  if (status != null) {
    return status == 401 ||
        status == 408 ||
        status == 425 ||
        status == 429 ||
        status >= 500;
  }

  final type = error.runtimeType.toString().toLowerCase();
  if (type.contains('socketexception') ||
      type.contains('clientexception') ||
      type.contains('handshakeexception') ||
      type.contains('httpexception') ||
      type.contains('tlsexception')) {
    return true;
  }

  final message = error.toString().toLowerCase();
  return _retryableImageMessages.any(message.contains);
}

const _retryableImageMessages = <String>[
  'connection reset',
  'connection refused',
  'connection timed out',
  'failed host lookup',
  'network is unreachable',
  'networkerror',
  'software caused connection abort',
  'failed to fetch',
];
