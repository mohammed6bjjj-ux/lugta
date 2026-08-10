import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/category_sticker_icons.dart';
import 'package:flutter_app/data/catalog_snapshot_cache.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('round-trips a fresh multilingual catalog snapshot', () async {
    final store = _MemoryCatalogSnapshotStore();
    final cache = CatalogSnapshotCache(store: store);
    final savedAt = DateTime.utc(2026, 7, 22, 7);
    final category = Category(
      id: 'category-1',
      nameAr: 'ساعات',
      nameCkb: 'کاتژمێر',
      nameEn: 'Watches',
      icon: Icons.watch,
      imageUrl: 'https://example.com/category.jpg',
      stickerKey: CategoryStickerKey.premium,
    );
    final product = Product(
      id: 'product-1',
      nameAr: 'ساعة',
      nameCkb: 'کاتژمێر',
      nameEn: 'Watch',
      categoryId: category.id,
      description: 'وصف',
      specs: const {'الخامة': 'فولاذ'},
      media: const [
        MediaItem(
          id: 'media-1',
          type: MediaType.image,
          url: 'https://example.com/image.jpg?token=one',
        ),
      ],
      variants: const [
        ProductVariant(id: 'variant-1', nameAr: 'أسود', imageUrl: '', stock: 3),
      ],
      wholesalePrice: 10000,
      suggestedPrice: 15000,
      createdAt: savedAt,
    );

    await cache.write(
      categories: [category],
      products: [product],
      savedAt: savedAt,
    );
    final restored = await cache.read(
      now: savedAt.add(const Duration(hours: 2)),
    );

    expect(restored, isNotNull);
    expect(restored!.categories.single.nameEn, 'Watches');
    expect(restored.categories.single.icon.codePoint, Icons.watch.codePoint);
    expect(restored.categories.single.stickerKey, CategoryStickerKey.premium);
    expect(restored.products.single.media.single.url, contains('token=one'));
    expect(restored.products.single.variants.single.stock, 3);
    expect(restored.products.single.specs['الخامة'], 'فولاذ');
  });

  test('ignores expired or corrupt catalog snapshots', () async {
    final store = _MemoryCatalogSnapshotStore();
    final cache = CatalogSnapshotCache(store: store);
    final savedAt = DateTime.utc(2026, 7, 1);

    await cache.write(
      categories: const [],
      products: const [],
      savedAt: savedAt,
    );
    expect(await cache.read(now: savedAt.add(const Duration(days: 8))), isNull);

    await store.setString(store.values.keys.single, '{broken');
    expect(await cache.read(now: savedAt), isNull);
  });

  test('keeps every supported category icon after cache restoration', () async {
    final store = _MemoryCatalogSnapshotStore();
    final cache = CatalogSnapshotCache(store: store);
    final savedAt = DateTime.utc(2026, 8, 9);
    const icons = [
      Icons.watch,
      Icons.watch_rounded,
      Icons.watch_outlined,
      Icons.visibility_outlined,
      Icons.diamond_outlined,
      Icons.inventory_2_outlined,
      Icons.smartphone_rounded,
      Icons.laptop_mac_rounded,
      Icons.desktop_windows_rounded,
      Icons.tablet_mac_rounded,
      Icons.tv_rounded,
      Icons.photo_camera_rounded,
      Icons.headphones_rounded,
      Icons.sports_esports_rounded,
      Icons.wifi_rounded,
      Icons.electrical_services_rounded,
      Icons.memory_rounded,
      Icons.kitchen_rounded,
      Icons.chair_rounded,
      Icons.home_rounded,
      Icons.shopping_bag_rounded,
      Icons.hiking_rounded,
      Icons.palette_rounded,
      Icons.checkroom_rounded,
      Icons.fitness_center_rounded,
      Icons.toys_rounded,
      Icons.menu_book_rounded,
      Icons.pets_rounded,
      Icons.directions_car_rounded,
      Icons.build_rounded,
      Icons.shopping_basket_rounded,
      Icons.restaurant_rounded,
      Icons.health_and_safety_rounded,
      Icons.business_center_rounded,
      Icons.luggage_rounded,
      Icons.devices_rounded,
      Icons.category_outlined,
    ];
    final categories = [
      for (var index = 0; index < icons.length; index++)
        Category(
          id: 'category-$index',
          nameAr: 'تصنيف $index',
          icon: icons[index],
          imageUrl: '',
        ),
    ];

    await cache.write(
      categories: categories,
      products: const [],
      savedAt: savedAt,
    );
    final restored = await cache.read(now: savedAt);

    expect(
      restored!.categories.map((category) => category.icon.codePoint),
      icons.map((icon) => icon.codePoint),
    );
  });

  test(
    'category sticker wire contract is complete and backwards compatible',
    () {
      for (final sticker in CategoryStickerKey.values) {
        expect(categoryStickerKeyFromWire(sticker.wireValue), sticker);
      }
      expect(categoryStickerKeyFromWire(null), CategoryStickerKey.auto);
      expect(categoryStickerKeyFromWire('unknown'), CategoryStickerKey.auto);
    },
  );

  test('every explicit category sticker has a material icon', () {
    expect(categoryStickerIconFor(CategoryStickerKey.auto), isNull);
    expect(categoryStickerIconFor(CategoryStickerKey.none), isNull);
    for (final sticker in CategoryStickerKey.values.where(
      (value) =>
          value != CategoryStickerKey.auto && value != CategoryStickerKey.none,
    )) {
      expect(
        categoryStickerIconFor(sticker),
        isNotNull,
        reason: sticker.wireValue,
      );
    }
  });

  test('restores a legacy snapshot without a category sticker key', () async {
    final store = _MemoryCatalogSnapshotStore();
    final cache = CatalogSnapshotCache(store: store);
    final savedAt = DateTime.utc(2026, 8, 9);

    await cache.write(
      categories: const [
        Category(
          id: 'legacy-category',
          nameAr: 'ساعات ذكية',
          icon: Icons.watch,
          imageUrl: '',
        ),
      ],
      products: const [],
      savedAt: savedAt,
    );

    final storageKey = store.values.keys.single;
    final payload =
        jsonDecode(store.values[storageKey]!) as Map<String, dynamic>;
    final categories = payload['categories'] as List<dynamic>;
    (categories.single as Map<String, dynamic>).remove('sticker_key');
    await store.setString(storageKey, jsonEncode(payload));

    final restored = await cache.read(now: savedAt);
    expect(restored!.categories.single.stickerKey, CategoryStickerKey.auto);
  });

  test('bounds the first-paint snapshot for very large catalogs', () async {
    final store = _MemoryCatalogSnapshotStore();
    final cache = CatalogSnapshotCache(store: store);
    final savedAt = DateTime.utc(2026, 7, 22);
    final products = List<Product>.generate(
      CatalogSnapshotCache.maxCachedProducts + 5,
      (index) => Product(
        id: 'product-$index',
        nameAr: 'منتج $index',
        categoryId: 'category-1',
        description: '',
        specs: const {},
        media: const [],
        variants: const [],
        wholesalePrice: 1000,
        suggestedPrice: 1500,
        createdAt: savedAt.subtract(Duration(minutes: index)),
      ),
    );

    await cache.write(
      categories: const [],
      products: products,
      savedAt: savedAt,
    );
    final restored = await cache.read(now: savedAt);

    expect(
      restored!.products,
      hasLength(CatalogSnapshotCache.maxCachedProducts),
    );
    expect(restored.products.first.id, 'product-0');
    expect(
      restored.products.last.id,
      'product-${CatalogSnapshotCache.maxCachedProducts - 1}',
    );
  });

  test('keeps snapshots isolated between authenticated users', () async {
    final store = _MemoryCatalogSnapshotStore();
    final cache = CatalogSnapshotCache(store: store);
    final savedAt = DateTime.utc(2026, 7, 22);
    final first = Product(
      id: 'seller-a-product',
      nameAr: 'منتج أ',
      categoryId: 'category-1',
      description: '',
      specs: const {},
      media: const [],
      variants: const [],
      wholesalePrice: 1000,
      suggestedPrice: 1500,
      createdAt: savedAt,
    );
    final second = Product(
      id: 'seller-b-product',
      nameAr: 'منتج ب',
      categoryId: 'category-1',
      description: '',
      specs: const {},
      media: const [],
      variants: const [],
      wholesalePrice: 1000,
      suggestedPrice: 1500,
      createdAt: savedAt,
    );

    await cache.write(
      categories: const [],
      products: [first],
      scopeKey: 'seller-a',
      savedAt: savedAt,
    );
    await cache.write(
      categories: const [],
      products: [second],
      scopeKey: 'seller-b',
      savedAt: savedAt,
    );

    expect(
      (await cache.read(
        scopeKey: 'seller-a',
        now: savedAt,
      ))!.products.single.id,
      first.id,
    );
    expect(
      (await cache.read(
        scopeKey: 'seller-b',
        now: savedAt,
      ))!.products.single.id,
      second.id,
    );
  });
}

class _MemoryCatalogSnapshotStore implements CatalogSnapshotStore {
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
