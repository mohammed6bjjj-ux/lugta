import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import 'product_size_options.dart';

@Preview(
  name: 'Clothing sizes — Arabic',
  group: 'Products',
  size: Size(375, 700),
)
Widget clothingSizesPreview() =>
    MaterialApp(theme: AppTheme.light(), home: const _SizePreview());

class _SizePreview extends StatefulWidget {
  const _SizePreview();
  @override
  State<_SizePreview> createState() => _SizePreviewState();
}

class _SizePreviewState extends State<_SizePreview> {
  String? selected;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: ProductSizeOptions(
          variants: const [
            ProductVariant(
              id: 'preview-m',
              nameAr: 'أسود / M',
              size: 'M',
              imageUrl: '',
              stock: 3,
            ),
            ProductVariant(
              id: 'preview-l',
              nameAr: 'أسود / L',
              size: 'L',
              imageUrl: '',
              stock: 0,
            ),
            ProductVariant(
              id: 'preview-white',
              nameAr: 'أبيض / M',
              size: 'M',
              imageUrl: '',
              stock: 2,
            ),
          ],
          selectedId: selected,
          onSelected: (variant) => setState(() => selected = variant.id),
          availableStock: (variant) => variant.stock,
        ),
      ),
    ),
  );
}
