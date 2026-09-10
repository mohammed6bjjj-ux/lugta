import 'package:flutter/material.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/features/catalog/home_catalog_sections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const categories = [
    Category(
      id: 'clothes',
      nameAr: 'ملابس رجالية',
      icon: Icons.checkroom,
      imageUrl: '',
    ),
    Category(
      id: 'watches',
      nameAr: 'ساعات رجالية',
      icon: Icons.watch,
      imageUrl: '',
    ),
    Category(id: 'empty', nameAr: 'فارغ', icon: Icons.category, imageUrl: ''),
  ];
  test('six newest per category, admin category order, no empty sections', () {
    final products = [
      for (var i = 0; i < 9; i++) fixtureProduct('watch-$i', 'watches', i),
      for (var i = 0; i < 8; i++) fixtureProduct('shirt-$i', 'clothes', i),
      fixtureProduct('orphan', 'unknown', 20),
    ];
    final original = List.of(products);
    final sections = homeCatalogSections(categories, products);
    expect(sections.map((s) => s.category.id), ['clothes', 'watches']);
    expect(sections.map((s) => s.products.length), [6, 6]);
    expect(sections.first.products.map((p) => p.id), [
      'shirt-7',
      'shirt-6',
      'shirt-5',
      'shirt-4',
      'shirt-3',
      'shirt-2',
    ]);
    for (final section in sections) {
      expect(
        section.products.every((p) => p.categoryId == section.category.id),
        isTrue,
      );
    }
    expect(products, original);
  });

  test('fewer than six remain visible; empty and late catalogs are safe', () {
    expect(homeCatalogSections(categories, []), isEmpty);
    final sections = homeCatalogSections(categories, [
      fixtureProduct('only', 'watches', 1),
    ]);
    expect(sections.single.products.single.id, 'only');
    expect(homeCatalogSections([], sections.single.products), isEmpty);
  });
}

Product fixtureProduct(String id, String categoryId, int day) => Product(
  id: id,
  nameAr: 'ساعة كلاسيك $day',
  categoryId: categoryId,
  description: '',
  specs: const {},
  media: const [],
  variants: const [],
  wholesalePrice: 6500,
  suggestedPrice: 15000,
  createdAt: DateTime(2026, 9, day + 1),
  ordersCount: day,
);
