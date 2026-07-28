import 'dart:async';

import '../../core/external_actions.dart';
import '../../core/phone_number.dart';
import '../mock_data.dart';
import '../models.dart';
import 'repositories.dart';

AppRepositories createDemoRepositories() {
  final auth = DemoAuthRepository();
  final profile = DemoProfileRepository();
  final catalog = DemoCatalogRepository();
  final orders = DemoOrdersRepository(() => profile.seller);
  final wallet = DemoWalletRepository(() => orders.currentOrders);
  final notifications = DemoNotificationsRepository();
  return AppRepositories(
    auth: auth,
    profile: profile,
    catalog: catalog,
    orders: orders,
    wallet: wallet,
    notifications: notifications,
    isDemo: true,
  );
}

class DemoAuthRepository implements AuthRepository {
  final StreamController<String?> _userIdChanges =
      StreamController<String?>.broadcast(sync: true);
  bool _hasSession = false;
  String? _userId;
  bool _passwordRecoveryActive = false;

  @override
  bool get hasSession => _hasSession && !_passwordRecoveryActive;

  @override
  String? get currentUserId => hasSession ? _userId : null;

  @override
  Stream<String?> get userIdChanges =>
      _userIdChanges.stream.map((_) => currentUserId).distinct();

  @override
  Future<void> signIn({required String phone, required String password}) async {
    normalizeIraqiPhone(phone);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _hasSession = true;
    _passwordRecoveryActive = false;
    _userId = MockData.seller.id;
    _userIdChanges.add(_userId);
  }

  @override
  Future<void> signUp(RegistrationRequest request) async {
    normalizeIraqiPhone(request.phone);
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  @override
  Future<bool> completePendingRegistration() async => false;

  @override
  Future<void> verifyOtp({
    required String phone,
    required String token,
    required OtpPurpose purpose,
  }) async {
    normalizeIraqiPhone(phone);
    if (token.length != 6) {
      throw const BackendException('رمز التحقق يجب أن يتكون من 6 أرقام.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (purpose == OtpPurpose.passwordRecovery && !_passwordRecoveryActive) {
      throw const BackendException(
        'انتهت جلسة استعادة كلمة المرور. أعد طلب الرمز.',
      );
    }
    _hasSession = true;
    _userId = MockData.seller.id;
    _userIdChanges.add(_userId);
  }

  @override
  Future<void> resendOtp({
    required String phone,
    required OtpPurpose purpose,
  }) async {
    normalizeIraqiPhone(phone);
  }

  @override
  Future<void> sendPasswordRecoveryOtp(String phone) async {
    normalizeIraqiPhone(phone);
    _passwordRecoveryActive = true;
  }

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> abandonPasswordRecovery() async {
    if (!_passwordRecoveryActive) return;
    if (_hasSession) await signOut();
    _passwordRecoveryActive = false;
  }

  @override
  Future<void> signOut() async {
    _hasSession = false;
    _passwordRecoveryActive = false;
    _userId = null;
    _userIdChanges.add(null);
  }
}

class DemoProfileRepository implements ProfileRepository {
  Seller seller = MockData.seller;
  AccountDeletionRequest? _deletionRequest;

  @override
  Future<Seller> fetchCurrentProfile() async => seller;

  @override
  Future<Seller> updateCurrentProfile({
    required String name,
    required String storeName,
    required String instagramUrl,
  }) async {
    final normalizedInstagram = instagramUrl.trim().isEmpty
        ? ''
        : normalizeInstagramProfile(instagramUrl);
    if (normalizedInstagram == null) {
      throw const BackendException(
        'رابط إنستغرام غير صالح. استخدم اسم المستخدم أو رابط الصفحة فقط.',
        code: 'invalid_instagram_profile',
      );
    }
    seller = seller.copyWith(
      name: name,
      storeName: storeName,
      instagramUrl: normalizedInstagram,
    );
    return seller;
  }

  @override
  Future<Seller> updateSettings({
    required String locale,
    required Map<String, bool> notificationPreferences,
  }) async {
    seller = seller.copyWith(
      locale: locale,
      notificationPreferences: notificationPreferences,
    );
    return seller;
  }

  @override
  Future<AccountDeletionRequest?> fetchLatestAccountDeletionRequest() async =>
      _deletionRequest;

  @override
  Future<AccountDeletionRequest> requestAccountDeletion({
    required String reason,
    required String clientRequestId,
  }) async {
    final existing = _deletionRequest;
    if (existing?.status == AccountDeletionStatus.pending) return existing!;
    return _deletionRequest = AccountDeletionRequest(
      id: 'deletion-${DateTime.now().microsecondsSinceEpoch}',
      status: AccountDeletionStatus.pending,
      reason: reason,
      requestedAt: DateTime.now(),
    );
  }

  @override
  Future<AccountDeletionRequest> cancelAccountDeletion({
    required String requestId,
    required String clientRequestId,
  }) async {
    final current = _deletionRequest;
    if (current == null || current.status != AccountDeletionStatus.pending) {
      throw const BackendException('لا يوجد طلب حذف معلّق لإلغائه.');
    }
    return _deletionRequest = AccountDeletionRequest(
      id: current.id,
      status: AccountDeletionStatus.cancelled,
      reason: current.reason,
      requestedAt: current.requestedAt,
      cancelledAt: DateTime.now(),
    );
  }

  @override
  Future<void> touchLastActive() async {}
}

class DemoCatalogRepository implements CatalogRepository {
  final Set<String> _favorites = {
    'p-smart-pro',
    'p-sun-lady',
    'p-classic-leather',
  };
  final Set<String> _stockAlerts = {};

  @override
  Future<List<Category>> fetchCategories() async =>
      List.of(MockData.categories);

  @override
  Future<List<Product>> fetchProducts() async => List.of(MockData.products);

  @override
  Future<Product> fetchProduct(String productId) async =>
      MockData.products.firstWhere((product) => product.id == productId);

  @override
  Stream<void> watchCatalogChanges() => const Stream<void>.empty();

  @override
  Future<List<Governorate>> fetchDeliveryZones() async =>
      List.of(MockData.governorates);

  @override
  Future<PublicContentSnapshot> fetchPublicContent() async =>
      PublicContentSnapshot(
        banners: List.of(MockData.banners),
        faq: List.of(MockData.faq),
        policiesText: MockData.policiesText,
        supportPhone: MockData.supportPhone,
        supportWhatsapp: MockData.supportWhatsapp,
        termsVersion: 'demo-v1',
      );

  @override
  Future<Set<String>> fetchFavoriteProductIds() async => Set.of(_favorites);

  @override
  Future<Set<String>> fetchStockAlertProductIds() async => Set.of(_stockAlerts);

  @override
  Future<void> setFavorite(String productId, {required bool enabled}) async {
    enabled ? _favorites.add(productId) : _favorites.remove(productId);
  }

  @override
  Future<void> setStockAlert(String productId, {required bool enabled}) async {
    enabled ? _stockAlerts.add(productId) : _stockAlerts.remove(productId);
  }
}

class DemoOrdersRepository implements OrdersRepository {
  DemoOrdersRepository(this._seller);

  final Seller Function() _seller;
  final List<Order> _orders = List.of(MockData.orders);
  int _serial = 1051;

  List<Order> get currentOrders => List.unmodifiable(_orders);

  @override
  Future<List<Order>> fetchOrders() async => List.of(_orders);

  @override
  Future<Order> fetchOrder(String orderId) async =>
      _orders.firstWhere((order) => order.id == orderId);

  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    final serial = _serial++;
    final now = DateTime.now();
    final seller = _seller();
    final order = Order(
      id: 'o-$serial',
      code: 'ORD-$serial',
      productId: request.product.id,
      productName: request.product.nameAr,
      productImage: request.product.coverImage,
      items: [
        for (final draft in request.items)
          OrderItem(
            variantId: draft.variant.id,
            variantName: draft.variant.nameAr,
            imageUrl: draft.variant.imageUrl,
            quantity: draft.quantity,
          ),
      ],
      wholesalePrice: request.product.wholesalePrice,
      unitSalePrice: request.unitSalePrice,
      deliveryFee: request.governorate.deliveryFee,
      customerName: request.customerName,
      customerPhone: request.customerPhone,
      customerPhone2: request.customerPhone2,
      governorateName: request.governorate.nameAr,
      regionName: '',
      addressDetails: request.addressDetails,
      notes: request.notes,
      status: OrderStatus.pendingReview,
      statusHistory: [
        OrderStatusEntry(status: OrderStatus.pendingReview, at: now),
      ],
      createdAt: now,
      storeNameSnapshot: seller.storeName,
      sellerPhoneSnapshot: seller.phone,
    );
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<void> cancelOrder(
    String orderId, {
    required String clientRequestId,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1 || !_orders[index].status.sellerCanCancelDirectly) return;
    final order = _orders[index];
    _orders[index] = order.copyWith(
      status: OrderStatus.cancelled,
      statusHistory: [
        ...order.statusHistory,
        OrderStatusEntry(
          status: OrderStatus.cancelled,
          at: DateTime.now(),
          note: 'ألغى البائع الطلب قبل التأكيد',
        ),
      ],
    );
  }

  @override
  Future<void> submitChangeRequest({
    required String orderId,
    required OrderChangeRequestType type,
    required String reason,
    required Map<String, dynamic> proposedChanges,
    required String clientRequestId,
  }) async {}
}

class DemoWalletRepository implements WalletRepository {
  DemoWalletRepository(this._orders);

  final List<Order> Function() _orders;
  final List<WalletTransaction> _transactions = List.of(MockData.transactions);
  final List<Withdrawal> _withdrawals = List.of(MockData.withdrawals);
  int _available = 92000;
  final List<PayoutAccount> _payoutAccounts = [
    const PayoutAccount(
      id: 'demo-zain',
      provider: 'zain_cash',
      accountHolderName: 'أحمد الياسري',
      accountIdentifier: '07712345678',
      identifierLast4: '5678',
      isVerified: true,
      isDefault: true,
    ),
  ];

  @override
  Future<WalletSnapshot> fetchWallet() async => WalletSnapshot(
    available: _available,
    pending: _orders()
        .where((order) => order.status.holdsPendingProfit)
        .fold(0, (sum, order) => sum + order.profit),
    totalEarned: _orders()
        .where((order) => order.status == OrderStatus.completed)
        .fold(0, (sum, order) => sum + order.profit),
    minimumWithdrawal: MockData.minWithdrawalAmount,
    withdrawalFees: const <String, int>{'zain_cash': 0, 'superqi': 0},
    transactions: List.of(_transactions),
    withdrawals: List.of(_withdrawals),
    payoutAccounts: List.of(_payoutAccounts),
    statementLines: [
      for (final order in _orders())
        for (final (index, item) in order.items.indexed)
          AccountStatementLine(
            orderItemId: '${order.id}-$index',
            orderId: order.id,
            orderCode: order.code,
            orderStatus: order.status,
            orderCreatedAt: order.createdAt,
            completedAt: order.status == OrderStatus.completed
                ? order.statusHistory.last.at
                : null,
            productNameAr: order.productName,
            variantNameAr: item.variantName,
            quantity: item.quantity,
            unitWholesalePrice: item.wholesaleUnitPrice ?? order.wholesalePrice,
            unitSalePrice: item.saleUnitPrice ?? order.unitSalePrice,
            unitProfit:
                (item.saleUnitPrice ?? order.unitSalePrice) -
                (item.wholesaleUnitPrice ?? order.wholesalePrice),
            lineWholesaleTotal:
                (item.wholesaleUnitPrice ?? order.wholesalePrice) *
                item.quantity,
            lineSaleTotal:
                (item.saleUnitPrice ?? order.unitSalePrice) * item.quantity,
            lineProfitTotal:
                ((item.saleUnitPrice ?? order.unitSalePrice) -
                    (item.wholesaleUnitPrice ?? order.wholesalePrice)) *
                item.quantity,
          ),
    ],
    withdrawalSources: const [],
  );

  @override
  Stream<void> watchWalletChanges() => const Stream<void>.empty();

  @override
  Future<List<PayoutAccount>> fetchPayoutAccounts() async =>
      List.of(_payoutAccounts);

  @override
  Future<PayoutAccount> upsertPayoutAccount(
    SavePayoutAccountRequest request,
  ) async {
    final id =
        request.accountId ?? 'payout-${DateTime.now().microsecondsSinceEpoch}';
    if (request.makeDefault) {
      for (var index = 0; index < _payoutAccounts.length; index++) {
        final item = _payoutAccounts[index];
        _payoutAccounts[index] = PayoutAccount(
          id: item.id,
          provider: item.provider,
          accountHolderName: item.accountHolderName,
          accountIdentifier: item.accountIdentifier,
          identifierLast4: item.identifierLast4,
          isVerified: item.isVerified,
          isDefault: false,
        );
      }
    }
    final digits = request.accountIdentifier.replaceAll(RegExp(r'\D'), '');
    final account = PayoutAccount(
      id: id,
      provider: request.provider,
      accountHolderName: request.accountHolderName,
      accountIdentifier: request.accountIdentifier,
      identifierLast4: digits.length <= 4
          ? digits
          : digits.substring(digits.length - 4),
      isVerified: false,
      isDefault: request.makeDefault,
    );
    _payoutAccounts.removeWhere((item) => item.id == id);
    _payoutAccounts.insert(0, account);
    return account;
  }

  @override
  Future<void> deletePayoutAccount(String accountId) async {
    _payoutAccounts.removeWhere((item) => item.id == accountId);
  }

  @override
  Future<Withdrawal> requestWithdrawal(CreateWithdrawalRequest request) async {
    if (request.amount > _available) {
      throw const BackendException('الرصيد المتاح لا يكفي لهذا السحب.');
    }
    final now = DateTime.now();
    final withdrawal = Withdrawal(
      id: 'wd-${now.microsecondsSinceEpoch}',
      amount: request.amount,
      method: request.method,
      accountDetail: request.accountDetail,
      status: WithdrawalStatus.pending,
      requestedAt: now,
    );
    _available -= request.amount;
    _withdrawals.insert(0, withdrawal);
    _transactions.insert(
      0,
      WalletTransaction(
        id: 'tx-${now.microsecondsSinceEpoch}',
        type: WalletTxType.withdrawal,
        amount: request.amount,
        at: now,
        note: 'سحب عبر ${request.method} — قيد المراجعة',
      ),
    );
    return withdrawal;
  }

  @override
  Future<Withdrawal> cancelWithdrawal(
    String withdrawalId, {
    required String clientRequestId,
  }) async {
    final index = _withdrawals.indexWhere((item) => item.id == withdrawalId);
    if (index < 0 || _withdrawals[index].status != WithdrawalStatus.pending) {
      throw const BackendException('لا يمكن إلغاء طلب السحب بهذه الحالة.');
    }
    final current = _withdrawals[index];
    final cancelled = Withdrawal(
      id: current.id,
      amount: current.amount,
      method: current.method,
      accountDetail: current.accountDetail,
      status: WithdrawalStatus.cancelled,
      requestedAt: current.requestedAt,
      processedAt: DateTime.now(),
    );
    _withdrawals[index] = cancelled;
    _available += current.amount;
    return cancelled;
  }
}

class DemoNotificationsRepository implements NotificationsRepository {
  final List<AppNotification> _notifications = [
    for (final item in MockData.notifications)
      AppNotification(
        id: item.id,
        title: item.title,
        body: item.body,
        type: item.type,
        at: item.at,
        isRead: item.isRead,
        targetOrderId: item.targetOrderId,
        targetProductId: item.targetProductId,
      ),
  ];
  final StreamController<List<AppNotification>> _controller =
      StreamController<List<AppNotification>>.broadcast();

  @override
  Future<List<AppNotification>> fetchNotifications() async =>
      List.of(_notifications);

  @override
  Future<void> markRead(String notificationId) async {
    for (final notification in _notifications) {
      if (notification.id == notificationId) notification.isRead = true;
    }
    _controller.add(List.of(_notifications));
  }

  @override
  Future<void> markAllRead() async {
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    _controller.add(List.of(_notifications));
  }

  @override
  Stream<List<AppNotification>> watchNotifications() => _controller.stream;
}
