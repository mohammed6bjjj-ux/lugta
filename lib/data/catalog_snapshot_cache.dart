import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Small, non-sensitive stale-while-revalidate snapshot for the seller catalog.
///
/// The backend remains authoritative. This cache only lets the catalog paint
/// immediately on a cold start or a temporarily slow connection; order submit
/// already revalidates the selected product before committing the order.
class CatalogSnapshotCache {
  CatalogSnapshotCache({CatalogSnapshotStore? store})
    : this._(store ?? _SharedPreferencesCatalogSnapshotStore());

  CatalogSnapshotCache._(this._store);

  static const _storageKeyPrefix = 'lugta.catalog.snapshot.v2';
  static const _legacyStorageKey = 'nawl.catalog.snapshot.v1';
  static const defaultMaxAge = Duration(days: 7);
  static const maxCachedProducts = 120;

  final CatalogSnapshotStore _store;
  Future<void> _writeTail = Future<void>.value();

  Future<CatalogSnapshot?> read({
    String scopeKey = 'default',
    DateTime? now,
    Duration maxAge = defaultMaxAge,
  }) async {
    String? encoded;
    try {
      // v1 persisted temporary signed bearer URLs in one global key. It is
      // intentionally removed instead of migrated.
      await _store.remove(_legacyStorageKey);
      encoded = await _store.getString(_keyForScope(scopeKey));
    } catch (_) {
      return null;
    }
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final json = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
      if (json['version'] != 1) return null;
      final savedAt = DateTime.parse(json['saved_at'] as String).toUtc();
      final current = (now ?? DateTime.now()).toUtc();
      final age = current.difference(savedAt);
      if (age.isNegative || age > maxAge) return null;

      return CatalogSnapshot(
        savedAt: savedAt,
        categories: _list(json['categories']).map(_categoryFromJson).toList(),
        products: _list(json['products']).map(_productFromJson).toList(),
      );
    } catch (_) {
      // Corrupt or partially-written cache data must never block live data.
      return null;
    }
  }

  Future<void> write({
    required List<Category> categories,
    required List<Product> products,
    String scopeKey = 'default',
    DateTime? savedAt,
  }) {
    final payload = <String, Object?>{
      'version': 1,
      'saved_at': (savedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'categories': categories.map(_categoryToJson).toList(),
      // This is a first-paint accelerator, not a second source of truth. Keep
      // it bounded so a large catalog never turns SharedPreferences into a
      // multi-megabyte database; the live request replaces it moments later.
      'products': products.take(maxCachedProducts).map(_productToJson).toList(),
    };
    final previous = _writeTail;
    late final Future<void> next;
    next = () async {
      try {
        await previous;
      } catch (_) {
        // A failed older write must not poison a newer catalog snapshot.
      }
      try {
        await _store.remove(_legacyStorageKey);
        await _store.setString(_keyForScope(scopeKey), jsonEncode(payload));
      } catch (_) {
        // The cache is optional on unsupported/test platforms and must never
        // surface as a background error after live catalog publication.
      }
    }();
    _writeTail = next;
    return next;
  }

  Future<void> clear({String scopeKey = 'default'}) async {
    try {
      await _writeTail;
    } catch (_) {
      // Clear remains authoritative even if the last acceleration write failed.
    }
    try {
      await Future.wait<void>([
        _store.remove(_legacyStorageKey),
        _store.remove(_keyForScope(scopeKey)),
      ]);
    } catch (_) {
      // Removing an optional acceleration cache is best-effort.
    }
  }

  static String _keyForScope(String scopeKey) {
    final normalized = scopeKey.trim().isEmpty ? 'default' : scopeKey.trim();
    final encoded = base64Url
        .encode(utf8.encode(normalized))
        .replaceAll('=', '');
    return '$_storageKeyPrefix.$encoded';
  }
}

abstract interface class CatalogSnapshotStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

class _SharedPreferencesCatalogSnapshotStore implements CatalogSnapshotStore {
  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _prefs =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class CatalogSnapshot {
  const CatalogSnapshot({
    required this.savedAt,
    required this.categories,
    required this.products,
  });

  final DateTime savedAt;
  final List<Category> categories;
  final List<Product> products;
}

List<Map<String, dynamic>> _list(Object? value) => value is List
    ? value.map((item) => Map<String, dynamic>.from(item as Map)).toList()
    : const [];

Map<String, Object?> _categoryToJson(Category category) => {
  'id': category.id,
  'name_ar': category.nameAr,
  'name_ckb': category.nameCkb,
  'name_en': category.nameEn,
  'image_url': category.imageUrl,
  'icon_code_point': category.icon.codePoint,
  'sticker_key': category.stickerKey.wireValue,
};

Category _categoryFromJson(Map<String, dynamic> json) => Category(
  id: json['id'] as String,
  nameAr: json['name_ar'] as String,
  nameCkb: json['name_ckb'] as String?,
  nameEn: json['name_en'] as String?,
  imageUrl: json['image_url'] as String? ?? '',
  icon: _categoryIcon(json['icon_code_point'] as int?),
  stickerKey: categoryStickerKeyFromWire(json['sticker_key']),
);

IconData _categoryIcon(int? codePoint) => switch (codePoint) {
  final value when value == Icons.watch.codePoint => Icons.watch,
  final value when value == Icons.watch_rounded.codePoint =>
    Icons.watch_rounded,
  final value when value == Icons.watch_outlined.codePoint =>
    Icons.watch_outlined,
  final value when value == Icons.visibility_outlined.codePoint =>
    Icons.visibility_outlined,
  final value when value == Icons.diamond_outlined.codePoint =>
    Icons.diamond_outlined,
  final value when value == Icons.inventory_2_outlined.codePoint =>
    Icons.inventory_2_outlined,
  final value when value == Icons.smartphone_rounded.codePoint =>
    Icons.smartphone_rounded,
  final value when value == Icons.laptop_mac_rounded.codePoint =>
    Icons.laptop_mac_rounded,
  final value when value == Icons.desktop_windows_rounded.codePoint =>
    Icons.desktop_windows_rounded,
  final value when value == Icons.tablet_mac_rounded.codePoint =>
    Icons.tablet_mac_rounded,
  final value when value == Icons.tv_rounded.codePoint => Icons.tv_rounded,
  final value when value == Icons.photo_camera_rounded.codePoint =>
    Icons.photo_camera_rounded,
  final value when value == Icons.headphones_rounded.codePoint =>
    Icons.headphones_rounded,
  final value when value == Icons.sports_esports_rounded.codePoint =>
    Icons.sports_esports_rounded,
  final value when value == Icons.wifi_rounded.codePoint => Icons.wifi_rounded,
  final value when value == Icons.electrical_services_rounded.codePoint =>
    Icons.electrical_services_rounded,
  final value when value == Icons.memory_rounded.codePoint =>
    Icons.memory_rounded,
  final value when value == Icons.kitchen_rounded.codePoint =>
    Icons.kitchen_rounded,
  final value when value == Icons.chair_rounded.codePoint =>
    Icons.chair_rounded,
  final value when value == Icons.home_rounded.codePoint => Icons.home_rounded,
  final value when value == Icons.shopping_bag_rounded.codePoint =>
    Icons.shopping_bag_rounded,
  final value when value == Icons.hiking_rounded.codePoint =>
    Icons.hiking_rounded,
  final value when value == Icons.palette_rounded.codePoint =>
    Icons.palette_rounded,
  final value when value == Icons.checkroom_rounded.codePoint =>
    Icons.checkroom_rounded,
  final value when value == Icons.fitness_center_rounded.codePoint =>
    Icons.fitness_center_rounded,
  final value when value == Icons.toys_rounded.codePoint => Icons.toys_rounded,
  final value when value == Icons.menu_book_rounded.codePoint =>
    Icons.menu_book_rounded,
  final value when value == Icons.pets_rounded.codePoint => Icons.pets_rounded,
  final value when value == Icons.directions_car_rounded.codePoint =>
    Icons.directions_car_rounded,
  final value when value == Icons.build_rounded.codePoint =>
    Icons.build_rounded,
  final value when value == Icons.shopping_basket_rounded.codePoint =>
    Icons.shopping_basket_rounded,
  final value when value == Icons.restaurant_rounded.codePoint =>
    Icons.restaurant_rounded,
  final value when value == Icons.health_and_safety_rounded.codePoint =>
    Icons.health_and_safety_rounded,
  final value when value == Icons.business_center_rounded.codePoint =>
    Icons.business_center_rounded,
  final value when value == Icons.luggage_rounded.codePoint =>
    Icons.luggage_rounded,
  final value when value == Icons.devices_rounded.codePoint =>
    Icons.devices_rounded,
  final value when value == Icons.category_outlined.codePoint =>
    Icons.category_outlined,
  _ => Icons.category_outlined,
};

Map<String, Object?> _productToJson(Product product) => {
  'id': product.id,
  'name_ar': product.nameAr,
  'name_ckb': product.nameCkb,
  'name_en': product.nameEn,
  'category_id': product.categoryId,
  'description_ar': product.description,
  'description_ckb': product.descriptionCkb,
  'description_en': product.descriptionEn,
  'specs': product.specs,
  'media': product.media.map(_mediaToJson).toList(),
  'variants': product.variants.map(_variantToJson).toList(),
  'wholesale_price': product.wholesalePrice,
  'old_wholesale_price': product.oldWholesalePrice,
  'suggested_price': product.suggestedPrice,
  'min_sale_price': product.minSalePrice,
  'max_sale_price': product.maxSalePrice,
  'orders_count': product.ordersCount,
  'is_new': product.isNew,
  'created_at': product.createdAt.toUtc().toIso8601String(),
};

Product _productFromJson(Map<String, dynamic> json) => Product(
  id: json['id'] as String,
  nameAr: json['name_ar'] as String,
  nameCkb: json['name_ckb'] as String?,
  nameEn: json['name_en'] as String?,
  categoryId: json['category_id'] as String,
  description: json['description_ar'] as String? ?? '',
  descriptionCkb: json['description_ckb'] as String?,
  descriptionEn: json['description_en'] as String?,
  specs: Map<String, String>.from(json['specs'] as Map? ?? const {}),
  media: _list(json['media']).map(_mediaFromJson).toList(),
  variants: _list(json['variants']).map(_variantFromJson).toList(),
  wholesalePrice: json['wholesale_price'] as int,
  oldWholesalePrice: json['old_wholesale_price'] as int?,
  suggestedPrice: json['suggested_price'] as int,
  minSalePrice: json['min_sale_price'] as int?,
  maxSalePrice: json['max_sale_price'] as int?,
  ordersCount: json['orders_count'] as int? ?? 0,
  isNew: json['is_new'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
);

Map<String, Object?> _mediaToJson(MediaItem item) => {
  'id': item.id,
  'type': item.type.name,
  'url': item.url,
  'thumbnail_url': item.thumbnailUrl,
  'duration_sec': item.durationSec,
};

MediaItem _mediaFromJson(Map<String, dynamic> json) => MediaItem(
  id: json['id'] as String,
  type: json['type'] == MediaType.video.name
      ? MediaType.video
      : MediaType.image,
  url: json['url'] as String,
  thumbnailUrl: json['thumbnail_url'] as String?,
  durationSec: json['duration_sec'] as int?,
);

Map<String, Object?> _variantToJson(ProductVariant variant) => {
  'id': variant.id,
  'name_ar': variant.nameAr,
  'name_ckb': variant.nameCkb,
  'name_en': variant.nameEn,
  'sku': variant.sku,
  'wholesale_price_override': variant.wholesalePriceOverride,
  'suggested_price_override': variant.suggestedPriceOverride,
  'image_url': variant.imageUrl,
  'stock': variant.stock,
  'color_hex': variant.colorHex,
};

ProductVariant _variantFromJson(Map<String, dynamic> json) => ProductVariant(
  id: json['id'] as String,
  nameAr: json['name_ar'] as String,
  nameCkb: json['name_ckb'] as String?,
  nameEn: json['name_en'] as String?,
  sku: json['sku'] as String?,
  wholesalePriceOverride: json['wholesale_price_override'] as int?,
  suggestedPriceOverride: json['suggested_price_override'] as int?,
  imageUrl: json['image_url'] as String? ?? '',
  stock: json['stock'] as int,
  colorHex: json['color_hex'] as int?,
);
