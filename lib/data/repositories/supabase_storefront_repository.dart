import 'dart:typed_data';
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/request_id.dart';
import '../storefront_models.dart';
import '../storefront_media.dart';
import 'storefront_repository.dart';

class SupabaseStorefrontRepository implements StorefrontRepository {
  SupabaseStorefrontRepository(
    this._client, {
    this.requestTimeout = const Duration(seconds: 20),
  });
  final SupabaseClient _client;
  final Duration requestTimeout;

  Future<dynamic> _requestCall(
    String name, [
    Map<String, dynamic>? params,
  ]) async {
    final user = _client.auth.currentUser?.id;
    if (user == null) {
      throw const StorefrontException('authentication_required');
    }
    try {
      final data = await _client
          .rpc(name, params: params)
          .timeout(requestTimeout);
      if (_client.auth.currentUser?.id != user) {
        throw const StorefrontException('authentication_required');
      }
      if (data is Map) {
        final request = name == 'approve_my_storefront_request'
            ? data['request']
            : data;
        if (request is Map && request['items'] is List) {
          await _attachRequestImages(request);
        }
      }
      if (_client.auth.currentUser?.id != user) {
        throw const StorefrontException('authentication_required');
      }
      return data;
    } on TimeoutException {
      throw const StorefrontException('request_timeout');
    } on AuthException {
      throw const StorefrontException('authentication_required');
    } on PostgrestException catch (error) {
      throw StorefrontException(error.message);
    }
  }

  Future<void> _attachRequestImages(Map request) async {
    final items = (request['items'] as List).whereType<Map>().toList();
    final ids = items
        .map((i) => i['product_id'])
        .whereType<String>()
        .where((id) => RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id))
        .toSet()
        .toList();
    if (ids.isEmpty) return;
    // Optional, bounded read through existing catalog RLS. Never changes a
    // committed decision or replaces the request's financial snapshot.
    try {
      final rows = await _client
          .from('product_media')
          .select('id,product_id,variant_id,object_path,is_cover,sort_order')
          .inFilter('product_id', ids)
          .eq('bucket_name', 'catalog-media')
          .eq('media_type', 'image')
          .order('is_cover', ascending: false)
          .order('sort_order')
          .order('id')
          .timeout(const Duration(seconds: 2));
      for (final item in items) {
        final matches = rows.where(
          (m) => m['product_id'] == item['product_id'],
        );
        final media =
            matches
                .where(
                  (m) =>
                      m['variant_id'] == item['variant_id'] &&
                      item['variant_id'] != null,
                )
                .firstOrNull ??
            matches.where((m) => m['variant_id'] == null).firstOrNull;
        final path = media?['object_path'] as String?;
        if (path == null || path.isEmpty) continue;
        item['image_url'] = _client.storage
            .from('catalog-media')
            .getPublicUrl(path)
            .replaceFirst('/object/public/', '/object/authenticated/');
      }
    } catch (_) {
      // Missing/restricted images are placeholders, not failed orders.
    }
  }

  @override
  Future<StorefrontRequestPage> fetchRequests({
    StorefrontRequestCursor? before,
  }) async {
    final data = await _requestCall('get_my_storefront_requests', {
      'p_limit': 25,
      'p_before_created_at': before?.createdAt.toUtc().toIso8601String(),
      'p_before_id': before?.id,
    });
    final cursor = data['next_cursor'];
    return StorefrontRequestPage(
      requests: [
        for (final row in data['requests'] as List)
          parseStorefrontRequest(Map<String, dynamic>.from(row as Map)),
      ],
      nextCursor: cursor is Map
          ? StorefrontRequestCursor(
              createdAt: DateTime.parse(cursor['created_at'] as String),
              id: cursor['id'] as String,
            )
          : null,
    );
  }

  @override
  Future<StorefrontRequest> fetchRequest(String id) async =>
      parseStorefrontRequest(
        Map<String, dynamic>.from(
          await _requestCall('get_my_storefront_request', {'p_request_id': id})
              as Map,
        ),
      );
  @override
  Future<StorefrontRequest> approveRequest(
    StorefrontRequest request,
    String idempotencyKey,
  ) async {
    final data = await _requestCall('approve_my_storefront_request', {
      'p_request_id': request.id,
      'p_expected_version': request.version,
      'p_idempotency_key': idempotencyKey,
    });
    return parseStorefrontRequest(
      Map<String, dynamic>.from(data['request'] as Map),
    );
  }

  @override
  Future<StorefrontRequest> rejectRequest(
    StorefrontRequest request,
    String reason,
  ) async {
    final data = await _requestCall('reject_my_storefront_request', {
      'p_request_id': request.id,
      'p_reason': reason,
      'p_expected_version': request.version,
    });
    return parseStorefrontRequest(Map<String, dynamic>.from(data as Map));
  }

  Future<StorefrontSnapshot> _call(
    String name, [
    Map<String, dynamic>? params,
  ]) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const StorefrontException('authentication_required');
    }
    try {
      final data = await _client
          .rpc(name, params: params)
          .timeout(requestTimeout);
      if (_client.auth.currentUser?.id != userId) {
        throw const StorefrontException('authentication_required');
      }
      final payload = Map<String, dynamic>.from(data as Map);
      final rows =
          (payload['storefront'] as Map?)?['items'] as List? ?? const [];
      final paths = rows
          .whereType<Map>()
          .map((r) => r['image_path'])
          .whereType<String>()
          .where((p) => p.isNotEmpty)
          .toSet()
          .toList();
      // Batch-sign only the current merchant's catalogue images. Image failure
      // never hides the store or changes the success of a committed save.
      if (paths.isNotEmpty) {
        try {
          final urls = await _client.storage
              .from('catalog-media')
              .createSignedUrlsResult(paths, 3600)
              .timeout(requestTimeout);
          final byPath = {
            for (final image in urls.whereType<SignedUrlSuccess>())
              image.path: image.signedUrl,
          };
          for (final row in rows.whereType<Map>()) {
            row['image_url'] = byPath[row['image_path']] ?? '';
          }
        } catch (_) {
          /* The visible placeholder offers a refresh. */
        }
      }
      if (_client.auth.currentUser?.id != userId) {
        throw const StorefrontException('authentication_required');
      }
      return parseStorefrontSnapshot(
        payload,
        designUrl: (path) =>
            _client.storage.from('storefront-designs').getPublicUrl(path),
        logoUrl: (path) =>
            _client.storage.from('storefront-logos').getPublicUrl(path),
      );
    } on TimeoutException {
      throw const StorefrontException('request_timeout');
    } on PostgrestException catch (error) {
      throw StorefrontException(error.message);
    } on AuthException {
      throw const StorefrontException('authentication_required');
    }
  }

  @override
  Future<StorefrontSnapshot> fetch() => _call('get_my_storefront');
  @override
  Future<StorefrontSnapshot> save(StorefrontDraft draft) => _call(
    draft.paletteId.isEmpty
        ? 'save_my_storefront'
        : 'save_my_storefront_design',
    {
      'p_slug': draft.slug,
      'p_brand_name': draft.brandName,
      'p_logo_path': draft.logoPath,
      if (draft.paletteId.isEmpty) 'p_theme_id': draft.themeId,
      if (draft.paletteId.isNotEmpty) ...{
        'p_design_id': draft.themeId,
        'p_palette_id': draft.paletteId,
      },
    },
  );
  @override
  Future<StorefrontSnapshot> activate() => _call('activate_my_storefront');
  @override
  Future<StorefrontSnapshot> pause() => _call('pause_my_storefront');
  @override
  Future<StorefrontSnapshot> saveProduct({
    required String productId,
    required List<String> variantIds,
    required int retailPrice,
    String? coverMediaId,
    Map<String, String>? variantMedia,
  }) => _call(
    variantMedia == null
        ? 'save_my_storefront_product'
        : 'save_my_storefront_product_media',
    {
      'p_product_id': productId,
      'p_variant_ids': variantIds,
      'p_sale_price': retailPrice,
      if (variantMedia != null) ...{
        'p_cover_media_id': coverMediaId,
        'p_variant_media': variantMedia,
      },
    },
  );
  @override
  Future<StorefrontSnapshot> saveListing({
    required String productId,
    required String variantId,
    required int retailPrice,
  }) async {
    return _call('upsert_my_storefront_item', {
      'p_variant_id': variantId,
      'p_sale_price': retailPrice,
      'p_is_active': true,
      'p_sort_order': 0,
    });
  }

  @override
  Future<StorefrontSnapshot> removeListing(String listingId) async {
    final userId = _client.auth.currentUser?.id;
    final snapshot = await fetch();
    if (userId == null || _client.auth.currentUser?.id != userId) {
      throw const StorefrontException('authentication_required');
    }
    final listing = snapshot.listings
        .where((item) => item.id == listingId)
        .firstOrNull;
    if (listing == null) return snapshot;
    return _call('upsert_my_storefront_item', {
      'p_variant_id': listing.variantId,
      'p_sale_price': listing.retailPrice,
      'p_is_active': false,
      'p_sort_order': 0,
    });
  }

  @override
  Future<({String path, String url})> uploadLogo(
    Uint8List bytes,
    String mimeType,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const StorefrontException('authentication_required');
    }
    if (bytes.isEmpty ||
        bytes.length > 2 * 1024 * 1024 ||
        storefrontLogoMime(bytes) != mimeType) {
      throw const StorefrontException('invalid_logo');
    }
    final extension = switch (mimeType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => throw const StorefrontException('invalid_logo'),
    };
    final path = '$userId/${newUuidV4()}.$extension';
    try {
      await _client.storage
          .from('storefront-logos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          )
          .timeout(requestTimeout);
      if (_client.auth.currentUser?.id != userId) {
        throw const StorefrontException('authentication_required');
      }
      return (
        path: path,
        url: _client.storage.from('storefront-logos').getPublicUrl(path),
      );
    } on TimeoutException {
      throw const StorefrontException('logo_upload_failed');
    } on StorageException {
      throw const StorefrontException('logo_upload_failed');
    }
  }
}

StorefrontRequest parseStorefrontRequest(Map<String, dynamic> data) =>
    StorefrontRequest(
      id: data['id'] as String,
      number: '${data['request_number'] ?? ''}',
      status: data['status'] as String,
      version: (data['version'] as num).toInt(),
      customerName: data['customer_name'] as String,
      customerPhone: data['customer_phone'] as String,
      customerAltPhone: data['customer_alt_phone'] as String? ?? '',
      deliveryZoneId: data['delivery_zone_id'] as String? ?? '',
      address: data['address_line'] as String? ?? '',
      landmark: data['landmark'] as String? ?? '',
      notes: data['delivery_notes'] as String? ?? '',
      saleTotal: (data['sale_total'] as num).toInt(),
      deliveryFee: (data['delivery_fee'] as num).toInt(),
      total: (data['total_collect_amount'] as num).toInt(),
      createdAt: DateTime.parse(data['created_at'] as String),
      expiresAt: DateTime.tryParse('${data['expires_at'] ?? ''}'),
      orderId: data['order_id'] as String?,
      rejectionReason: data['rejection_reason'] as String? ?? '',
      items: [
        for (final row in data['items'] as List? ?? const [])
          StorefrontRequestItem(
            productId: row['product_id'] as String? ?? '',
            variantId: row['variant_id'] as String? ?? '',
            imageUrl: row['image_url'] as String? ?? '',
            productName: row['product_name'] as String? ?? '',
            variantName: row['variant_name'] as String? ?? '',
            quantity: (row['quantity'] as num).toInt(),
            unitSalePrice: (row['unit_sale_price'] as num).toInt(),
          ),
      ],
    );

/// Kept pure for contract tests; only server-derived counts unlock the feature.
StorefrontSnapshot parseStorefrontSnapshot(
  Map<String, dynamic> data, {
  String Function(String)? logoUrl,
  String Function(String)? designUrl,
}) {
  final row = data['storefront'] is Map
      ? Map<String, dynamic>.from(data['storefront'] as Map)
      : null;
  final path = row?['logo_path'] as String? ?? '';
  final slug = row?['slug'] as String? ?? '';
  final store = row == null
      ? null
      : MerchantStore(
          id: row['id'] as String,
          slug: slug,
          brandName: row['brand_name'] as String? ?? '',
          themeId:
              row['design_id'] as String? ?? row['theme_id'] as String? ?? '',
          paletteId: row['palette_id'] as String? ?? '',
          logoPath: path,
          logoUrl:
              row['logo_url'] as String? ??
              (path.isEmpty ? '' : logoUrl?.call(path) ?? ''),
          publicUrl: 'https://$slug.lugta.app',
          published: row['published'] == true,
          activeUntil: DateTime.tryParse(row['active_until'] as String? ?? ''),
        );
  final items = row?['items'] as List? ?? const [];
  return StorefrontSnapshot(
    designs: data['designs'] is List
        ? [
            for (final d in data['designs'] as List)
              if (d is Map && d['id'] is String && d['name'] is String)
                StoreTheme(
                  id: d['id'] as String,
                  name: d['name'] as String,
                  thumbnailAsset:
                      'assets/storefronts/theme-${(d['renderer'] as String? ?? 'theme1').replaceFirst('theme', '')}-thumb.png',
                  previewAsset:
                      'assets/storefronts/theme-${(d['renderer'] as String? ?? 'theme1').replaceFirst('theme', '')}-full.png',
                  thumbnailUrl: (d['thumbnail_path'] as String? ?? '').isEmpty
                      ? ''
                      : designUrl?.call(d['thumbnail_path'] as String) ?? '',
                  previewUrl: (d['preview_path'] as String? ?? '').isEmpty
                      ? ''
                      : designUrl?.call(d['preview_path'] as String) ?? '',
                  palettes: [
                    for (final p in d['palettes'] as List? ?? const [])
                      if (p is Map && p['tokens'] is Map)
                        StorePalette(
                          id: p['id'] as String,
                          name: p['name'] as String,
                          accent: p['tokens']['accent'] as String,
                          background: p['tokens']['bg'] as String,
                        ),
                  ],
                ),
          ]
        : null,
    eligible: data['eligible'] == true,
    completedOrders: (data['eligible_order_count'] as num?)?.toInt() ?? 0,
    orderProgress: [
      for (final value in data['order_progress'] as List? ?? const [])
        if (value is Map)
          StorefrontOrderProgress(
            id: value['id'] as String,
            number: value['number'] as String,
            status: value['status'] as String,
          ),
    ],
    domainSuffix: 'lugta.app',
    store: store,
    listings: [
      for (final value in items)
        if (value is Map && value['is_active'] != false)
          StoreListing(
            id: value['id'] as String,
            productId: value['product_id'] as String? ?? '',
            variantId: value['variant_id'] as String,
            retailPrice: (value['sale_price'] as num).toInt(),
            productName: value['product_name'] as String? ?? '',
            variantName: value['variant_name'] as String? ?? '',
            imageUrl: value['image_url'] as String? ?? '',
            imageMediaId: value['image_media_id'] as String?,
            coverMediaId: value['cover_media_id'] as String?,
          ),
    ],
  );
}
