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
