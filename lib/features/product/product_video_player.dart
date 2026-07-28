import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme.dart';
import '../../core/network_media_request.dart';
import '../../data/models.dart';
import 'product_media_thumbnail.dart';
import 'product_strings.dart';

typedef ProductVideoControllerFactory =
    ProductVideoController Function(Uri uri);

abstract interface class ProductVideoController {
  bool get isInitialized;
  bool get isPlaying;
  bool get isBuffering;
  bool get hasError;
  String? get errorDescription;
  double get aspectRatio;
  Duration get duration;
  Duration get position;

  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Widget buildVideo();
  Future<void> dispose();
}

class ProductVideoPlayer extends StatefulWidget {
  const ProductVideoPlayer({
    super.key,
    required this.item,
    required this.active,
    this.controllerFactory,
  });

  final MediaItem item;
  final bool active;
  final ProductVideoControllerFactory? controllerFactory;

  @override
  State<ProductVideoPlayer> createState() => _ProductVideoPlayerState();
}

class _ProductVideoPlayerState extends State<ProductVideoPlayer>
    with WidgetsBindingObserver {
  ProductVideoController? _controller;
  Object? _error;
  bool _loading = true;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  @override
  void didUpdateWidget(covariant ProductVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.url != widget.item.url) {
      unawaited(_initialize());
    } else if (oldWidget.active && !widget.active) {
      unawaited(_pause());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_pause());
  }

  ProductVideoController _createController(Uri uri) {
    return widget.controllerFactory?.call(uri) ??
        _PlatformProductVideoController(
          uri,
          httpHeaders: NetworkMediaRequest.headersFor(uri.toString()),
        );
  }

  /// Platform players surface an authorization failure inside a free-form
  /// description: ExoPlayer reports `InvalidResponseCodeException: Response
  /// code: 401`, AVFoundation reports its own codes. Only those justify
  /// spending a full Supabase session refresh — a timeout or a decoder error
  /// would just delay the retry.
  bool get _lastFailureLooksUnauthorized {
    final description = _error?.toString().toLowerCase() ?? '';
    if (description.isEmpty) return false;
    return description.contains('401') ||
        description.contains('403') ||
        description.contains('unauthorized') ||
        description.contains('forbidden');
  }

  Future<void> _retryInitialization() async {
    if (_lastFailureLooksUnauthorized &&
        NetworkMediaRequest.headersFor(widget.item.url).isNotEmpty) {
      try {
        await NetworkMediaRequest.refreshAuthorization();
      } catch (_) {
        // The following controller attempt renders the final network outcome.
      }
    }
    // Refreshing the session is a real round trip; the viewer can be closed
    // while it is in flight, and re-entering _initialize() then would touch an
    // already disposed controller.
    if (!mounted) return;
    await _initialize();
  }

  Future<void> _initialize() async {
    final generation = ++_loadGeneration;
    final previous = _controller;
    _controller = null;
    if (previous != null) {
      previous.removeListener(_handleControllerChange);
      await previous.dispose();
    }
    if (!mounted || generation != _loadGeneration) return;

    final uri = Uri.tryParse(widget.item.url);
    if (uri == null ||
        !uri.hasAuthority ||
        !const ['http', 'https'].contains(uri.scheme)) {
      setState(() {
        _loading = false;
        _error = const FormatException('Invalid video URL');
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final controller = _createController(uri);
    _controller = controller;
    controller.addListener(_handleControllerChange);
    try {
      await controller.initialize();
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      controller.removeListener(_handleControllerChange);
      await controller.dispose();
      if (!mounted || generation != _loadGeneration) return;
      _controller = null;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  void _handleControllerChange() {
    final controller = _controller;
    if (!mounted || controller == null) return;
    if (controller.hasError) {
      _error = controller.errorDescription ?? 'Playback error';
    }
    setState(() {});
  }

  Future<void> _pause() async {
    final controller = _controller;
    if (controller?.isInitialized == true && controller!.isPlaying) {
      try {
        await controller.pause();
      } catch (_) {
        // A lifecycle pause is best-effort; playback errors are rendered by
        // the controller listener if the native player reports one.
      }
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (!widget.active || controller?.isInitialized != true) return;
    try {
      if (controller!.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _seek(double milliseconds) async {
    final controller = _controller;
    if (controller?.isInitialized != true) return;
    await controller!.seekTo(Duration(milliseconds: milliseconds.round()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadGeneration += 1;
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_handleControllerChange);
      // Clear the field too: a late _initialize() would otherwise read this
      // controller back and dispose it a second time, which throws.
      _controller = null;
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null || controller?.hasError == true) {
      return _VideoError(onRetry: () => unawaited(_retryInitialization()));
    }

    if (_loading || controller?.isInitialized != true) {
      return Stack(
        key: const Key('product-video-loading'),
        fit: StackFit.expand,
        children: [
          ProductMediaThumbnail(item: widget.item, fit: BoxFit.contain),
          Container(color: Colors.black.withValues(alpha: .46)),
          Center(child: CircularProgressIndicator(color: AppColors.gold)),
        ],
      );
    }

    final durationMs = controller!.duration.inMilliseconds;
    final positionMs = controller.position.inMilliseconds.clamp(0, durationMs);
    final ratio = controller.aspectRatio.isFinite && controller.aspectRatio > 0
        ? controller.aspectRatio
        : 16 / 9;

    return GestureDetector(
      key: const Key('product-video-ready'),
      behavior: HitTestBehavior.opaque,
      onTap: () => unawaited(_togglePlayback()),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: ratio,
              child: controller.buildVideo(),
            ),
          ),
          if (!controller.isPlaying)
            Center(
              child: Container(
                key: const Key('product-video-play'),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .55),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
            ),
          if (controller.isBuffering)
            Center(child: CircularProgressIndicator(color: AppColors.gold)),
          PositionedDirectional(
            start: AppSpacing.md,
            end: AppSpacing.md,
            bottom: 126,
            child: Row(
              children: [
                _TimeLabel(controller.position),
                Expanded(
                  child: Slider(
                    value: positionMs.toDouble(),
                    max: durationMs > 0 ? durationMs.toDouble() : 1,
                    activeColor: AppColors.gold,
                    inactiveColor: Colors.white24,
                    onChanged: durationMs > 0
                        ? (value) => unawaited(_seek(value))
                        : null,
                  ),
                ),
                _TimeLabel(controller.duration),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoError extends StatelessWidget {
  const _VideoError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('product-video-error'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_file_outlined,
              color: Colors.white54,
              size: 54,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              ProductStrings.videoLoadFailed,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              key: const Key('product-video-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(ProductStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel(this.value);

  final Duration value;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = value.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$minutes:$seconds',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PlatformProductVideoController implements ProductVideoController {
  _PlatformProductVideoController(
    Uri uri, {
    required Map<String, String> httpHeaders,
  }) : _controller = VideoPlayerController.networkUrl(
         uri,
         httpHeaders: httpHeaders,
         // Some Android hardware decoders (including Huawei's HiSilicon AVC
         // decoder) fail when video_player renders through the default
         // SurfaceProducer-backed texture. A native platform view avoids that
         // OEM codec/surface incompatibility.
         viewType: VideoViewType.platformView,
       );

  final VideoPlayerController _controller;

  @override
  bool get isInitialized => _controller.value.isInitialized;
  @override
  bool get isPlaying => _controller.value.isPlaying;
  @override
  bool get isBuffering => _controller.value.isBuffering;
  @override
  bool get hasError => _controller.value.hasError;
  @override
  String? get errorDescription => _controller.value.errorDescription;
  @override
  double get aspectRatio => _controller.value.aspectRatio;
  @override
  Duration get duration => _controller.value.duration;
  @override
  Duration get position => _controller.value.position;

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _controller.removeListener(listener);
  @override
  Future<void> initialize() => _controller.initialize();
  @override
  Future<void> play() => _controller.play();
  @override
  Future<void> pause() => _controller.pause();
  @override
  Future<void> seekTo(Duration position) => _controller.seekTo(position);
  @override
  Widget buildVideo() => VideoPlayer(_controller);
  @override
  Future<void> dispose() => _controller.dispose();
}
