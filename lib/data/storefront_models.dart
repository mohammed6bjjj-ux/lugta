import 'package:flutter/foundation.dart';

@immutable
class StoreTheme {
  const StoreTheme({
    required this.id,
    required this.name,
    required this.thumbnailAsset,
    required this.previewAsset,
    this.previewUrl = '',
    this.thumbnailUrl = '',
    this.palettes = const [],
  });
  final String id;
  final String name;
  final String thumbnailAsset;
  final String previewAsset;
  final String previewUrl;
  final String thumbnailUrl;
  final List<StorePalette> palettes;
}

@immutable
class StorePalette {
  const StorePalette({
    required this.id,
    required this.name,
    required this.accent,
    required this.background,
  });
  final String id, name, accent, background;
}

@immutable
class MerchantStore {
  const MerchantStore({
    required this.id,
    required this.slug,
    required this.brandName,
    required this.themeId,
    this.logoPath = '',
    this.logoUrl = '',
    this.publicUrl = '',
    this.published = false,
    this.activeUntil,
    this.paletteId = '',
  });
  final String id;
  final String slug;
  final String brandName;
  final String themeId;
  final String paletteId;
  final String logoPath;
  final String logoUrl;
  final String publicUrl;
  final bool published;
  final DateTime? activeUntil;

  bool isActiveAt(DateTime time) =>
      published && activeUntil?.isAfter(time) == true;
}

@immutable
class StoreListing {
  const StoreListing({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.retailPrice,
    this.productName = '',
    this.variantName = '',
    this.imageUrl = '',
    this.imageMediaId,
    this.coverMediaId,
  });
  final String id;
  final String productId;
  final String variantId;
  final int retailPrice;
  final String productName;
  final String variantName;
  final String imageUrl;
  final String? imageMediaId;
  final String? coverMediaId;
}

@immutable
class StorefrontOrderProgress {
  const StorefrontOrderProgress({
    required this.id,
    required this.number,
    required this.status,
  });
  final String id;
  final String number;
  final String status;
}

@immutable
class StorefrontSnapshot {
  StorefrontSnapshot({
    required this.eligible,
    required this.completedOrders,
    this.store,
    List<StoreListing> listings = const [],
    this.domainSuffix = '',
    List<StorefrontOrderProgress> orderProgress = const [],
    this.designs,
  }) : listings = List.unmodifiable(listings),
       orderProgress = List.unmodifiable(orderProgress);
  final List<StorefrontOrderProgress> orderProgress;
  final bool eligible;
  final int completedOrders;
  final MerchantStore? store;
  final List<StoreListing> listings;
  final String domainSuffix;

  /// Null means an older backend; an empty list deliberately offers no designs.
  final List<StoreTheme>? designs;
}

@immutable
class StorefrontDraft {
  const StorefrontDraft({
    this.brandName = '',
    this.slug = '',
    this.themeId = '',
    this.logoPath = '',
    this.logoUrl = '',
    this.paletteId = '',
  });
  final String brandName;
  final String slug;
  final String themeId;
  final String logoPath;
  final String logoUrl;
  final String paletteId;

  StorefrontDraft copyWith({
    String? brandName,
    String? slug,
    String? themeId,
    String? logoPath,
    String? logoUrl,
    String? paletteId,
  }) => StorefrontDraft(
    brandName: brandName ?? this.brandName,
    slug: slug ?? this.slug,
    themeId: themeId ?? this.themeId,
    logoPath: logoPath ?? this.logoPath,
    logoUrl: logoUrl ?? this.logoUrl,
    paletteId: paletteId ?? this.paletteId,
  );

  Map<String, Object?> toJson() => {
    'brand_name': brandName,
    'slug': slug,
    'theme_id': themeId,
    'logo_path': logoPath,
    'logo_url': logoUrl,
    'palette_id': paletteId,
  };

  factory StorefrontDraft.fromJson(Map<String, dynamic> json) =>
      StorefrontDraft(
        brandName: json['brand_name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        themeId: json['theme_id'] as String? ?? '',
        logoPath: json['logo_path'] as String? ?? '',
        logoUrl: json['logo_url'] as String? ?? '',
        paletteId: json['palette_id'] as String? ?? '',
      );

  factory StorefrontDraft.fromStore(MerchantStore store) => StorefrontDraft(
    brandName: store.brandName,
    slug: store.slug,
    themeId: store.themeId,
    logoPath: store.logoPath,
    logoUrl: store.logoUrl,
    paletteId: store.paletteId,
  );
}

@immutable
class StorefrontRequestItem {
  const StorefrontRequestItem({
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.unitSalePrice,
    this.productId = '',
    this.variantId = '',
    this.imageUrl = '',
  });
  final String productId;
  final String variantId;
  final String imageUrl;
  final String productName;
  final String variantName;
  final int quantity;
  final int unitSalePrice;
}

@immutable
class StorefrontRequest {
  StorefrontRequest({
    required this.id,
    required this.number,
    required this.status,
    required this.version,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.saleTotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    required List<StorefrontRequestItem> items,
    this.customerAltPhone = '',
    this.deliveryZoneId = '',
    this.landmark = '',
    this.notes = '',
    this.orderId,
    this.rejectionReason = '',
    this.expiresAt,
  }) : items = List.unmodifiable(items);
  final String id;
  final String number;
  final String status;
  final int version;
  final String customerName;
  final String customerPhone;
  final String customerAltPhone;
  final String deliveryZoneId;
  final String address;
  final String landmark;
  final String notes;
  final int saleTotal;
  final int deliveryFee;
  final int total;
  final DateTime createdAt;
  final List<StorefrontRequestItem> items;
  final String? orderId;
  final String rejectionReason;
  final DateTime? expiresAt;
  bool isExpiredAt(DateTime now) =>
      pending && expiresAt != null && !expiresAt!.isAfter(now);
  bool get expired => isExpiredAt(DateTime.now());
  bool get pending => status == 'pending';
}

@immutable
class StorefrontRequestCursor {
  const StorefrontRequestCursor({required this.createdAt, required this.id});
  final DateTime createdAt;
  final String id;
}

@immutable
class StorefrontRequestPage {
  StorefrontRequestPage({
    required List<StorefrontRequest> requests,
    this.nextCursor,
  }) : requests = List.unmodifiable(requests);
  final List<StorefrontRequest> requests;
  final StorefrontRequestCursor? nextCursor;
}
