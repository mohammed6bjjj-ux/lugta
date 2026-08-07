import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Product firstProduct;
  late Product secondProduct;
  late ProductVariant firstVariant;
  late ProductVariant secondVariant;

  setUp(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);

    final products = MockData.products
        .where(
          (product) => product.variants.any((variant) => variant.stock >= 4),
        )
        .take(2)
        .toList(growable: false);
    expect(products, hasLength(2));
    firstProduct = products[0];
    secondProduct = products[1];
    firstVariant = firstProduct.variants.firstWhere(
      (variant) => variant.stock >= 4,
    );
    secondVariant = secondProduct.variants.firstWhere(
      (variant) => variant.stock >= 4,
    );
  });

  tearDown(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
  });

  test('adds variants from two different products as independent lines', () {
    session.addToCart(
      product: firstProduct,
      variant: firstVariant,
      quantity: 2,
    );
    session.addToCart(
      product: secondProduct,
      variant: secondVariant,
      quantity: 3,
    );

    expect(session.cartLineCount, 2);
    expect(session.cartQuantity, 5);
    expect(session.cartItems.map((item) => item.product.id), [
      firstProduct.id,
      secondProduct.id,
    ]);
    expect(session.cartItems.map((item) => item.variant.id), [
      firstVariant.id,
      secondVariant.id,
    ]);
  });

  test('adding the same variant merges its quantity into one line', () {
    session.addToCart(
      product: firstProduct,
      variant: firstVariant,
      quantity: 1,
    );
    session.addToCart(
      product: firstProduct,
      variant: firstVariant,
      quantity: 2,
    );

    expect(session.cartLineCount, 1);
    expect(session.cartQuantity, 3);
    expect(session.cartItems.single.quantity, 3);
    expect(session.cartItems.single.variant.id, firstVariant.id);
  });

  test('configured cart line stores the chosen price before cart review', () {
    final minimum = firstVariant.wholesalePriceOverride == null
        ? firstProduct.effectiveMinSalePrice
        : firstVariant.wholesalePriceOverride! >
              firstProduct.effectiveMinSalePrice
        ? firstVariant.wholesalePriceOverride!
        : firstProduct.effectiveMinSalePrice;

    session.setCartItemConfiguration(
      product: firstProduct,
      variant: firstVariant,
      quantity: 2,
      unitSalePrice: minimum,
    );

    final line = session.cartItems.single;
    expect(line.quantity, 2);
    expect(line.unitSalePrice, minimum);
    expect(line.packagingBox, isNull);
  });

  test('reconfiguring the same variant replaces instead of duplicating', () {
    final minimum = firstVariant.wholesalePriceOverride == null
        ? firstProduct.effectiveMinSalePrice
        : firstVariant.wholesalePriceOverride! >
              firstProduct.effectiveMinSalePrice
        ? firstVariant.wholesalePriceOverride!
        : firstProduct.effectiveMinSalePrice;
    session.setCartItemConfiguration(
      product: firstProduct,
      variant: firstVariant,
      quantity: 1,
      unitSalePrice: minimum,
    );
    session.setCartItemConfiguration(
      product: firstProduct,
      variant: firstVariant,
      quantity: 3,
      unitSalePrice: minimum,
    );

    expect(session.cartLineCount, 1);
    expect(session.cartQuantity, 3);
    expect(session.cartItems.single.quantity, 3);
  });

  test(
    'stock limits reject additions and updates without mutating the line',
    () {
      session.addToCart(
        product: firstProduct,
        variant: firstVariant,
        quantity: firstVariant.stock,
      );

      expect(
        () => session.addToCart(product: firstProduct, variant: firstVariant),
        throwsA(isA<BackendException>()),
      );
      expect(session.cartItems.single.quantity, firstVariant.stock);

      expect(
        () =>
            session.updateCartQuantity(firstVariant.id, firstVariant.stock + 1),
        throwsA(isA<BackendException>()),
      );
      expect(session.cartItems.single.quantity, firstVariant.stock);
    },
  );

  test('updates quantities, removes individual lines, and clears the cart', () {
    session.addToCart(product: firstProduct, variant: firstVariant);
    session.addToCart(
      product: secondProduct,
      variant: secondVariant,
      quantity: 2,
    );

    session.updateCartQuantity(firstVariant.id, 3);
    expect(session.cartItemForVariant(firstVariant.id)?.quantity, 3);
    expect(session.cartQuantity, 5);

    session.removeFromCart(secondVariant.id);
    expect(session.cartLineCount, 1);
    expect(session.cartItemForVariant(secondVariant.id), isNull);

    session.updateCartQuantity(firstVariant.id, 0);
    expect(session.cartItems, isEmpty);

    session.addToCart(product: firstProduct, variant: firstVariant);
    session.addToCart(product: secondProduct, variant: secondVariant);
    session.clearCart();

    expect(session.cartItems, isEmpty);
    expect(session.cartLineCount, 0);
    expect(session.cartQuantity, 0);
    expect(session.cartWholesaleTotal, 0);
    expect(session.cartSaleTotal, 0);
    expect(session.cartPackagingTotal, 0);
    expect(session.cartProfitTotal, 0);
  });
}
