import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/features/order_wizard/order_draft_reconciliation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Product productWith({
    required Product source,
    required List<ProductVariant> variants,
    int? wholesalePrice,
    int? minSalePrice,
    int? maxSalePrice,
  }) => Product(
    id: source.id,
    nameAr: source.nameAr,
    nameCkb: source.nameCkb,
    nameEn: source.nameEn,
    categoryId: source.categoryId,
    description: source.description,
    descriptionCkb: source.descriptionCkb,
    descriptionEn: source.descriptionEn,
    specs: source.specs,
    media: source.media,
    variants: variants,
    wholesalePrice: wholesalePrice ?? source.wholesalePrice,
    oldWholesalePrice: source.oldWholesalePrice,
    suggestedPrice: source.suggestedPrice,
    minSalePrice: minSalePrice ?? source.minSalePrice,
    maxSalePrice: maxSalePrice ?? source.maxSalePrice,
    ordersCount: source.ordersCount,
    isNew: source.isNew,
    createdAt: source.createdAt,
  );

  ProductVariant variantWith({
    required ProductVariant source,
    required int stock,
    int? wholesalePriceOverride,
  }) => ProductVariant(
    id: source.id,
    nameAr: source.nameAr,
    nameCkb: source.nameCkb,
    nameEn: source.nameEn,
    sku: source.sku,
    imageUrl: source.imageUrl,
    stock: stock,
    colorHex: source.colorHex,
    wholesalePriceOverride:
        wholesalePriceOverride ?? source.wholesalePriceOverride,
    suggestedPriceOverride: source.suggestedPriceOverride,
  );

  test(
    'clamps requested quantity to latest stock and keeps latest variant',
    () {
      final source = MockData.products.first;
      final original = source.variants.first;
      final latestVariant = variantWith(source: original, stock: 2);
      final result = reconcileOrderDraft(
        currentDrafts: [OrderDraftItem(variant: original, quantity: 5)],
        latestProduct: productWith(source: source, variants: [latestVariant]),
        unitSalePrice: source.suggestedPrice,
      );

      expect(result.selectionAdjusted, isTrue);
      expect(result.selectedItems.single.quantity, 2);
      expect(result.selectedItems.single.variant, same(latestVariant));
    },
  );

  test('removes a selected variant that is no longer available', () {
    final source = MockData.products.first;
    final result = reconcileOrderDraft(
      currentDrafts: [
        OrderDraftItem(variant: source.variants.first, quantity: 1),
      ],
      latestProduct: productWith(source: source, variants: const []),
      unitSalePrice: source.suggestedPrice,
    );

    expect(result.selectionAdjusted, isTrue);
    expect(result.selectedItems, isEmpty);
  });

  test('uses latest variant wholesale override when validating sale price', () {
    final source = MockData.products.first;
    final original = source.variants.first;
    final latestVariant = variantWith(
      source: original,
      stock: 10,
      wholesalePriceOverride: source.suggestedPrice + 1000,
    );
    final result = reconcileOrderDraft(
      currentDrafts: [OrderDraftItem(variant: original, quantity: 1)],
      latestProduct: productWith(source: source, variants: [latestVariant]),
      unitSalePrice: source.suggestedPrice,
    );

    expect(result.selectionAdjusted, isFalse);
    expect(result.priceOutOfRange, isTrue);
    expect(result.effectiveMinSalePrice, source.suggestedPrice + 1000);
  });

  test('rejects more than the backend line limit', () {
    final source = MockData.products.first;
    final variants = List<ProductVariant>.generate(
      maxOrderLineCount + 1,
      (index) => ProductVariant(
        id: 'variant-$index',
        nameAr: 'خيار $index',
        imageUrl: '',
        stock: 1,
      ),
    );
    final result = reconcileOrderDraft(
      currentDrafts: [
        for (final variant in variants)
          OrderDraftItem(variant: variant, quantity: 1),
      ],
      latestProduct: productWith(source: source, variants: variants),
      unitSalePrice: source.suggestedPrice,
    );

    expect(result.selectionAdjusted, isFalse);
    expect(result.tooManyLines, isTrue);
  });
}
