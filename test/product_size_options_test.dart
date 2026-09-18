import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/features/product/product_size_labels.dart';
import 'package:flutter_app/features/product/product_size_options.dart';
import 'package:flutter_app/features/product/product_size_options_preview.dart';
import 'package:flutter_app/features/product/product_strings.dart';

Finder choice(String id) => find.byKey(ValueKey(id));
OutlinedButton button(WidgetTester tester, String id) => tester.widget(
  find.descendant(of: choice(id), matching: find.byType(OutlinedButton)),
);

Future<void> pumpOptions(
  WidgetTester tester, {
  List<ProductVariant> variants = clothingPreviewVariants,
  String? selected = 'black-m',
  ValueChanged<String?>? onChanged,
  int Function(ProductVariant)? availableStock,
  double width = 375,
  double height = 900,
  double textScale = 1,
  bool dark = false,
  AppLanguage language = AppLanguage.ar,
}) async {
  appSettings.language = language;
  addTearDown(() => appSettings.language = AppLanguage.ar);
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
              size: Size(width, height),
            ),
            child: Directionality(
              textDirection: language.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(16),
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        ProductStrings.sizesAndColors,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ProductSizeOptions(
                        variants: variants,
                        selectedId: selected,
                        onSelected: (variant) {
                          setState(() => selected = variant.id);
                          onChanged?.call(selected);
                        },
                        onSelectionCleared: () {
                          setState(() => selected = null);
                          onChanged?.call(null);
                        },
                        availableStock:
                            availableStock ?? (variant) => variant.stock,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Zain')
          ..addFont(rootBundle.load('assets/fonts/Zain-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Zain-Bold.ttf')))
        .load();
    var flutterCache = File(Platform.resolvedExecutable).parent;
    while (flutterCache.path.split(Platform.pathSeparator).last != 'cache') {
      final parent = flutterCache.parent;
      if (parent.path == flutterCache.path) {
        throw StateError('Unable to locate the Flutter cache directory.');
      }
      flutterCache = parent;
    }
    final materialIconBytes = await File(
      '${flutterCache.path}/artifacts/material_fonts/materialicons-regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(materialIconBytes)))).load();
  });

  test(
    'size labels stay compatible without mutating inventory or model labels',
    () {
      final first = clothingPreviewVariants.first;
      expect(first.localizedName, 'أسود / XLarge');
      expect(first.localizedOptionName, 'أسود');
      expect(productSizeLabel(first.size), 'XL');
      expect(first.size, 'XLarge');
      const old = ProductVariant(
        id: 'old',
        nameAr: 'أسود',
        imageUrl: '',
        stock: 1,
      );
      expect(old.hasSize, isFalse);
      expect(old.localizedName, 'أسود');
      const sized = ProductVariant(
        id: 'new',
        nameAr: 'أبيض',
        imageUrl: '',
        stock: 1,
        size: '42',
      );
      expect(sized.localizedName, 'أبيض / 42');
    },
  );

  test(
    'normalizes aliases, orders alpha and numeric sizes and preserves custom labels',
    () {
      expect(
        [
          'extra small',
          'Small',
          'medium',
          'LARGE',
          'X-Large',
          '2XL',
        ].map(productSizeLabel),
        ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      );
      final sizes = ['XXL', '40', 'XL', 'S', 'XS', 'M', '38', 'L']
        ..sort(compareProductSizes);
      expect(sizes, ['XS', 'S', 'M', 'L', 'XL', 'XXL', '38', '40']);
      expect(productSizeLabel('6–9 months'), '6–9 months');
      expect(productSizeLabel(null), '');
      expect(compareProductSizes('', ''), 0);
      const legacy = ProductVariant(
        id: 'a',
        nameAr: 'أسود / XLarge / XL',
        size: 'XL',
        imageUrl: '',
        stock: 1,
      );
      expect(productVariantOptionLabel(legacy), 'أسود');
    },
  );

  testWidgets(
    'colors filter sizes; chooses exact ID and keeps choice on repeated tap',
    (tester) async {
      String? selectedId;
      await pumpOptions(
        tester,
        onChanged: (id) => selectedId = id,
        selected: null,
      );
      expect(find.text('XLarge'), findsNothing);
      expect(find.text('XL'), findsOneWidget);
      expect(button(tester, 'product_size_L').onPressed, isNull);
      await tester.tap(choice('product_size_M'));
      await tester.pumpAndSettle();
      expect(selectedId, 'black-m');
      await tester.tap(choice('product_size_M'));
      await tester.pumpAndSettle();
      expect(selectedId, 'black-m');
      await tester.tap(choice('product_color_white-m'));
      await tester.pumpAndSettle();
      expect(selectedId, 'white-m');
      expect(choice('product_size_S'), findsNothing);
      expect(button(tester, 'product_size_L').onPressed, isNotNull);
      expect(button(tester, 'product_size_XL').onPressed, isNull);
      await tester.tap(choice('product_size_L'));
      await tester.pumpAndSettle();
      expect(selectedId, 'white-l');
      await tester.tap(choice('product_color_black-xl'));
      await tester.pumpAndSettle();
      expect(
        selectedId,
        isNull,
        reason: 'Black L is sold out; clear the cart selection.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'alias duplicates require an explicit SKU, never combine their stock',
    (tester) async {
      const duplicates = [
        ProductVariant(
          id: 'a',
          nameAr: 'أسود / XL',
          size: 'XL',
          sku: 'BLACK-A',
          imageUrl: '',
          stock: 2,
        ),
        ProductVariant(
          id: 'b',
          nameAr: 'أسود / XLarge',
          size: 'XLarge',
          sku: 'BLACK-B',
          imageUrl: '',
          stock: 7,
        ),
        ProductVariant(
          id: 'c',
          nameAr: 'أسود / XL',
          size: 'XL',
          sku: 'BLACK-C',
          imageUrl: '',
          stock: 0,
        ),
      ];
      String? selectedId;
      await pumpOptions(
        tester,
        variants: duplicates,
        selected: null,
        onChanged: (id) => selectedId = id,
      );
      expect(find.text('XL'), findsOneWidget);
      await tester.tap(choice('product_size_XL'));
      await tester.pumpAndSettle();
      expect(selectedId, isNull);
      expect(find.text('BLACK-A'), findsOneWidget);
      expect(find.text('BLACK-B'), findsOneWidget);
      expect(button(tester, 'product_variant_c').onPressed, isNull);
      await tester.tap(choice('product_variant_b'));
      await tester.pumpAndSettle();
      expect(selectedId, 'b');
      expect(
        find.textContaining(ProductStrings.variantInStock(formatNumber(7))),
        findsWidgets,
      );
      expect(
        find.textContaining(ProductStrings.variantInStock(formatNumber(9))),
        findsNothing,
      );
    },
  );

  testWidgets(
    'uses available stock callback and handles zero stock and empty lists',
    (tester) async {
      await pumpOptions(tester, selected: null, availableStock: (_) => 0);
      for (final label in ['S', 'M', 'L', 'XL', 'XXL']) {
        expect(button(tester, 'product_size_$label').onPressed, isNull);
      }
      expect(find.text(ProductStrings.outOfStockTemporarily), findsOneWidget);
      await tester.tap(choice('product_color_white-m'));
      await tester.pumpAndSettle();
      expect(choice('product_size_S'), findsNothing);
      await pumpOptions(tester, variants: [], selected: null);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text(ProductStrings.outOfStockTemporarily), findsOneWidget);
    },
  );

  testWidgets(
    'semantics announce selected and unavailable sizes; keyboard activates choices',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        String? selectedId;
        await pumpOptions(
          tester,
          language: AppLanguage.en,
          onChanged: (id) => selectedId = id,
        );
        expect(
          tester.getSemantics(choice('product_size_M')),
          matchesSemantics(
            label: 'M',
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
            hasSelectedState: true,
            isSelected: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        expect(
          tester.getSemantics(choice('product_size_L')).label,
          contains(ProductStrings.outOfStockTemporarily),
        );
        for (var index = 0; index < 3; index++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(selectedId, 'black-s');
        expect(FocusManager.instance.primaryFocus, isNotNull);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final width in [320.0, 375.0, 800.0]) {
    for (final dark in [false, true]) {
      for (final language in [AppLanguage.ar, AppLanguage.en]) {
        testWidgets('fits ${width}px $language dark=$dark 200% text', (
          tester,
        ) async {
          await pumpOptions(
            tester,
            width: width,
            height: width == 800 ? 375 : 1100,
            textScale: 2,
            dark: dark,
            language: language,
          );
          expect(tester.takeException(), isNull);
          for (final finder in [
            choice('product_color_black-xl'),
            choice('product_color_white-m'),
            ...[
              'S',
              'M',
              'L',
              'XL',
              'XXL',
            ].map((size) => choice('product_size_$size')),
          ]) {
            final rect = tester.getRect(finder);
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.left, greaterThanOrEqualTo(16));
            expect(rect.right, lessThanOrEqualTo(width - 16));
          }
          if (width == 375 && language == AppLanguage.ar) {
            await expectLater(
              find.byType(Scaffold),
              matchesGoldenFile(
                'goldens/clothing/sizes-rtl-${dark ? "dark" : "light"}.png',
              ),
            );
          }
        });
      }
    }
  }

  testWidgets(
    'long localized option and custom size labels stay available at 200%',
    (tester) async {
      const long = [
        ProductVariant(
          id: 'long',
          nameAr: 'موديل القطن الأسود بتفاصيل وتطريز طويل للمناسبات الخاصة',
          size: 'مقاس خاص حسب جدول القياسات',
          imageUrl: '',
          stock: 3,
        ),
      ];
      await pumpOptions(
        tester,
        variants: long,
        selected: null,
        width: 320,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(long.first.nameAr), findsOneWidget);
      expect(find.text(long.first.size!), findsOneWidget);
    },
  );

  for (final dark in [false, true]) {
    testWidgets('normal phone visual dark=$dark', (tester) async {
      await pumpOptions(tester, height: 560, dark: dark);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/clothing/sizes-phone-${dark ? "dark" : "light"}.png',
        ),
      );
    });
  }
  testWidgets('landscape visual retains one readable group', (tester) async {
    await pumpOptions(
      tester,
      width: 800,
      height: 375,
      language: AppLanguage.en,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/clothing/sizes-landscape.png'),
    );
  });
}
