import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/order_wizard/order_wizard_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const packagingBox = PackagingBox(
    id: 'box-1',
    name: 'علبة هدية فاخرة',
    price: 2500,
    imageUrl: 'https://example.com/packaging-box.png',
  );
  final product = Product(
    id: 'product-1',
    nameAr: 'ساعة تجريبية',
    categoryId: 'category-1',
    description: 'منتج تجريبي',
    specs: const {},
    media: const [],
    variants: const [
      ProductVariant(id: 'variant-1', nameAr: 'أسود', imageUrl: '', stock: 5),
    ],
    wholesalePrice: 20000,
    suggestedPrice: 30000,
    createdAt: DateTime(2026, 7, 28),
    packagingEnabled: true,
  );

  setUp(() {
    appSettings.language = AppLanguage.ar;
    session.packagingBoxes = const [packagingBox];
  });

  tearDown(() {
    session.packagingBoxes = const [];
  });

  testWidgets('packaging cards show a clear image and fullscreen preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OrderWizardScreen(product: product),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final card = find.byKey(const ValueKey('packaging_box_box-1'));
    await tester.ensureVisible(card);
    expect(card, findsOneWidget);
    expect(find.text(packagingBox.name), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(card);
    await tester.pump();
    final selectedSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('packaging_box_semantics_box-1')),
    );
    expect(selectedSemantics.properties.selected, isTrue);

    final preview = find.byKey(const ValueKey('packaging_preview_box-1'));
    await tester.ensureVisible(preview);
    await tester.tap(preview);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('packaging_preview_close')),
      findsOneWidget,
    );
    expect(find.text(packagingBox.name), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('packaging_preview_close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('packaging_preview_close')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
