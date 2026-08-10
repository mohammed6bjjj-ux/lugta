import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../l10n/core_strings.dart';
import '../formatters.dart';
import 'app_network_image.dart';
import 'pressable.dart';

/// بطاقة المنتج المضغوطة: صورة أعرض من ارتفاعها، سطر عنوان واحد،
/// وصف أسعار واحد أنيق — أقل ارتفاعاً وأكثر كثافة بصرية.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  /// نسبة الشبكة الموحّدة لبطاقات المنتج في كل الشاشات.
  static const double gridAspectRatio = 0.72;

  /// ارتفاع القوائم الأفقية الموحّد لبطاقة بعرض [horizontalWidth].
  static const double horizontalHeight = 224;
  static const double horizontalWidth = 164;

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap:
          onTap ??
          () => Navigator.pushNamed(
            context,
            Routes.productDetail,
            arguments: product,
          ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.08,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.md - 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        // Catalog photos arrive in mixed aspect ratios. Fitting
                        // them inside the tile left a different band of empty
                        // surface around each one, so the grid read as ragged;
                        // filling the tile keeps every card identical.
                        child: AppNetworkImage(
                          product.coverImage,
                          borderRadius: BorderRadius.circular(AppRadius.md - 3),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 6,
                    start: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 3,
                      children: [
                        if (product.hasDiscount)
                          _CardBadge(
                            label: CoreStrings.badgeDiscount(
                              formatNumber(product.discountPercent),
                            ),
                            background: AppColors.error,
                          ),
                        if (!product.inStock)
                          _CardBadge(
                            label: CoreStrings.badgeOutOfStock,
                            background: AppColors.error,
                          )
                        else if (product.isNew)
                          _CardBadge(
                            label: CoreStrings.badgeNew,
                            background: AppColors.accentStrong,
                            gradient: AppColors.accentGradient,
                            foreground: AppColors.onAccent,
                          )
                        else if (product.lowStock)
                          _CardBadge(
                            label: CoreStrings.badgeLeft(
                              formatNumber(product.totalStock),
                            ),
                            background: AppColors.warning,
                          ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    top: -5,
                    end: -5,
                    child: ListenableBuilder(
                      listenable: session,
                      builder: (context, _) {
                        final isFav = session.isFavorite(product.id);
                        return Pressable(
                          onTap: () => session.toggleFavorite(product.id),
                          scale: .85,
                          minimumSize: const Size.square(48),
                          semanticLabel: isFav
                              ? CoreStrings.removeFromFavorites
                              : CoreStrings.addToFavorites,
                          semanticToggled: isFav,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: .9),
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.card,
                            ),
                            child: AnimatedSwitcher(
                              duration: AppDurations.fast,
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                key: ValueKey(isFav),
                                size: 16,
                                color: isFav
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.localizedName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // يحافظ السعر على ظهوره كاملاً، ويصغر برفق فقط عندما
                      // تصبح بطاقة الشبكة شديدة الضيق.
                      Flexible(
                        flex: product.hasDiscount ? 3 : 4,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            formatIqd(product.wholesalePrice),
                            maxLines: 1,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formatNumber(product.oldWholesalePrice!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      // السعر المقترح يُقتطع أولاً عند ضيق المساحة.
                      Expanded(
                        flex: 3,
                        child: Text(
                          CoreStrings.sellsFor(
                            formatNumber(product.suggestedPrice),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  const _CardBadge({
    required this.label,
    required this.background,
    this.gradient,
    this.foreground = Colors.white,
  });

  final String label;
  final Color background;
  final Gradient? gradient;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: gradient == null ? background : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}
