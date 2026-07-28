import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/core_strings.dart';
import '../formatters.dart';

/// بطاقة الحسبة الحديثة — تُعرض قبل تأكيد الطلب وفي تفاصيله:
/// سعر الجملة، سعر البيع، ربح البائع، أجرة التوصيل، المبلغ النهائي على الزبون.
class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({
    super.key,
    required this.wholesaleTotal,
    required this.saleTotal,
    required this.deliveryFee,
    this.quantity,
    this.packagingTotal = 0,
    this.baseDeliveryFee,
  });

  final int wholesaleTotal;
  final int saleTotal;
  final int deliveryFee;
  final int packagingTotal;
  final int? baseDeliveryFee;

  /// إن مُررت الكمية تُعرض في ترويسة البطاقة.
  final int? quantity;

  int get profit => saleTotal - wholesaleTotal;
  int get customerTotal => saleTotal + packagingTotal + deliveryFee;
  int get deliveryDiscount {
    final discount = (baseDeliveryFee ?? deliveryFee) - deliveryFee;
    return discount > 0 ? discount : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            decoration: BoxDecoration(gradient: AppColors.goldGradient),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  quantity == null
                      ? CoreStrings.priceSummaryTitle
                      : CoreStrings.priceSummaryTitleWithQty(
                          formatNumber(quantity!),
                        ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _row(
                  context,
                  CoreStrings.wholesalePrice,
                  formatIqd(wholesaleTotal),
                ),
                _row(context, CoreStrings.salePrice, formatIqd(saleTotal)),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: _row(
                    context,
                    CoreStrings.yourProfit,
                    formatIqd(profit),
                    valueColor: AppColors.success,
                    bold: true,
                  ),
                ),
                _row(
                  context,
                  CoreStrings.deliveryFeeOnCustomer,
                  formatIqd(deliveryFee),
                ),
                if (deliveryDiscount > 0)
                  _row(
                    context,
                    CoreStrings.deliveryDiscount,
                    '- ${formatIqd(deliveryDiscount)}',
                    valueColor: AppColors.success,
                    bold: true,
                  ),
                if (packagingTotal > 0)
                  _row(
                    context,
                    CoreStrings.packagingFeeOnCustomer,
                    formatIqd(packagingTotal),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(),
                ),
                _row(
                  context,
                  CoreStrings.customerTotal,
                  formatIqd(customerTotal),
                  bold: true,
                  large: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
    bool large = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  (large
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: bold
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                      ),
            ),
          ),
          Text(
            value,
            style:
                (large
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.titleSmall)
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: valueColor ?? AppColors.textPrimary,
                    ),
          ),
        ],
      ),
    );
  }
}
