import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_network_image.dart';
import '../../data/storefront_models.dart';
import 'storefront_strings.dart';

/// Read-only receipt: order snapshots are never recalculated from the catalog.
class StorefrontRequestDetails extends StatelessWidget {
  const StorefrontRequestDetails({
    super.key,
    required this.request,
    required this.statusLabel,
    required this.zoneName,
    required this.onCall,
    required this.onWhatsApp,
    required this.onAlternateCall,
  });
  final StorefrontRequest request;
  final String statusLabel;
  final String zoneName;
  final VoidCallback onCall, onWhatsApp, onAlternateCall;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final approved = request.status == 'approved';
    final statusColor = request.expired || request.status == 'rejected'
        ? colors.error
        : approved
        ? AppColors.success
        : colors.primary;
    final address = [
      zoneName,
      request.address,
      request.landmark,
    ].where((s) => s.trim().isNotEmpty).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: text.labelLarge?.copyWith(color: statusColor),
                ),
              ),
            ),
            Text(
              formatDateTime(request.createdAt.toLocal()),
              style: text.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(request.customerName, style: text.titleLarge),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SelectableText(
                  request.customerPhone,
                  textDirection: TextDirection.ltr,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (request.customerAltPhone.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SelectableText(
                    request.customerAltPhone,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onCall,
                    icon: const Icon(Icons.call_outlined, size: 20),
                    label: Text(
                      StorefrontStrings.t('اتصال', 'پەیوەندی', 'Call'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onWhatsApp,
                    icon: const Icon(Icons.chat_outlined, size: 20),
                    label: Text(
                      StorefrontStrings.t('واتساب', 'واتساپ', 'WhatsApp'),
                    ),
                  ),
                  if (request.customerAltPhone.isNotEmpty)
                    TextButton(
                      onPressed: onAlternateCall,
                      child: Text(
                        StorefrontStrings.t(
                          'اتصال بالرقم البديل',
                          'پەیوەندی بە ژمارەی دووەم',
                          'Call alternate number',
                        ),
                      ),
                    ),
                ],
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SelectableText(address, style: text.bodyMedium),
                    ),
                  ],
                ),
              ],
              if (request.notes.isNotEmpty) ...[
                const Divider(height: 20),
                Text(
                  StorefrontStrings.t(
                    'ملاحظة الزبون',
                    'تێبینی کڕیار',
                    'Customer note',
                  ),
                  style: text.labelLarge,
                ),
                SelectableText(request.notes, style: text.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          StorefrontStrings.t(
            'منتجات الطلب',
            'بەرهەمەکانی داواکاری',
            'Order items',
          ),
          style: text.titleMedium,
        ),
        const SizedBox(height: 8),
        _Section(
          child: Column(
            children: [
              for (var i = 0; i < request.items.length; i++) ...[
                if (i != 0) const Divider(height: 24),
                StorefrontRequestItemRow(item: request.items[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Amount(
                label: StorefrontStrings.t(
                  'المنتجات',
                  'بەرهەمەکان',
                  'Products',
                ),
                value: request.saleTotal,
              ),
              const SizedBox(height: 4),
              _Amount(
                label: StorefrontStrings.t('التوصيل', 'گەیاندن', 'Delivery'),
                value: request.deliveryFee,
              ),
              const Divider(height: 20),
              _Amount(
                label: approved
                    ? StorefrontStrings.t(
                        'التقدير عند إرسال الطلب',
                        'خەمڵاندنی کاتی ناردن',
                        'Submitted estimate',
                      )
                    : StorefrontStrings.t(
                        'المبلغ على الزبون',
                        'کۆی گشتی کڕیار',
                        'Customer total',
                      ),
                value: request.total,
                strong: true,
              ),
              const SizedBox(height: 4),
              Text(
                StorefrontStrings.t(
                  'الدفع نقداً عند الاستلام',
                  'پارەدان بە نەقد لە وەرگرتن',
                  'Cash on delivery',
                ),
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StorefrontRequestItemRow extends StatelessWidget {
  const StorefrontRequestItemRow({super.key, required this.item});
  final StorefrontRequestItem item;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: StorefrontStrings.t(
            'صورة ${item.productName}',
            'وێنەی ${item.productName}',
            '${item.productName} image',
          ),
          image: true,
          child: AppNetworkImage(
            item.imageUrl,
            width: 76,
            height: 90,
            fit: BoxFit.contain,
            borderRadius: BorderRadius.circular(10),
            fallbackIcon: Icons.image_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item.productName, style: text.titleMedium),
              if (item.variantName.isNotEmpty)
                Text(item.variantName, style: text.bodySmall),
              const SizedBox(height: 4),
              Text(
                '${formatNumber(item.quantity)} × ${formatIqd(item.unitSalePrice)}',
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider),
    ),
    child: child,
  );
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final int value;
  final bool strong;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final text = Theme.of(context).textTheme;
      final labelWidget = Text(
        label,
        style: strong ? text.titleMedium : text.bodyMedium,
      );
      final amount = Text(
        formatIqd(value),
        style: strong
            ? text.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              )
            : text.titleSmall,
      );
      if (MediaQuery.textScalerOf(context).scale(16) > 22 ||
          box.maxWidth < 260) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [labelWidget, amount],
        );
      }
      return Row(
        children: [
          Expanded(child: labelWidget),
          const SizedBox(width: 8),
          amount,
        ],
      );
    },
  );
}
