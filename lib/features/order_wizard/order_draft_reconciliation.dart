import '../../data/models.dart';

/// The database contract accepts at most 50 distinct variants per order.
const int maxOrderLineCount = 50;

/// Reconciles a locally edited draft with the latest product snapshot.
///
/// The returned draft always references the latest variant objects and clamps
/// quantities to currently available stock. Callers must stop submission when
/// [selectionAdjusted], [tooManyLines], or [priceOutOfRange] is true so the
/// seller can review what changed before creating the order.
class OrderDraftReconciliation {
  const OrderDraftReconciliation({
    required this.drafts,
    required this.selectionAdjusted,
    required this.tooManyLines,
    required this.priceOutOfRange,
    required this.effectiveMinSalePrice,
    required this.maxSalePrice,
  });

  final List<OrderDraftItem> drafts;
  final bool selectionAdjusted;
  final bool tooManyLines;
  final bool priceOutOfRange;
  final int effectiveMinSalePrice;
  final int? maxSalePrice;

  List<OrderDraftItem> get selectedItems =>
      drafts.where((item) => item.quantity > 0).toList(growable: false);
}

OrderDraftReconciliation reconcileOrderDraft({
  required List<OrderDraftItem> currentDrafts,
  required Product latestProduct,
  required int unitSalePrice,
  Map<String, int> additionalOrderableStockByVariant = const <String, int>{},
}) {
  final requestedQuantities = <String, int>{
    for (final item in currentDrafts)
      if (item.quantity > 0) item.variant.id: item.quantity,
  };
  var selectionAdjusted = false;
  final drafts = <OrderDraftItem>[];

  for (final variant in latestProduct.variants) {
    final requested = requestedQuantities.remove(variant.id) ?? 0;
    final ownReserved = additionalOrderableStockByVariant[variant.id] ?? 0;
    final safeStock = (variant.stock + ownReserved).clamp(0, 1 << 31).toInt();
    final quantity = requested.clamp(0, safeStock);
    if (quantity != requested) selectionAdjusted = true;
    drafts.add(OrderDraftItem(variant: variant, quantity: quantity));
  }

  // Any remaining id belonged to a variant that was removed/deactivated.
  if (requestedQuantities.isNotEmpty) selectionAdjusted = true;

  final selected = drafts.where((item) => item.quantity > 0).toList();
  var effectiveMin = latestProduct.effectiveMinSalePrice;
  for (final item in selected) {
    final wholesale =
        item.variant.wholesalePriceOverride ?? latestProduct.wholesalePrice;
    if (wholesale > effectiveMin) effectiveMin = wholesale;
  }
  final max = latestProduct.maxSalePrice;
  final priceOutOfRange =
      unitSalePrice < effectiveMin || (max != null && unitSalePrice > max);

  return OrderDraftReconciliation(
    drafts: drafts,
    selectionAdjusted: selectionAdjusted,
    tooManyLines: selected.length > maxOrderLineCount,
    priceOutOfRange: priceOutOfRange,
    effectiveMinSalePrice: effectiveMin,
    maxSalePrice: max,
  );
}
