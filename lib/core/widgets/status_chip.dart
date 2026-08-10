import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models.dart';

/// شارة حالة الطلب الموحّدة.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final OrderStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 116 : 180),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: status.softColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: compact ? 14 : 16, color: status.color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                status.labelAr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شارة حالة طلب السحب.
class WithdrawalStatusChip extends StatelessWidget {
  const WithdrawalStatusChip({super.key, required this.status});

  final WithdrawalStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        status.labelAr,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: status.color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
