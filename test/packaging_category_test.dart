import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/order_wizard/order_wizard_screen.dart';
import 'package:flutter_test/flutter_test.dart';

Product product(String category, {bool enabled = true}) => Product(
  id: 'product-$category',
  nameAr: 'منتج تجريبي',
  categoryId: category,
  description: '',
  specs: const {},
  media: const [],
  variants: [
    ProductVariant(
      id: 'variant-$category',
      nameAr: 'أسود',
      imageUrl: '',
      stock: 10,
    ),
  ],
  wholesalePrice: 8000,
  suggestedPrice: 15000,
  createdAt: DateTime(2026, 9, 11),
  packagingEnabled: enabled,
);

const general = PackagingBox(
  id: 'general',
  name: 'علبة عامة',
  price: 1500,
  imageUrl: '',
);
const glasses = PackagingBox(
  id: 'glasses',
  name: 'علبة النظارات',
  price: 2000,
  imageUrl: '',
  categoryId: 'glasses',
);
const watch = PackagingBox(
  id: 'watch',
  name: 'علبة الساعة',
  price: 3000,
  imageUrl: '',
  categoryId: 'watches',
);

void main() {
  const multiWatch = PackagingBox(
    id: 'multi-watch',
    name: 'علبة ساعات رجالية ونسائية',
    price: 3000,
    imageUrl: '',
    categoryId: 'mens-watches',
    categoryIds: ['mens-watches', 'womens-watches'],
  );
  test(
    'multiple categories use IDs and still respect product packaging flag',
    () {
      expect(multiWatch.isAvailableFor(product('mens-watches')), isTrue);
      expect(multiWatch.isAvailableFor(product('womens-watches')), isTrue);
      expect(multiWatch.isAvailableFor(product('glasses')), isFalse);
      expect(
        multiWatch.isAvailableFor(product('womens-watches', enabled: false)),
        isFalse,
      );
    },
  );

  testWidgets('second selected category sees watch box but not glasses box', (
    tester,
  ) async {
    session.packagingBoxes = [multiWatch, glasses];
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OrderWizardScreen(product: product('womens-watches')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final picker = find.byKey(const ValueKey('packaging_picker_button'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(multiWatch.name), findsOneWidget);
    expect(find.text(glasses.name), findsNothing);
    expect(tester.takeException(), isNull);
  });
  setUp(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
    session.packagingBoxes = [general, glasses, watch];
  });
  tearDown(
    () async =>
        session.configure(createDemoRepositories(), loadInitialData: false),
  );

  test(
    'scoped boxes use category identity and preserve general/electronic behavior',
    () {
      expect(glasses.isAvailableFor(product('glasses')), isTrue);
      expect(glasses.isAvailableFor(product('watches')), isFalse);
      expect(glasses.isAvailableFor(product('electronics')), isFalse);
      expect(general.isAvailableFor(product('electronics')), isTrue);
      expect(
        general.isAvailableFor(product('electronics', enabled: false)),
        isFalse,
      );
      expect(
        glasses.isAvailableFor(product('glasses', enabled: false)),
        isFalse,
      );
    },
  );

  test('cart rejects wrong-category boxes without adding a line', () {
    final item = product('glasses');
    expect(
      () => session.setCartItemConfiguration(
        product: item,
        variant: item.variants.single,
        quantity: 1,
        unitSalePrice: 15000,
        packagingBox: watch,
      ),
      throwsA(isA<BackendException>()),
    );
    expect(session.cartItems, isEmpty);
  });

  test(
    'cart updates use canonical box price and reject mismatched changes',
    () {
      final item = product('glasses');
      session.setCartItemConfiguration(
        product: item,
        variant: item.variants.single,
        quantity: 2,
        unitSalePrice: 15000,
        packagingBox: glasses,
      );
      expect(
        () => session.updateCartPackaging(item.variants.single.id, watch),
        throwsA(isA<BackendException>()),
      );
      expect(session.cartItems.single.packagingBox, same(glasses));
      const stale = PackagingBox(
        id: 'general',
        name: 'قديم',
        price: 0,
        imageUrl: '',
      );
      session.updateCartPackaging(item.variants.single.id, stale);
      expect(session.cartItems.single.packagingBox, same(general));
      session.updateCartPackaging(item.variants.single.id, null);
      expect(session.cartItems.single.packagingBox, isNull);
    },
  );

  testWidgets(
    'glasses picker shows matching/general boxes and hides watch boxes',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: OrderWizardScreen(product: product('glasses')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final picker = find.byKey(const ValueKey('packaging_picker_button'));
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(glasses.name), findsOneWidget);
      expect(find.text(general.name), findsOneWidget);
      expect(find.text(watch.name), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
