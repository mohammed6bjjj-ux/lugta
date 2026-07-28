import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/app_network_image.dart';
import '../../data/models.dart';
import 'product_strings.dart';

class ProductMediaThumbnail extends StatelessWidget {
  const ProductMediaThumbnail({super.key, required this.item, this.fit});

  final MediaItem item;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    if (!item.isVideo) {
      return AppNetworkImage(item.url, fit: fit ?? BoxFit.cover);
    }

    final hasDedicatedThumbnail =
        item.thumbnailUrl != item.url && _looksLikeImageUrl(item.thumbnailUrl);
    if (hasDedicatedThumbnail) {
      return AppNetworkImage(item.thumbnailUrl, fit: fit ?? BoxFit.cover);
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF17261F), Color(0xFF080D0B)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .1),
                border: Border.all(color: Colors.white.withValues(alpha: .2)),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              ProductStrings.video,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _looksLikeImageUrl(String value) {
  final uri = Uri.tryParse(value);
  final path = (uri?.path ?? value).toLowerCase();
  return const ['.jpg', '.jpeg', '.png', '.webp', '.avif'].any(path.endsWith);
}
