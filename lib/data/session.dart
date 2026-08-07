import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network_image_cache.dart';
import '../core/request_id.dart';
import 'app_settings.dart';
import 'async_request_deduplicator.dart';
import 'catalog_snapshot_cache.dart';
import 'mock_data.dart';
import 'models.dart';
import 'notification_deep_link.dart';
import 'repositories/demo_repositories.dart';
import 'repositories/repositories.dart';
import 'services/device_token_registrar.dart';

enum SessionDestination {
  onboarding,
  shell,
  pendingApproval,
  rejected,
  blocked,
  deleted,
}

/// UI-facing application store.
///
/// Screens keep listening to one stable [ChangeNotifier], while all persistence
/// and network operations are delegated to repositories. Demo repositories are
/// the default only for tests/design previews; production bootstrap replaces
/// them with Supabase repositories before the first screen is shown.
class AppSession extends ChangeNotifier {
  AppSession._() : _repositories = createDemoRepositories();

  static final AppSession instance = AppSession._();
  static const String _cartStoragePrefix = 'lugta.cart.v1.';

  AppRepositories _repositories;
  DeviceTokenRegistrar _deviceTokens = const NoopDeviceTokenRegistrar();
  StreamSubscription<String?>? _authStateSubscription;
  StreamSubscription<List<AppNotification>>? _notificationsSubscription;
  StreamSubscription<void>? _catalogSubscription;
  StreamSubscription<void>? _walletSubscription;
  StreamSubscription<void>? _promotionGrantsSubscription;
  StreamSubscription<void>? _foregroundPushSubscription;
  Timer? _catalogRefreshTimer;
  Timer? _walletRefreshTimer;
  Timer? _promotionGrantsRefreshTimer;
  bool _catalogRealtimeDirty = false;
  bool _catalogRealtimeWorkerRunning = false;
  bool _walletRealtimeDirty = false;
  bool _walletRealtimeWorkerRunning = false;
  bool _promotionGrantsRealtimeDirty = false;
  bool _promotionGrantsRealtimeWorkerRunning = false;
  DateTime? _lastActiveTouch;
  final AsyncRequestDeduplicator _publicRefresh = AsyncRequestDeduplicator();
  final Random _realtimeJitter = Random();
  AsyncRequestDeduplicator _authenticatedRefreshWithoutProfile =
      AsyncRequestDeduplicator();
  AsyncRequestDeduplicator _authenticatedRefreshWithProfile =
      AsyncRequestDeduplicator();
  AsyncRequestDeduplicator _allDataRefresh = AsyncRequestDeduplicator();
  AsyncRequestDeduplicator _catalogRefresh = AsyncRequestDeduplicator();
  AsyncRequestDeduplicator _ordersRefresh = AsyncRequestDeduplicator();
  AsyncRequestDeduplicator _walletRefresh = AsyncRequestDeduplicator();
  AsyncRequestDeduplicator _notificationsRefresh = AsyncRequestDeduplicator();
  AsyncRequestDeduplicator _promotionGrantsRefresh = AsyncRequestDeduplicator();
  AsyncRequestDeduplicator _referralSummaryRefresh = AsyncRequestDeduplicator();
  AsyncRequestDeduplicator _resumeReconciliation = AsyncRequestDeduplicator();
  final CatalogSnapshotCache _catalogSnapshotCache = CatalogSnapshotCache();
  Future<Seller>? _profileRefresh;
  final Map<String, Future<Order>> _orderRefreshes = {};
  final Map<String, Future<Product>> _productRefreshes = {};
  int _activeRefreshes = 0;
  int _authGeneration = 0;
  String? _observedUserId;
  DateTime? _lastResumeReconciliation;
  DateTime? _lastCatalogRefresh;

  Seller seller = MockData.seller;
  AccountDeletionRequest? accountDeletionRequest;
  List<Category> categories = List.of(MockData.categories);
  List<Product> products = List.of(MockData.products);
  List<PackagingBox> packagingBoxes = const <PackagingBox>[];
  List<Governorate> governorates = List.of(MockData.governorates);
  List<PromoBanner> banners = List.of(MockData.banners);
  List<FaqItem> faq = List.of(MockData.faq);
  List<Order> orders = List.of(MockData.orders);
  List<WalletTransaction> transactions = List.of(MockData.transactions);
  List<Withdrawal> withdrawals = List.of(MockData.withdrawals);
  List<PayoutAccount> payoutAccounts = [];
  List<AccountStatementLine> statementLines = [];
  List<WithdrawalSourceLine> withdrawalSources = [];
  List<AppNotification> notifications = List.of(MockData.notifications);
  List<PromotionGrant> promotionGrants = List.of(MockData.promotionGrants);
  ReferralSummary? referralSummary = MockData.referralSummary;
  bool promotionGrantsLoading = false;
  bool promotionGrantsLoaded = true;
  String? promotionGrantsError;
  bool referralSummaryLoading = false;
  bool referralSummaryLoaded = true;
  String? referralSummaryError;
  final Set<String> _popupSeenNotificationIds = {};

  Set<String> favoriteIds = {'p-smart-pro', 'p-sun-lady', 'p-classic-leather'};
  Set<String> stockAlertIds = {};
  List<CartItem> cartItems = [];
  String _cartClientRequestId = newUuidV4();
  String? _cartRestoredUserId;
  Future<void> _cartWriteQueue = Future<void>.value();

  String policiesText = MockData.policiesText;
  String supportPhone = MockData.supportPhone;
  String supportWhatsapp = MockData.supportWhatsapp;
  String termsVersion = 'demo-v1';

  int _availableBalance = 92000;
  int _pendingBalance = 0;
  int _totalEarned = 0;
  int _minWithdrawalAmount = MockData.minWithdrawalAmount;
  Map<String, int> _withdrawalFees = const <String, int>{
    'zain_cash': 0,
    'superqi': 0,
  };

  bool isBootstrapping = false;
  String? lastError;
  bool _isConfigured = false;

  AuthRepository get auth => _repositories.auth;
  bool get isConfigured => _isConfigured;
  bool get isDemo => _repositories.isDemo;
  bool get isAuthenticated => auth.hasSession;
  bool get isRefreshing => _activeRefreshes > 0;

  int get availableBalance => _availableBalance;
  int get pendingBalance => _repositories.isDemo
      ? orders
            .where((order) => order.status.holdsPendingProfit)
            .fold(0, (sum, order) => sum + order.profit)
      : _pendingBalance;
  int get totalEarned => _repositories.isDemo
      ? orders
            .where((order) => order.status == OrderStatus.completed)
            .fold(0, (sum, order) => sum + order.profit)
      : _totalEarned;
  int get minWithdrawalAmount => _minWithdrawalAmount;
  int withdrawalFeeFor(String provider) => _withdrawalFees[provider] ?? 0;
  bool get canWithdraw => _availableBalance >= _minWithdrawalAmount;
  int get unreadNotificationsCount => notifications
      .where((notification) => notification.showInbox && !notification.isRead)
      .length;
  int get cartLineCount => cartItems.length;
  int get cartQuantity => cartItems.fold(0, (sum, item) => sum + item.quantity);
  int get cartWholesaleTotal =>
      cartItems.fold(0, (sum, item) => sum + item.wholesaleTotal);
  int get cartSaleTotal =>
      cartItems.fold(0, (sum, item) => sum + item.saleTotal);
  int get cartPackagingTotal =>
      cartItems.fold(0, (sum, item) => sum + item.packagingTotal);
  int get cartProfitTotal =>
      cartItems.fold(0, (sum, item) => sum + item.profitTotal);
  String get cartClientRequestId => _cartClientRequestId;
  AppNotification? get nextPopupNotification {
    final candidates =
        notifications
            .where(
              (item) =>
                  item.hasPendingPopup &&
                  !_popupSeenNotificationIds.contains(item.id),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final priority = b.popupPriority.compareTo(a.popupPriority);
            return priority != 0 ? priority : b.at.compareTo(a.at);
          });
    return candidates.firstOrNull;
  }

  AppNotification? notificationById(String id) =>
      notifications.where((item) => item.id == id).firstOrNull;

  Future<void> configure(
    AppRepositories repositories, {
    DeviceTokenRegistrar deviceTokens = const NoopDeviceTokenRegistrar(),
    bool loadInitialData = true,
  }) async {
    // Invalidate work started by a previously configured backend before any
    // asynchronous listener cleanup gives it a chance to update shared state.
    _invalidateAuthenticatedRequests();
    await _authStateSubscription?.cancel();
    _authStateSubscription = null;
    _repositories = repositories;
    _deviceTokens = deviceTokens;
    _isConfigured = true;
    await _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    await _stopCatalogListener();
    await _stopWalletListener();
    await _stopPromotionGrantsListener();
    await _foregroundPushSubscription?.cancel();
    _foregroundPushSubscription = _deviceTokens.foregroundMessages.listen(
      _handleForegroundPush,
    );
    _observedUserId = _currentAuthUserId();
    _authStateSubscription = auth.userIdChanges.listen(
      _handleAuthUserIdChange,
      onError: (_) {
        // Direct identity checks before every authenticated request remain the
        // fallback if the Auth event stream is temporarily unavailable.
      },
    );
    _lastActiveTouch = null;
    _lastResumeReconciliation = null;
    _lastCatalogRefresh = null;
    lastError = null;
    _resetCartMemory();

    if (!repositories.isDemo) {
      seller = _emptySeller();
      accountDeletionRequest = null;
      categories = [];
      products = [];
      packagingBoxes = [];
      governorates = [];
      banners = [];
      faq = [];
      orders = [];
      transactions = [];
      withdrawals = [];
      payoutAccounts = [];
      statementLines = [];
      withdrawalSources = [];
      notifications = [];
      promotionGrants = [];
      referralSummary = null;
      promotionGrantsLoaded = false;
      referralSummaryLoaded = false;
      promotionGrants = [];
      referralSummary = null;
      promotionGrantsLoading = false;
      promotionGrantsLoaded = false;
      promotionGrantsError = null;
      referralSummaryLoading = false;
      referralSummaryLoaded = false;
      referralSummaryError = null;
      _popupSeenNotificationIds.clear();
      favoriteIds = {};
      stockAlertIds = {};
      cartItems = [];
      policiesText = '';
      supportPhone = '';
      supportWhatsapp = '';
      termsVersion = '';
      _availableBalance = 0;
      _pendingBalance = 0;
      _totalEarned = 0;
      _withdrawalFees = const <String, int>{};
    }

    isBootstrapping = loadInitialData;
    notifyListeners();
    if (!loadInitialData) return;
    try {
      if (auth.hasSession) {
        await auth.completePendingRegistration();
        await Future.wait<void>([
          refreshPublicData(),
          refreshAuthenticatedData(),
        ]);
      } else {
        await refreshPublicData();
      }
    } catch (error) {
      lastError = _messageFor(error);
    } finally {
      isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> refreshPublicData() =>
      _publicRefresh.run(() => _runRefresh(_loadPublicData));

  Future<void> _loadPublicData() async {
    // Publish each independent public section as soon as it arrives. A
    // delivery-zone outage must not keep home banners hidden, and a content
    // outage must not block checkout governorates that loaded successfully.
    await Future.wait<void>([
      _repositories.catalog.fetchDeliveryZones().then((value) {
        governorates = value;
        notifyListeners();
      }),
      _repositories.catalog.fetchPublicContent().then((content) {
        banners = content.banners;
        faq = content.faq;
        policiesText = content.policiesText;
        supportPhone = content.supportPhone;
        supportWhatsapp = content.supportWhatsapp;
        termsVersion = content.termsVersion;
        notifyListeners();
      }),
    ]);
  }

  Future<void> refreshAuthenticatedData({bool refreshProfile = true}) {
    final scope = _captureAuthenticatedScope();
    if (scope == null) return Future<void>.value();
    final weakRefresh = _authenticatedRefreshWithoutProfile;
    final strongRefresh = _authenticatedRefreshWithProfile;

    if (!refreshProfile) {
      // A profile-inclusive refresh is a strict superset. Joining it avoids a
      // duplicate full snapshot without weakening the caller's request.
      final strongerRequest = strongRefresh.inFlight;
      if (strongerRequest != null) return strongerRequest;
      return weakRefresh.run(
        () => _runRefresh(
          () => _loadAuthenticatedData(scope, refreshProfile: false),
          authScope: scope,
        ),
      );
    }

    return strongRefresh.run(() async {
      // Never let a profile refresh silently join an already-running weaker
      // refresh. Finish the weaker snapshot, then verify profile/status.
      final weakerRequest = weakRefresh.inFlight;
      if (weakerRequest != null) {
        try {
          await weakerRequest;
        } catch (_) {
          // The explicitly requested stronger refresh is still allowed to
          // recover from a failed weaker request.
        }
        if (!_isCurrent(scope)) return;
      }
      await _runRefresh(
        () => _loadAuthenticatedData(scope, refreshProfile: true),
        authScope: scope,
      );
    });
  }

  /// Reconciles security-sensitive and frequently changing data after resume.
  ///
  /// A short cooldown avoids an API burst when Android emits several lifecycle
  /// transitions in quick succession. Catalog reconciliation uses its own TTL
  /// because Realtime events can be missed while the process is suspended.
  Future<void> reconcileAfterResume({
    Duration minimumInterval = const Duration(seconds: 45),
  }) {
    final scope = _captureAuthenticatedScope();
    if (scope == null) return Future<void>.value();
    final refresh = _resumeReconciliation;
    final current = refresh.inFlight;
    if (current != null) return current;

    final now = DateTime.now();
    final previous = _lastResumeReconciliation;
    if (previous != null) {
      final age = now.difference(previous);
      if (!age.isNegative && age < minimumInterval) {
        return Future<void>.value();
      }
    }

    return refresh.run(() async {
      _lastResumeReconciliation = DateTime.now();
      await _runRefresh(() => _loadResumeData(scope), authScope: scope);
    });
  }

  Future<void> _loadResumeData(_AuthenticatedRequestScope scope) async {
    if (!_isCurrent(scope)) return;
    final profile = await scope.repositories.profile.fetchCurrentProfile();
    if (!_isCurrent(scope)) return;
    _setSeller(profile);
    // Publish status immediately so the route gate can remove protected UI
    // before any secondary reconciliation request completes.
    notifyListeners();

    if (seller.status != AccountStatus.approved) {
      await _loadAuthenticatedData(scope, refreshProfile: false);
      return;
    }

    _registerDeviceBestEffort();
    _touchLastActiveBestEffort();
    await Future.wait<void>([
      _loadAccountDeletionData(scope),
      _ordersRefresh.run(() => _loadApprovedOrders(scope)),
      _notificationsRefresh.run(() => _loadApprovedNotifications(scope)),
      _refreshPromotionEngagementForScopeBestEffort(
        scope,
        includeReferralSummary: referralSummaryLoaded,
      ),
      if (_catalogNeedsResumeRefresh())
        _refreshCatalogAfterResumeBestEffort(scope),
    ]);
  }

  bool _catalogNeedsResumeRefresh() {
    final last = _lastCatalogRefresh;
    if (last == null) return true;
    final age = DateTime.now().difference(last);
    return age.isNegative || age >= const Duration(minutes: 2);
  }

  Future<void> _refreshCatalogAfterResumeBestEffort(
    _AuthenticatedRequestScope scope,
  ) async {
    try {
      await _catalogRefresh.run(() => _loadCatalogData(scope));
    } catch (_) {
      // Keep the visible disk/live snapshot. Pull-to-refresh or the next
      // Realtime/resume reconciliation can retry without blanking the screen.
    }
  }

  /// Refreshes every backend-backed value currently visible to the phone app.
  ///
  /// Public and authenticated requests run together, while each request group
  /// is deduplicated so repeated pull gestures cannot fan out network calls.
  Future<void> refreshAllData() {
    _synchronizeAuthIdentity();
    final refresh = _allDataRefresh;
    return refresh.run(() async {
      await Future.wait<void>([
        refreshPublicData(),
        if (auth.hasSession) refreshAuthenticatedData(),
      ]);
    });
  }

  /// Refreshes only the seller-facing catalog snapshot.
  ///
  /// Catalog screens use this instead of pulling orders, wallet and
  /// notifications on every gesture. The shared deduplicator also lets a
  /// Realtime invalidation and a manual refresh join the same request.
  Future<void> refreshCatalog() {
    final scope = _captureAuthenticatedScope();
    if (scope == null || seller.status != AccountStatus.approved) {
      return Future<void>.value();
    }
    return _catalogRefresh.run(
      () => _runRefresh(() => _loadCatalogData(scope), authScope: scope),
    );
  }

  /// Refreshes only the order list shown by the orders tab.
  Future<void> refreshOrders() {
    final scope = _captureAuthenticatedScope();
    if (scope == null || seller.status != AccountStatus.approved) {
      return Future<void>.value();
    }
    return _ordersRefresh.run(
      () => _runRefresh(() => _loadApprovedOrders(scope), authScope: scope),
    );
  }

  /// Refreshes only the durable notification inbox.
  Future<void> refreshNotifications() {
    final scope = _captureAuthenticatedScope();
    if (scope == null || seller.status != AccountStatus.approved) {
      return Future<void>.value();
    }
    return _notificationsRefresh.run(
      () => _runRefresh(
        () => _loadApprovedNotifications(scope),
        authScope: scope,
      ),
    );
  }

  Future<void> refreshPromotionGrants() {
    final scope = _captureAuthenticatedScope();
    if (scope == null || seller.status != AccountStatus.approved) {
      return Future<void>.value();
    }
    return _refreshPromotionGrantsForScope(scope);
  }

  Future<void> _refreshPromotionGrantsForScope(
    _AuthenticatedRequestScope scope,
  ) {
    _listenForPromotionGrantChanges(scope);
    return _promotionGrantsRefresh.run(() async {
      promotionGrantsLoading = true;
      promotionGrantsError = null;
      notifyListeners();
      try {
        final items = await scope.repositories.promotions
            .fetchPromotionGrants();
        if (!_isCurrent(scope)) return;
        promotionGrants = items;
        promotionGrantsLoaded = true;
      } catch (error) {
        if (!_isCurrent(scope)) rethrow;
        promotionGrantsError = _messageFor(error);
        rethrow;
      } finally {
        if (_isCurrent(scope)) {
          promotionGrantsLoading = false;
          notifyListeners();
        }
      }
    });
  }

  Future<void> refreshReferralSummary() {
    final scope = _captureAuthenticatedScope();
    if (scope == null || seller.status != AccountStatus.approved) {
      return Future<void>.value();
    }
    return _refreshReferralSummaryForScope(scope);
  }

  Future<void> _refreshReferralSummaryForScope(
    _AuthenticatedRequestScope scope,
  ) {
    return _referralSummaryRefresh.run(() async {
      referralSummaryLoading = true;
      referralSummaryError = null;
      notifyListeners();
      try {
        final summary = await scope.repositories.promotions
            .fetchReferralSummary();
        if (!_isCurrent(scope)) return;
        referralSummary = summary;
        referralSummaryLoaded = true;
      } catch (error) {
        if (!_isCurrent(scope)) rethrow;
        referralSummaryError = _messageFor(error);
        rethrow;
      } finally {
        if (_isCurrent(scope)) {
          referralSummaryLoading = false;
          notifyListeners();
        }
      }
    });
  }

  Future<void> refreshPromotionEngagement({
    bool includeReferralSummary = false,
  }) {
    final scope = _captureAuthenticatedScope();
    if (scope == null || seller.status != AccountStatus.approved) {
      return Future<void>.value();
    }
    return Future.wait<void>([
      _refreshPromotionGrantsForScope(scope),
      if (includeReferralSummary) _refreshReferralSummaryForScope(scope),
    ]);
  }

  Future<void> _loadAuthenticatedData(
    _AuthenticatedRequestScope scope, {
    bool refreshProfile = true,
  }) async {
    if (!_isCurrent(scope)) return;
    if (refreshProfile || seller.id.isEmpty) {
      final profile = await scope.repositories.profile.fetchCurrentProfile();
      if (!_isCurrent(scope)) return;
      _setSeller(profile);
    }
    if (seller.status == AccountStatus.deleted) {
      accountDeletionRequest = null;
      products = [];
      packagingBoxes = [];
      categories = [];
      orders = [];
      transactions = [];
      withdrawals = [];
      payoutAccounts = [];
      statementLines = [];
      withdrawalSources = [];
      promotionGrants = [];
      referralSummary = null;
      promotionGrantsLoaded = false;
      referralSummaryLoaded = false;
      notifications = [];
      favoriteIds = {};
      stockAlertIds = {};
      _resetCartMemory();
      _availableBalance = 0;
      _pendingBalance = 0;
      _totalEarned = 0;
      final notificationsSubscription = _notificationsSubscription;
      _notificationsSubscription = null;
      await notificationsSubscription?.cancel();
      await _stopCatalogListener();
      await _stopWalletListener();
      await _stopPromotionGrantsListener();
      return;
    }
    _registerDeviceBestEffort();
    _touchLastActiveBestEffort();
    final deletionRefresh = _loadAccountDeletionData(scope);

    // A pending/blocked seller can only read their own status/public content.
    if (seller.status != AccountStatus.approved) {
      await deletionRefresh;
      if (!_isCurrent(scope)) return;
      products = [];
      packagingBoxes = [];
      categories = [];
      orders = [];
      transactions = [];
      withdrawals = [];
      payoutAccounts = [];
      statementLines = [];
      withdrawalSources = [];
      favoriteIds = {};
      stockAlertIds = {};
      _resetCartMemory();
      _availableBalance = 0;
      _pendingBalance = 0;
      _totalEarned = 0;
      await _refreshNotifications(scope);
      if (!_isCurrent(scope)) return;
      await _stopCatalogListener();
      await _stopWalletListener();
      await _stopPromotionGrantsListener();
      return;
    }

    // Publish catalog data independently from account-specific sections. A
    // slow or failed wallet/orders/notifications request must not keep product
    // browsing blank. Future.wait still waits for both branches before the
    // overall refresh settles, but each branch applies its own valid snapshot.
    final snapshotRestore = _restoreCatalogSnapshotIfNeeded(scope);
    final catalogRefresh = _catalogRefresh.run(() => _loadCatalogData(scope));
    final accountRefresh = _loadApprovedAccountData(scope);
    await Future.wait<void>([
      deletionRefresh,
      snapshotRestore,
      catalogRefresh,
      accountRefresh,
    ]);
  }

  Future<void> _loadAccountDeletionData(
    _AuthenticatedRequestScope scope,
  ) async {
    final request = await scope.repositories.profile
        .fetchLatestAccountDeletionRequest();
    if (!_isCurrent(scope)) return;
    accountDeletionRequest = request;
    notifyListeners();
  }

  Future<void> _restoreCatalogSnapshotIfNeeded(
    _AuthenticatedRequestScope scope,
  ) async {
    if (_repositories.isDemo ||
        (products.isNotEmpty && categories.isNotEmpty)) {
      return;
    }
    try {
      final snapshot = await _catalogSnapshotCache.read(scopeKey: scope.userId);
      if (snapshot == null ||
          !_isCurrent(scope) ||
          seller.status != AccountStatus.approved) {
        return;
      }
      var changed = false;
      if (categories.isEmpty && snapshot.categories.isNotEmpty) {
        categories = snapshot.categories;
        changed = true;
      }
      if (products.isEmpty && snapshot.products.isNotEmpty) {
        products = snapshot.products;
        changed = true;
      }
      if (changed) notifyListeners();
    } catch (_) {
      // A missing/corrupt platform cache must never delay the live catalog.
    }
  }

  void _cacheCatalogBestEffort(_AuthenticatedRequestScope scope) {
    if (_repositories.isDemo) return;
    final categorySnapshot = List<Category>.of(categories);
    final productSnapshot = List<Product>.of(products);
    unawaited(
      _catalogSnapshotCache
          .write(
            categories: categorySnapshot,
            products: productSnapshot,
            scopeKey: scope.userId,
          )
          .catchError((_) {
            // The live backend snapshot is already visible; disk caching is
            // strictly an acceleration for the next launch.
          }),
    );
  }

  Future<void> _restoreOrReconcileCart(_AuthenticatedRequestScope scope) async {
    if (!_isCurrent(scope) || products.isEmpty) return;
    if (_repositories.isDemo) {
      _reconcileCartWithCatalog();
      return;
    }
    if (_cartRestoredUserId == scope.userId) {
      _reconcileCartWithCatalog();
      return;
    }

    List<CartItem> restored = const <CartItem>[];
    var requestId = newUuidV4();
    var normalizedDuringRestore = false;
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString('$_cartStoragePrefix${scope.userId}');
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        final payload = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{'items': decoded};
        final storedRequestId = payload['request_id']?.toString() ?? '';
        if (_looksLikeUuid(storedRequestId)) requestId = storedRequestId;
        final rawItems = payload['items'];
        if (rawItems is List) {
          final byVariant = <String, CartItem>{};
          for (final rawItem in rawItems) {
            if (rawItem is! Map) {
              normalizedDuringRestore = true;
              continue;
            }
            final map = Map<String, dynamic>.from(rawItem);
            final product = _productForCartId(map['product_id']?.toString());
            if (product == null) {
              normalizedDuringRestore = true;
              continue;
            }
            final variant = _variantForCartId(
              product,
              map['variant_id']?.toString(),
            );
            if (variant == null || !variant.inStock) {
              normalizedDuringRestore = true;
              continue;
            }
            final rawQuantity = map['quantity'];
            final requestedQuantity = rawQuantity is num
                ? rawQuantity.toInt()
                : int.tryParse(rawQuantity?.toString() ?? '') ?? 1;
            final quantity = requestedQuantity.clamp(1, variant.stock);
            if (quantity != requestedQuantity) normalizedDuringRestore = true;
            final rawPrice = map['unit_sale_price'];
            var unitSalePrice = rawPrice is num
                ? rawPrice.toInt()
                : int.tryParse(rawPrice?.toString() ?? '') ?? 0;
            if (unitSalePrice <= 0) {
              unitSalePrice =
                  variant.suggestedPriceOverride ?? product.suggestedPrice;
              final minimum = _effectiveMinimumFor(product, variant);
              if (unitSalePrice < minimum) unitSalePrice = minimum;
              normalizedDuringRestore = true;
            }
            final packagingBox = product.packagingEnabled
                ? _packagingBoxForCartId(map['packaging_box_id']?.toString())
                : null;
            if (map['packaging_box_id'] != null && packagingBox == null) {
              normalizedDuringRestore = true;
            }
            if (byVariant.containsKey(variant.id)) {
              normalizedDuringRestore = true;
              continue;
            }
            byVariant[variant.id] = CartItem(
              product: product,
              variant: variant,
              quantity: quantity,
              unitSalePrice: unitSalePrice,
              packagingBox: packagingBox,
            );
          }
          restored = byVariant.values.take(50).toList(growable: false);
          if (byVariant.length > 50) normalizedDuringRestore = true;
        }
      }
    } catch (_) {
      // A corrupt/missing local cart must not block the live catalog.
      restored = const <CartItem>[];
      requestId = newUuidV4();
      normalizedDuringRestore = true;
    }
    if (!_isCurrent(scope)) return;
    cartItems = List<CartItem>.unmodifiable(restored);
    _cartClientRequestId = requestId;
    _cartRestoredUserId = scope.userId;
    notifyListeners();
    if (normalizedDuringRestore) _persistCartBestEffort();
  }

  void _reconcileCartWithCatalog() {
    if (cartItems.isEmpty) return;
    final reconciled = <CartItem>[];
    final seenVariants = <String>{};
    var payloadChanged = false;
    var referencesChanged = false;
    for (final current in cartItems) {
      final product = _productForCartId(current.product.id);
      final variant = product == null
          ? null
          : _variantForCartId(product, current.variant.id);
      if (product == null || variant == null || !variant.inStock) {
        payloadChanged = true;
        continue;
      }
      if (!seenVariants.add(variant.id)) {
        payloadChanged = true;
        continue;
      }
      final quantity = current.quantity.clamp(1, variant.stock);
      final packaging = product.packagingEnabled
          ? _packagingBoxForCartId(current.packagingBox?.id)
          : null;
      if (quantity != current.quantity ||
          packaging?.id != current.packagingBox?.id) {
        payloadChanged = true;
      }
      if (!identical(product, current.product) ||
          !identical(variant, current.variant) ||
          !identical(packaging, current.packagingBox)) {
        referencesChanged = true;
      }
      reconciled.add(
        current.copyWith(
          product: product,
          variant: variant,
          quantity: quantity,
          packagingBox: packaging,
          clearPackaging: packaging == null,
        ),
      );
    }
    if (!payloadChanged && !referencesChanged) return;
    cartItems = List<CartItem>.unmodifiable(reconciled);
    if (payloadChanged) {
      _cartClientRequestId = newUuidV4();
      _persistCartBestEffort();
    }
    notifyListeners();
  }

  Product? _productForCartId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  ProductVariant? _variantForCartId(Product product, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final variant in product.variants) {
      if (variant.id == id) return variant;
    }
    return null;
  }

  PackagingBox? _packagingBoxForCartId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final box in packagingBoxes) {
      if (box.id == id) return box;
    }
    return null;
  }

  bool _looksLikeUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);

  void _persistCartBestEffort() {
    if (_repositories.isDemo) return;
    final userId = _observedUserId;
    if (userId == null || userId.isEmpty) return;
    final requestId = _cartClientRequestId;
    final itemSnapshot = [
      for (final item in cartItems)
        <String, dynamic>{
          'product_id': item.product.id,
          'variant_id': item.variant.id,
          'quantity': item.quantity,
          'unit_sale_price': item.unitSalePrice,
          'packaging_box_id': item.packagingBox?.id,
        },
    ];
    _cartWriteQueue = _cartWriteQueue.then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        final key = '$_cartStoragePrefix$userId';
        if (itemSnapshot.isEmpty) {
          await preferences.remove(key);
          return;
        }
        await preferences.setString(
          key,
          jsonEncode(<String, dynamic>{
            'version': 1,
            'request_id': requestId,
            'items': itemSnapshot,
          }),
        );
      } catch (_) {
        // The in-memory cart remains fully usable when local storage fails.
      }
    });
  }

  Future<void> _loadCatalogData(_AuthenticatedRequestScope scope) async {
    await Future.wait<void>([
      _loadCatalogEntities(scope),
      _loadCatalogPreferences(scope),
    ]);
  }

  Future<void> _loadCatalogEntities(_AuthenticatedRequestScope scope) async {
    _listenForCatalogChanges(scope);
    List<Category>? fetchedCategories;
    List<Product>? fetchedProducts;
    List<PackagingBox>? fetchedPackagingBoxes;
    Object? categoriesError;
    StackTrace? categoriesStackTrace;
    Object? productsError;
    StackTrace? productsStackTrace;
    Object? packagingError;
    StackTrace? packagingStackTrace;
    await Future.wait<void>([
      scope.repositories.catalog.fetchCategories().then<void>(
        (value) => fetchedCategories = value,
        onError: (Object error, StackTrace stackTrace) {
          categoriesError = error;
          categoriesStackTrace = stackTrace;
        },
      ),
      scope.repositories.catalog.fetchProducts().then<void>(
        (value) => fetchedProducts = value,
        onError: (Object error, StackTrace stackTrace) {
          productsError = error;
          productsStackTrace = stackTrace;
        },
      ),
      scope.repositories.catalog.fetchPackagingBoxes().then<void>(
        (value) => fetchedPackagingBoxes = value,
        onError: (Object error, StackTrace stackTrace) {
          packagingError = error;
          packagingStackTrace = stackTrace;
        },
      ),
    ]);
    if (!_isCurrent(scope) || seller.status != AccountStatus.approved) return;

    // A healthy branch may still update the screen when the other endpoint is
    // temporarily unavailable, but only a complete revision reaches disk.
    if (fetchedCategories != null) categories = fetchedCategories!;
    if (fetchedProducts != null) products = fetchedProducts!;
    if (fetchedPackagingBoxes != null) {
      packagingBoxes = fetchedPackagingBoxes!;
    }
    if (fetchedProducts != null || fetchedPackagingBoxes != null) {
      await _restoreOrReconcileCart(scope);
    }
    if (fetchedCategories != null ||
        fetchedProducts != null ||
        fetchedPackagingBoxes != null) {
      notifyListeners();
    }
    if (fetchedCategories != null && fetchedProducts != null) {
      _lastCatalogRefresh = DateTime.now();
      _cacheCatalogBestEffort(scope);
    }

    if (categoriesError != null) {
      Error.throwWithStackTrace(categoriesError!, categoriesStackTrace!);
    }
    if (productsError != null) {
      Error.throwWithStackTrace(productsError!, productsStackTrace!);
    }
    if (packagingError != null) {
      Error.throwWithStackTrace(packagingError!, packagingStackTrace!);
    }
  }

  Future<void> _loadCatalogPreferences(_AuthenticatedRequestScope scope) async {
    final results = await Future.wait<Object>([
      scope.repositories.catalog.fetchFavoriteProductIds(),
      scope.repositories.catalog.fetchStockAlertProductIds(),
    ]);
    if (!_isCurrent(scope) || seller.status != AccountStatus.approved) return;
    favoriteIds = results[0] as Set<String>;
    stockAlertIds = results[1] as Set<String>;
    notifyListeners();
  }

  Future<void> _loadApprovedAccountData(
    _AuthenticatedRequestScope scope,
  ) async {
    _listenForPromotionGrantChanges(scope);
    await Future.wait<void>([
      _ordersRefresh.run(() => _loadApprovedOrders(scope)),
      _loadApprovedWallet(scope),
      _notificationsRefresh.run(() => _loadApprovedNotifications(scope)),
    ]);
  }

  Future<void> _loadApprovedOrders(_AuthenticatedRequestScope scope) async {
    final value = await scope.repositories.orders.fetchOrders();
    if (!_isCurrent(scope) || seller.status != AccountStatus.approved) return;
    orders = value;
    notifyListeners();
  }

  Future<void> _loadApprovedWallet(_AuthenticatedRequestScope scope) async {
    final value = await scope.repositories.wallet.fetchWallet();
    if (!_isCurrent(scope) || seller.status != AccountStatus.approved) return;
    _applyWallet(value);
    _listenForWalletChanges(scope);
    notifyListeners();
  }

  Future<void> _loadApprovedNotifications(
    _AuthenticatedRequestScope scope,
  ) async {
    final value = await scope.repositories.notifications.fetchNotifications();
    if (!_isCurrent(scope) || seller.status != AccountStatus.approved) return;
    _applyNotificationItems(value);
    _listenForNotifications(scope);
    notifyListeners();
  }

  Future<void> _runRefresh(
    Future<void> Function() load, {
    _AuthenticatedRequestScope? authScope,
  }) async {
    _activeRefreshes += 1;
    lastError = null;
    notifyListeners();
    try {
      await load();
    } catch (error) {
      if (authScope == null || _isCurrent(authScope)) {
        lastError = _messageFor(error);
      }
      rethrow;
    } finally {
      _activeRefreshes -= 1;
      notifyListeners();
    }
  }

  Future<Seller> refreshCurrentProfile() {
    final scope = _captureAuthenticatedScope();
    if (scope == null) return Future<Seller>.value(seller);
    final current = _profileRefresh;
    if (current != null) return current;

    late final Future<Seller> next;
    next =
        Future<Seller>.sync(() async {
          final profile = await scope.repositories.profile
              .fetchCurrentProfile();
          if (!_isCurrent(scope)) return seller;
          _setSeller(profile);
          notifyListeners();
          return seller;
        }).whenComplete(() {
          if (identical(_profileRefresh, next)) _profileRefresh = null;
        });
    _profileRefresh = next;
    return next;
  }

  /// Refreshes only the wallet data shown on balance and withdrawal screens.
  /// Repeated calls are deduplicated so tab entry, app resume and Realtime can
  /// safely request the same snapshot together.
  Future<void> refreshWallet() {
    final scope = _captureAuthenticatedScope();
    if (scope == null || seller.status != AccountStatus.approved) {
      return Future<void>.value();
    }
    final refresh = _walletRefresh;
    return refresh.run(
      () => _runRefresh(() async {
        final snapshot = await scope.repositories.wallet.fetchWallet();
        if (!_isCurrent(scope) || seller.status != AccountStatus.approved) {
          return;
        }
        _applyWallet(snapshot);
      }, authScope: scope),
    );
  }

  SessionDestination get destination => switch (seller.status) {
    AccountStatus.approved => SessionDestination.shell,
    AccountStatus.pending => SessionDestination.pendingApproval,
    AccountStatus.rejected => SessionDestination.rejected,
    AccountStatus.blocked => SessionDestination.blocked,
    AccountStatus.deleted => SessionDestination.deleted,
  };

  Product? productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Category categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    if (categories.isNotEmpty) return categories.first;
    return Category(
      id: id,
      nameAr: 'غير مصنف',
      nameCkb: 'بێ پۆلێن',
      nameEn: 'Uncategorized',
      icon: Icons.category_outlined,
      imageUrl: '',
    );
  }

  Order? orderById(String id) {
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  /// Fetches one order under the current RLS scope and replaces any cached
  /// snapshot before a notification opens its detail screen.
  Future<Order> refreshOrderById(String orderId) {
    final scope = _requireAuthenticatedScope();
    if (seller.status != AccountStatus.approved) {
      throw const BackendException('Seller account is not approved.');
    }
    final id = orderId.trim();
    if (id.isEmpty) {
      throw const BackendException('Order id is required.');
    }
    final existing = _orderRefreshes[id];
    if (existing != null) return existing;

    late final Future<Order> next;
    next =
        Future<Order>.sync(() async {
          final order = await scope.repositories.orders.fetchOrder(id);
          _ensureCurrent(scope);
          if (seller.status != AccountStatus.approved) {
            throw const BackendException('Seller account is not approved.');
          }
          final index = orders.indexWhere((item) => item.id == order.id);
          if (index == -1) {
            orders.insert(0, order);
          } else {
            orders[index] = order;
          }
          notifyListeners();
          return order;
        }).whenComplete(() {
          if (identical(_orderRefreshes[id], next)) _orderRefreshes.remove(id);
        });
    _orderRefreshes[id] = next;
    return next;
  }

  /// Fetches one active product and replaces its cached snapshot before a
  /// notification opens product details.
  Future<Product> refreshProductById(String productId) {
    final scope = _requireAuthenticatedScope();
    if (seller.status != AccountStatus.approved) {
      throw const BackendException('Seller account is not approved.');
    }
    final id = productId.trim();
    if (id.isEmpty) {
      throw const BackendException('Product id is required.');
    }
    final existing = _productRefreshes[id];
    if (existing != null) return existing;

    late final Future<Product> next;
    next =
        Future<Product>.sync(() async {
          final product = await scope.repositories.catalog.fetchProduct(id);
          _ensureCurrent(scope);
          if (seller.status != AccountStatus.approved) {
            throw const BackendException('Seller account is not approved.');
          }
          final index = products.indexWhere((item) => item.id == product.id);
          if (index == -1) {
            products.insert(0, product);
          } else {
            products[index] = product;
          }
          notifyListeners();
          return product;
        }).whenComplete(() {
          if (identical(_productRefreshes[id], next)) {
            _productRefreshes.remove(id);
          }
        });
    _productRefreshes[id] = next;
    return next;
  }

  bool isFavorite(String productId) => favoriteIds.contains(productId);

  Future<void> toggleFavorite(String productId) async {
    final scope = _requireAuthenticatedScope();
    final wasFavorite = favoriteIds.contains(productId);
    wasFavorite ? favoriteIds.remove(productId) : favoriteIds.add(productId);
    notifyListeners();
    try {
      await scope.repositories.catalog.setFavorite(
        productId,
        enabled: !wasFavorite,
      );
    } catch (error) {
      if (!_isCurrent(scope)) rethrow;
      wasFavorite ? favoriteIds.add(productId) : favoriteIds.remove(productId);
      lastError = _messageFor(error);
      notifyListeners();
      rethrow;
    }
  }

  bool hasStockAlert(String productId) => stockAlertIds.contains(productId);

  Future<void> toggleStockAlert(String productId) async {
    final scope = _requireAuthenticatedScope();
    final wasEnabled = stockAlertIds.contains(productId);
    wasEnabled ? stockAlertIds.remove(productId) : stockAlertIds.add(productId);
    notifyListeners();
    try {
      await scope.repositories.catalog.setStockAlert(
        productId,
        enabled: !wasEnabled,
      );
    } catch (error) {
      if (!_isCurrent(scope)) rethrow;
      wasEnabled
          ? stockAlertIds.add(productId)
          : stockAlertIds.remove(productId);
      lastError = _messageFor(error);
      notifyListeners();
      rethrow;
    }
  }

  // ─────────────────────────── السلة ───────────────────────────

  CartItem? cartItemForVariant(String variantId) {
    for (final item in cartItems) {
      if (item.variant.id == variantId) return item;
    }
    return null;
  }

  void addToCart({
    required Product product,
    required ProductVariant variant,
    int quantity = 1,
  }) {
    if (quantity <= 0) {
      throw const BackendException('يجب أن تكون الكمية أكبر من صفر.');
    }
    if (!variant.inStock) {
      throw const BackendException('هذا الخيار غير متوفر حالياً.');
    }

    final existingIndex = cartItems.indexWhere(
      (item) => item.variant.id == variant.id,
    );
    if (existingIndex >= 0) {
      final existing = cartItems[existingIndex];
      final updatedQuantity = existing.quantity + quantity;
      if (updatedQuantity > variant.stock) {
        throw BackendException(
          'الكمية المطلوبة أكبر من المخزون المتوفر (${variant.stock}).',
        );
      }
      _replaceCartItem(
        existingIndex,
        existing.copyWith(
          product: product,
          variant: variant,
          quantity: updatedQuantity,
        ),
      );
      return;
    }

    if (cartItems.length >= 50) {
      throw const BackendException(
        'يمكن إضافة 50 خياراً مختلفاً كحد أقصى للطلب الواحد.',
      );
    }
    final minimum = _effectiveMinimumFor(product, variant);
    var salePrice = variant.suggestedPriceOverride ?? product.suggestedPrice;
    if (salePrice < minimum) salePrice = minimum;
    final maximum = product.maxSalePrice;
    if (maximum != null && salePrice > maximum) salePrice = maximum;

    cartItems = List<CartItem>.unmodifiable([
      ...cartItems,
      CartItem(
        product: product,
        variant: variant,
        quantity: quantity,
        unitSalePrice: salePrice,
      ),
    ]);
    _cartMutated();
  }

  /// Adds a fully configured line, or replaces the configuration of the same
  /// variant when it is already in the cart.
  ///
  /// A cart line is uniquely identified by [ProductVariant.id], matching the
  /// order RPC contract. Price and packaging are therefore selected together
  /// before the line enters the cart instead of being partially edited later.
  void setCartItemConfiguration({
    required Product product,
    required ProductVariant variant,
    required int quantity,
    required int unitSalePrice,
    PackagingBox? packagingBox,
  }) {
    final belongsToProduct = product.variants.any(
      (candidate) => candidate.id == variant.id,
    );
    if (!belongsToProduct) {
      throw const BackendException('هذا الخيار لا يتبع للمنتج المحدد.');
    }
    if (!variant.inStock) {
      throw const BackendException('هذا الخيار غير متوفر حالياً.');
    }
    if (quantity <= 0 || quantity > variant.stock) {
      throw BackendException(
        'الكمية المطلوبة يجب أن تكون بين 1 و${variant.stock}.',
      );
    }

    final minimum = _effectiveMinimumFor(product, variant);
    if (unitSalePrice < minimum) {
      throw BackendException('سعر البيع أقل من الحد المسموح ($minimum).');
    }
    final maximum = product.maxSalePrice;
    if (maximum != null && unitSalePrice > maximum) {
      throw BackendException('سعر البيع أعلى من الحد المسموح ($maximum).');
    }

    PackagingBox? canonicalBox;
    if (packagingBox != null) {
      if (!product.packagingEnabled) {
        throw const BackendException('التعليب غير متاح لهذا المنتج.');
      }
      for (final availableBox in packagingBoxes) {
        if (availableBox.id == packagingBox.id) {
          canonicalBox = availableBox;
          break;
        }
      }
      if (canonicalBox == null) {
        throw const BackendException('العلبة المختارة لم تعد متاحة.');
      }
    }

    final configuredItem = CartItem(
      product: product,
      variant: variant,
      quantity: quantity,
      unitSalePrice: unitSalePrice,
      packagingBox: canonicalBox,
    );
    final existingIndex = cartItems.indexWhere(
      (item) => item.variant.id == variant.id,
    );
    if (existingIndex >= 0) {
      _replaceCartItem(existingIndex, configuredItem);
      return;
    }
    if (cartItems.length >= 50) {
      throw const BackendException(
        'يمكن إضافة 50 خياراً مختلفاً كحد أقصى للطلب الواحد.',
      );
    }
    cartItems = List<CartItem>.unmodifiable([...cartItems, configuredItem]);
    _cartMutated();
  }

  void updateCartQuantity(String variantId, int quantity) {
    final index = cartItems.indexWhere((item) => item.variant.id == variantId);
    if (index < 0) return;
    if (quantity <= 0) {
      removeFromCart(variantId);
      return;
    }
    final item = cartItems[index];
    if (quantity > item.variant.stock) {
      throw BackendException(
        'الكمية المطلوبة أكبر من المخزون المتوفر (${item.variant.stock}).',
      );
    }
    _replaceCartItem(index, item.copyWith(quantity: quantity));
  }

  void updateCartSalePrice(String variantId, int unitSalePrice) {
    final index = cartItems.indexWhere((item) => item.variant.id == variantId);
    if (index < 0 || unitSalePrice <= 0) return;
    _replaceCartItem(
      index,
      cartItems[index].copyWith(unitSalePrice: unitSalePrice),
    );
  }

  void updateCartPackaging(String variantId, PackagingBox? packagingBox) {
    final index = cartItems.indexWhere((item) => item.variant.id == variantId);
    if (index < 0) return;
    final item = cartItems[index];
    if (packagingBox != null && !item.product.packagingEnabled) {
      throw const BackendException('التعليب غير متاح لهذا المنتج.');
    }
    _replaceCartItem(
      index,
      item.copyWith(
        packagingBox: packagingBox,
        clearPackaging: packagingBox == null,
      ),
    );
  }

  void removeFromCart(String variantId) {
    final updated = cartItems
        .where((item) => item.variant.id != variantId)
        .toList(growable: false);
    if (updated.length == cartItems.length) return;
    cartItems = List<CartItem>.unmodifiable(updated);
    _cartMutated();
  }

  void clearCart() {
    if (cartItems.isEmpty) return;
    cartItems = const <CartItem>[];
    _cartMutated();
  }

  void _replaceCartItem(int index, CartItem item) {
    final updated = List<CartItem>.of(cartItems);
    updated[index] = item;
    cartItems = List<CartItem>.unmodifiable(updated);
    _cartMutated();
  }

  void _cartMutated() {
    _cartClientRequestId = newUuidV4();
    notifyListeners();
    _persistCartBestEffort();
  }

  int _effectiveMinimumFor(Product product, ProductVariant variant) {
    final wholesale = variant.wholesalePriceOverride ?? product.wholesalePrice;
    return wholesale > product.effectiveMinSalePrice
        ? wholesale
        : product.effectiveMinSalePrice;
  }

  Future<Order> createCartOrder({
    required Governorate governorate,
    required String customerName,
    required String customerPhone,
    String? customerPhone2,
    required String addressDetails,
    String? notes,
  }) async {
    final scope = _requireAuthenticatedScope();
    if (cartItems.isEmpty) {
      throw const BackendException('السلة فارغة.');
    }
    if (cartItems.length > 50) {
      throw const BackendException(
        'يمكن إضافة 50 خياراً مختلفاً كحد أقصى للطلب الواحد.',
      );
    }
    if (cartItems.any((item) => !item.priceIsValid)) {
      throw const BackendException(
        'راجع أسعار البيع في السلة قبل تأكيد الطلب.',
      );
    }
    final requestId = _cartClientRequestId;
    final submittedLines = [
      for (final item in cartItems) CreateOrderLine.fromCartItem(item),
    ];
    final order = await scope.repositories.orders.createOrder(
      CreateOrderRequest.lines(
        clientRequestId: requestId,
        lines: submittedLines,
        governorate: governorate,
        customerName: customerName,
        customerPhone: customerPhone,
        customerPhone2: customerPhone2,
        addressDetails: addressDetails,
        notes: notes,
      ),
    );
    _ensureCurrent(scope);
    orders.removeWhere((item) => item.id == order.id);
    orders.insert(0, order);
    if (_cartClientRequestId == requestId) {
      cartItems = const <CartItem>[];
      _cartClientRequestId = newUuidV4();
      _persistCartBestEffort();
    }
    notifyListeners();
    return order;
  }

  Future<Order> createOrder({
    String? clientRequestId,
    required Product product,
    required List<OrderDraftItem> items,
    required int unitSalePrice,
    required Governorate governorate,
    required String customerName,
    required String customerPhone,
    String? customerPhone2,
    required String addressDetails,
    String? notes,
    PackagingBox? packagingBox,
  }) async {
    final scope = _requireAuthenticatedScope();
    final order = await scope.repositories.orders.createOrder(
      CreateOrderRequest(
        clientRequestId: clientRequestId ?? _newRequestId(),
        product: product,
        items: items,
        unitSalePrice: unitSalePrice,
        governorate: governorate,
        customerName: customerName,
        customerPhone: customerPhone,
        customerPhone2: customerPhone2,
        addressDetails: addressDetails,
        notes: notes,
        packagingBox: packagingBox,
      ),
    );
    _ensureCurrent(scope);
    orders.removeWhere((item) => item.id == order.id);
    orders.insert(0, order);
    notifyListeners();
    return order;
  }

  Future<DeliveryQuote> quoteDeliveryFee(String deliveryZoneId) {
    final scope = _requireAuthenticatedScope();
    if (seller.status != AccountStatus.approved) {
      throw const BackendException('Seller account is not approved.');
    }
    return scope.repositories.catalog.quoteDeliveryFee(deliveryZoneId);
  }

  Future<OrderComplaint> createOrderComplaint({
    required String orderId,
    required OrderComplaintKind kind,
    required String subject,
    required String message,
    String? clientRequestId,
  }) async {
    final scope = _requireAuthenticatedScope();
    final complaint = await scope.repositories.orders.createComplaint(
      orderId: orderId,
      kind: kind,
      subject: subject,
      message: message,
      clientRequestId: clientRequestId ?? _newRequestId(),
    );
    _ensureCurrent(scope);
    await refreshOrderById(orderId);
    return complaint;
  }

  Future<void> cancelOrder(String orderId, {String? clientRequestId}) async {
    final scope = _requireAuthenticatedScope();
    await scope.repositories.orders.cancelOrder(
      orderId,
      clientRequestId:
          clientRequestId ?? 'seller-cancel-order:${orderId.trim()}',
    );
    _ensureCurrent(scope);
    final index = orders.indexWhere((item) => item.id == orderId);
    if (index >= 0 && orders[index].status != OrderStatus.cancelled) {
      final current = orders[index];
      orders[index] = current.copyWith(
        status: OrderStatus.cancelled,
        statusHistory: [
          ...current.statusHistory,
          OrderStatusEntry(
            status: OrderStatus.cancelled,
            at: DateTime.now(),
            note: 'Cancelled by seller',
          ),
        ],
      );
      notifyListeners();
    }
    try {
      final latest = await scope.repositories.orders.fetchOrder(orderId);
      _ensureCurrent(scope);
      final latestIndex = orders.indexWhere((item) => item.id == latest.id);
      if (latestIndex == -1) {
        orders.insert(0, latest);
      } else {
        orders[latestIndex] = latest;
      }
      notifyListeners();
    } catch (_) {
      _ensureCurrent(scope);
      // The cancellation RPC already committed; resume/push/manual refresh
      // will replace the optimistic snapshot with the authoritative event.
    }
  }

  Future<void> submitOrderChangeRequest({
    required String orderId,
    required OrderChangeRequestType type,
    required String reason,
    Map<String, dynamic> proposedChanges = const {},
    String? clientRequestId,
  }) async {
    final scope = _requireAuthenticatedScope();
    await scope.repositories.orders.submitChangeRequest(
      orderId: orderId,
      type: type,
      reason: reason,
      proposedChanges: proposedChanges,
      clientRequestId: clientRequestId ?? _newRequestId(),
    );
    _ensureCurrent(scope);
  }

  Future<Withdrawal> requestWithdrawal({
    String? clientRequestId,
    required int amount,
    required String method,
    required String accountDetail,
    String? payoutAccountId,
  }) async {
    final scope = _requireAuthenticatedScope();
    final withdrawal = await scope.repositories.wallet.requestWithdrawal(
      CreateWithdrawalRequest(
        clientRequestId: clientRequestId ?? _newRequestId(),
        amount: amount,
        method: method,
        accountDetail: accountDetail,
        payoutAccountId: payoutAccountId,
      ),
    );
    _ensureCurrent(scope);
    _applyCreatedWithdrawalLocally(withdrawal);
    try {
      final wallet = await scope.repositories.wallet.fetchWallet();
      _ensureCurrent(scope);
      _applyWallet(wallet);
      notifyListeners();
    } catch (_) {
      _ensureCurrent(scope);
      // The atomic RPC already succeeded. Keep that success visible and let a
      // later Realtime/resume/manual refresh reconcile the full ledger.
      unawaited(_refreshWalletBestEffort());
    }
    return withdrawal;
  }

  Future<PayoutAccount> savePayoutAccount({
    String? accountId,
    required String provider,
    required String accountHolderName,
    required String accountIdentifier,
    bool makeDefault = false,
  }) async {
    final scope = _requireAuthenticatedScope();
    final account = await scope.repositories.wallet.upsertPayoutAccount(
      SavePayoutAccountRequest(
        accountId: accountId,
        provider: provider,
        accountHolderName: accountHolderName,
        accountIdentifier: accountIdentifier,
        makeDefault: makeDefault,
      ),
    );
    _ensureCurrent(scope);
    _applyPayoutAccountLocally(account);
    try {
      final accounts = await scope.repositories.wallet.fetchPayoutAccounts();
      _ensureCurrent(scope);
      payoutAccounts = accounts;
      notifyListeners();
    } catch (_) {
      _ensureCurrent(scope);
      // Saving is already committed; do not turn a follow-up read outage into
      // a false mutation failure that encourages duplicate submissions.
      unawaited(_refreshWalletBestEffort());
    }
    return account;
  }

  Future<void> deletePayoutAccount(String accountId) async {
    final scope = _requireAuthenticatedScope();
    await scope.repositories.wallet.deletePayoutAccount(accountId);
    _ensureCurrent(scope);
    payoutAccounts = [
      for (final item in payoutAccounts)
        if (item.id != accountId) item,
    ];
    notifyListeners();
    try {
      final accounts = await scope.repositories.wallet.fetchPayoutAccounts();
      _ensureCurrent(scope);
      payoutAccounts = accounts;
      notifyListeners();
    } catch (_) {
      _ensureCurrent(scope);
      unawaited(_refreshWalletBestEffort());
    }
  }

  Future<void> cancelWithdrawal(
    String withdrawalId, {
    String? clientRequestId,
  }) async {
    final scope = _requireAuthenticatedScope();
    final cancelled = await scope.repositories.wallet.cancelWithdrawal(
      withdrawalId,
      clientRequestId:
          clientRequestId ?? 'seller-cancel-withdrawal:${withdrawalId.trim()}',
    );
    _ensureCurrent(scope);
    _applyCancelledWithdrawalLocally(cancelled);
    try {
      final wallet = await scope.repositories.wallet.fetchWallet();
      _ensureCurrent(scope);
      _applyWallet(wallet);
      notifyListeners();
    } catch (_) {
      _ensureCurrent(scope);
      unawaited(_refreshWalletBestEffort());
    }
  }

  Future<void> updateProfile({
    String? name,
    String? storeName,
    String? instagramUrl,
  }) async {
    final scope = _requireAuthenticatedScope();
    final profile = await scope.repositories.profile.updateCurrentProfile(
      name: name ?? seller.name,
      storeName: storeName ?? seller.storeName,
      instagramUrl: instagramUrl ?? seller.instagramUrl,
    );
    _ensureCurrent(scope);
    _setSeller(profile);
    notifyListeners();
  }

  Future<void> updateSettings({
    required String locale,
    required Map<String, bool> notificationPreferences,
  }) async {
    final scope = _requireAuthenticatedScope();
    final profile = await scope.repositories.profile.updateSettings(
      locale: locale,
      notificationPreferences: notificationPreferences,
    );
    _ensureCurrent(scope);
    _setSeller(profile);
    notifyListeners();
  }

  Future<void> requestAccountDeletion(
    String reason, {
    String? clientRequestId,
  }) async {
    final scope = _requireAuthenticatedScope();
    final request = await scope.repositories.profile.requestAccountDeletion(
      reason: reason,
      clientRequestId: clientRequestId ?? _newRequestId(),
    );
    _ensureCurrent(scope);
    accountDeletionRequest = request;
    notifyListeners();
  }

  Future<void> cancelAccountDeletion({String? clientRequestId}) async {
    final scope = _requireAuthenticatedScope();
    final request = accountDeletionRequest;
    if (request == null || request.status != AccountDeletionStatus.pending) {
      throw const BackendException('لا يوجد طلب حذف معلّق لإلغائه.');
    }
    final cancelled = await scope.repositories.profile.cancelAccountDeletion(
      requestId: request.id,
      clientRequestId:
          clientRequestId ??
          'seller-cancel-account-deletion:${request.id.trim()}',
    );
    _ensureCurrent(scope);
    accountDeletionRequest = cancelled;
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    final scope = _requireAuthenticatedScope();
    final unread = notifications.where((item) => !item.isRead).toList();
    for (final item in unread) {
      item.isRead = true;
    }
    notifyListeners();
    try {
      await scope.repositories.notifications.markAllRead();
    } catch (error) {
      if (!_isCurrent(scope)) rethrow;
      for (final item in unread) {
        item.isRead = false;
      }
      lastError = _messageFor(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    final scope = _requireAuthenticatedScope();
    final notification = notifications
        .where((item) => item.id == notificationId)
        .firstOrNull;
    if (notification == null || notification.isRead) return;
    notification.isRead = true;
    notifyListeners();
    try {
      await scope.repositories.notifications.markRead(notificationId);
    } catch (error) {
      if (!_isCurrent(scope)) rethrow;
      notification.isRead = false;
      lastError = _messageFor(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markNotificationPopupSeen(String notificationId) async {
    final scope = _captureAuthenticatedScope();
    if (scope == null) return;
    final notification = notificationById(notificationId);
    _popupSeenNotificationIds.add(notificationId);
    if (notification != null) {
      notification.popupSeenAt ??= DateTime.now().toUtc();
    }
    notifyListeners();
    try {
      await scope.repositories.notifications.markPopupSeen(notificationId);
    } catch (_) {
      // Popup acknowledgement is best-effort. The local launch-level guard
      // prevents repeated interruption while the backend catches up.
    }
  }

  /// Signs out remotely when possible and always removes local account data.
  ///
  /// Supabase can clear its local Auth session and still throw when remote
  /// revocation fails, so the local cleanup must live in [finally].
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } finally {
      await clearAuthenticatedData();
    }
  }

  Future<void> clearAuthenticatedData() async {
    await _transitionAuthenticatedIdentity(null, force: true);
    await _clearCachedMedia();
  }

  /// Product media is private: it is fetched from `/object/authenticated/` with
  /// the seller's JWT. Cached bytes outlive the session by up to 30 days and are
  /// re-served from disk without any server-side authorization check, so a
  /// signed-out — or since-blocked — account could still browse them.
  /// Signing out must never fail because a cache could not be emptied, and it
  /// also runs on hosts with no binding (pure unit tests), so both stores are
  /// cleared defensively.
  Future<void> _clearCachedMedia() async {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (_) {
      // No binding means nothing was ever rendered from this cache.
    }
    try {
      await clearAppNetworkImageCacheIfCreated();
    } catch (_) {
      // The on-disk store is best-effort; the session teardown still completes.
    }
  }

  Future<void> clearCatalogSnapshotCache() async {
    final scopeKey = _observedUserId;
    if (scopeKey == null || scopeKey.isEmpty) return;
    await _catalogSnapshotCache.clear(scopeKey: scopeKey);
  }

  void _clearAuthenticatedFields() {
    _lastActiveTouch = null;
    _lastResumeReconciliation = null;
    _lastCatalogRefresh = null;
    seller = _emptySeller();
    accountDeletionRequest = null;
    products = [];
    packagingBoxes = [];
    categories = [];
    orders = [];
    transactions = [];
    withdrawals = [];
    payoutAccounts = [];
    statementLines = [];
    withdrawalSources = [];
    notifications = [];
    promotionGrants = [];
    referralSummary = null;
    promotionGrantsLoading = false;
    promotionGrantsLoaded = false;
    promotionGrantsError = null;
    referralSummaryLoading = false;
    referralSummaryLoaded = false;
    referralSummaryError = null;
    _popupSeenNotificationIds.clear();
    favoriteIds = {};
    stockAlertIds = {};
    _resetCartMemory();
    _availableBalance = 0;
    _pendingBalance = 0;
    _totalEarned = 0;
  }

  void _resetCartMemory() {
    cartItems = const <CartItem>[];
    _cartClientRequestId = newUuidV4();
    _cartRestoredUserId = null;
    _cartWriteQueue = Future<void>.value();
  }

  Future<void> _transitionAuthenticatedIdentity(
    String? userId, {
    bool force = false,
  }) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (!force && normalizedUserId == _observedUserId) return;

    final lostAuthenticatedIdentity =
        normalizedUserId == null && _observedUserId != null;

    _observedUserId = normalizedUserId;
    _invalidateAuthenticatedRequests();
    final notificationsSubscription = _notificationsSubscription;
    _notificationsSubscription = null;
    final catalogCleanup = _stopCatalogListener();
    final walletCleanup = _stopWalletListener();
    final promotionGrantsCleanup = _stopPromotionGrantsListener();
    _clearAuthenticatedFields();
    lastError = null;
    notifyListeners();

    await Future.wait<void>([
      if (lostAuthenticatedIdentity) _unregisterDeviceBestEffort(),
      if (notificationsSubscription != null) notificationsSubscription.cancel(),
      catalogCleanup,
      walletCleanup,
      promotionGrantsCleanup,
    ]);
  }

  Future<void> _unregisterDeviceBestEffort() async {
    try {
      // Auth can disappear because of expiry, remote revocation, or another
      // SDK event without passing through [signOut]. Invalidating the Firebase
      // installation token prevents a signed-out device from continuing to
      // receive account notifications. The registrar keeps a durable retry
      // marker if Firebase itself is temporarily unavailable.
      await _deviceTokens.unregisterCurrentDevice();
    } catch (_) {
      // Account data is already cleared synchronously. Push cleanup is retried
      // by the registrar on a later unauthenticated startup when necessary.
    }
  }

  void _invalidateAuthenticatedRequests() {
    _authGeneration += 1;
    _authenticatedRefreshWithoutProfile = AsyncRequestDeduplicator();
    _authenticatedRefreshWithProfile = AsyncRequestDeduplicator();
    _allDataRefresh = AsyncRequestDeduplicator();
    _catalogRefresh = AsyncRequestDeduplicator();
    _ordersRefresh = AsyncRequestDeduplicator();
    _walletRefresh = AsyncRequestDeduplicator();
    _notificationsRefresh = AsyncRequestDeduplicator();
    _promotionGrantsRefresh = AsyncRequestDeduplicator();
    _referralSummaryRefresh = AsyncRequestDeduplicator();
    _resumeReconciliation = AsyncRequestDeduplicator();
    _catalogRealtimeDirty = false;
    _catalogRealtimeWorkerRunning = false;
    _walletRealtimeDirty = false;
    _walletRealtimeWorkerRunning = false;
    _promotionGrantsRealtimeDirty = false;
    _promotionGrantsRealtimeWorkerRunning = false;
    _profileRefresh = null;
    _orderRefreshes.clear();
    _productRefreshes.clear();
  }

  void _handleAuthUserIdChange(String? userId) {
    // Some terminal-state screens revoke Auth from initState. A synchronous
    // stream emission during a widget build must not notify the route gate
    // while that same ListenableBuilder is still rebuilding.
    scheduleMicrotask(() => _scheduleAuthIdentityTransition(userId));
  }

  void _synchronizeAuthIdentity() {
    final currentUserId = _currentAuthUserId();
    if (currentUserId != _observedUserId) {
      _scheduleAuthIdentityTransition(currentUserId);
    }
  }

  void _scheduleAuthIdentityTransition(String? userId) {
    unawaited(
      _transitionAuthenticatedIdentity(userId).catchError((_) {
        // Identity and sensitive fields are invalidated synchronously before
        // listener cancellation, so cleanup failure cannot restore old data.
      }),
    );
  }

  _AuthenticatedRequestScope? _captureAuthenticatedScope() {
    _synchronizeAuthIdentity();
    final userId = _currentAuthUserId();
    if (userId == null || userId != _observedUserId) return null;
    return _AuthenticatedRequestScope(
      generation: _authGeneration,
      userId: userId,
      repositories: _repositories,
    );
  }

  _AuthenticatedRequestScope _requireAuthenticatedScope() {
    final scope = _captureAuthenticatedScope();
    if (scope != null) return scope;
    throw const BackendException(
      'انتهت جلسة تسجيل الدخول. سجل الدخول مجدداً للمتابعة.',
      code: 'auth_session_missing',
    );
  }

  void _ensureCurrent(_AuthenticatedRequestScope scope) {
    if (_isCurrent(scope)) return;
    throw const BackendException(
      'تغيّر الحساب أثناء تنفيذ العملية. أعد المحاولة من الحساب الحالي.',
      code: 'auth_session_changed',
    );
  }

  bool _isCurrent(_AuthenticatedRequestScope scope) =>
      scope.generation == _authGeneration &&
      scope.userId == _observedUserId &&
      identical(scope.repositories, _repositories) &&
      scope.userId == _currentAuthUserId();

  String? _currentAuthUserId() =>
      auth.hasSession ? _normalizeUserId(auth.currentUserId) : null;

  String? _normalizeUserId(String? userId) {
    final normalized = userId?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Future<void> _refreshNotifications(_AuthenticatedRequestScope scope) async {
    final items = await scope.repositories.notifications.fetchNotifications();
    if (!_isCurrent(scope)) return;
    _applyNotificationItems(items);
    _listenForNotifications(scope);
  }

  void _applyNotificationItems(List<AppNotification> items) {
    final previousIds = notifications.map((item) => item.id).toSet();
    final newEngagementItems = items.where(
      (item) =>
          !previousIds.contains(item.id) &&
          _notificationTargetsPromotionEngagement(item),
    );
    final shouldRefreshEngagement = newEngagementItems.isNotEmpty;
    final shouldRefreshReferral =
        referralSummaryLoaded &&
        newEngagementItems.any(_notificationTargetsReferrals);
    notifications = items;
    if (shouldRefreshEngagement) {
      unawaited(
        _refreshPromotionEngagementBestEffort(
          includeReferralSummary: shouldRefreshReferral,
        ),
      );
    }
  }

  void _listenForNotifications(_AuthenticatedRequestScope scope) {
    final previousSubscription = _notificationsSubscription;
    _notificationsSubscription = null;
    if (previousSubscription != null) {
      unawaited(previousSubscription.cancel());
    }
    if (!_isCurrent(scope)) return;
    _notificationsSubscription = scope.repositories.notifications
        .watchNotifications()
        .listen(
          (items) {
            if (!_isCurrent(scope)) return;
            _applyNotificationItems(items);
            notifyListeners();
          },
          onError: (_) {
            // The durable inbox refresh remains available when Realtime drops.
          },
        );
  }

  void _listenForCatalogChanges(_AuthenticatedRequestScope scope) {
    if (_catalogSubscription != null) return;
    _catalogSubscription = scope.repositories.catalog.watchCatalogChanges().listen(
      (_) {
        if (!_isCurrent(scope)) return;
        _catalogRealtimeDirty = true;
        if (_catalogRealtimeWorkerRunning) return;
        _catalogRefreshTimer?.cancel();
        // Spread a global catalog invalidation across devices instead of
        // making every signed-in phone hit PostgREST in the same millisecond.
        final spread = _realtimeJitter.nextInt(1201);
        _catalogRefreshTimer = Timer(
          Duration(milliseconds: 700 + spread),
          () => unawaited(_drainCatalogRealtimeRefreshes()),
        );
      },
      onError: (_) {
        // Pull-to-refresh remains available when Realtime is temporarily down.
      },
    );
  }

  Future<void> _stopCatalogListener() async {
    _catalogRefreshTimer?.cancel();
    _catalogRefreshTimer = null;
    _catalogRealtimeDirty = false;
    final subscription = _catalogSubscription;
    _catalogSubscription = null;
    await subscription?.cancel();
  }

  void _listenForWalletChanges(_AuthenticatedRequestScope scope) {
    if (_walletSubscription != null) return;
    _walletSubscription = scope.repositories.wallet.watchWalletChanges().listen(
      (_) {
        if (!_isCurrent(scope)) return;
        _walletRealtimeDirty = true;
        if (_walletRealtimeWorkerRunning) return;
        _walletRefreshTimer?.cancel();
        _walletRefreshTimer = Timer(
          const Duration(milliseconds: 350),
          () => unawaited(_drainWalletRealtimeRefreshes()),
        );
      },
      onError: (_) {
        // Opening the wallet, resuming the app and pull-to-refresh still retry.
      },
    );
  }

  Future<void> _stopWalletListener() async {
    _walletRefreshTimer?.cancel();
    _walletRefreshTimer = null;
    _walletRealtimeDirty = false;
    final subscription = _walletSubscription;
    _walletSubscription = null;
    await subscription?.cancel();
  }

  void _listenForPromotionGrantChanges(_AuthenticatedRequestScope scope) {
    if (_promotionGrantsSubscription != null || !_isCurrent(scope)) return;
    _promotionGrantsSubscription = scope.repositories.promotions
        .watchPromotionGrantChanges()
        .listen(
          (_) {
            if (!_isCurrent(scope)) return;
            _promotionGrantsRealtimeDirty = true;
            if (_promotionGrantsRealtimeWorkerRunning) return;
            _promotionGrantsRefreshTimer?.cancel();
            _promotionGrantsRefreshTimer = Timer(
              const Duration(milliseconds: 350),
              () => unawaited(_drainPromotionGrantRealtimeRefreshes()),
            );
          },
          onError: (_) {
            // Resume, push delivery and manual refresh remain reliable fallbacks.
          },
        );
  }

  Future<void> _stopPromotionGrantsListener() async {
    _promotionGrantsRefreshTimer?.cancel();
    _promotionGrantsRefreshTimer = null;
    _promotionGrantsRealtimeDirty = false;
    final subscription = _promotionGrantsSubscription;
    _promotionGrantsSubscription = null;
    await subscription?.cancel();
  }

  Future<void> _refreshWalletBestEffort() async {
    try {
      await refreshWallet();
    } catch (_) {
      // A later Realtime event, app resume or manual refresh will retry.
    }
  }

  Future<void> _drainWalletRealtimeRefreshes() async {
    if (_walletRealtimeWorkerRunning) return;
    final generation = _authGeneration;
    _walletRealtimeWorkerRunning = true;
    try {
      while (_walletRealtimeDirty) {
        if (generation != _authGeneration ||
            seller.status != AccountStatus.approved) {
          _walletRealtimeDirty = false;
          return;
        }
        _walletRealtimeDirty = false;
        final joinedOlderSnapshot = _walletRefresh.inFlight != null;
        try {
          await refreshWallet();
        } catch (_) {
          return;
        }
        if (generation != _authGeneration ||
            seller.status != AccountStatus.approved) {
          return;
        }
        // If the event joined a request that started earlier, run one fresh
        // read after it; that older request may have captured pre-event data.
        if (joinedOlderSnapshot) _walletRealtimeDirty = true;
      }
    } finally {
      if (generation == _authGeneration) {
        _walletRealtimeWorkerRunning = false;
      }
    }
  }

  Future<void> _drainPromotionGrantRealtimeRefreshes() async {
    if (_promotionGrantsRealtimeWorkerRunning) return;
    final generation = _authGeneration;
    _promotionGrantsRealtimeWorkerRunning = true;
    try {
      while (_promotionGrantsRealtimeDirty) {
        if (generation != _authGeneration ||
            seller.status != AccountStatus.approved) {
          _promotionGrantsRealtimeDirty = false;
          return;
        }
        _promotionGrantsRealtimeDirty = false;
        final joinedOlderSnapshot = _promotionGrantsRefresh.inFlight != null;
        try {
          await refreshPromotionGrants();
          if (referralSummaryLoaded) {
            await _refreshReferralSummaryBestEffort();
          }
        } catch (_) {
          return;
        }
        if (generation != _authGeneration ||
            seller.status != AccountStatus.approved) {
          return;
        }
        if (joinedOlderSnapshot) _promotionGrantsRealtimeDirty = true;
      }
    } finally {
      if (generation == _authGeneration) {
        _promotionGrantsRealtimeWorkerRunning = false;
      }
    }
  }

  Future<void> _drainCatalogRealtimeRefreshes() async {
    if (_catalogRealtimeWorkerRunning) return;
    final generation = _authGeneration;
    _catalogRealtimeWorkerRunning = true;
    try {
      while (_catalogRealtimeDirty) {
        if (generation != _authGeneration ||
            seller.status != AccountStatus.approved) {
          _catalogRealtimeDirty = false;
          return;
        }
        _catalogRealtimeDirty = false;
        final joinedOlderSnapshot = _catalogRefresh.inFlight != null;
        try {
          await refreshCatalog();
        } catch (_) {
          return;
        }
        if (generation != _authGeneration ||
            seller.status != AccountStatus.approved) {
          return;
        }
        // Preserve a trailing invalidation that arrived after the active
        // request had already read its database snapshot.
        if (joinedOlderSnapshot) _catalogRealtimeDirty = true;
      }
    } finally {
      if (generation == _authGeneration) {
        _catalogRealtimeWorkerRunning = false;
      }
    }
  }

  void _applyWallet(WalletSnapshot snapshot) {
    _availableBalance = snapshot.available;
    _pendingBalance = snapshot.pending;
    _totalEarned = snapshot.totalEarned;
    _minWithdrawalAmount = snapshot.minimumWithdrawal;
    _withdrawalFees = Map<String, int>.unmodifiable(snapshot.withdrawalFees);
    transactions = snapshot.transactions;
    withdrawals = snapshot.withdrawals;
    payoutAccounts = snapshot.payoutAccounts;
    statementLines = snapshot.statementLines;
    withdrawalSources = snapshot.withdrawalSources;
  }

  void _applyCreatedWithdrawalLocally(Withdrawal withdrawal) {
    final wasAlreadyKnown = withdrawals.any((item) => item.id == withdrawal.id);
    withdrawals.removeWhere((item) => item.id == withdrawal.id);
    withdrawals.insert(0, withdrawal);
    if (!wasAlreadyKnown) {
      final remaining = _availableBalance - withdrawal.amount;
      _availableBalance = remaining < 0 ? 0 : remaining;
    }
    notifyListeners();
  }

  void _applyCancelledWithdrawalLocally(Withdrawal cancelled) {
    final index = withdrawals.indexWhere((item) => item.id == cancelled.id);
    final shouldRelease =
        index >= 0 && withdrawals[index].status == WithdrawalStatus.pending;
    if (index == -1) {
      withdrawals.insert(0, cancelled);
    } else {
      withdrawals[index] = cancelled;
    }
    if (shouldRelease) _availableBalance += cancelled.amount;
    notifyListeners();
  }

  void _applyPayoutAccountLocally(PayoutAccount account) {
    final updated = <PayoutAccount>[account];
    for (final current in payoutAccounts) {
      if (current.id == account.id) continue;
      if (!account.isDefault || !current.isDefault) {
        updated.add(current);
        continue;
      }
      updated.add(
        PayoutAccount(
          id: current.id,
          provider: current.provider,
          accountHolderName: current.accountHolderName,
          accountIdentifier: current.accountIdentifier,
          identifierLast4: current.identifierLast4,
          isVerified: current.isVerified,
          isDefault: false,
        ),
      );
    }
    payoutAccounts = updated;
    notifyListeners();
  }

  void _setSeller(Seller value) {
    seller = value;
    final language = AppLanguage.values.firstWhere(
      (item) => item.name == value.locale,
      orElse: () => appSettings.language,
    );
    appSettings.setLanguage(language);
  }

  void _touchLastActiveBestEffort() {
    final now = DateTime.now();
    final previous = _lastActiveTouch;
    if (previous != null &&
        now.difference(previous) < const Duration(minutes: 5)) {
      return;
    }
    _lastActiveTouch = now;
    unawaited(
      _repositories.profile.touchLastActive().catchError((_) {
        // Presence is best-effort and must never block actual app data.
      }),
    );
  }

  void _registerDeviceBestEffort() {
    unawaited(_deviceTokens.registerCurrentDevice().catchError((_) {}));
  }

  void _handleForegroundPush(PushMessage message) {
    if (!auth.hasSession) return;
    unawaited(_refreshNotificationsBestEffort());

    final event = message.openEvent;
    final type = event.targetType?.trim().toLowerCase();
    final deepTarget = parseTrustedNotificationDeepLink(event.deepLink);
    final targetsReferral =
        type == 'referral' ||
        deepTarget?.kind == NotificationDeepLinkKind.referrals;
    final targetsPromotion =
        targetsReferral ||
        event.promotionId != null ||
        type == 'promotion' ||
        type == 'reward' ||
        deepTarget?.kind == NotificationDeepLinkKind.promotions;
    if (targetsPromotion) {
      unawaited(
        _refreshPromotionEngagementBestEffort(
          includeReferralSummary: targetsReferral && referralSummaryLoaded,
        ),
      );
    }
  }

  bool _notificationTargetsReferrals(AppNotification notification) {
    final type = notification.targetType?.trim().toLowerCase();
    final deepTarget = parseTrustedNotificationDeepLink(notification.deepLink);
    return notification.type == NotificationType.referral ||
        type == 'referral' ||
        deepTarget?.kind == NotificationDeepLinkKind.referrals;
  }

  bool _notificationTargetsPromotionEngagement(AppNotification notification) {
    if (_notificationTargetsReferrals(notification)) return true;
    final type = notification.targetType?.trim().toLowerCase();
    final deepTarget = parseTrustedNotificationDeepLink(notification.deepLink);
    return notification.targetPromotionId != null ||
        notification.type == NotificationType.promotion ||
        notification.type == NotificationType.reward ||
        type == 'promotion' ||
        type == 'reward' ||
        deepTarget?.kind == NotificationDeepLinkKind.promotions;
  }

  Future<void> _refreshPromotionEngagementBestEffort({
    bool includeReferralSummary = false,
  }) async {
    final scope = _captureAuthenticatedScope();
    if (scope == null || seller.status != AccountStatus.approved) return;
    await _refreshPromotionEngagementForScopeBestEffort(
      scope,
      includeReferralSummary: includeReferralSummary,
    );
  }

  Future<void> _refreshPromotionEngagementForScopeBestEffort(
    _AuthenticatedRequestScope scope, {
    bool includeReferralSummary = false,
  }) async {
    try {
      await _refreshPromotionGrantsForScope(scope);
    } catch (_) {
      // Realtime, the next resume or pull-to-refresh will retry.
    }
    if (!includeReferralSummary || !_isCurrent(scope)) return;
    try {
      await _refreshReferralSummaryForScope(scope);
    } catch (_) {
      // The referral screen retains its previous usable summary.
    }
  }

  Future<void> _refreshReferralSummaryBestEffort() async {
    try {
      await refreshReferralSummary();
    } catch (_) {
      // A later grant event, resume or manual refresh will retry.
    }
  }

  Future<void> _refreshNotificationsBestEffort() async {
    try {
      await refreshNotifications();
    } catch (_) {
      // The durable row will be picked up by the next normal refresh.
    }
  }

  String _newRequestId() => newUuidV4();

  Seller _emptySeller() => Seller(
    id: '',
    name: '',
    phone: '',
    storeName: '',
    instagramUrl: '',
    governorateId: '',
    status: AccountStatus.pending,
    joinedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  String _messageFor(Object error) => switch (error) {
    BackendException(:final message) => message,
    _ => 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.',
  };
}

class _AuthenticatedRequestScope {
  const _AuthenticatedRequestScope({
    required this.generation,
    required this.userId,
    required this.repositories,
  });

  final int generation;
  final String userId;
  final AppRepositories repositories;
}

final AppSession session = AppSession.instance;
