import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../formatters.dart';

/// عدّاد كمية بحد أدنى وأقصى (الأقصى = المخزون المتاح).
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    required this.max,
    this.incrementKey,
    this.decrementKey,
  });

  final int value;
  final int min;
  final int max;
  final Key? incrementKey;
  final Key? decrementKey;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            key: incrementKey,
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 36),
            child: Text(
              formatNumber(value),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          _StepButton(
            key: decrementKey,
            icon: Icons.remove_rounded,
            enabled: value > min,
            onTap: () => onChanged(value - 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.textPrimary : AppColors.divider,
        ),
      ),
    );
  }
}
