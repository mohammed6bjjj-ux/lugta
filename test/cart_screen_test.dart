import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/cart/cart_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final firstProduct = Product(
    id: 'cart-product-1',
    nameAr: 'ساعة الخط الأول',
    categoryId: 'watches',
    description: 'منتج اختباري أول',
    specs: const {},
    media: const [],
    variants: const [
      ProductVariant(
        id: 'cart-variant-1',
        nameAr: 'أسود',
        imageUrl: '',
        stock: 5,
      ),
    ],
    wholesalePrice: 20000,
    suggestedPrice: 30000,
    createdAt: DateTime(2026, 8, 1),
  );
  final secondProduct = Product(
    id: 'cart-product-2',
    nameAr: 'ساعة الخط الثاني',
    categoryId: 'watches',
    description: 'منتج اختباري ثانٍ',
    specs: const {},
    media: const [],
    variants: const [
      ProductVariant(
        id: 'cart-variant-2',
        nameAr: 'ذهبي',
        imageUrl: '',
        stock: 5,
      ),
    ],
    wholesalePrice: 25000,
    suggestedPrice: 36000,
    createdAt: DateTime(2026, 8, 2),
  );

  setUp(() async {
    appSettings.language = AppLanguage.ar;
    await session.configure(createDemoRepositories(), loadInitialData: false);
    session.addToCart(
      product: firstProduct,
      variant: firstProduct.variants.single,
    );
    session.addToCart(
      product: secondProduct,
      variant: secondProduct.variants.single,
    );
  });

  tearDown(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
    appSettings.language = AppLanguage.ar;
  });

  testWidgets('السلة تعرض سطرين مستقلين وتنتقل إلى بيانات الزبون', (
    tester,
  ) async {
    _setViewport(tester, const Size(430, 1000));
    await _pumpCart(tester);
    final semantics = tester.ensureSemantics();
    try {
      expect(tester, meetsGuideline(androidTapTargetGuideline));
    } finally {
      semantics.dispose();
    }

    final firstVariant = firstProduct.variants.single;
    final secondVariant = secondProduct.variants.single;
    final firstLine = find.byKey(
      ValueKey<String>('cart_line_${firstVariant.id}'),
    );
    final secondLine = find.byKey(
      ValueKey<String>('cart_line_${secondVariant.id}'),
    );

    expect(session.cartLineCount, 2);
    expect(firstLine, findsOneWidget);
    expect(secondLine, findsOneWidget);
    expect(
      find.descendant(
        of: firstLine,
        matching: find.text(firstProduct.localizedName),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: secondLine,
        matching: find.text(secondProduct.localizedName),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(ValueKey<String>('cart_increment_${firstVariant.id}')),
    );
    await tester.pump();

    expect(session.cartItemForVariant(firstVariant.id)?.quantity, 2);
    expect(session.cartItemForVariant(secondVariant.id)?.quantity, 1);
    expect(
      find.descendant(of: firstLine, matching: find.text('2')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: secondLine, matching: find.text('1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('cart_next_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cart_customer_form')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cart_customer_name_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cart_customer_phone_field')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('شاشة السلة لا تُظهر overflow أو error على هاتف صغير', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 568));
    await _pumpCart(tester);

    expect(tester.takeException(), isNull);

    final cartList = find.byKey(const ValueKey('cart_items_list'));
    await tester.drag(cartList, const Offset(0, -650));
    await tester.pumpAndSettle();

    final secondVariant = secondProduct.variants.single;
    expect(
      find.byKey(ValueKey<String>('cart_line_${secondVariant.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('cart_next_button')));
    await tester.pumpAndSettle();

    final customerForm = find.byKey(const ValueKey('cart_customer_form'));
    expect(customerForm, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(customerForm, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cart_address_field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpCart(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: const CartScreen()),
  );
  await tester.pumpAndSettle();
}
