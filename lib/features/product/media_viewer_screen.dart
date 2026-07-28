import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/media_transfer.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models.dart';
import 'product_strings.dart';
import 'product_video_player.dart';

/// عارض الوسائط بملء الشاشة: خلفية سوداء نقية، صور بتكبير قرصة،
/// فيديو بمشغّل فعلي مع عناصر تحكم، وأشرطة زجاجية داكنة عائمة.
class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({
    super.key,
    required this.media,
    required this.initialIndex,
  });

  final List<MediaItem> media;
  final int initialIndex;

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}
class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final int _safeInitialIndex = widget.media.isEmpty
      ? 0
      : widget.initialIndex.clamp(0, widget.media.length - 1);
  late final PageController _pageController = PageController(
    initialPage: _safeInitialIndex,
  );
  late int _current = _safeInitialIndex;
  bool _transferring = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Guards against a second tap while a download/share is already running and
  /// reports the outcome once, from a messenger captured before the await.
  Future<void> _runTransfer(
    Future<MediaTransferResult> Function(List<MediaItem> items) action, {
    required String failureMessage,
    required bool announceSuccess,
  }) async {
    if (_transferring || widget.media.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _transferring = true);
    messenger.showSnackBar(
      SnackBar(content: Text(ProductStrings.mediaPreparing)),
    );

    MediaTransferResult result;
    try {
      result = await action([widget.media[_current]]);
    } catch (_) {
      result = const MediaTransferResult(succeeded: 0, failed: 1);
    }
    if (!mounted) return;
    setState(() => _transferring = false);

    messenger.hideCurrentSnackBar();
    if (result.dismissed) return;
    final message = switch (result) {
      MediaTransferResult(permissionDenied: true) =>
        ProductStrings.mediaPermissionDenied,
      MediaTransferResult(isCompleteFailure: true) => failureMessage,
      // The share sheet already confirms itself; only saving needs a receipt.
      _ when !announceSuccess => null,
      _ => ProductStrings.mediaSaved(formatNumber(result.succeeded)),
    };
    if (message == null) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _download() => _runTransfer(
    MediaTransfer.saveToGallery,
    failureMessage: ProductStrings.mediaSaveFailed,
    announceSuccess: true,
  );

  /// Opens the platform share sheet with the file attached.
  ///
  /// The previous in-app sheet listed WhatsApp/Instagram/Telegram, none of which
  /// it could actually target, and its "copy link" put a private
  /// `/object/authenticated/` URL on the clipboard — a link that answers 401 for
  /// every customer the seller sends it to. The OS sheet lists the apps that are
  /// really installed and receives the media itself.
  Future<void> _share() => _runTransfer(
    MediaTransfer.share,
    failureMessage: ProductStrings.mediaShareFailed,
    announceSuccess: false,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = widget.media;
    return Scaffold(
      backgroundColor: Colors.black,
      body: media.isEmpty
          ? Center(
              child: Text(
                ProductStrings.noMedia,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: media.length,
                    onPageChanged: (index) => setState(() => _current = index),
                    itemBuilder: (context, index) {
                      final item = media[index];
                      if (item.isVideo) {
                        return ProductVideoPlayer(
                          item: item,
                          active: index == _current,
                        );
                      }
                      return InteractiveViewer(
                        maxScale: 4,
                        child: Center(
                          // مطابقة Hero مع معرض شاشة التفاصيل.
                          child: Hero(
                            tag: item.id,
                            child: AppNetworkImage(
                              item.url,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildTopBar(theme, media.length),
                _buildBottomBar(),
              ],
            ),
    );
  }

  // ─────────────────────────── الشريط العلوي الزجاجي ───────────────────────────

  Widget _buildTopBar(ThemeData theme, int count) {
    return PositionedDirectional(
      top: 0,
      start: 0,
      end: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _GlassIconButton(
                tooltip: ProductStrings.close,
                icon: Icons.close_rounded,
                // Report the page the seller ended on so the gallery can align
                // to it; otherwise the Hero has no matching destination tag and
                // the image snaps instead of flying back.
                onTap: () => Navigator.pop(context, _current),
              ),
              // عدّاد الصفحات داخل كبسولة زجاجية.
              Expanded(
                child: Center(
                  child: FrostedPanel(
                    borderRadius: BorderRadius.circular(100),
                    fillAlpha: .1,
                    blur: 12,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 6,
                      ),
                      child: Text(
                        '${formatNumber(_current + 1)} / ${formatNumber(count)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // موازنة بصرية لزر الإغلاق كي يبقى العدّاد بالمنتصف.
              const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── الشريط السفلي الزجاجي ───────────────────────────

  Widget _buildBottomBar() {
    return PositionedDirectional(
      bottom: 0,
      start: 0,
      end: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FrostedPanel(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            fillAlpha: .1,
            blur: 16,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Row(
                children: [
                  Expanded(
                    child: _ViewerActionButton(
                      icon: Icons.download_rounded,
                      label: ProductStrings.download,
                      onTap: _download,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ViewerActionButton(
                      icon: Icons.share_outlined,
                      label: ProductStrings.share,
                      onTap: _share,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// زر دائري زجاجي داكن للعارض.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = Pressable(
      onTap: onTap,
      child: FrostedPanel(
        borderRadius: BorderRadius.circular(100),
        fillAlpha: .12,
        blur: 12,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class _ViewerActionButton extends StatelessWidget {
  const _ViewerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
