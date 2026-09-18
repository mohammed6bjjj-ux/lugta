import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/features/catalog/home_best_sellers.dart';
import 'package:flutter_test/flutter_test.dart';

Product product(String id, {int? rank, int orders = 0, int day = 1}) => Product(
  id: id,
  nameAr: id,
  categoryId: 'watches',
  description: '',
  specs: const {},
  media: const [],
  variants: const [],
  wholesalePrice: 1000,
  suggestedPrice: 2000,
  createdAt: DateTime(2026, 9, day),
  ordersCount: orders,
  homeDisplayOrder: rank,
);

void main() {
  test('only selected products appear in exact admin order', () {
    final items = [
      product('b', rank: 2),
      product('x', orders: 999),
      product('a', rank: 1),
    ];
    expect(homeBestSellers(items).map((p) => p.id), ['a', 'b']);
    expect(items.first.id, 'b');
  });
  test('fallback ties are deterministic and capped at six', () {
    final items = [for (var i = 8; i >= 0; i--) product('$i')];
    expect(homeBestSellers(items).map((p) => p.id), [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
    ]);
    expect(homeBestSellers(items.reversed).map((p) => p.id), [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
    ]);
    expect(
      homeBestSellers([
        product('a'),
        product('b', day: 2),
        product('c', orders: 1),
      ]).map((p) => p.id),
      ['c', 'b', 'a'],
    );
  });
  test('old cache, empty catalog and invalid ranks stay safe', () {
    expect(homeBestSellers([]), isEmpty);
    expect(homeBestSellers([product('a'), product('b', rank: -1)]).length, 2);
    expect(
      homeBestSellers([
        product('b', rank: 1),
        product('a', rank: 1),
      ]).map((p) => p.id),
      ['a', 'b'],
    );
  });
}
