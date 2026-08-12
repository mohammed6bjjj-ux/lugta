import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../data/models.dart';
import '../order_wizard/wizard_strings.dart';
import 'cart_strings.dart';

class ProductCartConfiguration {
  const ProductCartConfiguration({
    required this.quantity,
    required this.unitSalePrice,
    required this.packagingBox,
  });

  final int quantity;
  final int unitSalePrice;
  final PackagingBox? packagingBox;
}

Future<ProductCartConfiguration?> showProductCartConfigurator({
  required BuildContext context,
  required Product product,
  required ProductVariant variant,
  required List<PackagingBox> packagingBoxes,
  CartItem? existingItem,
  bool allowPriceEditing = true,
  int? availableStock,
  int reservedStock = 0,
}) => showModalBottomSheet<ProductCartConfiguration>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  elevation: 0,
  backgroundColor: AppColors.surface.withValues(alpha: 0),
  builder: (context) => _ProductCartConfiguratorSheet(
    product: product,
    variant: variant,
    packagingBoxes: packagingBoxes,
    existingItem: existingItem,
    allowPriceEditing: allowPriceEditing,
    availableStock: availableStock,
    reservedStock: reservedStock,
  ),
);

class _ProductCartConfiguratorSheet extends StatefulWidget {
  const _ProductCartConfiguratorSheet({
    required this.product,
    required this.variant,
    required this.packagingBoxes,
    required this.existingItem,
    required this.allowPriceEditing,
    required this.availableStock,
    required this.reservedStock,
  });

  final Product product;
  final ProductVariant variant;
  final List<PackagingBox> packagingBoxes;
  final CartItem? existingItem;
  final bool allowPriceEditing;
  final int? availableStock;
  final int reservedStock;

  @override
  State<_ProductCartConfiguratorSheet> createState() =>
      _ProductCartConfiguratorSheetState();
}

class _ProductCartConfiguratorSheetState
    extends State<_ProductCartConfiguratorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late int _quantity;
  PackagingBox? _packagingBox;

  int get _unitWholesalePrice =>
      widget.variant.wholesalePriceOverride ?? widget.product.wholesalePrice;

  int get _availableStock => widget.availableStock ?? widget.variant.stock;

  int get _minimumPrice {
    final productMinimum = widget.product.effectiveMinSalePrice;
    return _unitWholesalePrice > productMinimum
        ? _unitWholesalePrice
        : productMinimum;
  }

  int? get _maximumPrice => widget.product.maxSalePrice;

  int get _unitSalePrice =>
      int.tryParse(_priceController.text.replaceAll(',', '').trim()) ?? 0;

  int get _saleTotal => _unitSalePrice * _quantity;
  int get _packagingTotal => (_packagingBox?.price ?? 0) * _quantity;
  int get _profitTotal => (_unitSalePrice - _unitWholesalePrice) * _quantity;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    final safeAvailableStock = _availableStock < 1 ? 1 : _availableStock;
    _quantity = (existing?.quantity ?? 1).clamp(1, safeAvailableStock);
    _packagingBox = existing?.packagingBox;
    var initialPrice =
        existing?.unitSalePrice ??
        widget.variant.suggestedPriceOverride ??
        widget.product.suggestedPrice;
    if (initialPrice < _minimumPrice) initialPrice = _minimumPrice;
    final maximum = _maximumPrice;
    if (maximum != null && initialPrice > maximum) initialPrice = maximum;
    _priceController = TextEditingController(text: initialPrice.toString());
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String? _validatePrice(String? raw) {
    final value = int.tryParse((raw ?? '').replaceAll(',', '').trim());
    if (value == null || value <= 0) return CartStrings.salePriceRequired;
    if (value < _minimumPrice) {
      return WizardStrings.cannotSellBelow(formatIqd(_minimumPrice));
    }
    final maximum = _maximumPrice;
    if (maximum != null && value > maximum) {
      return WizardStrings.cannotSellAbove(formatIqd(maximum));
    }
    return null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      ProductCartConfiguration(
        quantity: _quantity,
        unitSalePrice: _unitSalePrice,
        packagingBox: _packagingBox,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = (constraints.maxHeight - viewInsets.bottom)
            .clamp(0.0, constraints.maxHeight);
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: availableHeight,
              child: Material(
                key: const ValueKey('product_cart_sheet_surface'),
                color: AppColors.surface,
                clipBehavior: Clip.antiAlias,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      key: const ValueKey('product_cart_sheet_drag_handle'),
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: .72),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    _buildHeader(context),
                    const Divider(height: 1),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          key: const ValueKey('product_cart_configurator'),
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.lg,
                          ),
                          children: [
                            _buildProductSummary(context),
                            const SizedBox(height: AppSpacing.lg),
                            if (widget.allowPriceEditing)
                              AppTextField(
                                fieldKey: const ValueKey(
                                  'product_cart_sale_price_field',
                                ),
                                label: CartStrings.salePrice,
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(12),
                                ],
                                validator: _validatePrice,
                                onChanged: (_) => setState(() {}),
                                suffix: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: AppSpacing.md,
                                  ),
                                  child: Center(
                                    widthFactor: 1,
                                    child: Text(
                                      'د.ع',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              _ReadOnlySalePrice(value: _unitSalePrice),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _maximumPrice == null
                                  ? CartStrings.minimumPrice(
                                      formatIqd(_minimumPrice),
                                    )
                                  : CartStrings.priceRange(
                                      formatIqd(_minimumPrice),
                                      formatIqd(_maximumPrice!),
                                    ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildQuantity(context),
                            if (widget.product.packagingEnabled) ...[
                              const SizedBox(height: AppSpacing.lg),
                              _buildPackaging(context),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            _buildSummary(context),
                          ],
                        ),
                      ),
                    ),
                    _buildAction(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      key: const ValueKey('product_cart_sheet_header'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingItem == null
                      ? CartStrings.configureProduct
                      : CartStrings.editConfiguration,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  CartStrings.configureProductSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: WizardStrings.closeTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSummary(BuildContext context) {
    final imageUrl = widget.variant.imageUrl.trim().isEmpty
        ? widget.product.coverImage
        : widget.variant.imageUrl;
    return Row(
      children: [
        AppNetworkImage(
          imageUrl,
          width: 72,
          height: 72,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.localizedName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.variant.localizedName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantity(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CartStrings.quantity,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  CartStrings.availableStock(formatNumber(_availableStock)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (widget.reservedStock > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    CartStrings.reservedForYou(
                      formatNumber(widget.reservedStock),
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          QuantityStepper(
            value: _quantity,
            min: 1,
            max: _availableStock,
            incrementKey: const ValueKey('product_cart_increment'),
            decrementKey: const ValueKey('product_cart_decrement'),
            onChanged: (value) => setState(() => _quantity = value),
          ),
        ],
      ),
    );
  }

  Widget _buildPackaging(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CartStrings.choosePackaging,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          CartStrings.packagingChargedPerPiece,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 166,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.packagingBoxes.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _PackagingOptionCard(
                  key: const ValueKey('product_cart_packaging_box_none'),
                  title: CartStrings.noPackaging,
                  priceLabel: CartStrings.free,
                  selected: _packagingBox == null,
                  onTap: () => setState(() => _packagingBox = null),
                );
              }
              final box = widget.packagingBoxes[index - 1];
              return _PackagingOptionCard(
                key: ValueKey('product_cart_packaging_box_${box.id}'),
                title: box.name,
                priceLabel: box.isFree
                    ? CartStrings.free
                    : formatIqd(box.price),
                imageUrl: box.imageUrl,
                selected: _packagingBox?.id == box.id,
                onTap: () => setState(() => _packagingBox = box),
              );
            },
          ),
        ),
        if (widget.packagingBoxes.isEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            CartStrings.noPackagingBoxesAvailable,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          _SummaryLine(
            label: CartStrings.productsTotal,
            value: formatIqd(_saleTotal),
          ),
          if (_packagingBox != null)
            _SummaryLine(
              label: CartStrings.packagingTotal,
              value: _packagingBox!.isFree
                  ? CartStrings.free
                  : formatIqd(_packagingTotal),
            ),
          const Divider(height: AppSpacing.lg),
          _SummaryLine(
            label: CartStrings.customerSubtotal,
            value: formatIqd(_saleTotal + _packagingTotal),
            emphasized: true,
          ),
          _SummaryLine(
            label: CartStrings.profitTotal,
            value: formatIqd(_profitTotal),
            positive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(
        left: AppSpacing.md,
        top: AppSpacing.sm,
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: PrimaryButton(
        key: const ValueKey('product_cart_confirm_button'),
        label: widget.existingItem == null
            ? CartStrings.addConfiguredToCart
            : CartStrings.updateCart,
        icon: widget.existingItem == null
            ? Icons.add_shopping_cart_rounded
            : Icons.sync_rounded,
        accented: true,
        onPressed: _submit,
      ),
    );
  }
}

class _ReadOnlySalePrice extends StatelessWidget {
  const _ReadOnlySalePrice({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('product_cart_sale_price_read_only'),
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.sell_outlined, color: AppColors.accentStrong),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              CartStrings.salePrice,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              formatIqd(value),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackagingOptionCard extends StatelessWidget {
  const _PackagingOptionCard({
    super.key,
    required this.title,
    required this.priceLabel,
    required this.selected,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final String priceLabel;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title، $priceLabel',
      child: SizedBox(
        width: 132,
        child: Material(
          color: selected ? AppColors.accentSoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? AppColors.accentStrong : AppColors.divider,
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      if (imageUrl?.trim().isNotEmpty == true)
                        AppNetworkImage(
                          imageUrl!,
                          width: double.infinity,
                          height: 82,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 82,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      PositionedDirectional(
                        top: AppSpacing.xs,
                        end: AppSpacing.xs,
                        child: Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected
                          ? AppColors.accentStrong
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
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

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.positive = false,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final style =
        (emphasized
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.bodyMedium)
            ?.copyWith(
              color: positive ? AppColors.success : AppColors.textPrimary,
              fontWeight: emphasized || positive
                  ? FontWeight.w900
                  : FontWeight.w600,
            );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(value, style: style),
          ),
        ],
      ),
    );
  }
}
