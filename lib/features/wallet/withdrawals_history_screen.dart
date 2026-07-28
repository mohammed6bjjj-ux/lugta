import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'wallet_strings.dart';
import 'widgets/withdrawal_card.dart';

/// شاشة سجل السحوبات المستقلة — تُفتح من الملف الشخصي
/// عبر Routes.withdrawalsHistory.
class WithdrawalsHistoryScreen extends StatelessWidget {
  const WithdrawalsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(WalletStrings.withdrawalsHistory)),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          var (paidTotal, inProgressTotal) = (0, 0);
          for (final w in session.withdrawals) {
            switch (w.status) {
              case WithdrawalStatus.paid:
                paidTotal += w.amount;
              case WithdrawalStatus.pending || WithdrawalStatus.approved:
                inProgressTotal += w.amount;
              case WithdrawalStatus.rejected || WithdrawalStatus.cancelled:
                break;
            }
          }
          return SessionRefreshIndicator(
            onRefresh: session.refreshWallet,
            child: WithdrawalsListView(
              withdrawals: session.withdrawals,
              header: _SummaryHeader(
                paidTotal: paidTotal,
                inProgressTotal: inProgressTotal,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ترويسة مختصرة: إجمالي المدفوع وما زال قيد المعالجة.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.paidTotal,
    required this.inProgressTotal,
  });

  final int paidTotal;
  final int inProgressTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.task_alt_rounded,
            label: WalletStrings.totalWithdrawn,
            value: paidTotal,
            color: AppColors.success,
            softColor: AppColors.successSoft,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: _StatCard(
            icon: Icons.hourglass_top_rounded,
            label: WalletStrings.inProgress,
            value: inProgressTotal,
            color: AppColors.warning,
            softColor: AppColors.warningSoft,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.softColor,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: softColor, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          // عدّ تصاعدي ناعم للإجمالي عند البناء.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 800),
              curve: AppCurves.emphasized,
              builder: (context, animatedValue, _) => Text(
                formatIqd(animatedValue),
                maxLines: 1,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
