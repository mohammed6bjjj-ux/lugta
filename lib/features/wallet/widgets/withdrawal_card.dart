import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models.dart';
import '../../../data/session.dart';
import '../wallet_strings.dart';

final Set<String> _withdrawalsBeingCancelled = <String>{};

/// بطاقة طلب سحب واحدة — ويدجت مشترك بين تبويب «السحوبات» في شاشة
/// المحفظة وشاشة «سجل السحوبات» المستقلة.
class WithdrawalCard extends StatelessWidget {
  const WithdrawalCard({super.key, required this.withdrawal});

  final Withdrawal withdrawal;

  /// اسم الطريقة قد يكون مخزّناً بأي من اللغات الثلاث — نغطي الصيغ كلها.
  IconData get _methodIcon {
    final method = withdrawal.method;
    final isZain =
        method.contains('زين') ||
        method.contains('زەین') ||
        method.toLowerCase().contains('zain');
    return isZain ? Icons.phone_android_rounded : Icons.credit_card_rounded;
  }

  Future<void> _showSources(BuildContext context) async {
    final sources = session.withdrawalSources
        .where((item) => item.withdrawalId == withdrawal.id)
        .toList();
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
                WalletStrings.withdrawalSourcesTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                WalletStrings.withdrawalSourcesSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (sources.isEmpty)
                Text(WalletStrings.noWithdrawalSources)
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .6,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sources.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final source = sources[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.successSoft,
                          child: Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.success,
                          ),
                        ),
                        title: Text(
                          source.localizedProductName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${source.orderCode} • '
                          '${source.localizedVariantName} • '
                          '${source.quantity}',
                        ),
                        trailing: Text(
                          formatIqd(source.allocatedAmount),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    if (!_withdrawalsBeingCancelled.add(withdrawal.id)) return;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(WalletStrings.cancelWithdrawal),
          content: Text(WalletStrings.cancelWithdrawalConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(WalletStrings.keepWithdrawal),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                WalletStrings.cancelWithdrawal,
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await session.cancelWithdrawal(withdrawal.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      _withdrawalsBeingCancelled.remove(withdrawal.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => _showSources(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppColors.goldSoft, const Color(0xFFFDFBF7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(_methodIcon, size: 22, color: AppColors.goldDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatIqd(withdrawal.amount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            withdrawal.method,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          ' — ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            withdrawal.accountDetail,
                            textDirection: TextDirection.ltr,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              WithdrawalStatusChip(status: withdrawal.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm + 2),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: WalletStrings.requestDate,
            value: formatDateTime(withdrawal.requestedAt),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.receipt_long_outlined,
            label: WalletStrings.transferFee,
            value: formatIqd(withdrawal.transferFee),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.account_balance_wallet_outlined,
            label: WalletStrings.netPayout,
            value: formatIqd(withdrawal.netAmount),
          ),
          if (withdrawal.processedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.task_alt_rounded,
              label: WalletStrings.processedDate,
              value: formatDateTime(withdrawal.processedAt!),
            ),
          ],
          if (withdrawal.rejectReason != null) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      WalletStrings.rejectReason(withdrawal.rejectReason!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (withdrawal.status == WithdrawalStatus.pending) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => _cancel(context),
                icon: const Icon(Icons.close_rounded),
                label: Text(WalletStrings.cancelWithdrawal),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm - 2),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// قائمة السحوبات الموحّدة مع حالة فارغة — تقبل ترويسة اختيارية أعلى القائمة
/// وحشوة قابلة للتخصيص (تبويب المحفظة يمرر حشوة سفلية أكبر للشريط العائم).
class WithdrawalsListView extends StatelessWidget {
  const WithdrawalsListView({
    super.key,
    required this.withdrawals,
    this.header,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final List<Withdrawal> withdrawals;
  final Widget? header;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (withdrawals.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: WalletStrings.noWithdrawalsTitle,
              subtitle: WalletStrings.noWithdrawalsSubtitle,
            ),
          ),
        ],
      );
    }
    final headerCount = header == null ? 0 : 1;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      itemCount: withdrawals.length + headerCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm + 2),
      itemBuilder: (context, index) => Entrance(
        index: index,
        child: header != null && index == 0
            ? header!
            : WithdrawalCard(withdrawal: withdrawals[index - headerCount]),
      ),
    );
  }
}
