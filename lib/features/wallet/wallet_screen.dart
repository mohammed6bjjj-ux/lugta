import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../l10n/core_strings.dart';
import 'wallet_strings.dart';
import 'widgets/withdrawal_card.dart';

/// شاشة المحفظة — صفحة واحدة تتمرر كاملة (البطاقة والتبويبات والقوائم معاً).
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  /// حشوة سفلية تُبقي آخر المحتوى ظاهراً فوق شريط التنقل العائم الزجاجي.
  static const double _bottomBarClearance = 110;

  /// 0 = الحركات، 1 = السحوبات.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refreshWalletBestEffort());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshWalletBestEffort());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshWalletBestEffort() async {
    try {
      await session.refreshWallet();
    } catch (_) {
      // Pull-to-refresh remains available if the connection is temporarily down.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            return SessionRefreshIndicator(
              onRefresh: session.refreshWallet,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  _bottomBarClearance,
                ),
                children: [
                  // ── الرأس ──
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackHeader =
                          constraints.maxWidth < 330 ||
                          MediaQuery.textScalerOf(context).scale(1) > 1.3;
                      final historyAction = TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          Routes.withdrawalsHistory,
                        ),
                        icon: Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          size: 18,
                        ),
                        label: Text(
                          WalletStrings.withdrawalsHistory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                      final title = Text(
                        CoreStrings.tabWallet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      );
                      if (stackHeader) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: historyAction,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: title),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(child: historyAction),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Entrance(child: _BalanceCard()),
                  const SizedBox(height: AppSpacing.md),
                  Entrance(
                    index: 2,
                    child: _SegmentedTabs(
                      selected: _tab,
                      labels: [
                        WalletStrings.transactionsTab,
                        WalletStrings.withdrawalsTab,
                      ],
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),

                  // ── المحتوى حسب التبويب — ضمن نفس تمرير الصفحة ──
                  AnimatedSwitcher(
                    duration: AppDurations.base,
                    switchInCurve: AppCurves.emphasized,
                    switchOutCurve: Curves.easeIn,
                    child: _tab == 0
                        ? _TransactionsStatement(
                            key: const ValueKey('transactions'),
                            transactions: session.transactions,
                            statementLines: session.statementLines,
                          )
                        : _WithdrawalsList(
                            key: const ValueKey('withdrawals'),
                            withdrawals: session.withdrawals,
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// بطاقة الرصيد المتكاملة: الرقم الكبير، إحصاءان، وزر السحب — في سطح داكن واحد.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      radius: AppRadius.xl,
      gradient: AppColors.darkGradient,
      shadows: AppShadows.floating,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  WalletStrings.availableBalance,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: .75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 17,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // عدّ تصاعدي ناعم للرصيد عند البناء.
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: session.availableBalance),
            duration: const Duration(milliseconds: 900),
            curve: AppCurves.emphasized,
            builder: (context, value, _) => Text(
              formatIqd(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _InlineMetric(
                  label: WalletStrings.pendingProfit,
                  value: session.pendingBalance,
                  valueColor: AppColors.accent,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: .12),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _InlineMetric(
                  label: WalletStrings.totalEarned,
                  value: session.totalEarned,
                  valueColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md + 2),
          PrimaryButton(
            label: WalletStrings.withdrawRequest,
            icon: Icons.payments_outlined,
            accented: true,
            onPressed: session.canWithdraw
                ? () => Navigator.pushNamed(context, Routes.withdrawRequest)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: Colors.white.withValues(alpha: .45),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  session.canWithdraw
                      ? WalletStrings.pendingAutoReleaseHint
                      : WalletStrings.minWithdrawalHint(
                          formatIqd(session.minWithdrawalAmount),
                        ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: .45),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// إحصاء مضمّن بسيط داخل البطاقة الداكنة — بلا صناديق.
class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final int value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: .55),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            formatIqd(value),
            maxLines: 1,
            style: theme.textTheme.titleSmall?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// محدد كبسولي حديث بدون TabController — يعمل داخل صفحة تتمرر كاملة.
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.selected,
    required this.labels,
    required this.onChanged,
  });

  final int selected;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          for (final (i, label) in labels.indexed)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: AppDurations.base,
                  curve: AppCurves.emphasized,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected == i
                        ? AppColors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: selected == i ? AppShadows.card : null,
                  ),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: AppDurations.fast,
                      style: (theme.textTheme.titleSmall ?? const TextStyle())
                          .copyWith(
                            fontWeight: FontWeight.w800,
                            color: selected == i
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// كشف الحركات: كل الحركات داخل بطاقة واحدة بصفوف رفيعة وخطوط شعرية.
class _TransactionsStatement extends StatelessWidget {
  const _TransactionsStatement({
    super.key,
    required this.transactions,
    required this.statementLines,
  });

  final List<WalletTransaction> transactions;
  final List<AccountStatementLine> statementLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SalesStatementSummary(lines: statementLines),
        const SizedBox(height: AppSpacing.sm + 2),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: WalletStrings.noTransactionsTitle,
              subtitle: WalletStrings.noTransactionsSubtitle,
            ),
          )
        else
          Entrance(
            index: 1,
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 4,
              ),
              child: Column(
                children: [
                  for (final (i, tx) in transactions.indexed) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: AppColors.divider.withValues(alpha: .6),
                      ),
                    _TransactionRow(transaction: tx),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SalesStatementSummary extends StatelessWidget {
  const _SalesStatementSummary({required this.lines});

  final List<AccountStatementLine> lines;

  Future<void> _showStatement(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                WalletStrings.salesStatement,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                WalletStrings.salesStatementSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (lines.isEmpty)
                Text(WalletStrings.noStatementLines)
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .68,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) =>
                        _StatementLineTile(line: lines[index]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quantity = lines.fold(0, (sum, item) => sum + item.quantity);
    final sales = lines.fold(0, (sum, item) => sum + item.lineSaleTotal);
    final profit = lines.fold(0, (sum, item) => sum + item.lineProfitTotal);
    return Entrance(
      child: AppCard(
        onTap: () => _showStatement(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: AppColors.accentStrong),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    WalletStrings.salesStatement,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_left_rounded),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatementMetric(
                    label: WalletStrings.productsSold,
                    value: formatNumber(quantity),
                  ),
                ),
                Expanded(
                  child: _StatementMetric(
                    label: WalletStrings.salesValue,
                    value: formatIqd(sales),
                  ),
                ),
                Expanded(
                  child: _StatementMetric(
                    label: WalletStrings.netProfit,
                    value: formatIqd(profit),
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementMetric extends StatelessWidget {
  const _StatementMetric({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}

class _StatementLineTile extends StatelessWidget {
  const _StatementLineTile({required this.line});

  final AccountStatementLine line;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      line.localizedProductName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      '${line.orderCode} • ${line.localizedVariantName} • '
      '${WalletStrings.quantityValue(line.quantity)}\n'
      '${WalletStrings.buyPrice(formatIqd(line.unitWholesalePrice))} • '
      '${WalletStrings.salePrice(formatIqd(line.unitSalePrice))}',
    ),
    isThreeLine: true,
    trailing: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatIqd(line.lineProfitTotal),
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          line.orderStatus.labelAr,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: line.orderStatus.color),
        ),
      ],
    ),
  );
}

/// قائمة السحوبات داخل تمرير الصفحة نفسه.
class _WithdrawalsList extends StatelessWidget {
  const _WithdrawalsList({super.key, required this.withdrawals});

  final List<Withdrawal> withdrawals;

  @override
  Widget build(BuildContext context) {
    if (withdrawals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
        child: EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: WalletStrings.noWithdrawalsTitle,
          subtitle: WalletStrings.noWithdrawalsSubtitle,
        ),
      );
    }
    return Column(
      children: [
        for (final (i, w) in withdrawals.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.sm + 2),
            child: Entrance(
              index: i,
              child: WithdrawalCard(withdrawal: w),
            ),
          ),
      ],
    );
  }
}

/// صف حركة واحد في كشف الحساب.
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final WalletTransaction transaction;

  /// إشارة المبلغ ولونه حسب اتجاه الحركة —
  /// المعلق أخضر داكن هادئ، والمتاح أخضر العلامة.
  (String, Color) get _signAndColor => switch (transaction.type) {
    WalletTxType.withdrawal => ('-', AppColors.info),
    WalletTxType.withdrawalRefund => ('+', AppColors.success),
    WalletTxType.adjustmentCredit => ('+', AppColors.success),
    WalletTxType.adjustmentDebit => ('-', AppColors.error),
    WalletTxType.reversal => ('-', AppColors.error),
    WalletTxType.profitReleased => ('+', AppColors.success),
    WalletTxType.pendingProfit => ('+', AppColors.accentStrong),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (sign, amountColor) = _signAndColor;
    final subtitle = [
      if (transaction.orderCode != null) transaction.orderCode!,
      timeAgo(transaction.at),
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 3),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: transaction.type.color.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.type.icon,
              size: 18,
              color: transaction.type.color,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.type.labelAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$sign${formatIqd(transaction.amount)}',
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleSmall?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
