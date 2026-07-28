import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/media_transfer.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models.dart';
import 'product_strings.dart';
import 'product_media_thumbnail.dart';

/// نص المنشور التسويقي الجاهز للنشر: الاسم + الوصف + السعر المقترح فقط.
/// لا يتضمن سعر الجملة أبداً — آمن للنشر لزبائن البائع.
String marketingPostText(Product product) =>
    '${product.localizedName}\n\n'
    '${product.localizedDescription}\n\n'
    '${ProductStrings.postPriceLine(formatIqd(product.suggestedPrice))}';

/// يفتح ورقة سفلية قابلة للسحب لتحديد وسائط المنتج وتحميلها ومشاركتها
/// ونسخ نص المنشور التسويقي.
Future<void> showMediaShareSheet(BuildContext context, Product product) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _MediaShareSheet(product: product),
  );
}

class _MediaShareSheet extends StatefulWidget {
  const _MediaShareSheet({required this.product});

  final Product product;

  @override
  State<_MediaShareSheet> createState() => _MediaShareSheetState();
}

class _MediaShareSheetState extends State<_MediaShareSheet> {
  /// تبدأ كل الوسائط محددة — الحالة الأكثر شيوعاً هي تحميل كل شيء.
  late final Set<String> _selectedIds = {
    for (final item in widget.product.media) item.id,
  };

  bool _transferring = false;

  List<MediaItem> get _media => widget.product.media;

  bool get _allSelected =>
      _media.isNotEmpty && _selectedIds.length == _media.length;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_media.map((m) => m.id));
      }
    });
  }

  void _toggleItem(MediaItem item) {
    setState(() {
      if (!_selectedIds.remove(item.id)) {
        _selectedIds.add(item.id);
      }
    });
  }

  List<MediaItem> get _selectedMedia => [
    for (final item in _media)
      if (_selectedIds.contains(item.id)) item,
  ];

  /// Downloads the selected objects with the seller's credentials attached and
  /// hands the real files to the gallery or the platform share sheet. Sharing
  /// the raw URL instead would give customers a link that answers 401.
  Future<void> _runTransfer(
    Future<MediaTransferResult> Function(List<MediaItem> items) action, {
    required String failureMessage,
    required bool announceSuccess,
  }) async {
    final items = _selectedMedia;
    if (_transferring || items.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _transferring = true);
    messenger.showSnackBar(
      SnackBar(content: Text(ProductStrings.mediaPreparing)),
    );

    MediaTransferResult result;
    try {
      result = await action(items);
    } catch (_) {
      result = MediaTransferResult(succeeded: 0, failed: items.length);
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

  Future<void> _downloadSelected() => _runTransfer(
    MediaTransfer.saveToGallery,
    failureMessage: ProductStrings.mediaSaveFailed,
    announceSuccess: true,
  );

  Future<void> _shareSelected() => _runTransfer(
    (items) =>
        MediaTransfer.share(items, text: marketingPostText(widget.product)),
    failureMessage: ProductStrings.mediaShareFailed,
    announceSuccess: false,
  );

  Future<void> _copyPostText() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await Clipboard.setData(
      ClipboardData(text: marketingPostText(widget.product)),
    );
    if (!mounted) {
      return;
    }
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(ProductStrings.postTextCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .8,
      minChildSize: .5,
      maxChildSize: .95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ProductStrings.downloadAndShareMedia,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedIds.isEmpty
                            ? ProductStrings.nothingSelectedYet
                            : ProductStrings.selectedOf(
                                formatNumber(_selectedIds.length),
                                formatNumber(_media.length),
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _media.isEmpty ? null : _toggleSelectAll,
                  child: Text(
                    _allSelected
                        ? ProductStrings.deselectAll
                        : ProductStrings.selectAll,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: AppSpacing.sm + 2,
                crossAxisSpacing: AppSpacing.sm + 2,
              ),
              itemCount: _media.length,
              itemBuilder: (context, index) => Entrance(
                index: index,
                baseDelay: const Duration(milliseconds: 30),
                offsetY: 16,
                child: _MediaTile(
                  item: _media[index],
                  selected: _selectedIds.contains(_media[index].id),
                  onTap: () => _toggleItem(_media[index]),
                ),
              ),
            ),
          ),
          const Divider(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm + 4,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: ProductStrings.downloadToDevice,
                          icon: Icons.download_rounded,
                          gold: true,
                          onPressed: _selectedIds.isEmpty
                              ? null
                              : _downloadSelected,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SecondaryButton(
                          label: ProductStrings.share,
                          icon: Icons.share_outlined,
                          onPressed: _selectedIds.isEmpty
                              ? null
                              : _shareSelected,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: ProductStrings.copyPostText,
                    icon: Icons.copy_rounded,
                    onPressed: _copyPostText,
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  // ملاحظة الأمان: بطاقة ذهبية ناعمة بأيقونة درع.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: AppColors.goldDark,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            ProductStrings.safeContentNote,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.goldDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// مربع وسائط واحد داخل شبكة التحديد — حد ذهبي متحرك وصح يظهر بتكبير ناعم.
class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final MediaItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.gold : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected ? AppShadows.goldGlow : AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md - 2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductMediaThumbnail(item: item),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: AppDurations.fast,
                child: Container(color: AppColors.gold.withValues(alpha: .18)),
              ),
              PositionedDirectional(
                top: 6,
                end: 6,
                child: AnimatedSwitcher(
                  duration: AppDurations.fast,
                  switchInCurve: AppCurves.spring,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Container(
                    key: ValueKey(selected),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: selected ? AppColors.goldGradient : null,
                      color: selected
                          ? null
                          : Colors.black.withValues(alpha: .35),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
              if (item.isVideo)
                PositionedDirectional(
                  bottom: 6,
                  start: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.videocam_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          ProductStrings.video,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
