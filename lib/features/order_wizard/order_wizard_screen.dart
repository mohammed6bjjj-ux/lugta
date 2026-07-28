import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/request_id.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/price_summary_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../l10n/core_strings.dart';
import '../profile/legal/legal_document_screen.dart';
import '../profile/legal/legal_documents.dart';
import 'order_draft_reconciliation.dart';
import 'wizard_strings.dart';

/// معالج إنشاء الطلب — أربع خطوات: المتغير والكمية، التسعير، الزبون، المراجعة.
class OrderWizardScreen extends StatefulWidget {
  const OrderWizardScreen({super.key, required this.product});

  final Product product;

  @override
  State<OrderWizardScreen> createState() => _OrderWizardScreenState();
}

class _OrderWizardScreenState extends State<OrderWizardScreen> {
  static List<String> get _stepTitles => [
    WizardStrings.stepProduct,
    WizardStrings.stepPrice,
    WizardStrings.stepCustomer,
    WizardStrings.stepReview,
  ];

  /// حشوة سفلية لقوائم الخطوات كي لا يغطي الشريط الزجاجي العائم آخر المحتوى.
  static const double _bottomBarClearance = 120;

  int _step = 0;
  bool _forward = true;
  bool _submitting = false;
  late final String _clientRequestId = newUuidV4();

  // ── الخطوة 1: مسودة عنصر لكل متغير (الكمية 0 = غير مختار) ──
  late Product _product;
  late List<OrderDraftItem> _drafts;

  // ── الخطوة 2 ──
  final TextEditingController _priceController = TextEditingController();

  // ── الخطوة 3 ──
  final GlobalKey<FormState> _customerFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  Governorate? _governorate;
  DeliveryQuote? _deliveryQuote;
  PackagingBox? _packagingBox;
  bool _loadingDeliveryQuote = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _drafts = [
      for (final v in _product.variants)
        OrderDraftItem(variant: v, quantity: 0),
    ];
  }

  @override
  void dispose() {
    _priceController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─────────────────────────── حسابات مشتركة ───────────────────────────

  List<OrderDraftItem> get _selectedItems =>
      _drafts.where((d) => d.quantity > 0).toList();

  int get _totalQuantity => _drafts.fold(0, (sum, d) => sum + d.quantity);

  int get _wholesaleTotal => _selectedItems.fold(
    0,
    (sum, item) =>
        sum +
        (item.variant.wholesalePriceOverride ?? _product.wholesalePrice) *
            item.quantity,
  );

  int get _averageWholesalePrice => _totalQuantity == 0
      ? _product.wholesalePrice
      : (_wholesaleTotal / _totalQuantity).round();

  int get _suggestedSalePrice {
    var value = _product.suggestedPrice;
    for (final item in _selectedItems) {
      final override = item.variant.suggestedPriceOverride;
      if (override != null && override > value) value = override;
    }
    return value;
  }

  int get _effectiveMinSalePrice {
    var value = _product.effectiveMinSalePrice;
    for (final item in _selectedItems) {
      final wholesale =
          item.variant.wholesalePriceOverride ?? _product.wholesalePrice;
      if (wholesale > value) value = wholesale;
    }
    return value;
  }

  int get _salePrice =>
      int.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;

  String? get _priceError {
    if (_priceController.text.trim().isEmpty) return null;
    if (_salePrice < _effectiveMinSalePrice) {
      return WizardStrings.cannotSellBelow(formatIqd(_effectiveMinSalePrice));
    }
    final max = _product.maxSalePrice;
    if (max != null && _salePrice > max) {
      return WizardStrings.cannotSellAbove(formatIqd(max));
    }
    return null;
  }

  bool get _priceValid =>
      _priceController.text.trim().isNotEmpty && _priceError == null;

  int get _unitProfit => _salePrice - _averageWholesalePrice;
  int get _totalProfit => (_salePrice * _totalQuantity) - _wholesaleTotal;

  int get _deliveryFee =>
      _deliveryQuote?.deliveryFee ?? _governorate?.deliveryFee ?? 0;
  int get _baseDeliveryFee =>
      _deliveryQuote?.baseDeliveryFee ?? _governorate?.deliveryFee ?? 0;
  int get _packagingTotal => (_packagingBox?.price ?? 0) * _totalQuantity;

  bool get _nextEnabled {
    if (_submitting) return false;
    return switch (_step) {
      0 => _totalQuantity >= 1 && _selectedItems.length <= maxOrderLineCount,
      1 => _priceValid,
      _ => true,
    };
  }

  void _changeDraftQuantity(OrderDraftItem draft, int quantity) {
    final addsNewLine = draft.quantity == 0 && quantity > 0;
    if (addsNewLine && _selectedItems.length >= maxOrderLineCount) {
      _showSubmissionWarning(WizardStrings.tooManyVariants);
      return;
    }
    setState(() => draft.quantity = quantity);
  }

  Future<void> _selectGovernorate(Governorate? governorate) async {
    setState(() {
      _governorate = governorate;
      _deliveryQuote = null;
      _loadingDeliveryQuote = governorate != null;
    });
    if (governorate == null) return;
    try {
      final quote = await session.quoteDeliveryFee(governorate.id);
      if (!mounted || _governorate?.id != governorate.id) return;
      setState(() {
        _deliveryQuote = quote;
        _loadingDeliveryQuote = false;
      });
    } catch (error) {
      if (!mounted || _governorate?.id != governorate.id) return;
      setState(() => _loadingDeliveryQuote = false);
      _showSubmissionWarning(error.toString());
    }
  }

  // ─────────────────────────── تنقّل الخطوات ───────────────────────────

  void _goNext() {
    FocusScope.of(context).unfocus();
    switch (_step) {
      case 0:
        if (_totalQuantity >= 1) {
          setState(() {
            _forward = true;
            _step = 1;
          });
        }
      case 1:
        if (_priceValid) {
          setState(() {
            _forward = true;
            _step = 2;
          });
        }
      case 2:
        if (_customerFormKey.currentState?.validate() ?? false) {
          setState(() {
            _forward = true;
            _step = 3;
          });
        }
      case 3:
        _submitOrder();
    }
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_step > 0) {
      setState(() {
        _forward = false;
        _step -= 1;
      });
    }
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(WizardStrings.exitDialogTitle),
        content: Text(WizardStrings.exitDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(WizardStrings.stay),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(WizardStrings.exit),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _submitOrder() async {
    if (_submitting) return;
    final selectedGovernorate = _governorate;
    if (selectedGovernorate == null || _selectedItems.isEmpty || !_priceValid) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final results = await Future.wait<Object>([
        session.refreshProductById(_product.id),
        session.refreshCatalog().then<Object>((_) => const Object()),
        session.refreshPublicData().then<Object>((_) => const Object()),
      ]);
      final latestProduct = results.first as Product;
      final reconciliation = reconcileOrderDraft(
        currentDrafts: _drafts,
        latestProduct: latestProduct,
        unitSalePrice: _salePrice,
      );
      if (!mounted) return;

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
          _submitting = false;
          _forward = false;
          _step = 2;
        });
        _showSubmissionWarning(WizardStrings.deliveryZoneUnavailable);
        return;
      }
      final latestQuote = await session.quoteDeliveryFee(latestGovernorate.id);
      if (!mounted) return;
      final deliveryFeeChanged =
          latestQuote.deliveryFee != _deliveryFee ||
          latestQuote.baseDeliveryFee != _baseDeliveryFee;
      final packagingStillAvailable =
          _packagingBox == null ||
          (latestProduct.packagingEnabled &&
              session.packagingBoxes.any((box) => box.id == _packagingBox!.id));

      _product = latestProduct;
      _drafts = reconciliation.drafts;
      _governorate = latestGovernorate;
      _deliveryQuote = latestQuote;
      if (!packagingStillAvailable) {
        _packagingBox = null;
        setState(() {
          _submitting = false;
          _forward = false;
          _step = 0;
        });
        _showSubmissionWarning(WizardStrings.packagingChangedBeforeSubmit);
        return;
      }
      if (reconciliation.selectionAdjusted || reconciliation.tooManyLines) {
        setState(() {
          _submitting = false;
          _forward = false;
          _step = 0;
        });
        _showSubmissionWarning(
          reconciliation.tooManyLines
              ? WizardStrings.tooManyVariants
              : WizardStrings.stockChangedBeforeSubmit,
        );
        return;
      }
      if (reconciliation.priceOutOfRange) {
        setState(() {
          _submitting = false;
          _forward = false;
          _step = 1;
        });
        _showSubmissionWarning(WizardStrings.priceChangedBeforeSubmit);
        return;
      }
      if (deliveryFeeChanged) {
        setState(() {
          _submitting = false;
          _forward = false;
          _step = 3;
        });
        _showSubmissionWarning(WizardStrings.deliveryFeeChangedBeforeSubmit);
        return;
      }

      final order = await session.createOrder(
        clientRequestId: _clientRequestId,
        product: _product,
        items: reconciliation.selectedItems,
        unitSalePrice: _salePrice,
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
        packagingBox: _packagingBox,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacementNamed(Routes.orderSuccess, arguments: order);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _showSubmissionWarning(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─────────────────────────── البناء ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_step > 0) {
          _goBack();
        } else {
          _confirmExit();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: WizardStrings.closeTooltip,
            onPressed: _confirmExit,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppNetworkImage(
                _product.coverImage,
                width: 34,
                height: 34,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  _product.localizedName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _StepIndicator(currentStep: _step, titles: _stepTitles),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildStepSwitcher()),
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 0,
                    child: _buildBottomBar(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// انتقال اتجاهي حديث بين الخطوات: انزلاق أفقي حسب تقدّم/رجوع + تلاشٍ.
  Widget _buildStepSwitcher() {
    // في واجهة RTL التقدم يدفع المحتوى نحو اليسار، والرجوع يعيده لليمين.
    final dx = _forward ? -.16 : .16;
    return AnimatedSwitcher(
      duration: AppDurations.base,
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey<int>(_step);
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppCurves.emphasized,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(incoming ? dx : -dx, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [...previousChildren, ?currentChild],
      ),
      child: KeyedSubtree(
        key: ValueKey<int>(_step),
        child: switch (_step) {
          0 => _buildVariantsStep(),
          1 => _buildPricingStep(),
          2 => _buildCustomerStep(),
          _ => _buildReviewStep(),
        },
      ),
    );
  }

  /// شريط سفلي زجاجي عائم بهامش — يطفو فوق المحتوى بظل واضح.
  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.floating,
        ),
        child: FrostedPanel(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Row(
              children: [
                if (_step > 0 && !_submitting) ...[
                  Expanded(
                    child: SecondaryButton(
                      key: const ValueKey('order_wizard_back_button'),
                      label: WizardStrings.back,
                      onPressed: _goBack,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                ],
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    key: const ValueKey('order_wizard_next_button'),
                    label: _step == 3
                        ? WizardStrings.confirmOrder
                        : WizardStrings.next,
                    icon: _step == 3
                        ? Icons.check_circle_outline_rounded
                        : null,
                    gold: _step == 3,
                    loading: _submitting,
                    onPressed: _nextEnabled ? _goNext : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── الخطوة 1: المتغير والكمية ───────────────────────────

  Widget _buildVariantsStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        _bottomBarClearance,
      ),
      children: [
        Entrance(
          child: Text(
            WizardStrings.variantsTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Entrance(
          index: 1,
          child: Text(
            WizardStrings.variantsSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (i, draft) in _drafts.indexed) ...[
          Entrance(
            index: 2 + i,
            child: _VariantTile(
              draft: draft,
              onQuantityChanged: (q) => _changeDraftQuantity(draft, q),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
        ],
        const SizedBox(height: AppSpacing.sm),
        Entrance(index: 3 + _drafts.length, child: _buildQuantitySummaryCard()),
        if (_product.packagingEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          Entrance(index: 4 + _drafts.length, child: _buildPackagingSelector()),
        ],
      ],
    );
  }

  Widget _buildPackagingSelector() {
    final theme = Theme.of(context);
    final boxes = session.packagingBoxes;
    final withoutPackagingSelected = _packagingBox == null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            WizardStrings.packagingTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            WizardStrings.packagingSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (boxes.any((box) => box.imageUrl.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.zoom_in_rounded,
                  size: 17,
                  color: AppColors.goldDark,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    WizardStrings.packagingImageHint,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Semantics(
            button: true,
            selected: withoutPackagingSelected,
            child: AnimatedContainer(
              key: const ValueKey('packaging_none'),
              duration: AppDurations.base,
              curve: AppCurves.emphasized,
              decoration: BoxDecoration(
                color: withoutPackagingSelected
                    ? AppColors.goldSoft
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: withoutPackagingSelected
                      ? AppColors.gold
                      : AppColors.divider,
                  width: withoutPackagingSelected ? 1.6 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => setState(() => _packagingBox = null),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 4,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: AppDurations.base,
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: withoutPackagingSelected
                                ? AppColors.gold
                                : AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            withoutPackagingSelected
                                ? Icons.check_rounded
                                : Icons.block_rounded,
                            color: withoutPackagingSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 4),
                        Expanded(
                          child: Text(
                            WizardStrings.noPackaging,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: withoutPackagingSelected
                                  ? AppColors.goldDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (boxes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 4),
            LayoutBuilder(
              builder: (context, constraints) {
                final columnCount = constraints.maxWidth >= 620
                    ? 3
                    : constraints.maxWidth >= 330
                    ? 2
                    : 1;
                const gap = AppSpacing.sm + 4;
                final tileWidth =
                    (constraints.maxWidth - (columnCount - 1) * gap) /
                    columnCount;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final box in boxes)
                      SizedBox(
                        width: tileWidth,
                        child: _PackagingBoxCard(
                          key: ValueKey('packaging_box_${box.id}'),
                          box: box,
                          selected: _packagingBox?.id == box.id,
                          onSelected: () => setState(() => _packagingBox = box),
                          onPreview: box.imageUrl.isEmpty
                              ? null
                              : () => _showPackagingPreview(box),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPackagingPreview(PackagingBox box) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PackagingPreviewScreen(box: box),
      ),
    );
  }

  Widget _buildQuantitySummaryCard() {
    final theme = Theme.of(context);
    final hasSelection = _totalQuantity > 0;
    return AnimatedContainer(
      duration: AppDurations.base,
      curve: AppCurves.emphasized,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasSelection ? AppColors.goldSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasSelection
              ? AppColors.gold.withValues(alpha: .55)
              : Colors.transparent,
          width: 1.4,
        ),
        boxShadow: hasSelection ? AppShadows.goldGlow : AppShadows.card,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppDurations.base,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasSelection ? AppColors.goldGradient : null,
              color: hasSelection ? null : AppColors.surfaceAlt,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 22,
              color: hasSelection ? Colors.white : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSelection
                      ? WizardStrings.totalPieces(formatNumber(_totalQuantity))
                      : WizardStrings.noPiecesSelected,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasSelection
                      ? WizardStrings.wholesaleTotal(formatIqd(_wholesaleTotal))
                      : WizardStrings.increaseQuantityHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── الخطوة 2: التسعير ───────────────────────────

  Widget _buildPricingStep() {
    final theme = Theme.of(context);
    final error = _priceError;
    final valid = _priceValid;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        _bottomBarClearance,
      ),
      children: [
        Entrance(
          child: Text(
            WizardStrings.pricingTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Entrance(
          index: 1,
          child: Text(
            WizardStrings.pricingSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Entrance(
          index: 2,
          child: AppCard(
            child: Column(
              children: [
                _priceInfoRow(
                  WizardStrings.wholesalePerPiece,
                  formatIqd(_averageWholesalePrice),
                  emphasized: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                _priceInfoRow(
                  WizardStrings.suggestedPrice,
                  formatIqd(_suggestedSalePrice),
                ),
                const SizedBox(height: AppSpacing.sm),
                _priceInfoRow(
                  WizardStrings.minAllowedPrice,
                  formatIqd(_effectiveMinSalePrice),
                ),
                if (_product.maxSalePrice != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _priceInfoRow(
                    WizardStrings.maxAllowedPrice,
                    formatIqd(_product.maxSalePrice!),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Entrance(
          index: 3,
          child: AppTextField(
            fieldKey: const ValueKey('order_sale_price_field'),
            label: WizardStrings.salePriceLabel,
            controller: _priceController,
            hint: WizardStrings.exampleHint(formatNumber(_suggestedSalePrice)),
            keyboardType: TextInputType.number,
            prefixIcon: Icons.sell_outlined,
            inputFormatters: [_ThousandsSeparatorFormatter()],
            onChanged: (_) => setState(() {}),
          ),
        ),
        AnimatedSize(
          duration: AppDurations.base,
          curve: AppCurves.emphasized,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: AppDurations.base,
            switchInCurve: AppCurves.emphasized,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -.25),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: error == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey<String>(error),
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            error,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        Entrance(
          index: 4,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () {
                _priceController.text = formatNumber(_suggestedSalePrice);
                setState(() {});
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                foregroundColor: AppColors.goldDark,
                backgroundColor: AppColors.surface,
                shape: const StadiumBorder(),
                side: BorderSide(color: AppColors.gold.withValues(alpha: .55)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                WizardStrings.useSuggestedPrice(formatIqd(_suggestedSalePrice)),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Entrance(
          index: 5,
          child: _buildProfitCard(valid: valid, invalidInput: error != null),
        ),
      ],
    );
  }

  Widget _priceInfoRow(String label, String value, {bool emphasized = false}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: emphasized
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: emphasized ? AppColors.goldDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// بطاقة الربح اللحظية — تتلوّن حسب صحة السعر وتعدّ الأرقام تصاعدياً.
  Widget _buildProfitCard({required bool valid, required bool invalidInput}) {
    final theme = Theme.of(context);
    final hasInput = _priceController.text.trim().isNotEmpty;
    final (Gradient bg, Color fg) = switch ((valid, invalidInput)) {
      (true, _) => (
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.successSoft, AppColors.surface],
        ),
        AppColors.success,
      ),
      (_, true) => (
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.errorSoft, AppColors.surface],
        ),
        AppColors.error,
      ),
      _ => (
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface, AppColors.surface],
        ),
        AppColors.textSecondary,
      ),
    };
    return AnimatedContainer(
      duration: AppDurations.base,
      curve: AppCurves.emphasized,
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        gradient: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 20, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  WizardStrings.profitCalcTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: .85),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: AppShadows.card,
                ),
                child: Text(
                  WizardStrings.piecesCount(formatNumber(_totalQuantity)),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  WizardStrings.profitPerPiece,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasInput)
                _CountingIqd(
                  value: _unitProfit,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: valid ? AppColors.textPrimary : fg,
                  ),
                )
              else
                Text(
                  '—',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  WizardStrings.totalProfit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              if (hasInput)
                _CountingIqd(
                  value: _totalProfit,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: fg,
                  ),
                )
              else
                Text(
                  '—',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: fg,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── الخطوة 3: الزبون والعنوان ───────────────────────────

  Widget _buildCustomerStep() {
    final theme = Theme.of(context);
    return Form(
      key: _customerFormKey,
      child: ListView(
        key: const ValueKey('order_customer_scrollable'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          _bottomBarClearance,
        ),
        children: [
          Entrance(
            child: Text(
              WizardStrings.customerTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Entrance(
            index: 1,
            child: Text(
              WizardStrings.customerSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Entrance(
            index: 2,
            child: AppTextField(
              fieldKey: const ValueKey('order_customer_name_field'),
              label: WizardStrings.customerName,
              controller: _nameController,
              hint: WizardStrings.customerNameHint,
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) => validateRequired(
                v,
                message: WizardStrings.customerNameRequired,
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(160)],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Entrance(
            index: 3,
            child: AppTextField(
              fieldKey: const ValueKey('order_customer_phone_field'),
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
          ),
          const SizedBox(height: AppSpacing.md),
          Entrance(
            index: 4,
            child: AppTextField(
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
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? null
                  : validateIraqiPhone(v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Entrance(
            index: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdownLabel(WizardStrings.governorate),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<Governorate>(
                  key: const ValueKey('order_governorate_field'),
                  initialValue: _governorate,
                  isExpanded: true,
                  hint: Text(WizardStrings.selectGovernorate),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.location_city_outlined,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  items: [
                    for (final g in session.governorates)
                      DropdownMenuItem(
                        key: ValueKey<String>(
                          'order_governorate_option_${g.id}',
                        ),
                        value: g,
                        child: Text(
                          g.localizedName,
                          key: ValueKey<String>(
                            'order_governorate_option_label_${g.id}',
                          ),
                        ),
                      ),
                  ],
                  onChanged: (g) {
                    _selectGovernorate(g);
                  },
                  validator: (g) =>
                      g == null ? WizardStrings.selectGovernorate : null,
                ),
              ],
            ),
          ),
          if (_governorate != null) ...[
            const SizedBox(height: AppSpacing.sm + 4),
            Entrance(
              key: ValueKey<String>('fee-${_governorate!.id}'),
              offsetY: 14,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md + 2,
                    vertical: AppSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: AppShadows.goldGlow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          _loadingDeliveryQuote
                              ? WizardStrings.checkingDeliveryOffer
                              : (_deliveryQuote?.isFree == true
                                    ? WizardStrings.freeDelivery
                                    : WizardStrings.deliveryFeeIs(
                                        formatIqd(_deliveryFee),
                                      )),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Entrance(
            index: 7,
            child: AppTextField(
              fieldKey: const ValueKey('order_address_field'),
              label: WizardStrings.addressLabel,
              controller: _addressController,
              hint: WizardStrings.addressHint,
              prefixIcon: Icons.home_outlined,
              maxLines: 3,
              inputFormatters: [LengthLimitingTextInputFormatter(1200)],
              validator: (v) =>
                  validateRequired(v, message: WizardStrings.addressRequired),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Entrance(
            index: 8,
            child: AppTextField(
              label: WizardStrings.deliveryNotes,
              controller: _notesController,
              hint: WizardStrings.deliveryNotesHint,
              prefixIcon: Icons.sticky_note_2_outlined,
              maxLines: 2,
              inputFormatters: [LengthLimitingTextInputFormatter(2000)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownLabel(String label) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  // ─────────────────────────── الخطوة 4: المراجعة والتأكيد ───────────────────────────

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        _bottomBarClearance,
      ),
      children: [
        Entrance(
          child: Text(
            WizardStrings.reviewTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Entrance(
          index: 1,
          child: _reviewCard(
            icon: Icons.watch_outlined,
            title: WizardStrings.productAndItems,
            child: Column(
              children: [
                Row(
                  children: [
                    AppNetworkImage(
                      _product.coverImage,
                      width: 52,
                      height: 52,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Text(
                        _product.localizedName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                  child: Divider(),
                ),
                for (final item in _selectedItems)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        AppNetworkImage(
                          item.variant.imageUrl,
                          width: 36,
                          height: 36,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        const SizedBox(width: AppSpacing.sm + 4),
                        Expanded(
                          child: Text(
                            item.variant.localizedName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neutralChip,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '× ${formatNumber(item.quantity)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_packagingBox != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                    child: Divider(),
                  ),
                  _reviewInfoRow(
                    Icons.inventory_2_outlined,
                    _packagingBox!.isFree
                        ? '${_packagingBox!.name} · ${WizardStrings.freePackaging}'
                        : '${_packagingBox!.name} · ${formatIqd(_packagingTotal)}',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Entrance(
          index: 2,
          child: _reviewCard(
            icon: Icons.person_pin_circle_outlined,
            title: WizardStrings.customerAndAddress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewInfoRow(
                  Icons.person_outline_rounded,
                  _nameController.text.trim(),
                ),
                _reviewInfoRow(
                  Icons.phone_outlined,
                  _phone2Controller.text.trim().isEmpty
                      ? _phoneController.text.trim()
                      : '${_phoneController.text.trim()} — ${_phone2Controller.text.trim()}',
                ),
                _reviewInfoRow(
                  Icons.location_on_outlined,
                  _governorate?.localizedName ?? '',
                ),
                _reviewInfoRow(
                  Icons.home_outlined,
                  _addressController.text.trim(),
                ),
                if (_notesController.text.trim().isNotEmpty)
                  _reviewInfoRow(
                    Icons.sticky_note_2_outlined,
                    _notesController.text.trim(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Entrance(
          index: 3,
          child: PriceSummaryCard(
            wholesaleTotal: _wholesaleTotal,
            saleTotal: _salePrice * _totalQuantity,
            deliveryFee: _deliveryFee,
            baseDeliveryFee: _baseDeliveryFee,
            packagingTotal: _packagingTotal,
            quantity: _totalQuantity,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Entrance(
          index: 4,
          child: ListenableBuilder(
            listenable: session,
            builder: (context, _) => AppCard(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.goldSoft, AppColors.surface],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldGradient,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    child: Text(
                      WizardStrings.storeNameNotice(session.seller.storeName),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Entrance(
          index: 5,
          child: AppCard(
            color: AppColors.infoSoft,
            shadows: const [],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.policy_outlined, color: AppColors.info),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        WizardStrings.orderPolicyNotice,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('order_policy_link'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LegalDocumentScreen(
                              document: LegalDocuments.orders,
                            ),
                          ),
                        ),
                        child: Text(WizardStrings.readOrderPolicy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldSoft,
                ),
                child: Icon(icon, size: 18, color: AppColors.goldDark),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          child,
        ],
      ),
    );
  }

  Widget _reviewInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── عدّاد مبلغ متحرك ───────────────────────────

/// نص مبلغ يعدّ تصاعدياً نحو قيمته عند كل تغيّر (Count-up).
class _CountingIqd extends StatelessWidget {
  const _CountingIqd({required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: AppDurations.slow,
      curve: AppCurves.emphasized,
      builder: (context, v, _) => Text(
        formatIqd(v),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

// ─────────────────────────── مؤشر التقدم ───────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.titles});

  final int currentStep;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < titles.length; i++) ...[
            if (i > 0) Expanded(child: _ProgressLine(filled: i <= currentStep)),
            _StepDot(
              index: i,
              title: titles[i],
              state: switch (i) {
                _ when i < currentStep => _StepDotState.done,
                _ when i == currentStep => _StepDotState.current,
                _ => _StepDotState.upcoming,
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// خط تقدم بين دائرتين — يمتلئ بتدرج ذهبي بعرض متحرك.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: SizedBox(
          height: 3.4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: AppColors.divider),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: filled ? 1 : 0),
                  duration: AppDurations.slow,
                  curve: AppCurves.emphasized,
                  builder: (context, t, child) => FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: t,
                    child: child,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.goldGradient),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StepDotState { done, current, upcoming }

/// دائرة خطوة: المنجزة بتدرج ذهبي وعلامة صح نابضة، والحالية بحلقة ذهبية نابضة.
class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.title,
    required this.state,
  });

  final int index;
  final String title;
  final _StepDotState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dot = AnimatedContainer(
      duration: AppDurations.base,
      curve: AppCurves.emphasized,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: state == _StepDotState.done ? AppColors.goldGradient : null,
        color: switch (state) {
          _StepDotState.done => null,
          _StepDotState.current => AppColors.primary,
          _StepDotState.upcoming => AppColors.surface,
        },
        border: state == _StepDotState.upcoming
            ? Border.all(color: AppColors.divider, width: 1.4)
            : null,
        boxShadow: switch (state) {
          _StepDotState.done => AppShadows.goldGlow,
          _StepDotState.current => AppShadows.card,
          _StepDotState.upcoming => null,
        },
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: AppDurations.base,
          switchInCurve: AppCurves.spring,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: state == _StepDotState.done
              ? const Icon(
                  Icons.check_rounded,
                  key: ValueKey('check'),
                  size: 17,
                  color: Colors.white,
                )
              : Text(
                  formatNumber(index + 1),
                  key: const ValueKey('number'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: state == _StepDotState.current
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
        ),
      ),
    );

    return SizedBox(
      width: 64,
      child: Column(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (state == _StepDotState.current) const _PulseRing(),
                dot,
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: state == _StepDotState.current
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: state == _StepDotState.upcoming
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// حلقة ذهبية نابضة تحيط بدائرة الخطوة الحالية.
class _PulseRing extends StatefulWidget {
  const _PulseRing();

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);
        return Opacity(
          opacity: (1 - t) * .55,
          child: Transform.scale(
            scale: .95 + t * .42,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PackagingBoxCard extends StatelessWidget {
  const _PackagingBoxCard({
    super.key,
    required this.box,
    required this.selected,
    required this.onSelected,
    this.onPreview,
  });

  final PackagingBox box;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceLabel = box.isFree
        ? WizardStrings.freePackaging
        : formatIqd(box.price);

    return Semantics(
      key: ValueKey('packaging_box_semantics_${box.id}'),
      button: true,
      selected: selected,
      label: '${box.name}, $priceLabel',
      child: AnimatedContainer(
        duration: AppDurations.base,
        curve: AppCurves.emphasized,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppShadows.goldGlow : AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onSelected,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.18,
                      child: AppNetworkImage(
                        box.imageUrl,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.inventory_2_outlined,
                      ),
                    ),
                    if (selected)
                      PositionedDirectional(
                        top: AppSpacing.sm,
                        end: AppSpacing.sm,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.card,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (onPreview != null)
                      PositionedDirectional(
                        bottom: AppSpacing.sm,
                        end: AppSpacing.sm,
                        child: Material(
                          color: Colors.black.withValues(alpha: .64),
                          shape: const CircleBorder(),
                          child: InkWell(
                            key: ValueKey('packaging_preview_${box.id}'),
                            customBorder: const CircleBorder(),
                            onTap: onPreview,
                            child: const Padding(
                              padding: EdgeInsets.all(7),
                              child: Icon(
                                Icons.zoom_in_rounded,
                                size: 19,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 42,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            box.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: box.isFree
                              ? AppColors.success
                              : AppColors.goldDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PackagingPreviewScreen extends StatelessWidget {
  const _PackagingPreviewScreen({required this.box});

  final PackagingBox box;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceLabel = box.isFree
        ? WizardStrings.freePackaging
        : formatIqd(box.price);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: AppNetworkImage(
                      box.imageUrl,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.contain,
                      fallbackIcon: Icons.inventory_2_outlined,
                    ),
                  ),
                );
              },
            ),
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Material(
                  color: Colors.black.withValues(alpha: .62),
                  shape: const CircleBorder(),
                  child: IconButton(
                    key: const ValueKey('packaging_preview_close'),
                    tooltip: WizardStrings.closeTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.xxl,
                  bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .86),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      box.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      priceLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.p.brightness == Brightness.dark
                            ? AppColors.goldDark
                            : AppColors.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── بطاقة المتغير ───────────────────────────

class _VariantTile extends StatelessWidget {
  const _VariantTile({required this.draft, required this.onQuantityChanged});

  final OrderDraftItem draft;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant = draft.variant;
    final selected = draft.quantity > 0;
    final outOfStock = !variant.inStock;

    return Opacity(
      opacity: outOfStock ? .55 : 1,
      child: AnimatedContainer(
        duration: AppDurations.base,
        curve: AppCurves.emphasized,
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.goldSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? AppColors.gold.withValues(alpha: .65)
                : Colors.transparent,
            width: 1.4,
          ),
          boxShadow: selected ? AppShadows.goldGlow : AppShadows.card,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  variant.imageUrl,
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                if (variant.colorHex != null)
                  PositionedDirectional(
                    bottom: 3,
                    start: 3,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Color(variant.colorHex!),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.6),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.localizedName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (outOfStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorSoft,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        CoreStrings.badgeOutOfStock,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else
                    Text(
                      variant.lowStock
                          ? WizardStrings.stockLimited(
                              formatNumber(variant.stock),
                            )
                          : WizardStrings.stockCount(
                              formatNumber(variant.stock),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: variant.lowStock
                            ? AppColors.warning
                            : AppColors.textSecondary,
                        fontWeight: variant.lowStock
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (!outOfStock)
              QuantityStepper(
                incrementKey: ValueKey<String>(
                  'variant_increment_${variant.id}',
                ),
                decrementKey: ValueKey<String>(
                  'variant_decrement_${variant.id}',
                ),
                value: draft.quantity,
                max: variant.stock,
                onChanged: onQuantityChanged,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── منسّق فواصل الآلاف ───────────────────────────

/// يضيف فواصل الآلاف أثناء الكتابة ويمنع أي محارف غير رقمية.
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    if (digits.length > 9) digits = digits.substring(0, 9);
    final formatted = formatNumber(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
