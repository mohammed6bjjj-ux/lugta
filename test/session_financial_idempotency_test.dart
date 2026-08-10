import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppRepositories base;
  late _IdempotentProfileRepository profile;
  late _IdempotentOrdersRepository orders;
  late _MutationThenReadFailureWalletRepository wallet;

  setUp(() async {
    base = createDemoRepositories();
    await base.auth.signIn(phone: '07712345678', password: 'test-password');
    profile = _IdempotentProfileRepository(base.profile);
    orders = _IdempotentOrdersRepository(base.orders);
    wallet = _MutationThenReadFailureWalletRepository(base.wallet);
    await session.configure(
      AppRepositories(
        auth: base.auth,
        profile: profile,
        catalog: base.catalog,
        orders: orders,
        wallet: wallet,
        notifications: base.notifications,
        isDemo: true,
      ),
      loadInitialData: false,
    );
    session.seller = MockData.seller;
    session.orders = List.of(MockData.orders);
    session.withdrawals = List.of(MockData.withdrawals);
    session.payoutAccounts = const [
      PayoutAccount(
        id: 'demo-zain',
        provider: 'zain_cash',
        accountHolderName: 'أحمد الياسري',
        accountIdentifier: '07712345678',
        identifierLast4: '5678',
        isVerified: true,
        isDefault: true,
      ),
    ];
  });

  tearDown(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
  });

  test('caller-owned order request id stays stable across a retry', () async {
    final product = MockData.products.first;
    final variant = product.variants.first;
    const requestId = '11111111-1111-4111-8111-111111111111';

    final first = await session.createOrder(
      clientRequestId: requestId,
      product: product,
      items: [OrderDraftItem(variant: variant, quantity: 1)],
      unitSalePrice: product.suggestedPrice,
      governorate: MockData.governorates.first,
      customerName: 'زبون اختبار',
      customerPhone: '07701234567',
      addressDetails: 'بغداد - عنوان اختبار',
    );
    final retried = await session.createOrder(
      clientRequestId: requestId,
      product: product,
      items: [OrderDraftItem(variant: variant, quantity: 1)],
      unitSalePrice: product.suggestedPrice,
      governorate: MockData.governorates.first,
      customerName: 'زبون اختبار',
      customerPhone: '07701234567',
      addressDetails: 'بغداد - عنوان اختبار',
    );

    expect(orders.requestIds, [requestId, requestId]);
    expect(retried.id, first.id);
    expect(session.orders.where((item) => item.id == first.id), hasLength(1));
  });

  test(
    'successful withdrawal survives a failed follow-up wallet read',
    () async {
      wallet.failWalletFetch = true;
      const requestId = '22222222-2222-4222-8222-222222222222';

      final withdrawal = await session.requestWithdrawal(
        clientRequestId: requestId,
        amount: 25000,
        method: 'زين كاش',
        accountDetail: '07712345678',
        payoutAccountId: 'demo-zain',
      );

      expect(wallet.withdrawalRequestIds, [requestId]);
      expect(withdrawal.amount, 25000);
      expect(session.withdrawals.first.id, withdrawal.id);
      expect(session.availableBalance, 67000);
    },
  );

  test('successful payout save survives failed reconciliation reads', () async {
    wallet
      ..failWalletFetch = true
      ..failPayoutFetch = true;

    final account = await session.savePayoutAccount(
      provider: 'superqi',
      accountHolderName: 'سارة محمد',
      accountIdentifier: '12345',
    );

    expect(session.payoutAccounts.first.id, account.id);
    expect(session.payoutAccounts.first.accountIdentifier, '12345');
  });

  test(
    'successful payout delete survives a failed reconciliation read',
    () async {
      wallet.failPayoutFetch = true;

      await session.deletePayoutAccount('demo-zain');

      expect(session.payoutAccounts, isEmpty);
    },
  );

  test('order change retries reuse the caller-owned request id', () async {
    final order = session.orders.firstWhere(
      (item) => item.status.canRequestChange,
    );
    const requestId = '33333333-3333-4333-8333-333333333333';

    for (var attempt = 0; attempt < 2; attempt++) {
      await session.submitOrderChangeRequest(
        orderId: order.id,
        type: OrderChangeRequestType.edit,
        reason: 'Update delivery details',
        proposedChanges: const {'address_details': 'Updated address'},
        clientRequestId: requestId,
      );
    }

    expect(orders.changeRequestIds, [requestId, requestId]);
  });

  test(
    'cancel order stays successful when its reconciliation read fails',
    () async {
      final order = session.orders.firstWhere(
        (item) => item.status.sellerCanCancelDirectly,
      );
      orders.failFetchOrder = true;

      await session.cancelOrder(order.id);

      expect(orders.cancelRequestIds, ['seller-cancel-order:${order.id}']);
      expect(session.orderById(order.id)?.status, OrderStatus.cancelled);
    },
  );

  test('cancel withdrawal retries reuse a deterministic request id', () async {
    final withdrawal = session.withdrawals.firstWhere(
      (item) => item.status == WithdrawalStatus.pending,
    );

    await session.cancelWithdrawal(withdrawal.id);
    await session.cancelWithdrawal(withdrawal.id);

    expect(wallet.cancelRequestIds, [
      'seller-cancel-withdrawal:${withdrawal.id}',
      'seller-cancel-withdrawal:${withdrawal.id}',
    ]);
    expect(
      session.withdrawals.firstWhere((item) => item.id == withdrawal.id).status,
      WithdrawalStatus.cancelled,
    );
  });

  test('account deletion retries reuse the caller-owned request id', () async {
    const requestId = '44444444-4444-4444-8444-444444444444';

    for (var attempt = 0; attempt < 2; attempt++) {
      await session.requestAccountDeletion(
        'No longer needed',
        clientRequestId: requestId,
      );
    }

    expect(profile.deletionRequestIds, [requestId, requestId]);
    expect(
      session.accountDeletionRequest?.status,
      AccountDeletionStatus.pending,
    );
  });

  test('account deletion cancel recovers from a lost response', () async {
    const createRequestId = '55555555-5555-4555-8555-555555555555';
    await session.requestAccountDeletion(
      'No longer needed',
      clientRequestId: createRequestId,
    );
    final deletionRequest = session.accountDeletionRequest!;
    profile.failFirstCancelAfterMutation = true;

    await expectLater(
      session.cancelAccountDeletion(),
      throwsA(isA<BackendException>()),
    );
    await session.cancelAccountDeletion();

    final expectedId = 'seller-cancel-account-deletion:${deletionRequest.id}';
    expect(profile.deletionCancelIds, [expectedId, expectedId]);
    expect(
      session.accountDeletionRequest?.status,
      AccountDeletionStatus.cancelled,
    );
  });
}

class _IdempotentProfileRepository implements ProfileRepository {
  _IdempotentProfileRepository(this._delegate);

  final ProfileRepository _delegate;
  final List<String> deletionRequestIds = [];
  final List<String> deletionCancelIds = [];
  final Map<String, AccountDeletionRequest> _cancelledByRequestId = {};
  bool failFirstCancelAfterMutation = false;
  bool _didFailCancelAfterMutation = false;

  @override
  Future<Seller> fetchCurrentProfile() => _delegate.fetchCurrentProfile();

  @override
  Future<Seller> updateCurrentProfile({
    required String name,
    required String storeName,
    required String instagramUrl,
    ProfileAvatarChange? avatarChange,
  }) => _delegate.updateCurrentProfile(
    name: name,
    storeName: storeName,
    instagramUrl: instagramUrl,
    avatarChange: avatarChange,
  );

  @override
  Future<Seller> updateSettings({
    required String locale,
    required Map<String, bool> notificationPreferences,
  }) => _delegate.updateSettings(
    locale: locale,
    notificationPreferences: notificationPreferences,
  );

  @override
  Future<AccountDeletionRequest?> fetchLatestAccountDeletionRequest() =>
      _delegate.fetchLatestAccountDeletionRequest();

  @override
  Future<AccountDeletionRequest> requestAccountDeletion({
    required String reason,
    required String clientRequestId,
  }) {
    deletionRequestIds.add(clientRequestId);
    return _delegate.requestAccountDeletion(
      reason: reason,
      clientRequestId: clientRequestId,
    );
  }

  @override
  Future<AccountDeletionRequest> cancelAccountDeletion({
    required String requestId,
    required String clientRequestId,
  }) async {
    deletionCancelIds.add(clientRequestId);
    final existing = _cancelledByRequestId[clientRequestId];
    if (existing != null) return existing;
    final cancelled = await _delegate.cancelAccountDeletion(
      requestId: requestId,
      clientRequestId: clientRequestId,
    );
    _cancelledByRequestId[clientRequestId] = cancelled;
    if (failFirstCancelAfterMutation && !_didFailCancelAfterMutation) {
      _didFailCancelAfterMutation = true;
      throw const BackendException('cancel response was lost');
    }
    return cancelled;
  }

  @override
  Future<void> touchLastActive() => _delegate.touchLastActive();
}

class _IdempotentOrdersRepository implements OrdersRepository {
  _IdempotentOrdersRepository(this._delegate);

  final OrdersRepository _delegate;
  final List<String> requestIds = [];
  final List<String> cancelRequestIds = [];
  final List<String> changeRequestIds = [];
  final Map<String, Order> _created = {};
  final Set<String> _completedCancellationRequests = {};
  bool failFetchOrder = false;

  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    requestIds.add(request.clientRequestId);
    final existing = _created[request.clientRequestId];
    if (existing != null) return existing;
    final created = await _delegate.createOrder(request);
    _created[request.clientRequestId] = created;
    return created;
  }

  @override
  Future<void> cancelOrder(
    String orderId, {
    required String clientRequestId,
  }) async {
    cancelRequestIds.add(clientRequestId);
    if (!_completedCancellationRequests.add(clientRequestId)) return;
    await _delegate.cancelOrder(orderId, clientRequestId: clientRequestId);
  }

  @override
  Future<Order> fetchOrder(String orderId) {
    if (failFetchOrder) {
      throw const BackendException('follow-up order read failed');
    }
    return _delegate.fetchOrder(orderId);
  }

  @override
  Future<List<Order>> fetchOrders() => _delegate.fetchOrders();

  @override
  Future<void> submitChangeRequest({
    required String orderId,
    required OrderChangeRequestType type,
    required String reason,
    required Map<String, dynamic> proposedChanges,
    required String clientRequestId,
  }) {
    changeRequestIds.add(clientRequestId);
    return _delegate.submitChangeRequest(
      orderId: orderId,
      type: type,
      reason: reason,
      proposedChanges: proposedChanges,
      clientRequestId: clientRequestId,
    );
  }

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

class _MutationThenReadFailureWalletRepository implements WalletRepository {
  _MutationThenReadFailureWalletRepository(this._delegate);

  final WalletRepository _delegate;
  final List<String> withdrawalRequestIds = [];
  final List<String> cancelRequestIds = [];
  final Map<String, Withdrawal> _cancelledByRequestId = {};
  bool failWalletFetch = false;
  bool failPayoutFetch = false;

  @override
  Future<WalletSnapshot> fetchWallet() {
    if (failWalletFetch) {
      throw const BackendException('follow-up wallet read failed');
    }
    return _delegate.fetchWallet();
  }

  @override
  Future<List<PayoutAccount>> fetchPayoutAccounts() {
    if (failPayoutFetch) {
      throw const BackendException('follow-up payout read failed');
    }
    return _delegate.fetchPayoutAccounts();
  }

  @override
  Future<Withdrawal> requestWithdrawal(CreateWithdrawalRequest request) {
    withdrawalRequestIds.add(request.clientRequestId);
    return _delegate.requestWithdrawal(request);
  }

  @override
  Future<Withdrawal> cancelWithdrawal(
    String withdrawalId, {
    required String clientRequestId,
  }) async {
    cancelRequestIds.add(clientRequestId);
    final existing = _cancelledByRequestId[clientRequestId];
    if (existing != null) return existing;
    final cancelled = await _delegate.cancelWithdrawal(
      withdrawalId,
      clientRequestId: clientRequestId,
    );
    _cancelledByRequestId[clientRequestId] = cancelled;
    return cancelled;
  }

  @override
  Future<void> deletePayoutAccount(String accountId) =>
      _delegate.deletePayoutAccount(accountId);

  @override
  Future<PayoutAccount> upsertPayoutAccount(SavePayoutAccountRequest request) =>
      _delegate.upsertPayoutAccount(request);

  @override
  Stream<void> watchWalletChanges() => _delegate.watchWalletChanges();
}
