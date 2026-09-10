import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/features/product/product_size_options.dart';

const options = [
  ProductVariant(
    id: 'black-m',
    nameAr: 'أسود / M',
    imageUrl: '',
    stock: 3,
    size: 'M',
  ),
  ProductVariant(
    id: 'black-l',
    nameAr: 'أسود / L',
    imageUrl: '',
    stock: 0,
    size: 'L',
  ),
  ProductVariant(
    id: 'white-m',
    nameAr: 'أبيض / M',
    imageUrl: '',
    stock: 2,
    size: 'M',
  ),
];

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
  test('size labels remain compatible and are never repeated', () {
    expect(options.first.localizedName, 'أسود / M');
    expect(options.first.localizedOptionName, 'أسود');
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
  });

  testWidgets(
    'selects exact color-size ID and disables only sold-out combinations',
    (tester) async {
      String? selectedId;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ProductSizeOptions(
                variants: options,
                selectedId: selectedId,
                onSelected: (variant) =>
                    setState(() => selectedId = variant.id),
                availableStock: (variant) => variant.stock,
              ),
            ),
          ),
        ),
      );
      final disabled = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('product_size_black-l')),
      );
      expect(disabled.onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('product_size_white-m')));
      await tester.pumpAndSettle();
      expect(selectedId, 'white-m');
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('product_size_black-m')));
      await tester.pumpAndSettle();
      expect(selectedId, 'black-m');
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 375.0, 800.0]) {
    for (final dark in [false, true]) {
      testWidgets('size choices fit RTL ${width}px dark=$dark at 200% text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        AppColors.p = dark ? AppPalette.dark : AppPalette.light;
        addTearDown(() => AppColors.p = AppPalette.light);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                  size: Size(width, 1400),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(16),
                      child: ProductSizeOptions(
                        variants: options,
                        selectedId: 'black-m',
                        onSelected: (_) {},
                        availableStock: (v) => v.stock,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (width == 375) {
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
              'goldens/clothing/sizes-rtl-${dark ? "dark" : "light"}.png',
            ),
          );
        }
        for (final option in options) {
          final rect = tester.getRect(
            find.byKey(ValueKey('product_size_${option.id}')),
          );
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
        }
      });
    }
  }
}
