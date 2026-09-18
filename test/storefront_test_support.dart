import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_app/data/repositories/storefront_repository.dart';
import 'package:flutter_app/data/storefront_draft_store.dart';
import 'package:flutter_app/data/storefront_models.dart';

final testStore = MerchantStore(
  id: 's1',
  slug: 'test-store',
  brandName: 'متجر الاختبار',
  themeId: 'theme1',
  logoPath: 'user/logo.png',
  publicUrl: 'https://test-store.lugta.app',
  published: true,
  activeUntil: DateTime.now().add(const Duration(hours: 24)),
);
final testRequest = StorefrontRequest(
  id: '00000000-0000-4000-8000-000000000001',
  number: 'WEB-1',
  status: 'pending',
  version: 1,
  customerName: 'زبون تجريبي',
  customerPhone: '07700000000',
  address: 'عنوان تجريبي',
  saleTotal: 18000,
  deliveryFee: 5000,
  total: 23000,
  createdAt: DateTime.utc(2026, 9, 11),
  items: const [
    StorefrontRequestItem(
      productName: 'قميص تجريبي',
      variantName: 'أسود / XL',
      quantity: 1,
      unitSalePrice: 18000,
    ),
  ],
);

class MemoryStorefrontDrafts implements StorefrontDraftStore {
  StorefrontDraft? value;
  bool pending = false;
  bool failClear = false;
  @override
  Future<StorefrontDraft?> read() async => value;
  @override
  Future<void> write(StorefrontDraft draft) async {
    value = draft;
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('disk');
    value = null;
  }

  @override
  Future<bool> isPickerPending() async => pending;
  @override
  Future<void> setPickerPending(bool value) async {
    pending = value;
  }
}

class TestStorefrontRepository extends UnavailableStorefrontRepository {
  TestStorefrontRepository({StorefrontSnapshot? snapshot})
    : current =
          snapshot ?? StorefrontSnapshot(eligible: true, completedOrders: 10);
  StorefrontSnapshot current;
  StorefrontRequest request = testRequest;
  int fetchCalls = 0;
  int saveCalls = 0;
  StorefrontDraft? lastSavedDraft;
  int approveCalls = 0;
  int detailCalls = 0;
  int uploadCalls = 0;
  int listingCalls = 0;
  int removeCalls = 0;
  int activateCalls = 0;
  bool listingTimeoutAfterCommit = false;
  bool removalTimeoutAfterCommit = false;
  bool removalUnchanged = false;
  bool failRemoval = false;
  bool failFetch = false;
  bool failApprove = false;
  bool requestTimeoutAfterCommit = false;
  bool requestTimeoutBeforeCommit = false;
  int rejectCalls = 0;
  String? lastApprovalKey;
  int? savedPrice;
  String? savedVariant;
  Completer<void>? mutationGate;
  Completer<void>? fetchGate;
  List<StorefrontRequestCursor?> cursors = [];

  @override
  Future<StorefrontSnapshot> fetch() async {
    fetchCalls++;
    if (fetchGate != null) await fetchGate!.future;
    if (failFetch) throw const StorefrontException('network');
    return current;
  }

  @override
  Future<StorefrontSnapshot> save(StorefrontDraft draft) async {
    saveCalls++;
    lastSavedDraft = draft;
    if (mutationGate != null) await mutationGate!.future;
    current = StorefrontSnapshot(
      eligible: true,
      completedOrders: 10,
      designs: current.designs,
      store: MerchantStore(
        id: 's1',
        slug: draft.slug,
        brandName: draft.brandName,
        themeId: draft.themeId,
        paletteId: draft.paletteId,
        logoPath: draft.logoPath,
        logoUrl: draft.logoUrl,
      ),
    );
    return current;
  }

  @override
  Future<StorefrontSnapshot> activate() async {
    activateCalls++;
    if (mutationGate != null) await mutationGate!.future;
    current = StorefrontSnapshot(
      eligible: current.eligible,
      completedOrders: current.completedOrders,
      store: testStore,
      listings: current.listings,
    );
    return current;
  }

  @override
  Future<StorefrontSnapshot> pause() async => current;
  @override
  Future<StorefrontSnapshot> saveListing({
    required String productId,
    required String variantId,
    required int retailPrice,
  }) async {
    savedVariant = variantId;
    savedPrice = retailPrice;
    listingCalls++;
    if (mutationGate != null) await mutationGate!.future;
    current = StorefrontSnapshot(
      eligible: current.eligible,
      completedOrders: current.completedOrders,
      store: current.store,
      listings: [
        ...current.listings.where((item) => item.variantId != variantId),
        StoreListing(
          id: 'listing-$variantId',
          productId: productId,
          variantId: variantId,
          retailPrice: retailPrice,
        ),
      ],
    );
    if (listingTimeoutAfterCommit) {
      throw const StorefrontException('request_timeout');
    }
    return current;
  }

  @override
  Future<StorefrontSnapshot> saveProduct({
    required String productId,
    required List<String> variantIds,
    required int retailPrice,
    String? coverMediaId,
    Map<String, String>? variantMedia,
  }) async {
    if (variantIds.isEmpty) {
      removeCalls++;
    } else {
      listingCalls++;
    }
    savedVariant = variantIds.isEmpty ? null : variantIds.last;
    savedPrice = retailPrice;
    if (mutationGate != null) await mutationGate!.future;
    if (variantIds.isEmpty && failRemoval) {
      throw const StorefrontException('network');
    }
    if (!(variantIds.isEmpty && removalUnchanged)) {
      current = StorefrontSnapshot(
        eligible: current.eligible,
        completedOrders: current.completedOrders,
        store: current.store,
        listings: [
          ...current.listings.where((item) => item.productId != productId),
          for (final variant in variantIds)
            StoreListing(
              id: 'listing-$variant',
              productId: productId,
              variantId: variant,
              retailPrice: retailPrice,
              coverMediaId: coverMediaId,
              imageMediaId: variantMedia?[variant],
            ),
        ],
      );
    }
    if (variantIds.isEmpty
        ? removalTimeoutAfterCommit
        : listingTimeoutAfterCommit) {
      throw const StorefrontException('request_timeout');
    }
    return current;
  }

  @override
  Future<StorefrontSnapshot> removeListing(String listingId) async {
    removeCalls++;
    if (mutationGate != null) await mutationGate!.future;
    if (failRemoval) throw const StorefrontException('network');
    if (!removalUnchanged) {
      current = StorefrontSnapshot(
        eligible: current.eligible,
        completedOrders: current.completedOrders,
        store: current.store,
        listings: current.listings
            .where((item) => item.id != listingId)
            .toList(),
      );
    }
    if (removalTimeoutAfterCommit) {
      throw const StorefrontException('request_timeout');
    }
    return current;
  }

  @override
  Future<({String path, String url})> uploadLogo(
    Uint8List bytes,
    String mimeType,
  ) async {
    uploadCalls++;
    return (path: 'user/logo.png', url: '');
  }

  @override
  Future<StorefrontRequestPage> fetchRequests({
    StorefrontRequestCursor? before,
  }) async {
    cursors.add(before);
    return StorefrontRequestPage(requests: [request]);
  }

  @override
  Future<StorefrontRequest> fetchRequest(String id) async {
    detailCalls++;
    return request;
  }

  @override
  Future<StorefrontRequest> approveRequest(
    StorefrontRequest request,
    String idempotencyKey,
  ) async {
    approveCalls++;
    lastApprovalKey = idempotencyKey;
    if (mutationGate != null) await mutationGate!.future;
    if (failApprove) throw const StorefrontException('network');
    if (requestTimeoutBeforeCommit) {
      throw const StorefrontException('request_timeout');
    }
    final result = _changed('approved');
    if (requestTimeoutAfterCommit) {
      throw const StorefrontException('request_timeout');
    }
    return result;
  }

  @override
  Future<StorefrontRequest> rejectRequest(
    StorefrontRequest request,
    String reason,
  ) async {
    rejectCalls++;
    if (mutationGate != null) await mutationGate!.future;
    final result = _changed('rejected', reason: reason);
    if (requestTimeoutAfterCommit) {
      throw const StorefrontException('request_timeout');
    }
    return result;
  }

  StorefrontRequest _changed(String status, {String reason = ''}) =>
      request = StorefrontRequest(
        id: request.id,
        number: request.number,
        status: status,
        version: request.version + 1,
        customerName: request.customerName,
        customerPhone: request.customerPhone,
        address: request.address,
        saleTotal: request.saleTotal,
        deliveryFee: request.deliveryFee,
        total: request.total,
        createdAt: request.createdAt,
        items: request.items,
        rejectionReason: reason,
      );
}
