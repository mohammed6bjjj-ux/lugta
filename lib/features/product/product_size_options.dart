import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../data/models.dart';
import '../../l10n/core_strings.dart';
import 'product_strings.dart';

/// Each button is one real variant: size/color and quantity never diverge.
/// Inherits the product screen's theme; text can wrap at large accessibility sizes.
class ProductSizeOptions extends StatelessWidget {
  const ProductSizeOptions({
    super.key,
    required this.variants,
    required this.selectedId,
    required this.onSelected,
    required this.availableStock,
  });

  final List<ProductVariant> variants;
  final String? selectedId;
  final ValueChanged<ProductVariant> onSelected;
  final int Function(ProductVariant) availableStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
        final columns = largeText || constraints.maxWidth < 280 ? 1 : 2;
        final width =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(ProductStrings.chooseSize, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: variants.map((variant) {
                final stock = availableStock(variant);
                final selected = variant.id == selectedId;
                final stockLabel = stock > 0
                    ? ProductStrings.variantInStock(formatNumber(stock))
                    : CoreStrings.badgeOutOfStock;
                return SizedBox(
                  width: width,
                  child: Semantics(
                    selected: selected,
                    child: OutlinedButton(
                      key: ValueKey('product_size_${variant.id}'),
                      onPressed: stock > 0 ? () => onSelected(variant) : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                        backgroundColor: selected
                            ? colors.primaryContainer
                            : null,
                        foregroundColor: selected
                            ? colors.onPrimaryContainer
                            : colors.onSurface,
                        side: BorderSide(
                          color: selected ? colors.primary : colors.outline,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 24,
                            child: selected
                                ? const Icon(Icons.check_circle_outline)
                                : null,
                          ),
                          Text(
                            variant.hasSize
                                ? variant.size!.trim()
                                : ProductStrings.noSize,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (variant.localizedOptionName.isNotEmpty)
                            Text(
                              variant.localizedOptionName,
                              textAlign: TextAlign.center,
                            ),
                          Text(stockLabel, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
