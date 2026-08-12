import 'dart:async';

import '../../core/external_actions.dart';
import '../../core/phone_number.dart';
import '../mock_data.dart';
import '../models.dart';
import '../sales_analytics.dart';
import 'repositories.dart';

AppRepositories createDemoRepositories() {
  final auth = DemoAuthRepository();
  final profile = DemoProfileRepository();
  final catalog = DemoCatalogRepository();
  final orders = DemoOrdersRepository(() => profile.seller);
  final wallet = DemoWalletRepository(() => orders.currentOrders);
  final notifications = DemoNotificationsRepository();
  final promotions = DemoPromotionsRepository();
  final loyalty = DemoLoyaltyRepository();
  return AppRepositories(
    auth: auth,
    profile: profile,
    catalog: catalog,
    orders: orders,
    wallet: wallet,
    notifications: notifications,
    promotions: promotions,
    loyalty: loyalty,
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
    ProfileAvatarChange? avatarChange,
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
    final avatarPath = switch (avatarChange?.type) {
      ProfileAvatarChangeType.replace => 'demo/profile-avatar.jpg',
      ProfileAvatarChangeType.remove => '',
      null => seller.avatarPath,
    };
    final avatarUrl = switch (avatarChange?.type) {
      ProfileAvatarChangeType.replace =>
        'https://example.test/demo/profile-avatar.jpg',
      ProfileAvatarChangeType.remove => '',
      null => seller.avatarUrl,
    };
    seller = seller.copyWith(
      name: name,
      storeName: storeName,
      instagramUrl: normalizedInstagram,
      avatarPath: avatarPath,
      avatarUrl: avatarUrl,
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
  Future<List<PackagingBox>> fetchPackagingBoxes() async => const [
    PackagingBox(
      id: 'demo-box-free',
      name: 'علبة قياسية',
      price: 0,
      imageUrl: '',
    ),
    PackagingBox(
      id: 'demo-box-premium',
      name: 'علبة هدية فاخرة',
      price: 5000,
      imageUrl: '',
    ),
  ];

  @override
  Future<DeliveryQuote> quoteDeliveryFee(
    String deliveryZoneId, {
    required int orderSubtotal,
  }) async {
    final governorate = MockData.governorates.firstWhere(
      (item) => item.id == deliveryZoneId,
    );
    return DeliveryQuote(
      baseDeliveryFee: governorate.deliveryFee,
      deliveryFee: governorate.deliveryFee,
      deliveryDiscount: 0,
    );
  }

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
  Future<SalesAnalyticsSnapshot> fetchSalesAnalytics({
    required DateTime from,
    required DateTime to,
  }) async {
    final span = to.difference(from);
    final previousFrom = from.subtract(span);
    final currentOrders = _orders
        .where(
          (order) =>
              !order.createdAt.isBefore(from) && order.createdAt.isBefore(to),
        )
        .toList();
    final previousOrders = _orders
        .where(
          (order) =>
              !order.createdAt.isBefore(previousFrom) &&
              order.createdAt.isBefore(from),
        )
        .toList();
    final granularity = span.inDays <= 35
        ? 'day'
        : span.inDays <= 140
        ? 'week'
        : 'month';

    return SalesAnalyticsSnapshot(
      from: from,
      to: to,
      previousFrom: previousFrom,
      granularity: granularity,
      current: _demoAnalyticsSummary(currentOrders),
      previous: _demoAnalyticsSummary(previousOrders),
      trend: _demoAnalyticsTrend(currentOrders, granularity),
      statuses: _demoAnalyticsStatuses(currentOrders),
      topProducts: _demoAnalyticsTopProducts(currentOrders),
    );
  }

  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    final serial = _serial++;
    final now = DateTime.now();
    final seller = _seller();
    final firstLine = request.lines.first;
    final grossProfit = request.lines.fold<int>(
      0,
      (sum, line) =>
          sum +
          ((line.unitSalePrice -
                  (line.variant.wholesalePriceOverride ??
                      line.product.wholesalePrice)) *
              line.quantity),
    );
    final requestedContribution = request.sellerDeliveryContribution;
    final appliedContribution = requestedContribution
        .clamp(0, request.governorate.deliveryFee)
        .clamp(0, grossProfit)
        .toInt();
    final order = Order(
      id: 'o-$serial',
      code: 'ORD-$serial',
      productId: firstLine.product.id,
      productName: firstLine.product.nameAr,
      productImage: firstLine.product.coverImage,
      items: [
        for (final line in request.lines)
          OrderItem(
            productId: line.product.id,
            productName: line.product.nameAr,
            variantId: line.variant.id,
            variantName: line.variant.nameAr,
            imageUrl: line.variant.imageUrl.trim().isEmpty
                ? line.product.coverImage
                : line.variant.imageUrl,
            quantity: line.quantity,
            wholesaleUnitPrice:
                line.variant.wholesalePriceOverride ??
                line.product.wholesalePrice,
            saleUnitPrice: line.unitSalePrice,
            packagingBoxId: line.packagingBox?.id,
            packagingName: line.packagingBox?.name,
            packagingImageUrl: line.packagingBox?.imageUrl,
            packagingUnitPrice: line.packagingBox?.price ?? 0,
          ),
      ],
      wholesalePrice:
          firstLine.variant.wholesalePriceOverride ??
          firstLine.product.wholesalePrice,
      unitSalePrice: firstLine.unitSalePrice,
      deliveryFee: request.governorate.deliveryFee - appliedContribution,
      baseDeliveryFee: request.governorate.deliveryFee,
      sellerDeliveryContribution: appliedContribution,
      packagingTotal: request.lines.fold(
        0,
        (sum, line) => sum + (line.packagingBox?.price ?? 0) * line.quantity,
      ),
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

  @override
  Future<OrderComplaint> createComplaint({
    required String orderId,
    required OrderComplaintKind kind,
    required String subject,
    required String message,
    required String clientRequestId,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) throw const BackendException('الطلب غير موجود.');
    final complaint = OrderComplaint(
      id: 'demo-complaint-${DateTime.now().microsecondsSinceEpoch}',
      ticketNumber: 'CMP-DEMO',
      orderId: orderId,
      kind: kind,
      subject: subject,
      message: message,
      status: OrderComplaintStatus.open,
      createdAt: DateTime.now(),
    );
    final order = _orders[index];
    _orders[index] = Order(
      id: order.id,
      code: order.code,
      productId: order.productId,
      productName: order.productName,
      productImage: order.productImage,
      items: order.items,
      wholesalePrice: order.wholesalePrice,
      unitSalePrice: order.unitSalePrice,
      deliveryFee: order.deliveryFee,
      baseDeliveryFee: order.baseDeliveryFee,
      deliveryDiscount: order.deliveryDiscount,
      sellerDeliveryContribution: order.sellerDeliveryContribution,
      freeDeliveryReason: order.freeDeliveryReason,
      packagingTotal: order.packagingTotal,
      complaints: [...order.complaints, complaint],
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      customerPhone2: order.customerPhone2,
      governorateName: order.governorateName,
      regionName: order.regionName,
      addressDetails: order.addressDetails,
      landmark: order.landmark,
      notes: order.notes,
      deliveryCompany: order.deliveryCompany,
      trackingNumber: order.trackingNumber,
      status: order.status,
      statusHistory: order.statusHistory,
      failReason: order.failReason,
      createdAt: order.createdAt,
      storeNameSnapshot: order.storeNameSnapshot,
      sellerPhoneSnapshot: order.sellerPhoneSnapshot,
    );
    return complaint;
  }
}

SalesAnalyticsSummary _demoAnalyticsSummary(List<Order> orders) {
  final completed = orders
      .where((order) => order.status == OrderStatus.completed)
      .toList();
  final terminal = orders.where((order) => order.status.isTerminal).length;
  return SalesAnalyticsSummary(
    orderCount: orders.length,
    completedCount: completed.length,
    unsuccessfulCount: orders.where((order) {
      return order.status == OrderStatus.deliveryFailed ||
          order.status == OrderStatus.returned ||
          order.status == OrderStatus.rejected ||
          order.status == OrderStatus.cancelled;
    }).length,
    unitsSold: completed.fold(0, (sum, order) => sum + order.totalQuantity),
    salesTotal: completed.fold(0, (sum, order) => sum + order.saleTotal),
    netProfit: completed.fold(0, (sum, order) => sum + order.profit),
    pendingProfit: orders
        .where((order) => order.status.holdsPendingProfit)
        .fold(0, (sum, order) => sum + order.profit),
    deliveryContribution: orders
        .where(
          (order) =>
              order.status != OrderStatus.returned &&
              order.status != OrderStatus.rejected &&
              order.status != OrderStatus.cancelled,
        )
        .fold(0, (sum, order) => sum + order.sellerDeliveryContribution),
    averageOrderValue: completed.isEmpty
        ? 0
        : (completed.fold<int>(0, (sum, order) => sum + order.saleTotal) /
                  completed.length)
              .round(),
    successRate: terminal == 0 ? 0 : completed.length * 100 / terminal,
  );
}

List<SalesAnalyticsTrendPoint> _demoAnalyticsTrend(
  List<Order> orders,
  String granularity,
) {
  final grouped = <DateTime, List<Order>>{};
  for (final order in orders) {
    final date = order.createdAt;
    final bucket = switch (granularity) {
      'month' => DateTime(date.year, date.month),
      'week' => DateTime(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(days: date.weekday - DateTime.monday)),
      _ => DateTime(date.year, date.month, date.day),
    };
    grouped.putIfAbsent(bucket, () => <Order>[]).add(order);
  }
  final buckets = grouped.keys.toList()..sort();
  return [
    for (final bucket in buckets)
      SalesAnalyticsTrendPoint(
        bucket: bucket,
        orderCount: grouped[bucket]!.length,
        completedCount: grouped[bucket]!
            .where((order) => order.status == OrderStatus.completed)
            .length,
        salesTotal: grouped[bucket]!
            .where((order) => order.status == OrderStatus.completed)
            .fold(0, (sum, order) => sum + order.saleTotal),
        netProfit: grouped[bucket]!
            .where((order) => order.status == OrderStatus.completed)
            .fold(0, (sum, order) => sum + order.profit),
      ),
  ];
}

List<SalesAnalyticsStatusCount> _demoAnalyticsStatuses(List<Order> orders) {
  final counts = <OrderStatus, int>{};
  for (final order in orders) {
    counts.update(order.status, (value) => value + 1, ifAbsent: () => 1);
  }
  final rows = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final row in rows)
      SalesAnalyticsStatusCount(status: row.key, orderCount: row.value),
  ];
}

List<SalesAnalyticsTopProduct> _demoAnalyticsTopProducts(List<Order> orders) {
  final grouped = <String, _DemoProductTotals>{};
  for (final order in orders.where(
    (order) => order.status == OrderStatus.completed,
  )) {
    for (final item in order.items) {
      final id = item.productId.isEmpty ? order.productId : item.productId;
      final totals = grouped.putIfAbsent(
        id,
        () => _DemoProductTotals(
          name: item.productName.isEmpty ? order.productName : item.productName,
        ),
      );
      totals.orderIds.add(order.id);
      totals.units += item.quantity;
      totals.sales +=
          (item.saleUnitPrice ?? order.unitSalePrice) * item.quantity;
      totals.profit +=
          ((item.saleUnitPrice ?? order.unitSalePrice) -
              (item.wholesaleUnitPrice ?? order.wholesalePrice)) *
          item.quantity;
    }
  }
  final rows = grouped.entries.toList()
    ..sort((a, b) => b.value.profit.compareTo(a.value.profit));
  return [
    for (final row in rows.take(5))
      SalesAnalyticsTopProduct(
        productId: row.key,
        nameAr: row.value.name,
        orderCount: row.value.orderIds.length,
        unitsSold: row.value.units,
        salesTotal: row.value.sales,
        netProfit: row.value.profit,
      ),
  ];
}

class _DemoProductTotals {
  _DemoProductTotals({required this.name});

  final String name;
  final Set<String> orderIds = <String>{};
  int units = 0;
  int sales = 0;
  int profit = 0;
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
        targetPromotionId: item.targetPromotionId,
        targetType: item.targetType,
        showPopup: item.showPopup,
        showInbox: item.showInbox,
        popupSeenAt: item.popupSeenAt,
        popupPriority: item.popupPriority,
        expiresAt: item.expiresAt,
        deepLink: item.deepLink,
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
  Future<void> markPopupSeen(String notificationId) async {
    for (final notification in _notifications) {
      if (notification.id == notificationId) {
        notification.popupSeenAt = DateTime.now().toUtc();
      }
    }
    _controller.add(List.of(_notifications));
  }

  @override
  Stream<List<AppNotification>> watchNotifications() => _controller.stream;
}

class DemoPromotionsRepository implements PromotionsRepository {
  @override
  Future<List<PromotionGrant>> fetchPromotionGrants() async =>
      List.of(MockData.promotionGrants);

  @override
  Future<ReferralSummary> fetchReferralSummary() async =>
      MockData.referralSummary;

  @override
  Stream<void> watchPromotionGrantChanges() => const Stream.empty();
}

class DemoLoyaltyRepository implements LoyaltyRepository {
  final List<StockReservation> _stockReservations = <StockReservation>[];
  final Map<String, StockReservation> _stockReservationsByRequestId =
      <String, StockReservation>{};
  int _reservationSequence = 1;

  @override
  Future<LoyaltySummary> fetchLoyaltySummary() async =>
      _summaryWithStockReservations(MockData.loyaltySummary);

  @override
  Future<StockReservation> reserveProductStock({
    required String variantId,
    required int quantity,
    required String clientRequestId,
  }) async {
    if (quantity <= 0 || clientRequestId.trim().isEmpty) {
      throw const BackendException(
        'تعذر تأمين عملية الحجز. حاول مرة أخرى.',
        code: 'invalid_stock_reservation_request',
      );
    }
    final normalizedRequestId = clientRequestId.trim();
    final existing = _stockReservationsByRequestId[normalizedRequestId];
    if (existing != null) return existing;

    Product? product;
    ProductVariant? variant;
    for (final candidate in MockData.products) {
      for (final candidateVariant in candidate.variants) {
        if (candidateVariant.id == variantId) {
          product = candidate;
          variant = candidateVariant;
          break;
        }
      }
      if (variant != null) break;
    }
    if (product == null || variant == null) {
      throw const BackendException(
        'خيار المنتج غير موجود.',
        code: 'variant_not_found',
      );
    }

    final entitlement = MockData.loyaltySummary.currentTier?.stockReservation;
    if (entitlement == null || !entitlement.enabled) {
      throw const BackendException(
        'حجز القطع متاح للمستوى الماسي فقط.',
        code: 'stock_reservation_not_entitled',
      );
    }
    final activeUnits = _activeReservedUnits;
    final remainingUnits = (entitlement.maxActiveUnits - activeUnits)
        .clamp(0, 1 << 31)
        .toInt();
    if (quantity > entitlement.maxPerReservation ||
        quantity > remainingUnits ||
        quantity > variant.stock) {
      throw const BackendException(
        'الكمية المطلوبة تتجاوز الحد المتاح للحجز.',
        code: 'stock_reservation_limit_exceeded',
      );
    }

    final now = DateTime.now();
    final reservation = StockReservation(
      id: 'demo-stock-reservation-${now.microsecondsSinceEpoch}',
      reservationNumber: _reservationSequence++,
      variantId: variant.id,
      productId: product.id,
      productName: product.nameAr,
      variantName: variant.nameAr,
      imageUrl: variant.imageUrl.trim().isEmpty
          ? product.coverImage
          : variant.imageUrl,
      quantity: quantity,
      consumedQuantity: 0,
      releasedQuantity: 0,
      remainingQuantity: quantity,
      status: StockReservationStatus.active,
      expiresAt: now.add(Duration(hours: entitlement.holdHours)),
      createdAt: now,
    );
    _stockReservations.insert(0, reservation);
    _stockReservationsByRequestId[normalizedRequestId] = reservation;
    return reservation;
  }

  @override
  Future<void> releaseProductReservation(String reservationId) async {
    final index = _stockReservations.indexWhere(
      (reservation) => reservation.id == reservationId,
    );
    if (index < 0) {
      throw const BackendException(
        'الحجز غير موجود.',
        code: 'stock_reservation_not_found',
      );
    }
    final reservation = _stockReservations[index];
    if (!reservation.isActive) return;
    _stockReservations[index] = StockReservation(
      id: reservation.id,
      reservationNumber: reservation.reservationNumber,
      variantId: reservation.variantId,
      productId: reservation.productId,
      productName: reservation.productName,
      variantName: reservation.variantName,
      imageUrl: reservation.imageUrl,
      quantity: reservation.quantity,
      consumedQuantity: reservation.consumedQuantity,
      releasedQuantity:
          reservation.releasedQuantity + reservation.remainingQuantity,
      remainingQuantity: 0,
      status: StockReservationStatus.released,
      expiresAt: reservation.expiresAt,
      createdAt: reservation.createdAt,
    );
  }

  @override
  Future<void> submitBenefitRequest({
    required LoyaltyBenefitType type,
    required int quantity,
    String? itemName,
    String? productId,
    String details = '',
    LoyaltyReferenceImage? referenceImage,
    LoyaltyContentKind? contentKind,
  }) async {}

  @override
  Stream<void> watchLoyaltyChanges() => const Stream<void>.empty();

  int get _activeReservedUnits => _stockReservations
      .where(
        (reservation) =>
            reservation.isActive &&
            reservation.expiresAt.isAfter(DateTime.now()),
      )
      .fold(0, (total, reservation) => total + reservation.remainingQuantity);

  LoyaltySummary _summaryWithStockReservations(LoyaltySummary source) {
    final activeUnits = _activeReservedUnits;
    LoyaltyTierDefinition? updateTier(LoyaltyTierDefinition? tier) {
      if (tier == null || tier.stockReservation == null) return tier;
      final entitlement = tier.stockReservation!;
      return LoyaltyTierDefinition(
        code: tier.code,
        nameAr: tier.nameAr,
        nameCkb: tier.nameCkb,
        nameEn: tier.nameEn,
        threshold: tier.threshold,
        rewardEnabled: tier.rewardEnabled,
        rewardType: tier.rewardType,
        rewardValue: tier.rewardValue,
        rewardValidDays: tier.rewardValidDays,
        benefits: tier.benefits,
        stockReservation: StockReservationEntitlement(
          enabled: entitlement.enabled,
          maxActiveUnits: entitlement.maxActiveUnits,
          maxPerReservation: entitlement.maxPerReservation,
          holdHours: entitlement.holdHours,
          activeUnits: activeUnits,
          remainingUnits: (entitlement.maxActiveUnits - activeUnits)
              .clamp(0, entitlement.maxActiveUnits)
              .toInt(),
        ),
      );
    }

    return LoyaltySummary(
      programEnabled: source.programEnabled,
      pointsPerSoldUnit: source.pointsPerSoldUnit,
      totalPoints: source.totalPoints,
      completedUnits: source.completedUnits,
      currentTier: updateTier(source.currentTier),
      nextTier: source.nextTier,
      pointsToNextTier: source.pointsToNextTier,
      tiers: [for (final tier in source.tiers) updateTier(tier)!],
      recentEntries: source.recentEntries,
      recentBenefitRequests: source.recentBenefitRequests,
      recentStockReservations: List<StockReservation>.unmodifiable(
        _stockReservations,
      ),
    );
  }
}
