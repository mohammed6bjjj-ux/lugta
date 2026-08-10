import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/price_summary_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../order_wizard/wizard_strings.dart';
import 'cart_strings.dart';
import 'product_cart_configurator.dart';

/// سلة واحدة تنشئ رأس طلب واحد وعدة أسطر منتجات ذرّياً في Supabase.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const double _bottomClearance = 112;
  static const int _fixedDeliveryFee = 5000;

  final GlobalKey<FormState> _customerFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  int _step = 0;
  bool _submitting = false;
  bool _loadingDeliveryQuote = false;
  Governorate? _governorate;
  DeliveryQuote? _deliveryQuote;
  Timer? _deliveryQuoteRefreshTimer;
  int _deliveryQuoteRequest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refreshDeliveryQuote());
    });
  }

  @override
  void dispose() {
    _deliveryQuoteRefreshTimer?.cancel();
    _deliveryQuoteRequest += 1;
    _nameController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _allPricesValid =>
      session.cartItems.isNotEmpty &&
      session.cartItems.every((item) => item.priceIsValid);

  int get _productCount =>
      session.cartItems.map((item) => item.product.id).toSet().length;

  int get _deliveryFee => _deliveryQuote?.deliveryFee ?? _fixedDeliveryFee;
  int get _baseDeliveryFee =>
      _deliveryQuote?.baseDeliveryFee ?? _fixedDeliveryFee;

  Future<void> _confirmClearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(CartStrings.clearCartTitle),
        content: Text(CartStrings.clearCartBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(CartStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(CartStrings.clearCart),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _deliveryQuoteRefreshTimer?.cancel();
    session.clearCart();
    if (mounted) {
      setState(() {
        _step = 0;
        _deliveryQuote = null;
      });
    }
  }

  void _removeItem(CartItem item) {
    session.removeFromCart(item.id);
    if (session.cartItems.isEmpty) {
      _deliveryQuoteRefreshTimer?.cancel();
      setState(() {
        _step = 0;
        _deliveryQuote = null;
      });
      return;
    }
    _scheduleDeliveryQuoteRefresh();
  }

  Future<void> _editItemOptions(CartItem item) async {
    final configuration = await showProductCartConfigurator(
      context: context,
      product: item.product,
      variant: item.variant,
      packagingBoxes: session.packagingBoxes,
      existingItem: item,
      allowPriceEditing: false,
    );
    if (configuration == null || !mounted) return;
    try {
      session.setCartItemConfiguration(
        product: item.product,
        variant: item.variant,
        quantity: configuration.quantity,
        unitSalePrice: configuration.unitSalePrice,
        packagingBox: configuration.packagingBox,
      );
      _scheduleDeliveryQuoteRefresh();
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _selectGovernorate(Governorate? governorate) async {
    setState(() {
      _governorate = governorate;
      _deliveryQuote = null;
      _loadingDeliveryQuote = governorate != null;
    });
    if (governorate == null) return;
    await _refreshDeliveryQuote(
      governorate: governorate,
      showLoading: true,
      reportError: true,
    );
  }

  void _scheduleDeliveryQuoteRefresh() {
    _deliveryQuoteRefreshTimer?.cancel();
    _deliveryQuoteRequest += 1;
    if (mounted) {
      setState(() {
        _deliveryQuote = null;
        _loadingDeliveryQuote = false;
      });
    }
    if (session.cartItems.isEmpty) return;
    _deliveryQuoteRefreshTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) unawaited(_refreshDeliveryQuote());
    });
  }

  Future<void> _refreshDeliveryQuote({
    Governorate? governorate,
    bool showLoading = false,
    bool reportError = false,
  }) async {
    final quoteGovernorate =
        governorate ??
        _governorate ??
        (session.governorates.isEmpty ? null : session.governorates.first);
    if (quoteGovernorate == null || session.cartItems.isEmpty) return;
    final request = ++_deliveryQuoteRequest;
    if (showLoading && mounted) {
      setState(() => _loadingDeliveryQuote = true);
    }
    try {
      final quote = await session.quoteDeliveryFee(
        quoteGovernorate.id,
        orderSubtotal: session.cartSaleTotal,
      );
      if (!mounted || request != _deliveryQuoteRequest) return;
      setState(() {
        _deliveryQuote = quote;
        _loadingDeliveryQuote = false;
      });
    } catch (error) {
      if (!mounted || request != _deliveryQuoteRequest) return;
      setState(() => _loadingDeliveryQuote = false);
      if (reportError) _showMessage(error.toString());
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (session.isGuest) {
      Navigator.pushNamed(context, Routes.guestAccess);
      return;
    }
    if (_step == 0) {
      if (!_allPricesValid) {
        setState(() {});
        _showMessage(CartStrings.invalidPrices);
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (!(_customerFormKey.currentState?.validate() ?? false)) return;
      setState(() => _step = 2);
      return;
    }
    _submit();
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step > 0) setState(() => _step -= 1);
  }

  String _cartFingerprint() => session.cartItems
      .map(
        (item) =>
            '${item.product.id}|${item.variant.id}|${item.quantity}|'
            '${item.unitSalePrice}|${item.unitWholesalePrice}|'
            '${item.packagingBox?.id ?? ''}|${item.packagingBox?.price ?? 0}',
      )
      .join(';;');

  Future<void> _submit() async {
    if (_submitting || session.cartItems.isEmpty || !_allPricesValid) return;
    final selectedGovernorate = _governorate;
    if (selectedGovernorate == null) return;
    final before = _cartFingerprint();
    final previousDeliveryFee = _deliveryFee;
    setState(() => _submitting = true);
    try {
      await Future.wait<void>([
        session.refreshCatalog(),
        session.refreshPublicData(),
      ]);
      if (!mounted) return;
      if (before != _cartFingerprint() || !_allPricesValid) {
        setState(() {
          _submitting = false;
          _step = 0;
        });
        _showMessage(CartStrings.changedBeforeSubmit);
        return;
      }

      Governorate? latestGovernorate;
      for (final item in session.governorates) {
        if (item.id == selectedGovernorate.id) {
          latestGovernorate = item;
          break;
        }
      }
      if (latestGovernorate == null) {
        setState(() {
          _governorate = null;
          _deliveryQuote = null;
          _submitting = false;
          _step = 1;
        });
        _showMessage(WizardStrings.deliveryZoneUnavailable);
        return;
      }
      final latestQuote = await session.quoteDeliveryFee(
        latestGovernorate.id,
        orderSubtotal: session.cartSaleTotal,
      );
      if (!mounted) return;
      _governorate = latestGovernorate;
      _deliveryQuote = latestQuote;
      if (latestQuote.deliveryFee != previousDeliveryFee) {
        setState(() {
          _submitting = false;
          _step = 2;
        });
        _showMessage(WizardStrings.deliveryFeeChangedBeforeSubmit);
        return;
      }

      final order = await session.createCartOrder(
        governorate: latestGovernorate,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        customerPhone2: _phone2Controller.text.trim().isEmpty
            ? null
            : _phone2Controller.text.trim(),
        addressDetails: _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacementNamed(Routes.orderSuccess, arguments: order);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(
          title: Text(CartStrings.title),
          actions: [
            ListenableBuilder(
              listenable: session,
              builder: (context, _) => session.cartItems.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      key: const ValueKey('cart_clear_button'),
                      tooltip: CartStrings.clearCart,
                      onPressed: _submitting ? null : _confirmClearCart,
                      icon: const Icon(Icons.delete_sweep_outlined),
                    ),
            ),
          ],
        ),
        body: AbsorbPointer(
          absorbing: _submitting,
          child: ListenableBuilder(
            listenable: session,
            builder: (context, _) {
              if (session.cartItems.isEmpty) return _buildEmptyState();
              return Column(
                children: [
                  _CartStepIndicator(currentStep: _step),
                  Expanded(
                    child: switch (_step) {
                      0 => _buildCartStep(),
                      1 => _buildCustomerStep(),
                      _ => _buildReviewStep(),
                    },
                  ),
                  _buildBottomBar(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => LayoutBuilder(
    builder: (context, constraints) => ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 1,
      itemBuilder: (context, _) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: CartStrings.emptyTitle,
          subtitle: CartStrings.emptySubtitle,
          actionLabel: CartStrings.browseProducts,
          onAction: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );

  Widget _buildCartStep() {
    final theme = Theme.of(context);
    return ListView.builder(
      key: const ValueKey('cart_items_list'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        _bottomClearance,
      ),
      itemCount: session.cartItems.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CartStrings.itemsTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  CartStrings.piecesAndProducts(
                    formatNumber(session.cartQuantity),
                    formatNumber(_productCount),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        if (index == session.cartItems.length + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: _buildTotalsCard(includeDelivery: true),
          );
        }
        final item = session.cartItems[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _CartLineCard(
            key: ValueKey('cart_line_${item.id}'),
            item: item,
            onQuantityChanged: (quantity) {
              session.updateCartQuantity(item.id, quantity);
              _scheduleDeliveryQuoteRefresh();
            },
            onEditOptions: () => _editItemOptions(item),
            onRemove: () => _removeItem(item),
          ),
        );
      },
    );
  }

  Widget _buildCustomerStep() {
    return Form(
      key: _customerFormKey,
      child: ListView(
        key: const ValueKey('cart_customer_form'),
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          _bottomClearance,
        ),
        children: [
          Text(
            WizardStrings.customerTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            WizardStrings.customerSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            fieldKey: const ValueKey('cart_customer_name_field'),
            label: WizardStrings.customerName,
            controller: _nameController,
            hint: WizardStrings.customerNameHint,
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            inputFormatters: [LengthLimitingTextInputFormatter(160)],
            validator: (value) => validateRequired(
              value,
              message: WizardStrings.customerNameRequired,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const ValueKey('cart_customer_phone_field'),
            label: WizardStrings.customerPhone,
            controller: _phoneController,
            hint: '07XXXXXXXXX',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: validateIraqiPhone,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: WizardStrings.altPhone,
            controller: _phone2Controller,
            hint: '07XXXXXXXXX',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_forwarded_outlined,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: (value) => (value == null || value.trim().isEmpty)
                ? null
                : validateIraqiPhone(value),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<Governorate>(
            key: const ValueKey('cart_governorate_field'),
            initialValue: _governorate,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: WizardStrings.governorate,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
            hint: Text(WizardStrings.selectGovernorate),
            items: [
              for (final governorate in session.governorates)
                DropdownMenuItem(
                  value: governorate,
                  child: Text(governorate.localizedName),
                ),
            ],
            onChanged: _selectGovernorate,
            validator: (value) =>
                value == null ? WizardStrings.selectGovernorate : null,
          ),
          if (_governorate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              color: AppColors.accentSoft,
              shadows: const [],
              child: Row(
                children: [
                  if (_loadingDeliveryQuote)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _deliveryQuote?.isFree == true
                          ? Icons.redeem_outlined
                          : Icons.local_shipping_outlined,
                      color: AppColors.accentStrong,
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _deliveryQuote?.isFree == true
                          ? WizardStrings.freeDelivery
                          : WizardStrings.deliveryFeeIs(
                              formatIqd(_deliveryFee),
                            ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.accentStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const ValueKey('cart_address_field'),
            label: WizardStrings.addressLabel,
            controller: _addressController,
            hint: WizardStrings.addressHint,
            prefixIcon: Icons.home_outlined,
            maxLines: 3,
            inputFormatters: [LengthLimitingTextInputFormatter(1200)],
            validator: (value) =>
                validateRequired(value, message: WizardStrings.addressRequired),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: WizardStrings.deliveryNotes,
            controller: _notesController,
            hint: WizardStrings.deliveryNotesHint,
            prefixIcon: Icons.sticky_note_2_outlined,
            maxLines: 2,
            inputFormatters: [LengthLimitingTextInputFormatter(2000)],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    return ListView(
      key: const ValueKey('cart_review_step'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        _bottomClearance,
      ),
      children: [
        Text(
          CartStrings.multipleProducts(formatNumber(_productCount)),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in session.cartItems) ...[
          AppCard(
            child: Row(
              children: [
                AppNetworkImage(
                  item.variant.imageUrl.trim().isEmpty
                      ? item.product.coverImage
                      : item.variant.imageUrl,
                  width: 54,
                  height: 54,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.localizedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${item.variant.localizedName} · '
                        '${formatNumber(item.quantity)} × ${formatIqd(item.unitSalePrice)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.packagingBox != null)
                        Text(
                          '${CartStrings.packaging}: ${item.packagingBox!.name}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.accentStrong,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                WizardStrings.customerAndAddress,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ReviewInfo(
                icon: Icons.person_outline_rounded,
                value: _nameController.text.trim(),
              ),
              _ReviewInfo(
                icon: Icons.phone_outlined,
                value: _phoneController.text.trim(),
                ltr: true,
              ),
              _ReviewInfo(
                icon: Icons.location_on_outlined,
                value:
                    '${_governorate?.localizedName ?? ''} · ${_addressController.text.trim()}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTotalsCard(includeDelivery: true),
      ],
    );
  }

  Widget _buildTotalsCard({required bool includeDelivery}) => PriceSummaryCard(
    wholesaleTotal: session.cartWholesaleTotal,
    saleTotal: session.cartSaleTotal,
    packagingTotal: session.cartPackagingTotal,
    deliveryFee: includeDelivery ? _deliveryFee : 0,
    baseDeliveryFee: includeDelivery ? _baseDeliveryFee : 0,
    quantity: session.cartQuantity,
  );

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(
        left: AppSpacing.md,
        top: AppSpacing.xs,
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: SecondaryButton(
                key: const ValueKey('cart_back_button'),
                label: CartStrings.back,
                onPressed: _submitting ? null : _back,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            flex: 2,
            child: PrimaryButton(
              key: const ValueKey('cart_next_button'),
              label: switch (_step) {
                0 => CartStrings.continueToCustomer,
                1 => CartStrings.reviewOrder,
                _ => CartStrings.confirmOrder,
              },
              icon: _step == 2 ? Icons.check_circle_outline_rounded : null,
              accented: _step == 2,
              loading: _submitting,
              onPressed: _submitting ? null : _next,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onEditOptions,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onEditOptions;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                item.variant.imageUrl.trim().isEmpty
                    ? item.product.coverImage
                    : item.variant.imageUrl,
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
                      item.product.localizedName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.variant.localizedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      CartStrings.minimumPrice(
                        formatIqd(item.effectiveMinSalePrice),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('cart_remove_${item.id}'),
                tooltip: CartStrings.remove,
                onPressed: onRemove,
                color: AppColors.error,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            key: ValueKey('cart_price_display_${item.id}'),
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: item.priceIsValid
                  ? AppColors.surfaceAlt
                  : AppColors.errorSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: item.priceIsValid ? AppColors.divider : AppColors.error,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 18;
                final icon = Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.sell_outlined,
                    color: item.priceIsValid
                        ? AppColors.accentStrong
                        : AppColors.error,
                    size: 21,
                  ),
                );
                final label = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CartStrings.salePrice,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!item.priceIsValid)
                      Text(
                        CartStrings.invalidPrices,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                );
                final price = Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    formatIqd(item.unitSalePrice),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: item.priceIsValid
                          ? AppColors.textPrimary
                          : AppColors.error,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
                if (largeText || constraints.maxWidth < 230) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          icon,
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: label),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: price,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    icon,
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: label),
                    price,
                  ],
                );
              },
            ),
          ),
          if (item.product.packagingEnabled) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              key: ValueKey('cart_packaging_display_${item.id}'),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  if (item.packagingBox?.imageUrl.trim().isNotEmpty == true)
                    AppNetworkImage(
                      item.packagingBox!.imageUrl,
                      width: 52,
                      height: 52,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    )
                  else
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CartStrings.packaging,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          item.packagingBox?.name ?? CartStrings.noPackaging,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.packagingBox == null || item.packagingBox!.isFree
                        ? CartStrings.free
                        : formatIqd(item.packagingBox!.price),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.accentStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
              final iconOnly = constraints.maxWidth < 230 || largeText;
              final editAction = iconOnly
                  ? SizedBox.square(
                      dimension: 48,
                      child: IconButton.outlined(
                        key: ValueKey('cart_edit_options_${item.id}'),
                        tooltip: CartStrings.editOptions,
                        onPressed: onEditOptions,
                        icon: const Icon(Icons.tune_rounded, size: 19),
                      ),
                    )
                  : OutlinedButton(
                      key: ValueKey('cart_edit_options_${item.id}'),
                      onPressed: onEditOptions,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.sm + 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune_rounded, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              CartStrings.editOptionsShort,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
              return Row(
                key: ValueKey('cart_item_controls_row_${item.id}'),
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  QuantityStepper(
                    value: item.quantity,
                    min: 1,
                    max: item.variant.stock,
                    incrementKey: ValueKey('cart_increment_${item.id}'),
                    decrementKey: ValueKey('cart_decrement_${item.id}'),
                    onChanged: onQuantityChanged,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: editAction,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final profit = Text(
                '${CartStrings.profitTotal}: ${formatIqd(item.profitTotal)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              );
              final total = Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  formatIqd(item.saleTotal + item.packagingTotal),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
              if (constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [profit, const SizedBox(height: 2), total],
                );
              }
              return Row(
                children: [
                  Expanded(child: profit),
                  total,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CartStepIndicator extends StatelessWidget {
  const _CartStepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final labels = [
      CartStrings.cartStep,
      CartStrings.customerStep,
      CartStrings.reviewStep,
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: AppDurations.fast,
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: index <= currentStep
                      ? AppColors.accentSoft
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: index == currentStep
                        ? AppColors.accent
                        : AppColors.divider,
                  ),
                ),
                child: Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: index <= currentStep
                        ? AppColors.accentStrong
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (index < labels.length - 1) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _ReviewInfo extends StatelessWidget {
  const _ReviewInfo({
    required this.icon,
    required this.value,
    this.ltr = false,
  });

  final IconData icon;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    Widget text = Text(
      value,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    );
    if (ltr) {
      text = Directionality(textDirection: TextDirection.ltr, child: text);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: text),
        ],
      ),
    );
  }
}
