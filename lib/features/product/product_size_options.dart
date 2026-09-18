import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../data/models.dart';
import '../../l10n/core_strings.dart';
import 'product_size_labels.dart';
import 'product_strings.dart';

/// Color first, then size. Every completed choice still returns one real SKU.
class ProductSizeOptions extends StatefulWidget {
  const ProductSizeOptions({
    super.key,
    required this.variants,
    required this.selectedId,
    required this.onSelected,
    required this.onSelectionCleared,
    required this.availableStock,
  });

  final List<ProductVariant> variants;
  final String? selectedId;
  final ValueChanged<ProductVariant> onSelected;
  final VoidCallback onSelectionCleared;
  final int Function(ProductVariant) availableStock;

  @override
  State<ProductSizeOptions> createState() => _ProductSizeOptionsState();
}

class _ProductSizeOptionsState extends State<ProductSizeOptions> {
  String? _optionKey;
  String? _pendingSize;

  ProductVariant? get _selected {
    for (final variant in widget.variants) {
      if (variant.id == widget.selectedId) return variant;
    }
    return null;
  }

  @override
  void didUpdateWidget(ProductSizeOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId && _selected != null) {
      _optionKey = productVariantOptionKey(_selected!);
      _pendingSize = null;
    }
  }

  void _chooseOption(String key, List<ProductVariant> variants) {
    final previousSize = _selected == null
        ? null
        : productSizeLabel(_selected!.size);
    final matching = variants.where(
      (v) => productSizeLabel(v.size) == previousSize,
    );
    setState(() {
      _optionKey = key;
      _pendingSize = null;
    });
    // Never silently substitute another size or choose between duplicate SKUs.
    if (matching.length == 1 && widget.availableStock(matching.single) > 0) {
      widget.onSelected(matching.single);
    } else {
      widget.onSelectionCleared();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = _selected;
    final options = <String, List<ProductVariant>>{};
    for (final variant in widget.variants) {
      options
          .putIfAbsent(productVariantOptionKey(variant), () => [])
          .add(variant);
    }
    if (options.isEmpty) {
      return Text(
        ProductStrings.outOfStockTemporarily,
        style: theme.textTheme.bodyMedium,
      );
    }
    final preferred =
        _optionKey ??
        (selected == null ? null : productVariantOptionKey(selected));
    final activeKey = options.containsKey(preferred)
        ? preferred!
        : options.entries
              .firstWhere(
                (entry) => entry.value.any((v) => widget.availableStock(v) > 0),
                orElse: () => options.entries.first,
              )
              .key;
    final activeVariants = options[activeKey]!;
    final sizes = <String, List<ProductVariant>>{};
    for (final variant in activeVariants) {
      sizes.putIfAbsent(productSizeLabel(variant.size), () => []).add(variant);
    }
    final labels = sizes.keys.toList()..sort(compareProductSizes);
    final activeSelected =
        selected != null && productVariantOptionKey(selected) == activeKey
        ? selected
        : null;
    final selectedSize = activeSelected == null
        ? null
        : productSizeLabel(activeSelected.size);
    final pendingSize = _pendingSize ?? selectedSize;
    final pendingVariants = sizes[pendingSize] ?? const <ProductVariant>[];
    final showOptions =
        options.length > 1 ||
        productVariantOptionLabel(activeVariants.first).isNotEmpty;
    final hasAvailable = activeVariants.any(
      (v) => widget.availableStock(v) > 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showOptions) ...[
          Text(ProductStrings.colorOrStyle, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: options.entries.map((entry) {
                final variant = entry.value.first;
                final label = productVariantOptionLabel(variant);
                final isActive = entry.key == activeKey;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: _ChoiceButton(
                    key: ValueKey('product_color_${variant.id}'),
                    label: label.isEmpty ? ProductStrings.defaultOption : label,
                    selected: isActive,
                    // Filters stay operable even when all their sizes sold out.
                    onPressed: () {
                      if (!isActive) _chooseOption(entry.key, entry.value);
                    },
                    swatch: variant.colorHex == null
                        ? null
                        : Color(variant.colorHex!),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(ProductStrings.sizeLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final compactWidth = math.min(
              constraints.maxWidth,
              math.max(56.0, 40 * textScale + 16),
            );
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: labels.map((size) {
                final variants = sizes[size]!;
                final available = variants.any(
                  (v) => widget.availableStock(v) > 0,
                );
                final isSelected = size == pendingSize;
                final label = size.isEmpty ? ProductStrings.noSize : size;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: compactWidth,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: _ChoiceButton(
                    key: ValueKey('product_size_$size'),
                    label: label,
                    selected: isSelected,
                    unavailable: !available,
                    onPressed: !available
                        ? null
                        : () {
                            if (variants.length == 1) {
                              setState(() => _pendingSize = null);
                              widget.onSelected(variants.single);
                            } else {
                              setState(() => _pendingSize = size);
                              if (selectedSize != size) {
                                widget.onSelectionCleared();
                              }
                            }
                          },
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (pendingVariants.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            ProductStrings.chooseExactOption,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (index, variant) in pendingVariants.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            _ChoiceButton(
              key: ValueKey('product_variant_${variant.id}'),
              label: variant.sku?.trim().isNotEmpty == true
                  ? variant.sku!.trim()
                  : ProductStrings.numberedOption(formatNumber(index + 1)),
              supportingLabel: _stockLabel(variant),
              selected: variant.id == activeSelected?.id,
              unavailable: widget.availableStock(variant) <= 0,
              onPressed: widget.availableStock(variant) <= 0
                  ? null
                  : () => widget.onSelected(variant),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  activeSelected != null &&
                          widget.availableStock(activeSelected) > 0
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  activeSelected != null
                      ? '${productVariantOptionLabel(activeSelected)} '
                            '${selectedSize!.isEmpty ? ProductStrings.noSize : selectedSize}'
                            ' · ${_stockLabel(activeSelected)}'
                      : !hasAvailable
                      ? ProductStrings.outOfStockTemporarily
                      : ProductStrings.chooseSizeOnly,
                  key: const ValueKey('product_size_status'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _stockLabel(ProductVariant variant) =>
      widget.availableStock(variant) > 0
      ? ProductStrings.variantInStock(
          formatNumber(widget.availableStock(variant)),
        )
      : CoreStrings.badgeOutOfStock;
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.unavailable = false,
    this.swatch,
    this.supportingLabel,
  });

  final String label;
  final bool selected;
  final bool unavailable;
  final VoidCallback? onPressed;
  final Color? swatch;
  final String? supportingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = unavailable
        ? colors.onSurfaceVariant
        : selected
        ? colors.onPrimary
        : colors.onSurface;
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        label: unavailable
            ? '$label, ${ProductStrings.outOfStockTemporarily}'
            : label,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            backgroundColor: selected && !unavailable
                ? colors.primary
                : unavailable
                ? colors.surfaceContainer
                : colors.surface,
            foregroundColor: foreground,
            disabledForegroundColor: foreground,
            side: BorderSide(
              color: selected ? colors.primary : colors.outline,
              width: selected ? 2 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            animationDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppDurations.fast,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (swatch != null) ...[
                    ExcludeSemantics(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: swatch,
                          shape: BoxShape.circle,
                          border: Border.all(color: foreground),
                        ),
                        child: const SizedBox.square(dimension: 16),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExcludeSemantics(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w700,
                              decoration: unavailable
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (supportingLabel != null)
                          Text(
                            supportingLabel!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: foreground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // A fixed slot keeps color and SKU controls stable on selection.
                  if (swatch != null || supportingLabel != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox.square(
                      dimension: 16,
                      child: selected
                          ? ExcludeSemantics(
                              child: Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: foreground,
                              ),
                            )
                          : null,
                    ),
                  ],
                ],
              ),
              if (selected && swatch == null && supportingLabel == null)
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  top: -4,
                  end: -12,
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: foreground,
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
