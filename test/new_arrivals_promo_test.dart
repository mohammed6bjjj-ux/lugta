import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/features/catalog/catalog_strings.dart';
import 'package:flutter_app/features/catalog/new_arrivals_promo.dart';

Product _product({
  required String id,
  required bool isNew,
  required int day,
  String cover = 'https://example.test/cover.webp',
}) => Product(
  id: id,
  nameAr: 'ساعة $id',
  categoryId: 'category-1',
  description: '',
  specs: const {},
  media: [
    if (cover.isNotEmpty)
      MediaItem(id: '$id-cover', type: MediaType.image, url: cover),
  ],
  variants: const [],
  wholesalePrice: 10000,
  suggestedPrice: 15000,
  isNew: isNew,
  createdAt: DateTime(2026, 1, day),
);

void main() {
  setUp(NewArrivalsPromo.resetForTesting);

  group('pickPromoProduct', () {
    test('advertises nothing when no arrival is actually new', () {
      final products = [
        _product(id: 'a', isNew: false, day: 3),
        _product(id: 'b', isNew: false, day: 2),
      ];

      expect(pickPromoProduct(products), isNull);
    });

    test('skips products that have no cover image to show', () {
      final products = [_product(id: 'a', isNew: true, day: 3, cover: '')];

      expect(pickPromoProduct(products), isNull);
    });

    test('varies the pick across launches instead of pinning one product', () {
      final products = [
        for (var day = 1; day <= 6; day++)
          _product(id: 'p$day', isNew: true, day: day),
      ];

      final picked = {
        for (var seed = 0; seed < 40; seed++)
          pickPromoProduct(products, random: Random(seed))!.id,
      };

      expect(picked.length, greaterThan(1));
    });

    test('only ever advertises genuinely new arrivals', () {
      final products = [
        _product(id: 'old', isNew: false, day: 9),
        _product(id: 'fresh', isNew: true, day: 1),
      ];

      for (var seed = 0; seed < 20; seed++) {
        expect(pickPromoProduct(products, random: Random(seed))!.id, 'fresh');
      }
    });
  });

  testWidgets('the promo interrupts the seller at most once per launch', (
    tester,
  ) async {
    AppColors.p = AppPalette.light;
    addTearDown(() => AppColors.p = AppPalette.light);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => NewArrivalsPromo.maybeShow(
                    context,
                    random: Random(1),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // The default session already carries mock products, one of which is new.
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(CatalogStrings.promoNewArrivalsTitle), findsOneWidget);
    expect(find.text(CatalogStrings.promoSwipeUp), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(CatalogStrings.promoNewArrivalsTitle), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.text(CatalogStrings.promoNewArrivalsTitle),
      findsNothing,
      reason: 'a promo that returns on every entry reads as spam',
    );
    expect(tester.takeException(), isNull);
  });
}
