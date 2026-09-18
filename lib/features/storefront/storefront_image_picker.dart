import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/app_network_image.dart';
import '../../data/models.dart';
import 'storefront_strings.dart';

/// Only existing product image IDs are selectable. No gallery/upload access.
class StorefrontImagePicker extends StatelessWidget {
  const StorefrontImagePicker({
    super.key,
    required this.title,
    required this.images,
    required this.value,
    required this.onChanged,
    required this.keyPrefix,
  });
  final String title;
  final List<MediaItem> images;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
      1.0,
      2.0,
    );
    final choices = images
        .where((image) => !image.isVideo && image.url.isNotEmpty)
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (choices.isEmpty && value != null)
            TextButton(
              key: ValueKey('${keyPrefix}_clear_missing'),
              onPressed: onChanged == null ? null : () => onChanged!(null),
              child: Text(
                StorefrontStrings.t(
                  'إلغاء اختيار الصورة المحذوفة',
                  'هەڵبژاردنی وێنەی سڕاوە هەڵبوەشێنەوە',
                  'Clear removed image',
                ),
              ),
            ),
          if (choices.isEmpty)
            Text(
              StorefrontStrings.t(
                'ماكو صور متاحة لهذا المنتج حالياً.',
                'ئێستا وێنەی ئەم بەرهەمە بەردەست نییە.',
                'No product images available.',
              ),
            )
          else
            SizedBox(
              height: 112 + 28 * (textScale - 1),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: choices.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final image = index == 0 ? null : choices[index - 1];
                  final selected = value == image?.id;
                  final label = image == null
                      ? StorefrontStrings.t('تلقائي', 'خۆکار', 'Automatic')
                      : StorefrontStrings.t(
                          'صورة $index',
                          'وێنە $index',
                          'Image $index',
                        );
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: '$title — $label',
                    child: SizedBox(
                      width: 88 * textScale,
                      child: OutlinedButton(
                        key: ValueKey('${keyPrefix}_${image?.id ?? 'auto'}'),
                        onPressed: onChanged == null
                            ? null
                            : () => onChanged!(image?.id),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(6),
                          side: BorderSide(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                            width: selected ? 2 : 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: image == null
                                  ? const Icon(Icons.auto_awesome_outlined)
                                  : AppNetworkImage(
                                      image.thumbnailUrl.isNotEmpty
                                          ? image.thumbnailUrl
                                          : image.url,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                            const SizedBox(height: 4),
                            if (selected)
                              const Icon(Icons.check_circle, size: 18)
                            else
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
