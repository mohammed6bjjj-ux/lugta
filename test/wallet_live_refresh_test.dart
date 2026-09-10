import 'dart:async';

import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/services/device_token_registrar.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'pending and released profit stay visible and wallet push re-reads the ledger',
    () async {
      final base = createDemoRepositories();
      await base.auth.signIn(phone: '07700000000', password: 'test-password');
      final pushes = _WalletPushes();
      final pending = WalletTransaction(
        id: 'pending:order',
        type: WalletTxType.pendingProfit,
        amount: 12000,
        at: DateTime(2026, 9, 6),
        orderCode: 'ORD-TEST',
      );
      final released = WalletTransaction(
        id: 'released:order',
        type: WalletTxType.profitReleased,
        amount: 12000,
        at: DateTime(2026, 9, 9),
        orderCode: 'ORD-TEST',
      );
      final wallet = _MutableWalletRepository(base.wallet, available: 0)
        ..pending = 12000
        ..transactions = [pending];
      await session.configure(
        AppRepositories(
          auth: base.auth,
          profile: base.profile,
          catalog: base.catalog,
          orders: base.orders,
          wallet: wallet,
          notifications: base.notifications,
          isDemo: false,
        ),
        deviceTokens: pushes,
        loadInitialData: false,
      );
      try {
        await session.refreshCurrentProfile();
        await session.refreshWallet();
        expect(session.pendingBalance, 12000);
        expect(session.availableBalance, 0);
        expect(session.transactions.single.type, WalletTxType.pendingProfit);
        wallet.available = 12000;
        wallet.pending = 0;
        wallet.transactions = [released, pending];
        pushes.messages.add(
          PushMessage(data: {'target_type': 'wallet', 'amount': '999999999'}),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(wallet.fetchCount, 2);
        expect(
          session.availableBalance,
          12000,
          reason: 'Never trust the push amount.',
        );
        expect(session.pendingBalance, 0);
        expect(session.transactions.map((tx) => tx.type), [
          WalletTxType.profitReleased,
          WalletTxType.pendingProfit,
        ]);
      } finally {
        await session.configure(
          createDemoRepositories(),
          loadInitialData: false,
        );
        await pushes.messages.close();
      }
    },
  );

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

    await session.refreshCurrentProfile();
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
  int pending = 0;
  List<WalletTransaction> transactions = [];
  int fetchCount = 0;

  @override
  Future<WalletSnapshot> fetchWallet() async {
    fetchCount += 1;
    return WalletSnapshot(
      available: available,
      pending: pending,
      totalEarned: available,
      minimumWithdrawal: 25000,
      transactions: transactions,
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

class _WalletPushes extends NoopDeviceTokenRegistrar {
  final messages = StreamController<PushMessage>.broadcast();
  @override
  Stream<PushMessage> get foregroundMessages => messages.stream;
}
