import 'dart:typed_data';

import '../storefront_models.dart';

abstract interface class StorefrontRepository {
  Future<StorefrontSnapshot> fetch();
  Future<StorefrontSnapshot> save(StorefrontDraft draft);
  Future<StorefrontSnapshot> activate();
  Future<StorefrontSnapshot> pause();
  Future<StorefrontSnapshot> saveListing({
    required String productId,
    required String variantId,
    required int retailPrice,
  });
  Future<StorefrontSnapshot> removeListing(String listingId);
  Future<StorefrontSnapshot> saveProduct({
    required String productId,
    required List<String> variantIds,
    required int retailPrice,
    String? coverMediaId,
    Map<String, String>? variantMedia,
  });
  Future<({String path, String url})> uploadLogo(
    Uint8List bytes,
    String mimeType,
  );
  Future<StorefrontRequestPage> fetchRequests({
    StorefrontRequestCursor? before,
  });
  Future<StorefrontRequest> fetchRequest(String id);
  Future<StorefrontRequest> approveRequest(
    StorefrontRequest request,
    String idempotencyKey,
  );
  Future<StorefrontRequest> rejectRequest(
    StorefrontRequest request,
    String reason,
  );
}

/// Default for clients/tests built before the storefront backend is installed.
/// Never fabricates eligibility or a successfully-created public store.
class UnavailableStorefrontRepository implements StorefrontRepository {
  const UnavailableStorefrontRepository();
  Never _unavailable() => throw const StorefrontException('unavailable');
  @override
  Future<StorefrontSnapshot> saveProduct({
    required String productId,
    required List<String> variantIds,
    required int retailPrice,
    String? coverMediaId,
    Map<String, String>? variantMedia,
  }) async => _unavailable();
  @override
  Future<StorefrontSnapshot> fetch() async => _unavailable();
  @override
  Future<StorefrontSnapshot> save(StorefrontDraft draft) async =>
      _unavailable();
  @override
  Future<StorefrontSnapshot> activate() async => _unavailable();
  @override
  Future<StorefrontSnapshot> pause() async => _unavailable();
  @override
  Future<StorefrontSnapshot> saveListing({
    required String productId,
    required String variantId,
    required int retailPrice,
  }) async => _unavailable();
  @override
  Future<StorefrontSnapshot> removeListing(String listingId) async =>
      _unavailable();
  @override
  Future<({String path, String url})> uploadLogo(
    Uint8List bytes,
    String mimeType,
  ) async => _unavailable();
  @override
  Future<StorefrontRequestPage> fetchRequests({
    StorefrontRequestCursor? before,
  }) async => _unavailable();
  @override
  Future<StorefrontRequest> fetchRequest(String id) async => _unavailable();
  @override
  Future<StorefrontRequest> approveRequest(
    StorefrontRequest request,
    String idempotencyKey,
  ) async => _unavailable();
  @override
  Future<StorefrontRequest> rejectRequest(
    StorefrontRequest request,
    String reason,
  ) async => _unavailable();
}

class StorefrontException implements Exception {
  const StorefrontException(this.code);
  final String code;
}
