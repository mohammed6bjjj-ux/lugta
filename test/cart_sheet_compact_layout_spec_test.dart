import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/widgets/quantity_stepper.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/cart/cart_screen.dart';
import 'package:flutter_app/features/cart/cart_strings.dart';
import 'package:flutter_app/features/product/product_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final product = Product(
    id: 'compact-layout-product',
    nameAr: 'ساعة اختبار التخطيط',
    categoryId: 'test-category',
    description: 'منتج اختباري',
    specs: const {},
    media: const [],
    variants: const [
      ProductVariant(
        id: 'compact-layout-variant',
        nameAr: 'أسود',
        imageUrl: '',
        stock: 5,
      ),
    ],
    wholesalePrice: 20000,
    suggestedPrice: 30000,
    createdAt: DateTime(2026, 8, 7),
  );

  setUp(() async {
    appSettings.language = AppLanguage.ar;
    await session.configure(createDemoRepositories(), loadInitialData: false);
  });

  tearDown(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
    appSettings.language = AppLanguage.ar;
  });

  testWidgets('configurator bottom sheet has exactly one drag handle', (
    tester,
  ) async {
    _setViewport(tester, const Size(430, 900));
    await _pumpAndOpenConfigurator(tester, product);

    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    final visualHandles = _visualDragHandleRects(tester, sheet);
    expect(
      visualHandles,
      hasLength(1),
      reason: 'The modal must not render both framework and custom handles.',
    );

    final keyedHandle = find.byKey(
      const ValueKey('product_cart_sheet_drag_handle'),
    );
    expect(keyedHandle, findsOneWidget);
    expect(tester.getSize(keyedHandle).height, closeTo(4, .1));
  });

  testWidgets('configurator header has no large internal top gap', (
    tester,
  ) async {
    _setViewport(tester, const Size(430, 900));
    await _pumpAndOpenConfigurator(tester, product);

    final sheet = find.byType(BottomSheet);
    final headerTitle = find.text(CartStrings.configureProduct);
    expect(sheet, findsOneWidget);
    expect(headerTitle, findsOneWidget);

    final topGap = tester.getRect(headerTitle).top - tester.getRect(sheet).top;
    expect(
      topGap,
      lessThanOrEqualTo(56),
      reason: 'The configurator header started $topGap dp below the sheet.',
    );
    expect(
      find.byKey(const ValueKey('product_cart_sheet_header')),
      findsOneWidget,
    );
  });

  testWidgets(
    '320dp cart card keeps quantity and compact edit action in one row',
    (tester) async {
      _setViewport(tester, const Size(320, 568));
      session.addToCart(product: product, variant: product.variants.single);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const CartScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);

      final itemId = product.variants.single.id;
      final line = find.byKey(ValueKey<String>('cart_line_$itemId'));
      final quantity = find.descendant(
        of: line,
        matching: find.byType(QuantityStepper),
      );
      final editButton = find.byKey(
        ValueKey<String>('cart_edit_options_$itemId'),
      );
      expect(line, findsOneWidget);
      expect(quantity, findsOneWidget);
      expect(editButton, findsOneWidget);

      final quantityRect = tester.getRect(quantity);
      final editRect = tester.getRect(editButton);
      expect(
        (quantityRect.center.dy - editRect.center.dy).abs(),
        lessThanOrEqualTo(1),
        reason: 'Quantity and edit controls must share one horizontal row.',
      );
      expect(
        editRect.width,
        lessThanOrEqualTo(112),
        reason: 'The edit action must stay compact on a 320dp cart card.',
      );

      final actions = find.byKey(
        ValueKey<String>('cart_item_controls_row_$itemId'),
      );
      expect(actions, findsOneWidget);
      expect(
        find.descendant(of: actions, matching: find.byType(QuantityStepper)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: actions,
          matching: find.byKey(ValueKey<String>('cart_edit_options_$itemId')),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('large Arabic text keeps an accessible edit icon in the row', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 568));
    session.addToCart(product: product, variant: product.variants.single);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const CartScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final itemId = product.variants.single.id;
    final quantity = find.byType(QuantityStepper);
    final editButton = find.byKey(
      ValueKey<String>('cart_edit_options_$itemId'),
    );
    expect(quantity, findsOneWidget);
    expect(editButton, findsOneWidget);
    expect(
      (tester.getCenter(quantity).dy - tester.getCenter(editButton).dy).abs(),
      lessThanOrEqualTo(1),
    );
    expect(tester.getSize(editButton), const Size.square(48));
    expect(
      tester.widget<IconButton>(editButton).tooltip,
      CartStrings.editOptions,
    );
    expect(tester.takeException(), isNull);
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpAndOpenConfigurator(
  WidgetTester tester,
  Product product,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: ProductDetailScreen(product: product),
    ),
  );
  await tester.pump(const Duration(milliseconds: 700));
  await tester.tap(find.byKey(const ValueKey('product_add_to_cart_button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(
    find.byKey(const ValueKey('product_cart_configurator')),
    findsOneWidget,
  );
}

List<Rect> _visualDragHandleRects(WidgetTester tester, Finder sheet) {
  final candidates = find.descendant(
    of: sheet,
    matching: find.byType(DecoratedBox),
  );
  final handles = <Rect>[];
  for (final element in candidates.evaluate()) {
    final exact = find.byElementPredicate(
      (candidate) => identical(candidate, element),
    );
    final rect = tester.getRect(exact);
    if ((rect.height - 4).abs() <= .1 && rect.width >= 24 && rect.width <= 60) {
      handles.add(rect);
    }
  }
  return handles;
}
