import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_network_image.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../data/storefront_draft_store.dart';
import '../../data/storefront_models.dart';
import '../../data/storefront_media.dart';
import '../../data/storefront_validation.dart';
import 'storefront_strings.dart';
import 'storefront_view_model.dart';
import 'storefront_widgets.dart';
import 'storefront_image_picker.dart';
import 'storefront_design_widgets.dart';

List<StoreTheme> get storefrontThemes => List<StoreTheme>.unmodifiable([
  for (var index = 1; index <= 10; index++)
    StoreTheme(
      id: 'theme$index',
      name:
          '${StorefrontStrings.t('تصميم', 'دیزاین', 'Design')} ${index.toString().padLeft(2, '0')}',
      thumbnailAsset: 'assets/storefronts/theme-$index-thumb.png',
      previewAsset: 'assets/storefronts/theme-$index-full.png',
    ),
]);

/// Scoped extension of Lugta's existing trade-counter design. The theme gallery
/// uses real website screenshots; all eligibility and publishing state is server
/// authoritative. No order or cart state is mutated by configuring a storefront.
class StorefrontScreen extends StatefulWidget {
  const StorefrontScreen({
    super.key,
    this.product,
    this.initialVariantId,
    this.viewModel,
    this.pickImage,
    this.recoverLostData,
    this.refreshProduct,
  });
  final Product? product;
  final String? initialVariantId;
  @visibleForTesting
  final StorefrontViewModel? viewModel;
  @visibleForTesting
  final Future<XFile?> Function()? pickImage;
  @visibleForTesting
  final Future<LostDataResponse> Function()? recoverLostData;
  @visibleForTesting
  final Future<Product> Function(String)? refreshProduct;
  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  late final StorefrontViewModel _model;
  List<StoreTheme> get _themes => _model.snapshot?.designs ?? storefrontThemes;
  String? _openingProduct;
  final _brand = TextEditingController();
  final _slug = TextEditingController();
  final _price = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _picker = ImagePicker();
  bool _detailsStep = false;
  bool _editing = false;
  bool _picking = false;
  bool _controllersReady = false;
  ProductVariant? _variant;
  Uint8List? _logoBytes;
  Timer? _expiryTimer;
  String? _localError;
  Product? _freshProduct;
  bool _productRefreshing = false;
  bool _productRefreshFailed = false;
  bool _listingSaved = false;
  bool _activating = false;
  bool _removing = false;
  bool _confirmingRemoval = false;
  final Set<String> _selectedVariants = {};
  String? _coverMediaId;
  final Map<String, String> _variantMedia = {};

  @override
  void initState() {
    super.initState();
    final userId = session.auth.currentUserId;
    _model =
        widget.viewModel ??
        StorefrontViewModel(
          repository: session.storefront,
          drafts: PreferencesStorefrontDraftStore(userId ?? 'unavailable'),
          isCurrentUser: () =>
              userId != null && userId == session.auth.currentUserId,
        );
    unawaited(_initialize());
    _expiryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initialize() async {
    if (_model.busy) return;
    final productRefresh = _refreshProduct();
    await _model.load();
    await productRefresh;
    if (!mounted) return;
    _selectExistingListing();
    _syncControllers();
    try {
      final pending = await _model.drafts.isPickerPending();
      if (!mounted || !pending) return;
      final response =
          await (widget.recoverLostData?.call() ?? _picker.retrieveLostData());
      if (!mounted) return;
      final file = response.files?.firstOrNull ?? response.file;
      if (file != null) {
        await _acceptLogo(file);
      } else if (response.exception != null) {
        setState(() => _localError = StorefrontStrings.logoError);
      }
      await _model.drafts.setPickerPending(false);
    } catch (_) {
      if (mounted) setState(() => _localError = StorefrontStrings.logoError);
    }
  }

  void _selectExistingListing() {
    final product = _freshProduct ?? widget.product;
    if (product == null || _variant != null) return;
    final listings = _model.snapshot?.listings ?? const <StoreListing>[];
    final listing = listings
        .where(
          (item) =>
              item.productId == product.id &&
              (widget.initialVariantId == null ||
                  item.variantId == widget.initialVariantId),
        )
        .firstOrNull;
    final variant = product.variants
        .where((item) => item.id == listing?.variantId)
        .firstOrNull;
    if (listing == null || variant == null) return;
    setState(() {
      _variant = variant;
      _selectedVariants.addAll(
        listings
            .where((item) => item.productId == product.id)
            .map((item) => item.variantId),
      );
      _price.text = '${listing.retailPrice}';
      _coverMediaId = listing.coverMediaId;
      for (final item in listings.where(
        (item) => item.productId == product.id,
      )) {
        if (item.imageMediaId != null) {
          _variantMedia[item.variantId] = item.imageMediaId!;
        }
      }
    });
  }

  Future<void> _refreshProduct() async {
    final source = widget.product;
    if (source == null || _productRefreshing) return;
    if (widget.viewModel != null && widget.refreshProduct == null) return;
    setState(() {
      _productRefreshing = true;
      _productRefreshFailed = false;
    });
    try {
      final current =
          await (widget.refreshProduct?.call(source.id) ??
                  session.refreshProductById(source.id))
              .timeout(const Duration(seconds: 20));
      if (mounted) setState(() => _freshProduct = current);
    } catch (_) {
      if (mounted) setState(() => _productRefreshFailed = true);
    } finally {
      if (mounted) setState(() => _productRefreshing = false);
    }
  }

  void _syncControllers() {
    if (_controllersReady) return;
    _controllersReady = true;
    _brand.text = _model.draft.brandName;
    _slug.text = _model.draft.slug;
    setState(() => _detailsStep = _model.draft.themeId.isNotEmpty);
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _brand.dispose();
    _slug.dispose();
    _price.dispose();
    if (widget.viewModel == null) _model.dispose();
    super.dispose();
  }

  void _persistForm() => _model.updateDraft(
    _model.draft.copyWith(brandName: _brand.text, slug: _slug.text),
  );

  Future<void> _selectTheme(StoreTheme theme) async {
    final current = _model.draft;
    final keepPalette =
        current.themeId == theme.id &&
        theme.palettes.any((palette) => palette.id == current.paletteId);
    _model.updateDraft(
      _model.draft.copyWith(
        themeId: theme.id,
        paletteId: keepPalette
            ? current.paletteId
            : theme.palettes.firstOrNull?.id ?? '',
      ),
    );
    setState(() => _detailsStep = true);
  }

  Future<void> _preview(StoreTheme theme) async {
    final selected = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StoreThemePreviewScreen(theme: theme)),
    );
    if (!mounted || selected != true) return;
    await _selectTheme(theme);
  }

  Future<void> _pickLogo() async {
    if (_picking || _model.busy) return;
    setState(() {
      _picking = true;
      _localError = null;
    });
    try {
      _persistForm();
      await _model.drafts.setPickerPending(true);
      if (!mounted) return;
      final file =
          await (widget.pickImage?.call() ??
              _picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1200,
                maxHeight: 1200,
                imageQuality: 85,
              ));
      if (file != null) await _acceptLogo(file);
      await _model.drafts.setPickerPending(false);
    } catch (_) {
      if (mounted) setState(() => _localError = StorefrontStrings.logoError);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _acceptLogo(XFile file) async {
    if (await file.length() > 2 * 1024 * 1024) {
      throw const FormatException('logo too large');
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final mime = storefrontLogoMime(bytes);
    if (mime == null || bytes.length > 2 * 1024 * 1024) {
      throw const FormatException('invalid image');
    }
    setState(() => _logoBytes = bytes);
    final saved = await _model.uploadLogo(bytes, mime);
    if (!mounted) return;
    if (!saved) setState(() => _localError = StorefrontStrings.loadError);
  }

  Future<void> _saveStore() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    _persistForm();
    if (_model.draft.logoPath.isEmpty) {
      setState(() => _localError = StorefrontStrings.pickLogo);
      return;
    }
    final saved = await _model.save();
    if (!mounted || !saved) return;
    setState(() {
      _editing = false;
      _localError = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(StorefrontStrings.saved)));
  }

  String _errorText(String code) {
    if (code.contains('invalid_image')) {
      return StorefrontStrings.t(
        'الصورة لم تعد متاحة. حدّث المنتج واختر صورة من صوره الحالية.',
        'وێنە بەردەست نییە؛ بەرهەم نوێ بکەرەوە و وێنەیەک هەڵبژێرە.',
        'Image unavailable. Refresh the product and select an existing image.',
      );
    }
    if (code == 'remove_not_confirmed') {
      return StorefrontStrings.removeNotConfirmed;
    }
    if (code == 'request_timeout' || code == 'save_not_confirmed') {
      return StorefrontStrings.uncertainSave;
    }
    if (code.contains('listing_limit')) return StorefrontStrings.listingLimit;
    if (code.contains('variant_not_found') ||
        code.contains('price_or_product_invalid')) {
      return StorefrontStrings.refreshProduct;
    }
    if (code.contains('authentication') || code.contains('JWT')) {
      return StorefrontStrings.signInAgain;
    }
    if (code.contains('eligible') ||
        code.contains('silver') ||
        code.contains('requires_ten_completed_orders')) {
      return StorefrontStrings.eligibilityBody;
    }
    if (code.contains('slug')) {
      return StorefrontStrings.t(
        'عنوان المتجر غير متاح أو غير صالح. جرّب عنواناً آخر.',
        'ناونیشانی فرۆشگا بەردەست نییە یان دروست نییە. ناونیشانێکی تر تاقی بکەرەوە.',
        'This store address is unavailable or invalid. Try another address.',
      );
    }
    if (code.contains('logo')) return StorefrontStrings.logoError;
    if (code == 'unavailable') return StorefrontStrings.unavailable;
    if (code == 'draft_write_failed') {
      return StorefrontStrings.t(
        'تعذر حفظ المسودة على الجهاز. أبقِ هذه الصفحة مفتوحة.',
        'نەتوانرا ڕەشنووس پاشەکەوت بکرێت. پەڕەکە کراوە بهێڵەوە.',
        'Could not save the draft on this device. Keep this page open.',
      );
    }
    if (code.contains('price')) return StorefrontStrings.invalidPrice;
    return StorefrontStrings.loadError;
  }

  Future<void> _activateStore() async {
    if (_model.busy || _model.loading || _activating) return;
    setState(() => _activating = true);
    try {
      final saved = await _model.activate();
      if (mounted && saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(StorefrontStrings.active)));
      }
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: ListenableBuilder(
        listenable: _model,
        builder: (context, _) => Text(
          widget.product == null
              ? StorefrontStrings.title
              : (_model.snapshot?.listings.any(
                      (item) => item.productId == widget.product!.id,
                    ) ??
                    false)
              ? StorefrontStrings.manageProduct
              : StorefrontStrings.addProduct,
        ),
      ),
      actions: [
        IconButton(
          tooltip: StorefrontStrings.retry,
          onPressed: _model.busy || _productRefreshing ? null : _initialize,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _model,
        builder: (context, _) {
          if (_model.loading && _model.snapshot == null) {
            return const StorefrontLoading();
          }
          final snapshot = _model.snapshot;
          if (snapshot == null) {
            return ListView(
              children: [
                StorefrontMessage(
                  title: StorefrontStrings.title,
                  body: _errorText(_model.errorCode ?? 'network'),
                  icon: Icons.cloud_off_outlined,
                  action: StorefrontAction(
                    label: StorefrontStrings.retry,
                    onPressed: _initialize,
                  ),
                ),
              ],
            );
          }
          if (!snapshot.eligible) {
            return ListView(
              children: [
                StorefrontMessage(
                  title: StorefrontStrings.eligibility,
                  body: StorefrontStrings.eligibilityBody,
                  icon: Icons.lock_outline,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  child: Text(
                    '${formatNumber(snapshot.completedOrders)} / 10',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(StorefrontStrings.recentOrders),
                ),
                for (final order in snapshot.orderProgress)
                  ListTile(
                    title: Text(order.number, textDirection: TextDirection.ltr),
                    subtitle: Text(
                      StorefrontStrings.progressReason(order.status),
                    ),
                    leading: Icon(
                      order.status == 'completed'
                          ? Icons.check_circle_outline
                          : Icons.schedule,
                    ),
                  ),
              ],
            );
          }
          if (snapshot.store == null || _editing) {
            return _detailsStep ? _buildDetails() : _buildGallery();
          }
          if (widget.product != null) return _buildProductForm(widget.product!);
          return _buildStore(snapshot);
        },
      ),
    ),
  );

  Widget _errors() => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
        child: Text(
          _localError ??
              (_model.errorCode == null ? '' : _errorText(_model.errorCode!)),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    ),
  );

  Widget _buildGallery() => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 600 &&
              MediaQuery.textScalerOf(context).scale(16) < 28
          ? 2
          : 1;
      return ListView.builder(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        itemCount: 1 + (_themes.length / columns).ceil(),
        itemBuilder: (context, row) {
          if (row == 0) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StorefrontSetupProgress(step: 1),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    StorefrontStrings.themes,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    StorefrontStrings.t(
                      'اختر التصميم المناسب لبراندك، ثم اختر ألوانه. التصاميم وصورها تتحدّث من الإدارة.',
                      'دیزاینی گونجاو بۆ براندەکەت هەڵبژێرە، پاشان ڕەنگەکانی. دیزاین و وێنەکان لەلایەن بەڕێوەبەرایەتی نوێ دەکرێنەوە.',
                      'Choose a design for your brand, then its colors. Designs and previews are updated by the administrator.',
                    ),
                  ),
                  if (_themes.isEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      StorefrontStrings.t(
                        'لا توجد تصاميم متاحة للاختيار حالياً. جرّب تحديث القائمة لاحقاً.',
                        'ئێستا هیچ دیزاینێک بەردەست نییە. دواتر لیستەکە نوێ بکەرەوە.',
                        'No designs are currently available. Try refreshing the list later.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _model.loading ? null : _model.load,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        StorefrontStrings.t(
                          'تحديث التصاميم',
                          'نوێکردنەوەی دیزاینەکان',
                          'Refresh designs',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          final start = (row - 1) * columns;
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (
                  var column = 0;
                  column < columns && start + column < _themes.length;
                  column++
                ) ...[
                  if (column > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StoreThemeCard(
                      theme: _themes[start + column],
                      selected:
                          _model.draft.themeId == _themes[start + column].id,
                      onSelect: () => _selectTheme(_themes[start + column]),
                      onPreview: () => _preview(_themes[start + column]),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );

  Widget _buildDetails() => Form(
    key: _form,
    child: ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        const StorefrontSetupProgress(step: 2),
        const SizedBox(height: AppSpacing.md),
        Text(
          StorefrontStrings.details,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextButton.icon(
          onPressed: _model.busy
              ? null
              : () => setState(() => _detailsStep = false),
          icon: const Icon(Icons.palette_outlined),
          label: Text(StorefrontStrings.themes),
        ),
        if (_themes
                .where((theme) => theme.id == _model.draft.themeId)
                .firstOrNull
            case final theme?)
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _model.busy ? null : () => _preview(theme),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: StoreDesignImage(
                        theme: theme,
                        width: 56,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            theme.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(StorefrontStrings.preview),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_full),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (_themes.where((t) => t.id == _model.draft.themeId).firstOrNull
            case final design?)
          if (design.palettes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: StorePalettePicker(
                palettes: design.palettes,
                value: _model.draft.paletteId,
                onChanged: _model.busy
                    ? null
                    : (id) => _model.updateDraft(
                        _model.draft.copyWith(paletteId: id),
                      ),
              ),
            ),
        TextFormField(
          key: const ValueKey('storefront_brand'),
          controller: _brand,
          enabled: !_model.busy,
          onChanged: (_) => _persistForm(),
          maxLength: 80,
          decoration: InputDecoration(labelText: StorefrontStrings.brand),
          validator: (value) => (value?.trim().runes.length ?? 0) < 2
              ? StorefrontStrings.t(
                  'أدخل اسم متجر من حرفين إلى 80 حرفاً.',
                  'ناوی فرۆشگا لە ٢ تا ٨٠ پیت بێت.',
                  'Enter a store name from 2 to 80 characters.',
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: const ValueKey('storefront_slug'),
          controller: _slug,
          enabled: !_model.busy,
          readOnly: _model.snapshot?.store != null,
          onChanged: (_) => _persistForm(),
          textDirection: TextDirection.ltr,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 30,
          decoration: InputDecoration(
            labelText: StorefrontStrings.slug,
            helperText: _model.snapshot?.store == null
                ? StorefrontStrings.slugHelp
                : StorefrontStrings.t(
                    'عنوان المتجر ثابت بعد الإنشاء لحماية رابطك.',
                    'ناونیشانی فرۆشگا دوای دروستکردن ناگۆڕێت.',
                    'The store address cannot change after creation, so your link stays valid.',
                  ),
            helperMaxLines: 5,
          ),
          validator: (value) => isValidStorefrontSlug(value ?? '')
              ? null
              : StorefrontStrings.slugHelp,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_slug.text.trim().isEmpty ? 'your-store' : _slug.text.trim()}.lugta.app',
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          StorefrontStrings.logo,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox.square(
            dimension: 96,
            child: _logoBytes != null
                ? Image.memory(
                    _logoBytes!,
                    cacheWidth: 240,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  )
                : AppNetworkImage(
                    _model.draft.logoUrl,
                    fit: BoxFit.contain,
                    fallbackIcon: Icons.storefront_outlined,
                  ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _picking || _model.busy ? null : _pickLogo,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(StorefrontStrings.pickLogo),
        ),
        Text(
          StorefrontStrings.logoHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        _errors(),
        StorefrontAction(
          label: _model.snapshot?.store == null
              ? StorefrontStrings.create
              : StorefrontStrings.save,
          loading: _model.busy,
          onPressed: _picking ? null : _saveStore,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          StorefrontStrings.draft,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );

  Future<void> _browseProducts() async {
    await Navigator.pushNamed(context, Routes.products);
    if (mounted) await _model.load();
  }

  Widget _buildStore(StorefrontSnapshot snapshot) {
    final store = snapshot.store!;
    final active = store.isActiveAt(DateTime.now());
    final groups = <String, List<StoreListing>>{};
    for (final listing in snapshot.listings) {
      groups.putIfAbsent(listing.productId, () => []).add(listing);
    }
    final products = groups.values.toList();
    return RefreshIndicator(
      onRefresh: _model.load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        itemCount: products.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: store.logoUrl.isEmpty
                              ? Icon(
                                  Icons.storefront_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                )
                              : ClipOval(
                                  child: SizedBox.square(
                                    dimension: 52,
                                    child: AppNetworkImage(
                                      store.logoUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.brandName,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              Text(
                                active
                                    ? StorefrontStrings.active
                                    : StorefrontStrings.paused,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (active)
                          PopupMenuButton<String>(
                            tooltip: 'خيارات النشر',
                            enabled: !_model.busy,
                            onSelected: (_) => _model.pause(),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'pause',
                                child: Text('إيقاف المتجر مؤقتاً'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      store.publicUrl,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!active) Text(StorefrontStrings.activationBody),
                    const SizedBox(height: AppSpacing.md),
                    if (!active)
                      StorefrontAction(
                        label: StorefrontStrings.activate,
                        loading: _model.busy,
                        onPressed: _activateStore,
                      ),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        FilledButton.icon(
                          onPressed: () async {
                            final opened = await launchUrl(
                              Uri.parse(store.publicUrl),
                              mode: LaunchMode.externalApplication,
                            );
                            if (mounted && !opened) {
                              setState(
                                () => _localError = StorefrontStrings.loadError,
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: Text(StorefrontStrings.open),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: store.publicUrl),
                            );
                            if (!mounted || !context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(StorefrontStrings.copied)),
                            );
                          },
                          icon: const Icon(Icons.copy_outlined),
                          label: Text(StorefrontStrings.copy),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.palette_outlined),
                      onPressed: _model.busy
                          ? null
                          : () => setState(() {
                              _editing = true;
                              _detailsStep = true;
                              _brand.text = store.brandName;
                              _slug.text = store.slug;
                            }),
                      label: Text(StorefrontStrings.edit),
                    ),
                    if (_localError != null || _model.errorCode != null)
                      _errors(),
                    if (_openingProduct != null)
                      const LinearProgressIndicator(),
                  ],
                ),
              ),
            );
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.lg,
              ),
              child: snapshot.listings.isEmpty
                  ? StorefrontMessage(
                      title: StorefrontStrings.emptyProducts,
                      body: StorefrontStrings.emptyProductsBody,
                      action: StorefrontAction(
                        label: StorefrontStrings.browse,
                        onPressed: _browseProducts,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          StorefrontStrings.products,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        OutlinedButton.icon(
                          onPressed: _browseProducts,
                          icon: const Icon(Icons.add),
                          label: Text(StorefrontStrings.browse),
                        ),
                      ],
                    ),
            );
          }
          final group = products[index - 2];
          final listing = group.first;
          final product = session.productById(listing.productId);
          final image = listing.imageUrl.isNotEmpty
              ? listing.imageUrl
              : product?.coverImage ?? '';
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 12),
            child: StorefrontProductTile(
              name: product?.localizedName ?? listing.productName,
              imageUrl: image,
              price: formatIqd(listing.retailPrice),
              variants: group
                  .map(
                    (item) =>
                        product?.variants
                            .where((v) => v.id == item.variantId)
                            .firstOrNull
                            ?.localizedName ??
                        item.variantName,
                  )
                  .toList(),
              busy: _model.busy || _openingProduct != null,
              loading: _openingProduct == listing.productId,
              onEdit: () => _editStoreProduct(listing),
              onRemove: () => _confirmRemove(listing),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editStoreProduct(StoreListing listing) async {
    if (_openingProduct != null || _model.busy) return;
    setState(() => _openingProduct = listing.productId);
    try {
      final product =
          session.productById(listing.productId) ??
          await (widget.refreshProduct?.call(listing.productId) ??
                  session.refreshProductById(listing.productId))
              .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => StorefrontScreen(
            product: product,
            initialVariantId: listing.variantId,
          ),
        ),
      );
      if (mounted) await _model.load();
    } catch (_) {
      if (mounted) {
        setState(
          () => _localError =
              'تعذر تحميل تفاصيل المنتج. اسحب للتحديث وأعد المحاولة.',
        );
      }
    } finally {
      if (mounted) setState(() => _openingProduct = null);
    }
  }

  Future<void> _confirmRemove(StoreListing listing) async {
    if (_model.busy || _confirmingRemoval || _model.loading) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    _confirmingRemoval = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(StorefrontStrings.remove),
        content: Text(
          StorefrontStrings.t(
            'سيختفي المنتج بكل ألوانه من متجرك فقط؛ لن يتغير المنتج الأصلي أو الطلبات السابقة. يمكنك إضافته مجدداً.',
            'تەنها لە فرۆشگا دەشاردرێتەوە؛ کاتەلۆگ ناگۆڕێت.',
            'This product and all its colours will be hidden from your store only. The catalog and previous orders are unchanged.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(StorefrontStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(StorefrontStrings.remove),
          ),
        ],
      ),
    );
    _confirmingRemoval = false;
    if (!mounted || confirmed != true) return;
    setState(() => _removing = true);
    final removed = await _model.saveProduct(
      productId: listing.productId,
      variantIds: const [],
      retailPrice: 0,
    );
    if (!mounted) return;
    setState(() {
      _removing = false;
      if (removed) {
        _listingSaved = false;
        _selectedVariants.clear();
        _variant = null;
      }
    });
    if (removed) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(StorefrontStrings.listingRemoved)),
        );
    }
  }

  Widget _buildProductForm(Product source) {
    final product = _freshProduct ?? session.productById(source.id) ?? source;
    final available = product.variants.where((item) => item.inStock).toList();
    final selected = product.variants
        .where((item) => item.id == _variant?.id)
        .firstOrNull;
    final productListings = _model.snapshot!.listings
        .where((item) => item.productId == product.id)
        .toList();
    final existing = productListings.firstOrNull;
    final unchanged =
        productListings.length == _selectedVariants.length &&
        productListings.every(
          (item) =>
              _selectedVariants.contains(item.variantId) &&
              item.retailPrice == parseStorefrontPrice(_price.text) &&
              item.coverMediaId == _coverMediaId &&
              item.imageMediaId == _variantMedia[item.variantId],
        );
    final storeActive = _model.snapshot!.store!.isActiveAt(DateTime.now());
    final minimum = product.variants
        .where((item) => _selectedVariants.contains(item.id))
        .fold<int>(
          product.minSalePrice ?? 0,
          (value, item) => math.max(
            value,
            item.wholesalePriceOverride ?? product.wholesalePrice,
          ),
        );
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          if (_productRefreshing) const LinearProgressIndicator(),
          if (_productRefreshFailed)
            StorefrontMessage(
              title: StorefrontStrings.refreshProduct,
              body: StorefrontStrings.priceRefreshRequired,
              action: StorefrontAction(
                label: StorefrontStrings.retry,
                onPressed: _refreshProduct,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              storeActive
                  ? StorefrontStrings.publishedAfterSave
                  : StorefrontStrings.savedWhilePaused,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((selected?.imageUrl.isNotEmpty == true) ||
                  product.coverImage.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 88,
                    height: 112,
                    child: AppNetworkImage(
                      selected?.imageUrl.isNotEmpty == true
                          ? selected!.imageUrl
                          : product.coverImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.localizedName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('عدّل الألوان والسعر والصور لموقعك فقط.'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (existing != null) ...[
            Text(StorefrontStrings.listingHelp),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            StorefrontStrings.variant,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_model.snapshot!.listings.any(
            (item) => item.productId == product.id,
          ))
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.storefront_outlined, size: 18),
                Text(StorefrontStrings.listed),
              ],
            ),
          if (available.isEmpty)
            StorefrontMessage(
              title: StorefrontStrings.chooseVariant,
              body: StorefrontStrings.t(
                'لا يوجد نوع متوفر حالياً لهذا المنتج.',
                'ئێستا هیچ جۆرێک بەردەست نییە.',
                'No variant of this product is currently in stock.',
              ),
            ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final variant in product.variants)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.sm,
                  ),
                  child: FilterChip(
                    key: ValueKey('store_variant_${variant.id}'),
                    showCheckmark: true,
                    checkmarkColor: AppColors.onPrimary,
                    labelStyle: TextStyle(
                      color: _selectedVariants.contains(variant.id)
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                    avatar:
                        _model.snapshot!.listings.any(
                          (item) => item.variantId == variant.id,
                        )
                        ? Icon(
                            Icons.storefront_outlined,
                            size: 18,
                            color: _selectedVariants.contains(variant.id)
                                ? AppColors.onPrimary
                                : AppColors.primary,
                          )
                        : null,
                    selected: _selectedVariants.contains(variant.id),
                    onSelected:
                        (!variant.inStock &&
                                !_model.snapshot!.listings.any(
                                  (item) => item.variantId == variant.id,
                                )) ||
                            _model.busy ||
                            _productRefreshing
                        ? null
                        : (checked) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            setState(() {
                              if (checked) {
                                _selectedVariants.add(variant.id);
                              } else {
                                _selectedVariants.remove(variant.id);
                              }
                              _variant = variant;
                              _listingSaved = false;
                              if (_price.text.isEmpty) {
                                _price.text =
                                    '${existing?.retailPrice ?? product.suggestedPrice}';
                              }
                            });
                          },
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    label: Text(
                      variant.localizedName,
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            StorefrontStrings.sharedPrice,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('storefront_price'),
            controller: _price,
            enabled: !_model.busy,
            onChanged: (_) => setState(() => _listingSaved = false),
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'د.ع',
              helperText:
                  '${formatIqd(minimum)}${product.maxSalePrice != null ? ' — ${formatIqd(product.maxSalePrice!)}' : '+'}',
              helperMaxLines: 3,
            ),
            validator: (value) {
              final price = parseStorefrontPrice(value ?? '');
              return price == null ||
                      price < minimum ||
                      price >
                          math.min(product.maxSalePrice ?? 100000000, 100000000)
                  ? StorefrontStrings.invalidPrice
                  : null;
            },
          ),
          ExpansionTile(
            key: const ValueKey('storefront_image_choices'),
            title: Text(
              StorefrontStrings.t(
                'صور المنتج والغلاف',
                'وێنەکانی بەرهەم و بەرگ',
                'Product images and cover',
              ),
            ),
            tilePadding: EdgeInsets.zero,
            children: [
              Text(
                StorefrontStrings.t(
                  'اختَر من صور المنتج الموجودة؛ هذه الصور تخص موقعك فقط.',
                  'لە وێنەکانی بەرهەم هەڵبژێرە؛ تەنها بۆ ماڵپەڕەکەتە.',
                  'Choose existing product images for your storefront only.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              StorefrontImagePicker(
                title: StorefrontStrings.t(
                  'صورة غلاف المنتج',
                  'وێنەی سەرەکی بەرهەم',
                  'Product cover image',
                ),
                keyPrefix: 'store_cover_media',
                images: product.media,
                value: _coverMediaId,
                onChanged: _model.busy || _productRefreshing
                    ? null
                    : (id) => setState(() {
                        _coverMediaId = id;
                        _listingSaved = false;
                      }),
              ),
              for (final variant in product.variants.where(
                (item) => _selectedVariants.contains(item.id),
              ))
                StorefrontImagePicker(
                  title:
                      '${StorefrontStrings.t('صورة', 'وێنە', 'Image')} — ${variant.localizedName}',
                  keyPrefix: 'store_variant_${variant.id}_media',
                  images: product.media,
                  value: _variantMedia[variant.id],
                  onChanged: _model.busy || _productRefreshing
                      ? null
                      : (id) => setState(() {
                          if (id == null) {
                            _variantMedia.remove(variant.id);
                          } else {
                            _variantMedia[variant.id] = id;
                          }
                          _listingSaved = false;
                        }),
                ),
            ],
          ),
          _errors(),
          if (_listingSaved)
            Semantics(
              liveRegion: true,
              child: Text(
                StorefrontStrings.added,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          if (!storeActive) ...[
            StorefrontAction(
              label: StorefrontStrings.activate,
              loading: _activating,
              onPressed: _model.busy ? null : _activateStore,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (_selectedVariants.isEmpty) Text(StorefrontStrings.chooseVariant),
          StorefrontAction(
            key: const ValueKey('save_storefront_listing'),
            label: _listingSaved
                ? StorefrontStrings.added
                : existing == null
                ? StorefrontStrings.addProduct
                : StorefrontStrings.save,
            loading: _model.busy && !_activating && !_removing,
            onPressed:
                _activating ||
                    _model.busy ||
                    _selectedVariants.isEmpty ||
                    unchanged ||
                    _listingSaved ||
                    _productRefreshing ||
                    _productRefreshFailed ||
                    _model.loading
                ? null
                : () async {
                    if (!(_form.currentState?.validate() ?? false)) return;
                    final saved = await _model.saveProduct(
                      productId: product.id,
                      variantIds: _selectedVariants.toList(),
                      retailPrice: parseStorefrontPrice(_price.text)!,
                      coverMediaId: _coverMediaId,
                      variantMedia: {
                        for (final id in _selectedVariants)
                          if (_variantMedia[id] != null) id: _variantMedia[id]!,
                      },
                    );
                    if (!mounted || !saved) return;
                    FocusScope.of(context).unfocus();
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            existing == null
                                ? StorefrontStrings.added
                                : StorefrontStrings.listingUpdated,
                          ),
                        ),
                      );
                    setState(() => _listingSaved = true);
                  },
          ),
          if (existing != null) ...[
            const SizedBox(height: AppSpacing.md),
            StorefrontRemoveAction(
              key: const ValueKey('remove_storefront_listing'),
              loading: _removing,
              onPressed: _model.busy || _model.loading
                  ? null
                  : () => _confirmRemove(existing),
            ),
          ],
        ],
      ),
    );
  }
}
