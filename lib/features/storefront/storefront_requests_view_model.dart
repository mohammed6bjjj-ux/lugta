import 'package:flutter/foundation.dart';

import '../../core/request_id.dart';
import '../../data/repositories/storefront_repository.dart';
import '../../data/storefront_models.dart';

class StorefrontRequestsViewModel extends ChangeNotifier {
  StorefrontRequestsViewModel({
    required this.repository,
    required this.isCurrentUser,
  });
  final StorefrontRepository repository;
  final bool Function() isCurrentUser;
  List<StorefrontRequest> _requests = const [];
  final Map<String, String> _approvalKeys = {};
  bool _disposed = false;
  bool _loading = false;
  bool _busy = false;
  StorefrontRequestCursor? _nextCursor;
  bool get hasMore => _nextCursor != null;
  String? _errorCode;
  bool get loading => _loading;
  bool get busy => _busy;
  String? get errorCode => _errorCode;
  List<StorefrontRequest> get requests => _valid ? _requests : const [];
  bool get _valid => !_disposed && isCurrentUser();

  Future<void> load() => _load();
  Future<void> loadMore() =>
      _nextCursor == null ? Future.value() : _load(more: true);
  Future<void> loadRequest(String id) => _load(requestId: id);

  Future<void> _load({bool more = false, String? requestId}) async {
    if (!_valid || _loading || _busy) return;
    _loading = true;
    _errorCode = null;
    notifyListeners();
    try {
      if (requestId != null) {
        final result = await repository.fetchRequest(requestId);
        if (_valid) _requests = List.unmodifiable([result]);
      } else {
        final page = await repository.fetchRequests(
          before: more ? _nextCursor : null,
        );
        if (_valid) {
          _requests = List.unmodifiable(
            more
                ? [
                    ..._requests,
                    ...page.requests.where(
                      (item) =>
                          !_requests.any((existing) => existing.id == item.id),
                    ),
                  ]
                : page.requests,
          );
          _nextCursor = page.nextCursor;
        }
      }
    } catch (error) {
      if (_valid) {
        _errorCode = error is StorefrontException ? error.code : 'network';
      }
    } finally {
      if (_valid) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<StorefrontRequest?> approve(StorefrontRequest request) => _change(
    request,
    () => repository.approveRequest(
      request,
      _approvalKeys.putIfAbsent(request.id, newUuidV4),
    ),
    expectedStatus: 'approved',
  );
  Future<StorefrontRequest?> reject(StorefrontRequest request, String reason) =>
      _change(
        request,
        () => repository.rejectRequest(request, reason),
        expectedStatus: 'rejected',
        reason: reason.trim(),
      );

  Future<StorefrontRequest?> _change(
    StorefrontRequest request,
    Future<StorefrontRequest> Function() action, {
    required String expectedStatus,
    String? reason,
  }) async {
    if (!_valid || _busy || _loading) return null;
    if (expectedStatus == 'approved' && request.expired) {
      _errorCode = 'storefront_request_expired';
      notifyListeners();
      return null;
    }
    _busy = true;
    _errorCode = null;
    notifyListeners();
    try {
      StorefrontRequest changed;
      try {
        changed = await action();
      } on StorefrontException catch (error) {
        if (error.code != 'request_timeout') rethrow;
        // A timeout may follow a committed order. Read once, never replay.
        try {
          changed = await repository.fetchRequest(request.id);
        } catch (_) {
          throw const StorefrontException('request_result_unknown');
        }
        if (changed.status != expectedStatus ||
            (reason != null && changed.rejectionReason != reason)) {
          if (_valid) {
            _requests = List.unmodifiable([
              for (final item in _requests)
                if (item.id == changed.id) changed else item,
            ]);
          }
          throw const StorefrontException('request_result_unknown');
        }
      }
      if (!_valid) return null;
      _requests = List.unmodifiable([
        for (final item in _requests)
          if (item.id == changed.id) changed else item,
      ]);
      return changed;
    } catch (error) {
      if (_valid) {
        _errorCode = error is StorefrontException ? error.code : 'network';
      }
      return null;
    } finally {
      if (_valid) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
