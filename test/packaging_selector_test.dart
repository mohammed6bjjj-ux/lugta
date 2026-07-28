import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/formatters.dart';
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

  testWidgets('packaging button opens the list and shows selected details', (
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
    Future<void> finishTransition() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    final pickerButton = find.byKey(const ValueKey('packaging_picker_button'));
    await tester.ensureVisible(pickerButton);
    expect(pickerButton, findsOneWidget);
    expect(
      find.byKey(const ValueKey('packaging_selected_details')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(pickerButton);
    await finishTransition();

    expect(
      find.byKey(const ValueKey('packaging_picker_sheet')),
      findsOneWidget,
    );
    final card = find.byKey(const ValueKey('packaging_box_box-1'));
    expect(card, findsOneWidget);
    expect(find.text(packagingBox.name), findsOneWidget);
    expect(find.text(formatIqd(packagingBox.price)), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(card);
    await finishTransition();
    expect(find.byKey(const ValueKey('packaging_picker_sheet')), findsNothing);
    expect(
      find.byKey(const ValueKey('packaging_selected_details')),
      findsOneWidget,
    );
    expect(find.text(packagingBox.name), findsOneWidget);
    expect(find.text(formatIqd(packagingBox.price)), findsOneWidget);

    await tester.tap(pickerButton);
    await finishTransition();
    final selectedSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('packaging_box_semantics_box-1')),
    );
    expect(selectedSemantics.properties.selected, isTrue);
    await tester.tap(find.byKey(const ValueKey('packaging_picker_close')));
    await finishTransition();

    final preview = find.byKey(const ValueKey('packaging_selected_preview'));
    await tester.ensureVisible(preview);
    await tester.tap(preview);
    await finishTransition();

    expect(
      find.byKey(const ValueKey('packaging_preview_close')),
      findsOneWidget,
    );
    expect(find.text(packagingBox.name), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('packaging_preview_close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('packaging_preview_close')), findsNothing);

    await tester.tap(pickerButton);
    await finishTransition();
    await tester.tap(find.byKey(const ValueKey('packaging_none')));
    await finishTransition();
    expect(
      find.byKey(const ValueKey('packaging_selected_details')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
