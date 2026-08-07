import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/cart/cart_screen.dart';
import 'package:flutter_app/features/product/product_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const premiumBox = PackagingBox(
    id: 'configurator-premium-box',
    name: 'Premium gift box',
    price: 2500,
    imageUrl: 'https://example.com/premium-gift-box.png',
  );
  const freeBox = PackagingBox(
    id: 'configurator-free-box',
    name: 'Standard box',
    price: 0,
    imageUrl: '',
  );
  final product = Product(
    id: 'configurator-product',
    nameAr: 'ساعة اختبار السلة',
    nameEn: 'Configurator test watch',
    categoryId: 'test-category',
    description: 'منتج اختباري',
    descriptionEn: 'A deterministic configurator test product.',
    specs: const {},
    media: const [],
    variants: const [
      ProductVariant(
        id: 'configurator-variant',
        nameAr: 'أسود',
        nameEn: 'Black',
        imageUrl: '',
        stock: 5,
      ),
    ],
    wholesalePrice: 20000,
    suggestedPrice: 30000,
    minSalePrice: 25000,
    maxSalePrice: 60000,
    packagingEnabled: true,
    createdAt: DateTime(2026, 8, 7),
  );

  setUp(() async {
    appSettings.language = AppLanguage.ar;
    await session.configure(createDemoRepositories(), loadInitialData: false);
    session.packagingBoxes = const [freeBox, premiumBox];
  });

  tearDown(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
    appSettings.language = AppLanguage.ar;
  });

  testWidgets('Add to cart opens a configurator before mutating the cart', (
    tester,
  ) async {
    _setViewport(tester, const Size(430, 900));
    await _pumpProduct(tester, product);

    await tester.tap(find.byKey(const ValueKey('product_add_to_cart_button')));
    await _finishTransition(tester);

    expect(session.cartItems, isEmpty);
    expect(
      find.byKey(const ValueKey('product_cart_configurator')),
      findsOneWidget,
    );
  });

  testWidgets('invalid sale price cannot add, then a valid price adds', (
    tester,
  ) async {
    _setViewport(tester, const Size(430, 900));
    await _pumpProduct(tester, product);
    await _openConfigurator(tester);

    final priceField = find.byKey(
      const ValueKey('product_cart_sale_price_field'),
    );
    final confirmButton = find.byKey(
      const ValueKey('product_cart_confirm_button'),
    );

    await tester.enterText(priceField, '24000');
    await tester.pump();
    await tester.tap(confirmButton);
    await tester.pump();

    expect(session.cartItems, isEmpty);
    expect(
      find.byKey(const ValueKey('product_cart_configurator')),
      findsOneWidget,
    );

    await tester.enterText(priceField, '35000');
    await tester.pump();
    await tester.tap(confirmButton);
    await _finishTransition(tester);

    expect(session.cartLineCount, 1);
    expect(session.cartItems.single.variant.id, product.variants.single.id);
    expect(session.cartItems.single.unitSalePrice, 35000);
  });

  testWidgets(
    'packaging product shows box image and price and adds the selection',
    (tester) async {
      _setViewport(tester, const Size(430, 900));
      await _pumpProduct(tester, product);
      await _openConfigurator(tester);

      await tester.enterText(
        find.byKey(const ValueKey('product_cart_sale_price_field')),
        '35000',
      );
      await tester.pump();

      final premiumOption = find.byKey(
        const ValueKey('product_cart_packaging_box_configurator-premium-box'),
      );
      expect(premiumOption, findsOneWidget);
      expect(
        find.descendant(
          of: premiumOption,
          matching: find.text(premiumBox.name),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: premiumOption,
          matching: find.text(formatIqd(premiumBox.price)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: premiumOption,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is AppNetworkImage && widget.url == premiumBox.imageUrl,
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(premiumOption);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('product_cart_confirm_button')),
      );
      await _finishTransition(tester);

      expect(session.cartLineCount, 1);
      expect(session.cartItems.single.packagingBox?.id, premiumBox.id);
      expect(session.cartItems.single.packagingTotal, premiumBox.price);
    },
  );

  testWidgets('CartScreen renders sale price read-only', (tester) async {
    _setViewport(tester, const Size(430, 900));
    session.addToCart(product: product, variant: product.variants.single);
    session.updateCartSalePrice(product.variants.single.id, 35000);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const CartScreen()),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final line = find.byKey(
      ValueKey<String>('cart_line_${product.variants.single.id}'),
    );
    expect(line, findsOneWidget);
    expect(
      find.descendant(of: line, matching: find.byType(TextFormField)),
      findsNothing,
    );
    expect(
      find.descendant(of: line, matching: find.text(formatIqd(35000))),
      findsAtLeastNWidgets(1),
    );

    await tester.tap(
      find.byKey(
        ValueKey<String>('cart_edit_options_${product.variants.single.id}'),
      ),
    );
    await _finishTransition(tester);

    expect(
      find.byKey(const ValueKey('product_cart_sale_price_read_only')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('product_cart_sale_price_field')),
      findsNothing,
    );
  });

  testWidgets('configurator has no overflow at 320x568', (tester) async {
    _setViewport(tester, const Size(320, 568));
    await _pumpProduct(tester, product);
    await _openConfigurator(tester);

    expect(
      find.byKey(const ValueKey('product_cart_configurator')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('product_cart_sale_price_field')),
      '24000',
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpProduct(WidgetTester tester, Product product) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: ProductDetailScreen(product: product),
    ),
  );
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _openConfigurator(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('product_add_to_cart_button')));
  await _finishTransition(tester);
  expect(
    find.byKey(const ValueKey('product_cart_configurator')),
    findsOneWidget,
  );
  expect(session.cartItems, isEmpty);
}

Future<void> _finishTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
