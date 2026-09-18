import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/wallet_ledger_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> row({
    required String id,
    required String entryType,
    required String bucket,
    required int amount,
    String? orderId,
    String? orderNumber,
    String? withdrawalId,
    String createdAt = '2026-07-21T12:00:00Z',
  }) => {
    'id': id,
    'entry_type': entryType,
    'bucket': bucket,
    'amount': amount,
    'order_id': orderId,
    'order_number': orderNumber,
    'withdrawal_id': withdrawalId,
    'created_at': createdAt,
  };

  test(
    'released profit uses corrected settlement date without changing ledger',
    () {
      final ledger = [
        row(
          id: 'release',
          entryType: 'profit_release',
          bucket: 'available',
          amount: 11000,
          orderId: 'order-1',
          createdAt: '2026-09-16T13:51:00Z',
        ),
        row(
          id: 'pending',
          entryType: 'profit_pending',
          bucket: 'pending',
          amount: 11000,
          orderId: 'order-1',
          createdAt: '2026-09-14T13:00:00Z',
        ),
      ];
      final result = walletTransactionsFromLedgerRows(
        ledger,
        statementRows: [
          {
            'order_id': 'order-1',
            'order_status': 'completed',
            'completed_at': '2026-09-15T13:51:00Z',
          },
        ],
      );
      expect(result.first.at, DateTime.parse('2026-09-15T13:51:00Z').toLocal());
      expect(result.first.amount, 11000);
      expect(result.last.at, DateTime.parse('2026-09-14T13:00:00Z').toLocal());
      expect(ledger.first['created_at'], '2026-09-16T13:51:00Z');
    },
  );

  test('missing invalid or unsettled statement keeps original ledger date', () {
    for (final statement in [
      <String, dynamic>{},
      {
        'order_id': 'order-1',
        'order_status': 'completed',
        'completed_at': 'bad',
      },
      {
        'order_id': 'order-1',
        'order_status': 'delivered',
        'completed_at': '2026-09-13T12:00:00Z',
      },
      {
        'order_id': 'other',
        'order_status': 'completed',
        'completed_at': '2026-09-13T12:00:00Z',
      },
    ]) {
      final result = walletTransactionsFromLedgerRows(
        [
          row(
            id: 'r',
            entryType: 'profit_release',
            bucket: 'available',
            amount: 23000,
            orderId: 'order-1',
          ),
        ],
        statementRows: [statement],
      );
      expect(
        result.single.at,
        DateTime.parse('2026-07-21T12:00:00Z').toLocal(),
      );
    }
  });

  test(
    'shows pending, released and reversed rewards but hides release counter-entry',
    () {
      final transactions = walletTransactionsFromLedgerRows([
        row(
          id: 'r1',
          entryType: 'promotion_reward',
          bucket: 'pending',
          amount: 250,
        ),
        {
          ...row(
            id: 'r2',
            entryType: 'promotion_reward',
            bucket: 'pending',
            amount: -250,
          ),
          'metadata': {'reward_stage': 'released'},
        },
        row(
          id: 'r3',
          entryType: 'promotion_reward',
          bucket: 'available',
          amount: 250,
        ),
        row(
          id: 'r4',
          entryType: 'promotion_reward',
          bucket: 'available',
          amount: -250,
        ),
      ]);
      expect(transactions, hasLength(3));
      expect(
        transactions.map((t) => t.type),
        containsAll([
          WalletTxType.pendingReward,
          WalletTxType.rewardReleased,
          WalletTxType.rewardReversed,
        ]),
      );
      expect(transactions.every((t) => t.amount == 250), isTrue);
    },
  );
  test('shows only the available side of a profit release', () {
    final transactions = walletTransactionsFromLedgerRows([
      row(
        id: 'pending-out',
        entryType: 'profit_release',
        bucket: 'pending',
        amount: -12000,
        orderId: 'order-1',
        orderNumber: 'ORD-1',
      ),
      row(
        id: 'available-in',
        entryType: 'profit_release',
        bucket: 'available',
        amount: 12000,
        orderId: 'order-1',
        orderNumber: 'ORD-1',
      ),
    ]);

    expect(transactions, hasLength(1));
    expect(transactions.single.type, WalletTxType.profitReleased);
    expect(transactions.single.amount, 12000);
  });

  test('aggregates withdrawal source holds into one visible withdrawal', () {
    final transactions = walletTransactionsFromLedgerRows([
      row(
        id: 'available-out-1',
        entryType: 'withdrawal_hold',
        bucket: 'available',
        amount: -20000,
        withdrawalId: 'withdrawal-1',
      ),
      row(
        id: 'held-in-1',
        entryType: 'withdrawal_hold',
        bucket: 'held',
        amount: 20000,
        withdrawalId: 'withdrawal-1',
      ),
      row(
        id: 'available-out-2',
        entryType: 'withdrawal_hold',
        bucket: 'available',
        amount: -15000,
        withdrawalId: 'withdrawal-1',
      ),
      row(
        id: 'held-in-2',
        entryType: 'withdrawal_hold',
        bucket: 'held',
        amount: 15000,
        withdrawalId: 'withdrawal-1',
      ),
    ]);

    expect(transactions, hasLength(1));
    expect(transactions.single.type, WalletTxType.withdrawal);
    expect(transactions.single.amount, 35000);
  });

  test('renders one refund and hides paid settlement counter-entries', () {
    final transactions = walletTransactionsFromLedgerRows([
      row(
        id: 'held-out',
        entryType: 'withdrawal_release',
        bucket: 'held',
        amount: -35000,
        withdrawalId: 'withdrawal-1',
      ),
      row(
        id: 'available-back',
        entryType: 'withdrawal_release',
        bucket: 'available',
        amount: 35000,
        withdrawalId: 'withdrawal-1',
      ),
      row(
        id: 'paid-held-out',
        entryType: 'withdrawal_paid',
        bucket: 'held',
        amount: -25000,
        withdrawalId: 'withdrawal-2',
      ),
      row(
        id: 'paid-history',
        entryType: 'withdrawal_paid',
        bucket: 'withdrawn',
        amount: 25000,
        withdrawalId: 'withdrawal-2',
      ),
    ]);

    expect(transactions, hasLength(1));
    expect(transactions.single.type, WalletTxType.withdrawalRefund);
    expect(transactions.single.amount, 35000);
  });

  test('keeps the direction of administrative adjustments', () {
    final transactions = walletTransactionsFromLedgerRows([
      row(
        id: 'credit',
        entryType: 'admin_adjustment',
        bucket: 'available',
        amount: 4000,
      ),
      row(
        id: 'debit',
        entryType: 'admin_adjustment',
        bucket: 'available',
        amount: -1000,
        createdAt: '2026-07-21T13:00:00Z',
      ),
    ]);

    expect(transactions, hasLength(2));
    expect(transactions.first.type, WalletTxType.adjustmentDebit);
    expect(transactions.first.amount, 1000);
    expect(transactions.last.type, WalletTxType.adjustmentCredit);
    expect(transactions.last.amount, 4000);
  });
}
