import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/category_sticker_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../cart/cart_strings.dart';
import '../auth/guest_strings.dart';
import 'catalog_strings.dart';

/// الشاشة الرئيسية — محتوى تبويب «الرئيسية» داخل الشِل.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _gridAspectRatio = ProductCard.gridAspectRatio;

  List<Product> get _newArrivals {
    final sorted = [...session.products]
      ..sort((a, b) {
        if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return sorted.take(6).toList();
  }

  List<Product> get _bestSellers {
    final sorted = [...session.products]
      ..sort((a, b) => b.ordersCount.compareTo(a.ordersCount));
    return sorted.take(6).toList();
  }

  Future<void> _refreshHome() => Future.wait<void>([
    session.refreshCatalog(),
    session.refreshPublicData(),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final newArrivals = _newArrivals;
          final bestSellers = _bestSellers;
          return SessionRefreshIndicator(
            onRefresh: _refreshHome,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── هوية مختصرة، إجراءات سريعة، ثم بحث بعرض مريح ──
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm + 4,
                        AppSpacing.md,
                        0,
                      ),
                      child: Entrance(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: LugtaWordmark(height: 30),
                                  ),
                                ),
                                _CircleIconButton(
                                  tooltip: CatalogStrings.favorites,
                                  icon: Icons.favorite_border_rounded,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    Routes.favorites,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _CircleIconButton(
                                  tooltip: CartStrings.openCart,
                                  icon: Icons.shopping_cart_outlined,
                                  badgeCount: session.cartQuantity,
                                  onTap: () =>
                                      Navigator.pushNamed(context, Routes.cart),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                ListenableBuilder(
                                  listenable: session,
                                  builder: (context, _) => _CircleIconButton(
                                    tooltip: CatalogStrings.notifications,
                                    icon: Icons.notifications_none_rounded,
                                    badgeCount:
                                        session.unreadNotificationsCount,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      Routes.notifications,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm + 2),
                            const _FakeSearchBar(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (session.isGuest) ...[
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sm),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: _GuestPreviewStrip(
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.guestAccess),
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                SliverToBoxAdapter(
                  child: Entrance(
                    index: 1,
                    child: _BannerCarousel(banners: session.banners),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
                SliverToBoxAdapter(
                  child: Entrance(
                    index: 2,
                    child: SectionHeader(title: CatalogStrings.shopByCategory),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                SliverToBoxAdapter(
                  child: Entrance(
                    index: 3,
                    child: _CategoriesRow(categories: session.categories),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
                SliverToBoxAdapter(
                  child: SectionHeader(title: CatalogStrings.newArrivals),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: ProductCard.horizontalHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: newArrivals.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppSpacing.sm + 4),
                      itemBuilder: (context, index) => Entrance(
                        index: index,
                        child: SizedBox(
                          width: ProductCard.horizontalWidth,
                          child: ProductCard(product: newArrivals[index]),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
                SliverToBoxAdapter(
                  child: SectionHeader(title: CatalogStrings.bestSellers),
                ),
                SliverPadding(
                  // حشوة سفلية كبيرة كي لا يختفي آخر المحتوى خلف شريط التنقل العائم.
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    120,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.sm + 4,
                          crossAxisSpacing: AppSpacing.sm + 4,
                          childAspectRatio: _gridAspectRatio,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Entrance(
                        index: index,
                        child: ProductCard(product: bestSellers[index]),
                      ),
                      childCount: bestSellers.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GuestPreviewStrip extends StatelessWidget {
  const _GuestPreviewStrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: GuestStrings.previewTitle,
      child: AppCard(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        radius: AppRadius.md,
        color: AppColors.accentSoft,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility_outlined,
                color: AppColors.accentStrong,
                size: 21,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    GuestStrings.guestPreview,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    GuestStrings.liveDataNotice,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: AppColors.accentStrong,
            ),
          ],
        ),
      ),
    );
  }
}

/// زر أيقونة مدمج مع شارة عدد واضحة من لون الإبراز.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    Widget button = Pressable(
      onTap: onTap,
      scale: .88,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppShadows.card,
        ),
        child: Badge(
          isLabelVisible: badgeCount > 0,
          backgroundColor: AppColors.accent,
          textColor: AppColors.onAccent,
          label: Text(formatNumber(badgeCount)),
          child: Icon(icon, size: 21, color: AppColors.textPrimary),
        ),
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return Center(child: button);
  }
}

/// شريط بحث وهمي — كبسولة بظل ناعم تفتح شاشة البحث الفعلية.
class _FakeSearchBar extends StatelessWidget {
  const _FakeSearchBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => Navigator.pushNamed(context, Routes.search),
      radius: 100,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 21, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              CatalogStrings.searchHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// كاروسيل البانرات؛ يحترم إعداد تقليل الحركة.
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.banners});

  final List<PromoBanner> banners;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _page = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion && (_timer != null || reduceMotion)) {
      return;
    }
    _reduceMotion = reduceMotion;
    _timer?.cancel();
    _timer = null;
    if (reduceMotion) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients) return;
      if (widget.banners.isEmpty) return;
      final next = (_page + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: AppDurations.slow,
        curve: AppCurves.emphasized,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.banners.isEmpty) {
      _page = 0;
      return;
    }
    if (_page < widget.banners.length) return;
    _page = 0;
    if (_controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openBanner(BuildContext context, PromoBanner banner) {
    switch (banner) {
      case PromoBanner(targetProductId: final productId?):
        final product = session.productById(productId);
        if (product == null) return;
        Navigator.pushNamed(context, Routes.productDetail, arguments: product);
      case PromoBanner(targetCategoryId: final categoryId?):
        Category? category;
        for (final item in session.categories) {
          if (item.id == categoryId) {
            category = item;
            break;
          }
        }
        if (category == null) return;
        Navigator.pushNamed(
          context,
          Routes.categoryProducts,
          arguments: category,
        );
    }
  }

  /// بعد البطاقة عن مركز العرض (0 = في المركز تماماً).
  double _distanceFromCenter(int index) {
    if (_controller.hasClients && _controller.position.haveDimensions) {
      return ((_controller.page ?? _page.toDouble()) - index).abs().clamp(
        0.0,
        1.0,
      );
    }
    return index == _page ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();
    if (_page >= banners.length) _page = 0;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 8 / 3,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final banner = banners[index];
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.scale(
                  scale: _reduceMotion
                      ? 1
                      : 1 - _distanceFromCenter(index) * .08,
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs + 2,
                  ),
                  child: Pressable(
                    onTap: () => _openBanner(context, banner),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: AppShadows.card,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppNetworkImage(banner.imageUrl),
                          // غطاء تدرج داكن من الأسفل لإبراز النص.
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [.35, 1],
                                colors: [
                                  Colors.transparent,
                                  AppColors.primary.withValues(alpha: .82),
                                ],
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            start: AppSpacing.md,
                            end: AppSpacing.md,
                            bottom: AppSpacing.md,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  banner.localizedTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (banner.localizedSubtitle != null)
                                  Text(
                                    banner.localizedSubtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onPrimary
                                          .withValues(alpha: .9),
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
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < banners.length; i++)
              AnimatedContainer(
                duration: AppDurations.base,
                curve: AppCurves.emphasized,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  gradient: i == _page ? AppColors.accentGradient : null,
                  color: i == _page ? null : AppColors.divider,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// معرض تصنيفات مرن — يستوعب أي عدد ويُبقي بطاقة إضافية ظاهرة جزئياً
/// حتى يفهم المستخدم أن القائمة قابلة للسحب.
class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm + 4;
        final availableWidth = constraints.maxWidth - (AppSpacing.md * 2);
        final threeCardWidth = (availableWidth - (gap * 2)) / 3;
        final itemWidth = (threeCardWidth + ((textScale - 1) * 16)).clamp(
          104.0,
          136.0,
        );
        final rowHeight = 148.0 + ((textScale - 1) * 28);

        return RepaintBoundary(
          key: const ValueKey('home-category-list'),
          child: SizedBox(
            height: rowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: gap),
              itemBuilder: (context, index) => SizedBox(
                width: itemWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: _CategoryCard(
                    category: categories[index],
                    toneIndex: index,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.toneIndex});

  final Category category;
  final int toneIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Pressable(
      semanticLabel: category.localizedName,
      minimumSize: const Size(104, 48),
      onTap: () => Navigator.pushNamed(
        context,
        Routes.categoryProducts,
        arguments: category,
      ),
      child: ExcludeSemantics(
        child: Container(
          key: ValueKey('home-category-${category.id}'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CategoryArtwork(
                  category: category,
                  toneIndex: toneIndex,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.localizedName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryArtwork extends StatelessWidget {
  const _CategoryArtwork({required this.category, required this.toneIndex});

  final Category category;
  final int toneIndex;

  @override
  Widget build(BuildContext context) {
    final tone = _CategoryTone.resolve(context, toneIndex);
    final qualifier = _categoryQualifierIcon(category);
    if (category.imageUrl.trim().isNotEmpty) {
      // The whole card is the navigation target. Automatic retries remain
      // active, while this prevents the compact retry gesture from stealing
      // the tap that should open the category.
      return Stack(
        key: ValueKey('home-category-art-${category.id}'),
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: AppNetworkImage(
              category.imageUrl,
              fit: BoxFit.cover,
              fallbackIcon: category.icon,
            ),
          ),
          if (qualifier != null)
            PositionedDirectional(
              end: 10,
              top: 10,
              child: _CategoryStickerBubble(
                category: category,
                icon: qualifier,
                background: AppColors.accent,
                foreground: AppColors.onAccent,
              ),
            ),
        ],
      );
    }

    return DecoratedBox(
      key: ValueKey('home-category-art-${category.id}'),
      decoration: BoxDecoration(color: tone.background),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          PositionedDirectional(
            start: -26,
            bottom: -34,
            child: Container(
              width: 102,
              height: 102,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tone.foreground.withValues(alpha: .12),
                  width: 2,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: -14,
            top: -20,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: tone.detail.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: tone.foreground.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(category.icon, size: 32, color: tone.foreground),
            ),
          ),
          if (qualifier != null)
            PositionedDirectional(
              end: 10,
              top: 10,
              child: _CategoryStickerBubble(
                category: category,
                icon: qualifier,
                background: tone.detail,
                foreground: tone.onDetail,
              ),
            ),
          PositionedDirectional(
            start: 10,
            bottom: 10,
            child: Container(
              width: 24,
              height: 4,
              decoration: BoxDecoration(
                color: tone.detail,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStickerBubble extends StatelessWidget {
  const _CategoryStickerBubble({
    required this.category,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final Category category;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(
        'home-category-sticker-${category.id}-${category.stickerKey.wireValue}',
      ),
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 15, color: foreground),
    );
  }
}

@immutable
class _CategoryTone {
  const _CategoryTone({
    required this.background,
    required this.foreground,
    required this.detail,
    required this.onDetail,
  });

  final Color background;
  final Color foreground;
  final Color detail;
  final Color onDetail;

  static _CategoryTone resolve(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    return switch (index % 4) {
      0 => _CategoryTone(
        background: AppColors.primary,
        foreground: AppColors.onPrimary,
        detail: AppColors.accent,
        onDetail: AppColors.onAccent,
      ),
      1 => _CategoryTone(
        background: AppColors.accentSoft,
        foreground: AppColors.accentStrong,
        detail: AppColors.primary,
        onDetail: AppColors.onPrimary,
      ),
      2 => _CategoryTone(
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        detail: AppColors.accent,
        onDetail: AppColors.onAccent,
      ),
      _ => _CategoryTone(
        background: AppColors.surfaceAlt,
        foreground: AppColors.primary,
        detail: AppColors.accent,
        onDetail: AppColors.onAccent,
      ),
    };
  }
}

IconData? _categoryQualifierIcon(Category category) {
  final selected = categoryStickerIconFor(category.stickerKey);
  if (category.stickerKey != CategoryStickerKey.auto) return selected;

  final identity = [
    category.id,
    category.nameAr,
    category.nameCkb ?? '',
    category.nameEn ?? '',
  ].join(' ').toLowerCase();

  for (final rule in _categoryAutoStickerRules) {
    if (_containsAny(identity, rule.$1)) return rule.$2;
  }
  return null;
}

const List<(List<String>, IconData)> _categoryAutoStickerRules = [
  (
    ['هاتف', 'موبايل', 'جوال', 'تلفون', 'phone', 'mobile', 'مۆبایل'],
    Icons.smartphone_rounded,
  ),
  (['لابتوب', 'laptop', 'notebook'], Icons.laptop_mac_rounded),
  (
    ['حاسب', 'كمبيوتر', 'computer', 'desktop', 'کۆمپیوتەر'],
    Icons.desktop_windows_rounded,
  ),
  (['تابلت', 'لوحي', 'tablet', 'ipad'], Icons.tablet_mac_rounded),
  (['تلفاز', 'تلفزيون', 'شاشة', 'tv', 'television'], Icons.tv_rounded),
  (['كاميرا', 'camera', 'تصوير'], Icons.photo_camera_rounded),
  (
    ['سماعة', 'سماعات', 'صوت', 'audio', 'headphone', 'speaker'],
    Icons.headphones_rounded,
  ),
  (
    ['العاب إلكترونية', 'ألعاب إلكترونية', 'gaming', 'game console'],
    Icons.sports_esports_rounded,
  ),
  (['راوتر', 'شبكات', 'network', 'wifi', 'router'], Icons.wifi_rounded),
  (['شاحن', 'كابل', 'charger', 'cable'], Icons.electrical_services_rounded),
  (['أجهزة منزلية', 'اجهزة منزلية', 'appliances'], Icons.kitchen_rounded),
  (
    ['إلكترون', 'الكترون', 'electronics', 'devices', 'أجهزة'],
    Icons.memory_rounded,
  ),
  (['smart', 'ذكي', 'زیرەک'], Icons.bolt_rounded),
  (['أثاث', 'اثاث', 'furniture'], Icons.chair_rounded),
  (['منزل', 'home', 'house'], Icons.home_rounded),
  (['حقائب', 'حقيبة', 'bags', 'bag'], Icons.shopping_bag_rounded),
  (['أحذية', 'احذية', 'حذاء', 'shoes', 'footwear'], Icons.hiking_rounded),
  (['تجميل', 'عناية', 'beauty', 'cosmetic'], Icons.palette_rounded),
  (['ملابس', 'أزياء', 'ازياء', 'fashion', 'clothes'], Icons.checkroom_rounded),
  (['رجال', 'رجالي', 'رجل', 'men', 'male'], Icons.male_rounded),
  (['نسائ', 'امرأة', 'women', 'female', 'ژن'], Icons.female_rounded),
  (['أطفال', 'اطفال', 'kids', 'child', 'منداڵ'], Icons.child_care_rounded),
  (['watch', 'ساع', 'کاتژمێر'], Icons.watch_rounded),
  (['glass', 'نظر', 'چاویلکە'], Icons.visibility_outlined),
  (['access', 'اكسس', 'إكسس', 'ئێکسس'], Icons.diamond_rounded),
  (['رياض', 'sport', 'fitness'], Icons.fitness_center_rounded),
  (['ألعاب أطفال', 'العاب اطفال', 'toys'], Icons.toys_rounded),
  (['كتب', 'كتاب', 'books'], Icons.menu_book_rounded),
  (['حيوانات', 'pets'], Icons.pets_rounded),
  (['سيارات', 'سيارة', 'automotive', 'car'], Icons.directions_car_rounded),
  (['أدوات', 'ادوات', 'معدات', 'tools'], Icons.build_rounded),
  (['بقالة', 'grocery'], Icons.shopping_basket_rounded),
  (['أطعمة', 'اطعمة', 'طعام', 'food'], Icons.restaurant_rounded),
  (['صحة', 'health', 'medical'], Icons.health_and_safety_rounded),
  (['مكتب', 'مكتبية', 'office'], Icons.business_center_rounded),
  (['سفر', 'رحلات', 'travel'], Icons.luggage_rounded),
  (['علب', 'هدية', 'gift', 'box', 'تغليف'], Icons.redeem_rounded),
];

bool _containsAny(String value, List<String> needles) =>
    needles.any(value.contains);
