import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/storefront_repository.dart';
import '../../data/storefront_draft_store.dart';
import '../../data/storefront_models.dart';

class StorefrontViewModel extends ChangeNotifier {
  StorefrontViewModel({
    required this.repository,
    required this.drafts,
    required this.isCurrentUser,
  });
  final StorefrontRepository repository;
  final StorefrontDraftStore drafts;
  final bool Function() isCurrentUser;
  StorefrontSnapshot? _snapshot;
  StorefrontDraft _draft = const StorefrontDraft();
  bool _loading = true;
  bool _busy = false;
  bool _disposed = false;
  bool _draftRestored = false;
  String? _errorCode;
  Future<void>? _refresh;

  StorefrontSnapshot? get snapshot => _valid ? _snapshot : null;
  StorefrontDraft get draft => _valid ? _draft : const StorefrontDraft();
  bool get loading => _loading;
  bool get busy => _busy;
  String? get errorCode => _errorCode;
  bool get _valid => !_disposed && isCurrentUser();

  Future<void> load() =>
      _refresh ??= _load().whenComplete(() => _refresh = null);

  Future<void> _load() async {
    if (!_valid || _busy) return;
    _loading = true;
    _errorCode = null;
    _notify();
    try {
      if (!_draftRestored) {
        final restored = await drafts.read();
        if (!_valid) return;
        if (restored != null) _draft = restored;
        _draftRestored = true;
      }
      final result = await repository.fetch();
      if (!_valid) return;
      _snapshot = result;
      if (result.store != null) {
        _draft = StorefrontDraft.fromStore(result.store!);
      }
    } catch (error) {
      if (_valid) _errorCode = _code(error);
    } finally {
      if (_valid) {
        _loading = false;
        _notify();
      }
    }
  }

  void updateDraft(StorefrontDraft draft) {
    if (!_valid || _busy) return;
    _draft = draft;
    unawaited(
      drafts.write(draft).catchError((Object _) {
        if (_valid) {
          _errorCode = 'draft_write_failed';
          _notify();
        }
      }),
    );
    _notify();
  }

  Future<bool> save() => _perform(() async {
    final result = await repository.save(_draft);
    if (!_valid) return;
    _snapshot = result;
    if (_snapshot?.store != null) {
      _draft = StorefrontDraft.fromStore(_snapshot!.store!);
    }
    try {
      await drafts.clear();
    } catch (_) {
      /* A committed server save remains successful. */
    }
  });

  Future<bool> activate() => _perform(() async {
    final result = await repository.activate();
    if (_valid) _snapshot = result;
  });

  Future<bool> pause() => _perform(() async {
    final result = await repository.pause();
    if (_valid) _snapshot = result;
  });

  Future<bool> saveProduct({
    required String productId,
    required List<String> variantIds,
    required int retailPrice,
    String? coverMediaId,
    Map<String, String>? variantMedia,
  }) => _perform(() async {
    bool matches(StorefrontSnapshot value) {
      final rows = value.listings
          .where((item) => item.productId == productId)
          .toList();
      return rows.length == variantIds.length &&
          rows.every(
            (item) =>
                variantIds.contains(item.variantId) &&
                item.retailPrice == retailPrice &&
                (variantMedia == null ||
                    (item.coverMediaId == coverMediaId &&
                        item.imageMediaId == variantMedia[item.variantId])),
          );
    }

    StorefrontSnapshot result;
    try {
      result = await repository.saveProduct(
        productId: productId,
        variantIds: variantIds,
        retailPrice: retailPrice,
        coverMediaId: coverMediaId,
        variantMedia: variantMedia,
      );
    } on StorefrontException catch (error) {
      if (error.code != 'request_timeout') rethrow;
      try {
        result = await repository.fetch();
      } catch (_) {
        throw error;
      }
      if (!matches(result)) rethrow;
    }
    if (!matches(result)) throw const StorefrontException('save_not_confirmed');
    if (_valid) _snapshot = result;
  });

  Future<bool> saveListing({
    required String productId,
    required String variantId,
    required int retailPrice,
  }) => _perform(() async {
    StorefrontSnapshot result;
    try {
      result = await repository.saveListing(
        productId: productId,
        variantId: variantId,
        retailPrice: retailPrice,
      );
    } on StorefrontException catch (error) {
      if (error.code != 'request_timeout') rethrow;
      // Read back once after a lost acknowledgement. Never replay the write
      // automatically: a timeout does not establish whether it committed.
      try {
        result = await repository.fetch();
      } catch (_) {
        throw error;
      }
      if (!result.listings.any(
        (item) =>
            item.productId == productId &&
            item.variantId == variantId &&
            item.retailPrice == retailPrice,
      )) {
        rethrow;
      }
    }
    if (!result.listings.any(
      (item) =>
          item.productId == productId &&
          item.variantId == variantId &&
          item.retailPrice == retailPrice,
    )) {
      throw const StorefrontException('save_not_confirmed');
    }
    if (_valid) _snapshot = result;
  });

  Future<bool> removeListing(String listingId) => _perform(() async {
    StorefrontSnapshot result;
    try {
      result = await repository.removeListing(listingId);
    } on StorefrontException catch (error) {
      if (error.code != 'request_timeout') rethrow;
      // A lost acknowledgement is not permission to replay a removal.
      try {
        result = await repository.fetch();
      } catch (_) {
        throw const StorefrontException('remove_not_confirmed');
      }
    }
    if (result.listings.any((item) => item.id == listingId)) {
      throw const StorefrontException('remove_not_confirmed');
    }
    if (_valid) _snapshot = result;
  });

  Future<bool> uploadLogo(Uint8List bytes, String mimeType) => _perform(
    () async {
      final uploaded = await repository.uploadLogo(bytes, mimeType);
      if (!_valid) return;
      _draft = _draft.copyWith(logoPath: uploaded.path, logoUrl: uploaded.url);
      await drafts.write(_draft);
    },
  );

  Future<bool> _perform(Future<void> Function() action) async {
    if (!_valid || _busy || _loading) return false;
    _busy = true;
    _errorCode = null;
    _notify();
    try {
      await action();
      return _valid;
    } catch (error) {
      if (_valid) _errorCode = _code(error);
      return false;
    } finally {
      if (_valid) {
        _busy = false;
        _notify();
      }
    }
  }

  String _code(Object error) =>
      error is StorefrontException ? error.code : 'network';
  void _notify() {
    if (_valid) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
