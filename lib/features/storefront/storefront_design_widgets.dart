import 'package:flutter/material.dart';
import '../../core/widgets/app_network_image.dart';
import '../../data/storefront_models.dart';

/// Preview assets can be replaced remotely, without shipping a phone build.
class StoreDesignImage extends StatelessWidget {
  const StoreDesignImage({
    super.key,
    required this.theme,
    this.full = false,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });
  final StoreTheme theme;
  final bool full;
  final double? width, height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final url = full ? theme.previewUrl : theme.thumbnailUrl;
    Widget fallback() => Image.asset(
      full ? theme.previewAsset : theme.thumbnailAsset,
      width: width,
      height: height,
      fit: fit,
      alignment: Alignment.topCenter,
      cacheWidth: full ? 1600 : 640,
      errorBuilder: (_, _, _) => SizedBox(
        width: width,
        height: height ?? 180,
        child: const Center(child: Text('المعاينة غير متاحة حالياً')),
      ),
    );
    return url.isEmpty
        ? fallback()
        : Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            alignment: Alignment.topCenter,
            cacheWidth: full ? 1600 : 640,
            semanticLabel: theme.name,
            errorBuilder: (_, _, _) => fallback(),
          );
  }
}

class StorePalettePicker extends StatelessWidget {
  const StorePalettePicker({
    super.key,
    required this.palettes,
    required this.value,
    this.onChanged,
  });
  final List<StorePalette> palettes;
  final String value;
  final ValueChanged<String>? onChanged;
  Color color(String hex, Color fallback) =>
      RegExp(r'^#[a-fA-F0-9]{6}$').hasMatch(hex)
      ? Color(int.parse('ff${hex.substring(1)}', radix: 16))
      : fallback;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('ألوان التصميم', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      const Text('نفس الترتيب والتصميم، بألوان تناسب براندك.'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in palettes)
            ChoiceChip(
              key: ValueKey('palette_${p.id}'),
              label: Text(p.name),
              selected: value == p.id,
              avatar: CircleAvatar(
                backgroundColor: value == p.id
                    ? Theme.of(context).colorScheme.primary
                    : color(p.accent, Theme.of(context).colorScheme.primary),
                radius: 10,
              ),
              showCheckmark: true,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: onChanged == null ? null : (_) => onChanged!(p.id),
            ),
        ],
      ),
    ],
  );
}

class StorefrontProductTile extends StatelessWidget {
  const StorefrontProductTile({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.variants,
    required this.onEdit,
    required this.onRemove,
    this.busy = false,
    this.loading = false,
  });
  final String name, imageUrl, price;
  final List<String> variants;
  final VoidCallback onEdit, onRemove;
  final bool busy;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 104,
                    child: ColoredBox(
                      color: colors.surfaceContainerLow,
                      child: imageUrl.isEmpty
                          ? Icon(
                              Icons.image_outlined,
                              color: colors.onSurfaceVariant,
                            )
                          : AppNetworkImage(imageUrl, fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.trim().isEmpty
                            ? 'منتج يحتاج تحديث التفاصيل'
                            : name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        variants.where((v) => v.trim().isNotEmpty).join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_outlined, size: 18),
                  label: Text(loading ? 'جارٍ التحميل…' : 'تعديل المنتج'),
                ),
                TextButton.icon(
                  onPressed: busy ? null : onRemove,
                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: const Text('إخفاء'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
