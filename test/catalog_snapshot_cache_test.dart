import 'package:flutter/material.dart';
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
