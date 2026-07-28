import 'models.dart';

/// Converts the append-only double-entry wallet ledger into user-visible
/// movements. Internal counter-entries are intentionally not rendered twice.
List<WalletTransaction> walletTransactionsFromLedgerRows(
  List<Map<String, dynamic>> rows,
) {
  final grouped = <String, _WalletMovement>{};

  for (final row in rows) {
    final entryType = _text(row['entry_type']);
    final bucket = _text(row['bucket']);
    final amount = _integer(row['amount']);
    if (amount == 0) continue;

    final orderId = _nullableText(row['order_id']);
    final withdrawalId = _nullableText(row['withdrawal_id']);
    final rowId = _text(row['id']);
    final (WalletTxType type, String groupKey, int visibleAmount)? visible =
        switch (entryType) {
          'profit_pending' when bucket == 'pending' && amount > 0 => (
            WalletTxType.pendingProfit,
            'profit-pending:${orderId ?? rowId}',
            amount,
          ),
          'profit_release' when bucket == 'available' && amount > 0 => (
            WalletTxType.profitReleased,
            'profit-release:${orderId ?? rowId}',
            amount,
          ),
          'profit_reverse' when amount < 0 => (
            WalletTxType.reversal,
            'profit-reverse:${orderId ?? rowId}',
            amount.abs(),
          ),
          'withdrawal_hold' when bucket == 'available' && amount < 0 => (
            WalletTxType.withdrawal,
            'withdrawal-hold:${withdrawalId ?? rowId}',
            amount.abs(),
          ),
          'withdrawal_release' when bucket == 'available' && amount > 0 => (
            WalletTxType.withdrawalRefund,
            'withdrawal-refund:${withdrawalId ?? rowId}',
            amount,
          ),
          'admin_adjustment' when amount > 0 => (
            WalletTxType.adjustmentCredit,
            'adjustment-credit:$rowId',
            amount,
          ),
          'admin_adjustment' => (
            WalletTxType.adjustmentDebit,
            'adjustment-debit:$rowId',
            amount.abs(),
          ),
          // The held and withdrawn sides are settlement bookkeeping. The
          // available-balance hold was already shown when the request began.
          _ => null,
        };
    if (visible == null) continue;

    final (type, groupKey, visibleAmount) = visible;
    final at = _date(row['created_at']);
    final existing = grouped[groupKey];
    if (existing == null) {
      grouped[groupKey] = _WalletMovement(
        id: groupKey,
        type: type,
        amount: visibleAmount,
        at: at,
        orderCode: _nullableText(row['order_number']),
        note: _nullableText(row['description']),
      );
    } else {
      existing.amount += visibleAmount;
      if (at.isAfter(existing.at)) existing.at = at;
    }
  }

  final transactions = [
    for (final movement in grouped.values)
      WalletTransaction(
        id: movement.id,
        type: movement.type,
        amount: movement.amount,
        at: movement.at,
        orderCode: movement.orderCode,
        note: movement.note,
      ),
  ]..sort((a, b) => b.at.compareTo(a.at));
  return transactions;
}

class _WalletMovement {
  _WalletMovement({
    required this.id,
    required this.type,
    required this.amount,
    required this.at,
    required this.orderCode,
    required this.note,
  });

  final String id;
  final WalletTxType type;
  int amount;
  DateTime at;
  final String? orderCode;
  final String? note;
}

String _text(Object? value) => value?.toString().trim() ?? '';

String? _nullableText(Object? value) {
  final valueText = _text(value);
  return valueText.isEmpty ? null : valueText;
}

int _integer(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String text => int.tryParse(text) ?? 0,
  _ => 0,
};

DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal() ??
    DateTime.fromMillisecondsSinceEpoch(0);
