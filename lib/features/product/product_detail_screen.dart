import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../l10n/core_strings.dart';
import 'media_share_sheet.dart';
import 'product_strings.dart';
import 'product_media_thumbnail.dart';

/// شاشة تفاصيل المنتج — واجهة العرض الأهم بصرياً في التطبيق.
/// تصميم غامر: معرض ممتد بلا حواف علوية، أزرار زجاجية عائمة فوقه،
/// وورقة محتوى تتراكب على أسفل المعرض بزوايا كبيرة وظل ناعم.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const double _galleryHeight = 420;
  static const double _sheetOverlap = 28;

  final PageController _galleryController = PageController();
  int _currentPage = 0;
  ProductVariant? _selectedVariant;

  Product get product =>
      session.productById(widget.product.id) ?? widget.product;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  String _fmtDuration(int? seconds) {
    final s = seconds ?? 0;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _openViewer(int index) async {
    final lastPage = await Navigator.pushNamed<Object?>(
      context,
      Routes.mediaViewer,
      arguments: {'media': product.media, 'initialIndex': index},
    );
    // Follow the viewer so the gallery shows whatever the seller paged to.
    if (!mounted || lastPage is! int || lastPage == _currentPage) return;
    if (lastPage < 0 || lastPage >= product.media.length) return;
    if (_galleryController.hasClients) _galleryController.jumpToPage(lastPage);
  }

  void _selectVariant(ProductVariant variant) {
    setState(() {
      _selectedVariant = _selectedVariant?.id == variant.id ? null : variant;
    });
    // اختيار متغير يعيد المعرض للصورة الرئيسية التي تعرض صورة المتغير.
    if (_selectedVariant != null && _galleryController.hasClients) {
      _galleryController.animateToPage(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _copyDescription() async {
    // النص المنسوخ لا يتضمن سعر الجملة أبداً — السعر المقترح فقط.
    await Clipboard.setData(ClipboardData(text: marketingPostText(product)));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ProductStrings.descriptionCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) => Stack(
          children: [
            SessionRefreshIndicator(
              onRefresh: () async {
                await session.refreshProductById(product.id);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                children: [_buildGallery(), _buildSheet(theme)],
              ),
            ),
            _buildTopActions(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── الأزرار الزجاجية العلوية ───────────────────────────

  Widget _buildTopActions() {
    return PositionedDirectional(
      top: 0,
      start: 0,
      end: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _GlassCircleButton(
                tooltip: ProductStrings.back,
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: session,
                builder: (context, _) {
                  final isFav = session.isFavorite(product.id);
                  return _GlassCircleButton(
                    tooltip: isFav
                        ? ProductStrings.removeFromFavorites
                        : ProductStrings.addToFavorites,
                    onTap: () => session.toggleFavorite(product.id),
                    child: AnimatedSwitcher(
                      duration: AppDurations.fast,
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(isFav),
                        size: 22,
                        color: isFav ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _GlassCircleButton(
                tooltip: ProductStrings.shareMediaTooltip,
                onTap: () => showMediaShareSheet(context, product),
                child: Icon(
                  Icons.ios_share_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── معرض الوسائط ───────────────────────────

  Widget _buildGallery() {
    final media = product.media;
    if (media.isEmpty) {
      return const SizedBox(height: _galleryHeight, child: AppNetworkImage(''));
    }
    return SizedBox(
      height: _galleryHeight,
      child: PageView.builder(
        controller: _galleryController,
        itemCount: media.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) {
          final item = media[index];
          // عند اختيار متغير تعرض الصفحة الأولى صورة المتغير المختار.
          // معظم المتغيرات بلا صورة خاصة (_variantImage تُرجع نصاً فارغاً)،
          // فبلا فحص الفراغ تُستبدل صورة المنتج بمربع بديل عند كل اختيار.
          final variantImage = _selectedVariant?.imageUrl.trim() ?? '';
          final overrideUrl = index == 0 && variantImage.isNotEmpty
              ? variantImage
              : null;
          final showVideoOverlay = item.isVideo && overrideUrl == null;
          return GestureDetector(
            onTap: () => unawaited(_openViewer(index)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: item.id,
                  child: overrideUrl != null
                      ? AppNetworkImage(overrideUrl)
                      : ProductMediaThumbnail(item: item),
                ),
                if (showVideoOverlay) ...[
                  Center(
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .55),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 110,
                    start: AppSpacing.md,
                    child: _darkChip(
                      icon: Icons.videocam_rounded,
                      label: ProductStrings.video,
                    ),
                  ),
                  PositionedDirectional(
                    bottom: _sheetOverlap + AppSpacing.sm + 4,
                    start: AppSpacing.md,
                    child: _darkChip(
                      icon: Icons.schedule_rounded,
                      label: _fmtDuration(item.durationSec),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _darkChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    final count = product.media.length;
    if (count <= 1) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDurations.base,
            curve: AppCurves.emphasized,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _currentPage ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              gradient: i == _currentPage ? AppColors.goldGradient : null,
              color: i == _currentPage ? null : AppColors.divider,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────── ورقة المحتوى المتراكبة ───────────────────────────

  Widget _buildSheet(ThemeData theme) {
    return Entrance(
      offsetY: 40,
      child: Container(
        transform: Matrix4.translationValues(0, -_sheetOverlap, 0),
        padding: const EdgeInsets.only(
          top: AppSpacing.sm + 4,
          bottom: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D1B18).withValues(alpha: .08),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            _buildDots(),
            const SizedBox(height: AppSpacing.md),
            Entrance(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildTitleRow(theme),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Entrance(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildMetaRow(theme),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Entrance(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildPriceCard(theme),
              ),
            ),
            if (product.variants.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Entrance(
                index: 3,
                child: SectionHeader(title: ProductStrings.availableVariants),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Entrance(index: 3, child: _buildVariantChips(theme)),
            ],
            const SizedBox(height: AppSpacing.lg),
            Entrance(
              index: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildStockBanner(theme),
              ),
            ),
            if (product.specs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Entrance(
                index: 5,
                child: SectionHeader(title: ProductStrings.specifications),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Entrance(
                index: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: _buildSpecsTable(theme),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Entrance(index: 6, child: _buildDescriptionHeader(theme)),
            const SizedBox(height: AppSpacing.sm + 2),
            Entrance(
              index: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppCard(
                  child: Text(
                    product.localizedDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Entrance(
              index: 7,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SecondaryButton(
                  label: ProductStrings.downloadAndShareMedia,
                  icon: Icons.collections_outlined,
                  onPressed: () => showMediaShareSheet(context, product),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── الاسم والتصنيف ───────────────────────────

  Widget _buildTitleRow(ThemeData theme) {
    return Text(
      product.localizedName,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.35,
      ),
    );
  }

  Widget _buildMetaRow(ThemeData theme) {
    final category = session.categoryById(product.categoryId);
    final metaStyle = theme.textTheme.labelMedium?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
    );
    Widget meta(IconData icon, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: metaStyle,
          ),
        ),
      ],
    );
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        meta(category.icon, category.localizedName),
        meta(
          Icons.shopping_bag_outlined,
          ProductStrings.ordersViaPlatform(formatNumber(product.ordersCount)),
        ),
        if (product.isNew)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(100),
              boxShadow: AppShadows.goldGlow,
            ),
            child: Text(
              CoreStrings.badgeNew,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────── بطاقة الأسعار ───────────────────────────

  Widget _buildPriceCard(ThemeData theme) {
    final profit = product.suggestedPrice - product.wholesalePrice;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      shadows: [
        ...AppShadows.card,
        BoxShadow(
          color: AppColors.gold.withValues(alpha: .14),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          CoreStrings.wholesalePrice,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              formatIqd(product.oldWholesalePrice!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.error,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              ProductStrings.discountBadge(
                                formatNumber(product.discountPercent),
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // تدرج طباعي ذهبي كبير لسعر الجملة.
                    ShaderMask(
                      shaderCallback: (rect) =>
                          AppColors.goldGradient.createShader(rect),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        formatIqd(product.wholesalePrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                color: AppColors.divider,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ProductStrings.suggestedSalePrice,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatIqd(product.suggestedPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // كبسولة الربح — الرقم يُعدّ تصاعدياً عند الدخول.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: profit.toDouble()),
                    duration: const Duration(milliseconds: 900),
                    curve: AppCurves.emphasized,
                    builder: (context, value, _) => Text(
                      ProductStrings.approxProfit(formatIqd(value.round())),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (product.minSalePrice != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ProductStrings.minSalePrice(
                      formatIqd(product.minSalePrice!),
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────── المتغيرات ───────────────────────────

  Widget _buildVariantChips(ThemeData theme) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: product.variants.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm + 2),
        itemBuilder: (context, index) {
          final variant = product.variants[index];
          final selected = _selectedVariant?.id == variant.id;
          final chip = AnimatedScale(
            scale: selected ? 1.03 : 1,
            duration: AppDurations.base,
            curve: AppCurves.spring,
            child: AnimatedContainer(
              duration: AppDurations.base,
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.goldSoft : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: selected ? AppColors.gold : Colors.transparent,
                  width: 1.6,
                ),
                boxShadow: selected ? AppShadows.goldGlow : AppShadows.card,
              ),
              child: Row(
                children: [
                  ClipOval(
                    // المتغير بلا صورة خاصة يرث غلاف المنتج بدل مربع بديل.
                    child: AppNetworkImage(
                      variant.imageUrl.trim().isEmpty
                          ? product.coverImage
                          : variant.imageUrl,
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.localizedName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          variant.inStock
                              ? ProductStrings.variantInStock(
                                  formatNumber(variant.stock),
                                )
                              : CoreStrings.badgeOutOfStock,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: variant.inStock
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          // النافد يظهر معطّلاً ولا يُخفى.
          if (!variant.inStock) {
            return Opacity(opacity: .5, child: chip);
          }
          return Pressable(onTap: () => _selectVariant(variant), child: chip);
        },
      ),
    );
  }

  // ─────────────────────────── مؤشر المخزون الإجمالي ───────────────────────────

  Widget _buildStockBanner(ThemeData theme) {
    final (
      Color color,
      Color background,
      IconData icon,
      String label,
    ) = switch (product) {
      Product(inStock: false) => (
        AppColors.error,
        AppColors.errorSoft,
        Icons.remove_shopping_cart_outlined,
        ProductStrings.outOfStockTemporarily,
      ),
      Product(lowStock: true) => (
        AppColors.warning,
        AppColors.warningSoft,
        Icons.local_fire_department_rounded,
        ProductStrings.lowStockWarning(formatNumber(product.totalStock)),
      ),
      _ => (
        AppColors.success,
        AppColors.successSoft,
        Icons.check_circle_rounded,
        ProductStrings.totalStockAvailable(formatNumber(product.totalStock)),
      ),
    };
    return AnimatedContainer(
      duration: AppDurations.base,
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── المواصفات ───────────────────────────

  Widget _buildSpecsTable(ThemeData theme) {
    final entries = product.specs.entries.toList();
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  SizedBox(
                    width: 96,
                    child: Text(
                      entries[i].key,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      entries[i].value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────── الوصف ───────────────────────────

  Widget _buildDescriptionHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              ProductStrings.descriptionTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // زر النسخ كبسولة ذهبية ناعمة.
          Pressable(
            onTap: _copyDescription,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 4,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.goldSoft,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 15, color: AppColors.goldDark),
                  const SizedBox(width: 5),
                  Text(
                    ProductStrings.copyDescription,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── الشريط السفلي العائم ───────────────────────────

  Widget _buildBottomBar() {
    return PositionedDirectional(
      start: AppSpacing.md,
      end: AppSpacing.md,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Entrance(
            index: 2,
            offsetY: 34,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.floating,
              ),
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: ListenableBuilder(
                    listenable: session,
                    builder: (context, _) => product.inStock
                        ? PrimaryButton(
                            label: ProductStrings.createOrder,
                            icon: Icons.add_shopping_cart_rounded,
                            gold: true,
                            onPressed: () => Navigator.pushNamed(
                              context,
                              Routes.orderWizard,
                              arguments: product,
                            ),
                          )
                        : _buildAlertButton(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertButton(BuildContext context) {
    final active = session.hasStockAlert(product.id);
    return Pressable(
      onTap: () {
        session.toggleStockAlert(product.id);
        if (!active) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ProductStrings.alertActivated)),
          );
        }
      },
      child: AnimatedContainer(
        duration: AppDurations.base,
        curve: Curves.easeOut,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.goldSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: active ? AppColors.gold : AppColors.divider,
            width: active ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.fast,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                active
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                key: ValueKey(active),
                size: 20,
                color: active ? AppColors.goldDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                active ? ProductStrings.alertActive : ProductStrings.notifyMe,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: active ? AppColors.goldDark : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر دائري زجاجي يطفو فوق معرض الصور (رجوع/مفضلة/مشاركة).
class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.child,
    required this.onTap,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppShadows.card,
        ),
        child: FrostedPanel(
          borderRadius: BorderRadius.circular(100),
          fillAlpha: .82,
          blur: 14,
          child: SizedBox(width: 44, height: 44, child: Center(child: child)),
        ),
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
