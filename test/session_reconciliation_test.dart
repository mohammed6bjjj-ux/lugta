import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/routes.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/auth/account_blocked_screen.dart';
import 'package:flutter_app/features/auth/account_deleted_screen.dart';
import 'package:flutter_app/features/auth/login_screen.dart';
import 'package:flutter_app/features/auth/pending_approval_screen.dart';
import 'package:flutter_app/features/shell/main_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
  });

  test(
    'a profile-inclusive refresh runs after an in-flight weaker refresh',
    () async {
      final base = createDemoRepositories();
      await base.auth.signIn(phone: '07700000000', password: 'test-password');
      final profile = _MutableProfileRepository(base.profile);
      final orders = _BlockingOrdersRepository(base.orders);
      await session.configure(
        _repositories(base, profile: profile, orders: orders),
        loadInitialData: false,
      );
      await session.refreshAuthenticatedData();
      expect(profile.fetchCount, 1);

      orders.pauseNextFetch();
      final weaker = session.refreshAuthenticatedData(refreshProfile: false);
      await orders.pausedFetchStarted.future;
      final stronger = session.refreshAuthenticatedData(refreshProfile: true);

      expect(identical(weaker, stronger), isFalse);
      expect(profile.fetchCount, 1);

      orders.releasePausedFetch();
      await Future.wait([weaker, stronger]);
      expect(profile.fetchCount, 2);
    },
  );

  test(
    'resume reconciliation is throttled but can be explicitly retried',
    () async {
      final base = createDemoRepositories();
      await base.auth.signIn(phone: '07700000000', password: 'test-password');
      final profile = _MutableProfileRepository(base.profile);
      await session.configure(
        _repositories(base, profile: profile),
        loadInitialData: false,
      );

      await session.reconcileAfterResume(minimumInterval: Duration.zero);
      expect(profile.fetchCount, 1);

      await session.reconcileAfterResume();
      expect(profile.fetchCount, 1);

      await session.reconcileAfterResume(minimumInterval: Duration.zero);
      expect(profile.fetchCount, 2);
    },
  );

  test(
    'catalog is published before a failing wallet refresh settles',
    () async {
      final base = createDemoRepositories();
      await base.auth.signIn(phone: '07700000000', password: 'test-password');
      final profile = _MutableProfileRepository(base.profile);
      final wallet = _BlockingFailingWalletRepository(base.wallet);
      await session.configure(
        _repositories(base, profile: profile, wallet: wallet),
        loadInitialData: false,
      );

      final catalogPublished = Completer<void>();
      void observeCatalog() {
        if (session.categories.isNotEmpty && session.products.isNotEmpty) {
          if (!catalogPublished.isCompleted) catalogPublished.complete();
        }
      }

      session.addListener(observeCatalog);
      addTearDown(() => session.removeListener(observeCatalog));

      final refresh = session.refreshAuthenticatedData();
      await wallet.fetchStarted.future;
      await catalogPublished.future.timeout(const Duration(seconds: 1));

      expect(session.categories, isNotEmpty);
      expect(session.products, isNotEmpty);
      expect(wallet.release.isCompleted, isFalse);

      wallet.fail();
      await expectLater(refresh, throwsA(isA<StateError>()));

      expect(session.categories, isNotEmpty);
      expect(session.products, isNotEmpty);
      expect(session.lastError, isNotNull);
    },
  );

  test(
    'products remain visible when the independent categories read fails',
    () async {
      final base = createDemoRepositories();
      await base.auth.signIn(phone: '07700000000', password: 'test-password');
      final profile = _MutableProfileRepository(base.profile);
      final catalog = _PartiallyFailingCatalogRepository(
        base.catalog,
        failCategories: true,
      );
      await session.configure(
        _repositories(base, profile: profile, catalog: catalog),
        loadInitialData: false,
      );

      await expectLater(
        session.refreshAuthenticatedData(),
        throwsA(isA<StateError>()),
      );

      expect(session.products, isNotEmpty);
      expect(session.categories, isEmpty);
      expect(session.lastError, isNotNull);
    },
  );

  test(
    'banners remain visible when the independent delivery-zone read fails',
    () async {
      final base = createDemoRepositories();
      final profile = _MutableProfileRepository(base.profile);
      final catalog = _PartiallyFailingCatalogRepository(
        base.catalog,
        failDeliveryZones: true,
      );
      await session.configure(
        _repositories(base, profile: profile, catalog: catalog),
        loadInitialData: false,
      );

      await expectLater(
        session.refreshPublicData(),
        throwsA(isA<StateError>()),
      );

      expect(session.banners, isNotEmpty);
      expect(session.governorates, isEmpty);
      expect(session.lastError, isNotNull);
    },
  );

  test(
    'a realtime event during an older catalog read queues a trailing refresh',
    () async {
      final base = createDemoRepositories();
      await base.auth.signIn(phone: '07700000000', password: 'test-password');
      final profile = _MutableProfileRepository(base.profile);
      final catalog = _BlockingRealtimeCatalogRepository(base.catalog);
      addTearDown(catalog.dispose);
      await session.configure(
        _repositories(base, profile: profile, catalog: catalog),
        loadInitialData: false,
      );
      await session.refreshAuthenticatedData();
      expect(catalog.productFetchCount, 1);

      catalog.pauseNextProductFetch();
      final olderRefresh = session.refreshCatalog();
      await catalog.pausedFetchStarted.future;
      catalog.emitChange();

      // Catalog invalidations are deliberately spread by 700-1900ms across
      // devices. Wait until its worker has joined the blocked older request.
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(catalog.productFetchCount, 2);

      catalog.releasePausedFetch();
      await olderRefresh;
      await catalog.thirdFetchStarted.future.timeout(
        const Duration(seconds: 2),
      );
      expect(catalog.productFetchCount, 3);
      await catalog.thirdFetchCompleted.future.timeout(
        const Duration(seconds: 2),
      );
    },
  );

  testWidgets(
    'protected routes react to logout and every non-approved account state',
    (tester) async {
      final base = createDemoRepositories();
      await tester.runAsync(
        () => base.auth.signIn(phone: '07700000000', password: 'test-password'),
      );
      final profile = _MutableProfileRepository(base.profile);
      await tester.runAsync(
        () => session.configure(
          _repositories(base, profile: profile),
          loadInitialData: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-protected-shell'),
              onPressed: () => Navigator.pushNamed(context, Routes.shell),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-protected-shell')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(MainShell), findsOneWidget);

      profile.current = _seller(AccountStatus.pending);
      await tester.runAsync(
        () => session.reconcileAfterResume(minimumInterval: Duration.zero),
      );
      await tester.pump();
      expect(find.byType(PendingApprovalScreen), findsOneWidget);
      expect(session.availableBalance, 0);
      expect(session.payoutAccounts, isEmpty);
      expect(session.statementLines, isEmpty);

      profile.current = _seller(AccountStatus.blocked);
      await tester.runAsync(
        () => session.reconcileAfterResume(minimumInterval: Duration.zero),
      );
      await tester.pump();
      expect(find.byType(AccountBlockedScreen), findsOneWidget);

      profile.current = _seller(AccountStatus.deleted);
      await tester.runAsync(
        () => session.reconcileAfterResume(minimumInterval: Duration.zero),
      );
      await tester.pump();
      expect(find.byType(AccountDeletedScreen), findsOneWidget);

      await tester.runAsync(base.auth.signOut);
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

AppRepositories _repositories(
  AppRepositories base, {
  required ProfileRepository profile,
  CatalogRepository? catalog,
  OrdersRepository? orders,
  WalletRepository? wallet,
}) => AppRepositories(
  auth: base.auth,
  profile: profile,
  catalog: catalog ?? base.catalog,
  orders: orders ?? base.orders,
  wallet: wallet ?? base.wallet,
  notifications: base.notifications,
  isDemo: false,
);

Seller _seller(AccountStatus status) => Seller(
  id: 'seller-1',
  name: 'Seller',
  phone: '+9647700000000',
  storeName: 'Store',
  instagramUrl: '',
  governorateId: 'baghdad',
  status: status,
  statusReason: status == AccountStatus.blocked ? 'Blocked for test' : null,
  joinedAt: DateTime.utc(2026),
);

class _MutableProfileRepository implements ProfileRepository {
  _MutableProfileRepository(this._delegate)
    : current = _seller(AccountStatus.approved);

  final ProfileRepository _delegate;
  Seller current;
  int fetchCount = 0;

  @override
  Future<Seller> fetchCurrentProfile() async {
    fetchCount += 1;
    return current;
  }

  @override
  Future<AccountDeletionRequest?> fetchLatestAccountDeletionRequest() =>
      _delegate.fetchLatestAccountDeletionRequest();

  @override
  Future<Seller> updateCurrentProfile({
    required String name,
    required String storeName,
    required String instagramUrl,
  }) async {
    current = Seller(
      id: current.id,
      name: name,
      phone: current.phone,
      storeName: storeName,
      instagramUrl: instagramUrl,
      governorateId: current.governorateId,
      status: current.status,
      statusReason: current.statusReason,
      joinedAt: current.joinedAt,
      locale: current.locale,
      notificationPreferences: current.notificationPreferences,
    );
    return current;
  }

  @override
  Future<Seller> updateSettings({
    required String locale,
    required Map<String, bool> notificationPreferences,
  }) async {
    current = Seller(
      id: current.id,
      name: current.name,
      phone: current.phone,
      storeName: current.storeName,
      instagramUrl: current.instagramUrl,
      governorateId: current.governorateId,
      status: current.status,
      statusReason: current.statusReason,
      joinedAt: current.joinedAt,
      locale: locale,
      notificationPreferences: notificationPreferences,
    );
    return current;
  }

  @override
  Future<AccountDeletionRequest> requestAccountDeletion({
    required String reason,
    required String clientRequestId,
  }) => _delegate.requestAccountDeletion(
    reason: reason,
    clientRequestId: clientRequestId,
  );

  @override
  Future<AccountDeletionRequest> cancelAccountDeletion({
    required String requestId,
    required String clientRequestId,
  }) => _delegate.cancelAccountDeletion(
    requestId: requestId,
    clientRequestId: clientRequestId,
  );

  @override
  Future<void> touchLastActive() => _delegate.touchLastActive();
}

class _BlockingOrdersRepository implements OrdersRepository {
  _BlockingOrdersRepository(this._delegate);

  final OrdersRepository _delegate;
  Completer<void>? _release;
  bool _pauseNext = false;
  Completer<void> pausedFetchStarted = Completer<void>();

  void pauseNextFetch() {
    _pauseNext = true;
    _release = Completer<void>();
    pausedFetchStarted = Completer<void>();
  }

  void releasePausedFetch() {
    final release = _release;
    if (release != null && !release.isCompleted) release.complete();
  }

  @override
  Future<List<Order>> fetchOrders() async {
    final release = _pauseNext ? _release : null;
    if (release != null) {
      _pauseNext = false;
      pausedFetchStarted.complete();
      await release.future;
    }
    return _delegate.fetchOrders();
  }

  @override
  Future<Order> fetchOrder(String orderId) => _delegate.fetchOrder(orderId);

  @override
  Future<Order> createOrder(CreateOrderRequest request) =>
      _delegate.createOrder(request);

  @override
  Future<void> cancelOrder(String orderId, {required String clientRequestId}) =>
      _delegate.cancelOrder(orderId, clientRequestId: clientRequestId);

  @override
  Future<void> submitChangeRequest({
    required String orderId,
    required OrderChangeRequestType type,
    required String reason,
    required Map<String, dynamic> proposedChanges,
    required String clientRequestId,
  }) => _delegate.submitChangeRequest(
    orderId: orderId,
    type: type,
    reason: reason,
    proposedChanges: proposedChanges,
    clientRequestId: clientRequestId,
  );

  @override
  Future<OrderComplaint> createComplaint({
    required String orderId,
    required OrderComplaintKind kind,
    required String subject,
    required String message,
    required String clientRequestId,
  }) => _delegate.createComplaint(
    orderId: orderId,
    kind: kind,
    subject: subject,
    message: message,
    clientRequestId: clientRequestId,
  );
}

class _BlockingFailingWalletRepository implements WalletRepository {
  _BlockingFailingWalletRepository(this._delegate);

  final WalletRepository _delegate;
  final Completer<void> fetchStarted = Completer<void>();
  final Completer<void> release = Completer<void>();

  void fail() {
    if (!release.isCompleted) release.complete();
  }

  @override
  Future<WalletSnapshot> fetchWallet() async {
    if (!fetchStarted.isCompleted) fetchStarted.complete();
    await release.future;
    throw StateError('wallet unavailable');
  }

  @override
  Stream<void> watchWalletChanges() => _delegate.watchWalletChanges();

  @override
  Future<List<PayoutAccount>> fetchPayoutAccounts() =>
      _delegate.fetchPayoutAccounts();

  @override
  Future<PayoutAccount> upsertPayoutAccount(SavePayoutAccountRequest request) =>
      _delegate.upsertPayoutAccount(request);

  @override
  Future<void> deletePayoutAccount(String accountId) =>
      _delegate.deletePayoutAccount(accountId);

  @override
  Future<Withdrawal> requestWithdrawal(CreateWithdrawalRequest request) =>
      _delegate.requestWithdrawal(request);

  @override
  Future<Withdrawal> cancelWithdrawal(
    String withdrawalId, {
    required String clientRequestId,
  }) => _delegate.cancelWithdrawal(
    withdrawalId,
    clientRequestId: clientRequestId,
  );
}

class _BlockingRealtimeCatalogRepository implements CatalogRepository {
  _BlockingRealtimeCatalogRepository(this._delegate);

  final CatalogRepository _delegate;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  Completer<void>? _release;
  bool _pauseNext = false;
  Completer<void> pausedFetchStarted = Completer<void>();
  final Completer<void> thirdFetchStarted = Completer<void>();
  final Completer<void> thirdFetchCompleted = Completer<void>();
  int productFetchCount = 0;

  void pauseNextProductFetch() {
    _pauseNext = true;
    _release = Completer<void>();
    pausedFetchStarted = Completer<void>();
  }

  void releasePausedFetch() {
    final release = _release;
    if (release != null && !release.isCompleted) release.complete();
  }

  void emitChange() => _changes.add(null);

  Future<void> dispose() => _changes.close();

  @override
  Future<List<Category>> fetchCategories() => _delegate.fetchCategories();

  @override
  Future<List<Product>> fetchProducts() async {
    productFetchCount += 1;
    final fetchNumber = productFetchCount;
    if (fetchNumber >= 3 && !thirdFetchStarted.isCompleted) {
      thirdFetchStarted.complete();
    }
    final release = _pauseNext ? _release : null;
    if (release != null) {
      _pauseNext = false;
      pausedFetchStarted.complete();
      await release.future;
    }
    final products = await _delegate.fetchProducts();
    if (fetchNumber >= 3 && !thirdFetchCompleted.isCompleted) {
      thirdFetchCompleted.complete();
    }
    return products;
  }

  @override
  Future<Product> fetchProduct(String productId) =>
      _delegate.fetchProduct(productId);

  @override
  Stream<void> watchCatalogChanges() => _changes.stream;

  @override
  Future<List<Governorate>> fetchDeliveryZones() =>
      _delegate.fetchDeliveryZones();

  @override
  Future<List<PackagingBox>> fetchPackagingBoxes() =>
      _delegate.fetchPackagingBoxes();

  @override
  Future<DeliveryQuote> quoteDeliveryFee(String deliveryZoneId) =>
      _delegate.quoteDeliveryFee(deliveryZoneId);

  @override
  Future<PublicContentSnapshot> fetchPublicContent() =>
      _delegate.fetchPublicContent();

  @override
  Future<Set<String>> fetchFavoriteProductIds() =>
      _delegate.fetchFavoriteProductIds();

  @override
  Future<Set<String>> fetchStockAlertProductIds() =>
      _delegate.fetchStockAlertProductIds();

  @override
  Future<void> setFavorite(String productId, {required bool enabled}) =>
      _delegate.setFavorite(productId, enabled: enabled);

  @override
  Future<void> setStockAlert(String productId, {required bool enabled}) =>
      _delegate.setStockAlert(productId, enabled: enabled);
}

class _PartiallyFailingCatalogRepository implements CatalogRepository {
  _PartiallyFailingCatalogRepository(
    this._delegate, {
    this.failCategories = false,
    this.failDeliveryZones = false,
  });

  final CatalogRepository _delegate;
  final bool failCategories;
  final bool failDeliveryZones;

  @override
  Future<List<Category>> fetchCategories() => failCategories
      ? Future<List<Category>>.error(StateError('categories unavailable'))
      : _delegate.fetchCategories();

  @override
  Future<List<Product>> fetchProducts() => _delegate.fetchProducts();

  @override
  Future<Product> fetchProduct(String productId) =>
      _delegate.fetchProduct(productId);

  @override
  Stream<void> watchCatalogChanges() => _delegate.watchCatalogChanges();

  @override
  Future<List<Governorate>> fetchDeliveryZones() => failDeliveryZones
      ? Future<List<Governorate>>.error(
          StateError('delivery zones unavailable'),
        )
      : _delegate.fetchDeliveryZones();

  @override
  Future<List<PackagingBox>> fetchPackagingBoxes() =>
      _delegate.fetchPackagingBoxes();

  @override
  Future<DeliveryQuote> quoteDeliveryFee(String deliveryZoneId) =>
      _delegate.quoteDeliveryFee(deliveryZoneId);

  @override
  Future<PublicContentSnapshot> fetchPublicContent() =>
      _delegate.fetchPublicContent();

  @override
  Future<Set<String>> fetchFavoriteProductIds() =>
      _delegate.fetchFavoriteProductIds();

  @override
  Future<Set<String>> fetchStockAlertProductIds() =>
      _delegate.fetchStockAlertProductIds();

  @override
  Future<void> setFavorite(String productId, {required bool enabled}) =>
      _delegate.setFavorite(productId, enabled: enabled);

  @override
  Future<void> setStockAlert(String productId, {required bool enabled}) =>
      _delegate.setStockAlert(productId, enabled: enabled);
}
