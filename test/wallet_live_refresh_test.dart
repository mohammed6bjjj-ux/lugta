import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wallet refresh fetches and applies the latest balance', () async {
    final base = createDemoRepositories();
    await base.auth.signIn(phone: '07700000000', password: 'test-password');
    final wallet = _MutableWalletRepository(base.wallet, available: 110000);
    await session.configure(
      AppRepositories(
        auth: base.auth,
        profile: base.profile,
        catalog: base.catalog,
        orders: base.orders,
        wallet: wallet,
        notifications: base.notifications,
        isDemo: true,
      ),
      loadInitialData: false,
    );

    await session.refreshWallet();
    expect(session.availableBalance, 110000);
    expect(wallet.fetchCount, 1);

    wallet.available = 220000;
    await session.refreshWallet();
    expect(session.availableBalance, 220000);
    expect(wallet.fetchCount, 2);

    await session.configure(createDemoRepositories(), loadInitialData: false);
  });
}

class _MutableWalletRepository implements WalletRepository {
  _MutableWalletRepository(this._delegate, {required this.available});

  final WalletRepository _delegate;
  int available;
  int fetchCount = 0;

  @override
  Future<WalletSnapshot> fetchWallet() async {
    fetchCount += 1;
    return WalletSnapshot(
      available: available,
      pending: 0,
      totalEarned: available,
      minimumWithdrawal: 25000,
      transactions: const [],
      withdrawals: const [],
      payoutAccounts: const [],
      statementLines: const [],
      withdrawalSources: const [],
    );
  }

  @override
  Stream<void> watchWalletChanges() => const Stream<void>.empty();

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
