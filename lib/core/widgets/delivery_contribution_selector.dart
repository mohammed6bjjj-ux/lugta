import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/delivery_contribution_strings.dart';
import '../formatters.dart';
import 'app_card.dart';

class DeliveryContributionSelector extends StatelessWidget {
  const DeliveryContributionSelector({
    super.key,
    required this.deliveryFee,
    required this.grossProfit,
    required this.value,
    required this.onChanged,
    this.step = 500,
  });

  final int deliveryFee;
  final int grossProfit;
  final int value;
  final ValueChanged<int> onChanged;
  final int step;

  int get maxContribution =>
      math.min(deliveryFee, math.max(0, grossProfit ~/ step * step));

  int get safeValue => value.clamp(0, maxContribution).toInt();

  int get splitValue {
    if (maxContribution == 0) return 0;
    final rounded = (deliveryFee / 2 / step).round() * step;
    return rounded.clamp(0, maxContribution).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (deliveryFee <= 0) {
      return AppCard(
        key: const ValueKey('delivery_contribution_free_offer'),
        color: scheme.secondaryContainer,
        shadows: const [],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.redeem_rounded, color: scheme.onSecondaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DeliveryContributionStrings.freeByOfferTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DeliveryContributionStrings.freeByOfferBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      key: const ValueKey('delivery_contribution_selector'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.handshake_outlined,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DeliveryContributionStrings.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DeliveryContributionStrings.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 330;
              final choiceWidth = stacked
                  ? constraints.maxWidth
                  : (constraints.maxWidth - AppSpacing.xs * 2) / 3;
              return Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  SizedBox(
                    width: choiceWidth,
                    child: _PresetChoice(
                      key: const ValueKey('delivery_contribution_customer'),
                      icon: Icons.person_outline_rounded,
                      label: DeliveryContributionStrings.customerPays,
                      selected: safeValue == 0,
                      onTap: () => onChanged(0),
                    ),
                  ),
                  SizedBox(
                    width: choiceWidth,
                    child: _PresetChoice(
                      key: const ValueKey('delivery_contribution_split'),
                      icon: Icons.balance_rounded,
                      label: DeliveryContributionStrings.split,
                      selected: splitValue > 0 && safeValue == splitValue,
                      enabled: splitValue > 0,
                      onTap: () => onChanged(splitValue),
                    ),
                  ),
                  SizedBox(
                    width: choiceWidth,
                    child: _PresetChoice(
                      key: const ValueKey('delivery_contribution_seller'),
                      icon: Icons.storefront_outlined,
                      label: DeliveryContributionStrings.sellerPays,
                      selected:
                          maxContribution == deliveryFee &&
                          safeValue == deliveryFee,
                      enabled: maxContribution == deliveryFee,
                      onTap: () => onChanged(deliveryFee),
                    ),
                  ),
                ],
              );
            },
          ),
          if (maxContribution == 0) ...[
            const SizedBox(height: AppSpacing.md),
            _HintBanner(
              icon: Icons.info_outline_rounded,
              text: DeliveryContributionStrings.noProfitAvailable,
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  DeliveryContributionStrings.customAmount,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    formatIqd(safeValue),
                    key: const ValueKey('delivery_contribution_value'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              key: const ValueKey('delivery_contribution_slider'),
              value: safeValue.toDouble(),
              min: 0,
              max: maxContribution.toDouble(),
              divisions: maxContribution ~/ step,
              label: formatIqd(safeValue),
              semanticFormatterCallback: (sliderValue) =>
                  formatIqd(sliderValue.round()),
              onChanged: (sliderValue) {
                final stepped = (sliderValue / step).round() * step;
                onChanged(stepped.clamp(0, maxContribution).toInt());
              },
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  _SummaryValue(
                    icon: Icons.storefront_outlined,
                    text: DeliveryContributionStrings.sellerCovers(
                      formatIqd(safeValue),
                    ),
                  ),
                  _SummaryValue(
                    icon: Icons.person_outline_rounded,
                    text: DeliveryContributionStrings.customerCovers(
                      formatIqd(deliveryFee - safeValue),
                    ),
                  ),
                  _SummaryValue(
                    icon: Icons.trending_up_rounded,
                    text: DeliveryContributionStrings.netProfit(
                      formatIqd(grossProfit - safeValue),
                    ),
                  ),
                ],
              ),
            ),
            if (maxContribution < deliveryFee) ...[
              const SizedBox(height: AppSpacing.sm),
              _HintBanner(
                icon: Icons.info_outline_rounded,
                text: DeliveryContributionStrings.cannotCoverAll,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PresetChoice extends StatelessWidget {
  const _PresetChoice({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconForeground = enabled
        ? (selected ? scheme.primary : scheme.onSurfaceVariant)
        : scheme.onSurface.withValues(alpha: 0.38);
    final textForeground = enabled
        ? (selected ? scheme.onPrimaryContainer : scheme.onSurface)
        : scheme.onSurface.withValues(alpha: 0.38);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: Material(
        color: !enabled
            ? scheme.surfaceContainerHighest
            : selected
            ? scheme.primaryContainer
            : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: !enabled
                ? scheme.outlineVariant.withValues(alpha: 0.45)
                : selected
                ? scheme.primary
                : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: iconForeground),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: textForeground,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
