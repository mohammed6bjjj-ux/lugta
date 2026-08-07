import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/repositories/supabase_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps sale price and packaging independent for every order line', () {
    final firstProduct = MockData.products.first;
    final secondProduct = MockData.products.firstWhere(
      (product) => product.id != firstProduct.id,
    );
    final firstVariant = firstProduct.variants.first;
    final secondVariant = secondProduct.variants.first;
    final unboxedVariant = firstProduct.variants.firstWhere(
      (variant) => variant.id != firstVariant.id,
    );
    const premiumBox = PackagingBox(
      id: 'box-premium',
      name: 'علبة فاخرة',
      price: 5000,
      imageUrl: '',
    );
    const standardBox = PackagingBox(
      id: 'box-standard',
      name: 'علبة قياسية',
      price: 1000,
      imageUrl: '',
    );

    final request = CreateOrderRequest.lines(
      clientRequestId: '11111111-1111-4111-8111-111111111111',
      lines: [
        CreateOrderLine(
          product: firstProduct,
          variant: firstVariant,
          quantity: 2,
          unitSalePrice: 73000,
          packagingBox: premiumBox,
        ),
        CreateOrderLine(
          product: secondProduct,
          variant: secondVariant,
          quantity: 1,
          unitSalePrice: 41000,
          packagingBox: standardBox,
        ),
        CreateOrderLine(
          product: firstProduct,
          variant: unboxedVariant,
          quantity: 3,
          unitSalePrice: 68000,
        ),
      ],
      governorate: MockData.governorates.first,
      customerName: 'زبون اختبار',
      customerPhone: '07701234567',
      addressDetails: 'بغداد - عنوان اختبار',
    );

    final payload = buildCreateOrderItemsPayload(request.lines);

    expect(payload, [
      {
        'variant_id': firstVariant.id,
        'quantity': 2,
        'unit_sale_price': 73000,
        'packaging_box_id': premiumBox.id,
      },
      {
        'variant_id': secondVariant.id,
        'quantity': 1,
        'unit_sale_price': 41000,
        'packaging_box_id': standardBox.id,
      },
      {
        'variant_id': unboxedVariant.id,
        'quantity': 3,
        'unit_sale_price': 68000,
      },
    ]);
    expect(payload[2].containsKey('packaging_box_id'), isFalse);
  });
}
