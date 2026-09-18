import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import 'product_size_options.dart';
import 'product_strings.dart';

@Preview(name: 'Clothing — phone', group: 'Products', size: Size(375, 700))
Widget clothingSizesPreview() =>
    MaterialApp(theme: AppTheme.light(), home: const ClothingSizePreview());

@Preview(name: 'Clothing — dark', group: 'Products', size: Size(375, 700))
Widget clothingSizesDarkPreview() =>
    MaterialApp(theme: AppTheme.dark(), home: const ClothingSizePreview());

@Preview(name: 'Clothing — landscape', group: 'Products', size: Size(800, 375))
Widget clothingSizesLandscapePreview() =>
    MaterialApp(theme: AppTheme.light(), home: const ClothingSizePreview());

@Preview(name: 'Clothing — large text', group: 'Products', size: Size(375, 800))
Widget clothingSizesLargeTextPreview() => MaterialApp(
  theme: AppTheme.light(),
  home: const ClothingSizePreview(textScale: 2),
);

/// Interactive, dependency-free fixtures for visual and widget verification.
const clothingPreviewVariants = [
  ProductVariant(
    id: 'black-xl',
    nameAr: 'أسود / XLarge',
    nameEn: 'Black / XLarge',
    size: 'XLarge',
    imageUrl: '',
    stock: 5,
    colorHex: 0xFF202035,
  ),
  ProductVariant(
    id: 'black-s',
    nameAr: 'أسود / S',
    nameEn: 'Black / S',
    size: 'S',
    imageUrl: '',
    stock: 4,
    colorHex: 0xFF202035,
  ),
  ProductVariant(
    id: 'black-m',
    nameAr: 'أسود / Medium',
    nameEn: 'Black / Medium',
    size: 'Medium',
    imageUrl: '',
    stock: 3,
    colorHex: 0xFF202035,
  ),
  ProductVariant(
    id: 'black-l',
    nameAr: 'أسود / L',
    nameEn: 'Black / L',
    size: 'L',
    imageUrl: '',
    stock: 0,
    colorHex: 0xFF202035,
  ),
  ProductVariant(
    id: 'black-xxl',
    nameAr: 'أسود / 2XL',
    nameEn: 'Black / 2XL',
    size: '2XL',
    imageUrl: '',
    stock: 2,
    colorHex: 0xFF202035,
  ),
  ProductVariant(
    id: 'white-m',
    nameAr: 'أبيض / M',
    nameEn: 'White / M',
    size: 'M',
    imageUrl: '',
    stock: 2,
    colorHex: 0xFFFFFFFF,
  ),
  ProductVariant(
    id: 'white-l',
    nameAr: 'أبيض / Large',
    nameEn: 'White / Large',
    size: 'Large',
    imageUrl: '',
    stock: 4,
    colorHex: 0xFFFFFFFF,
  ),
  ProductVariant(
    id: 'white-xl',
    nameAr: 'أبيض / XL',
    nameEn: 'White / XL',
    size: 'XL',
    imageUrl: '',
    stock: 0,
    colorHex: 0xFFFFFFFF,
  ),
];

class ClothingSizePreview extends StatefulWidget {
  const ClothingSizePreview({super.key, this.textScale = 1});
  final double textScale;

  @override
  State<ClothingSizePreview> createState() => _ClothingSizePreviewState();
}

class _ClothingSizePreviewState extends State<ClothingSizePreview> {
  String? selected = 'black-m';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(widget.textScale)),
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      ProductStrings.sizesAndColors,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ProductSizeOptions(
                      variants: clothingPreviewVariants,
                      selectedId: selected,
                      onSelected: (variant) =>
                          setState(() => selected = variant.id),
                      onSelectionCleared: () => setState(() => selected = null),
                      availableStock: (variant) => variant.stock,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
