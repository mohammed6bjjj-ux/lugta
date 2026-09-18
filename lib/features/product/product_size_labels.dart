import '../../data/models.dart';

/// Display-only aliases. Stock, prices and cart operations always use variant ID.
String productSizeLabel(String? value) {
  final label = value?.trim() ?? '';
  final key = label.toUpperCase().replaceAll(RegExp(r'[\s_-]+'), '');
  return switch (key) {
    'EXTRASMALL' || 'XSMALL' || 'XS' => 'XS',
    'SMALL' || 'S' => 'S',
    'MEDIUM' || 'M' => 'M',
    'LARGE' || 'L' => 'L',
    'EXTRALARGE' || 'XLARGE' || 'XL' => 'XL',
    'XXLARGE' || 'XXL' || '2XL' || '2XLARGE' || 'DOUBLEEXTRALARGE' => 'XXL',
    'XXXLARGE' || 'XXXL' || '3XL' || '3XLARGE' || 'TRIPLEEXTRALARGE' => 'XXXL',
    _ => label,
  };
}

int compareProductSizes(String a, String b) {
  if (a == b) return 0;
  const sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  final aIndex = sizes.indexOf(a);
  final bIndex = sizes.indexOf(b);
  if (aIndex >= 0 || bIndex >= 0) {
    if (aIndex < 0) return 1;
    if (bIndex < 0) return -1;
    return aIndex.compareTo(bIndex);
  }
  final aNumber = num.tryParse(a);
  final bNumber = num.tryParse(b);
  if (aNumber != null && bNumber != null) return aNumber.compareTo(bNumber);
  if (a.isEmpty || b.isEmpty) return a.isEmpty ? 1 : -1;
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// Legacy names can contain an alias, e.g. "Black / XLarge" + size "XL".
/// Remove only matching trailing size segments, never meaningful option names.
String productVariantOptionLabel(ProductVariant variant) {
  var label = variant.localizedOptionName.trim();
  if (!variant.hasSize) return label;
  final size = productSizeLabel(variant.size);
  while (label.isNotEmpty) {
    final separator = label.lastIndexOf('/');
    final suffix = label.substring(separator + 1).trim();
    if (productSizeLabel(suffix) != size) break;
    label = separator < 0 ? '' : label.substring(0, separator).trim();
  }
  return label;
}

/// Options are filters, never inventory buckets. Include the supplied swatch so
/// equally named, differently colored options do not merge.
String productVariantOptionKey(ProductVariant variant) =>
    '${productVariantOptionLabel(variant).toLowerCase()}|${variant.colorHex ?? ''}';
