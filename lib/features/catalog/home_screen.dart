import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../cart/cart_strings.dart';
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
                // ── البحث + فقاعتا المفضلة والإشعارات (بلا تحية) ──
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
                        child: Builder(
                          builder: (context) => Row(
                            children: [
                              const Expanded(child: _FakeSearchBar()),
                              const SizedBox(width: AppSpacing.sm),
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
                                  badgeCount: session.unreadNotificationsCount,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    Routes.notifications,
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

/// زر أيقونة دائري أبيض بظل ناعم وتفاعل ضغط، مع شارة عدد ذهبية اختيارية.
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
          backgroundColor: AppColors.goldDark,
          textColor: Colors.white,
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
          Icon(Icons.search_rounded, size: 21, color: AppColors.goldDark),
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

/// كاروسيل البانرات بتمرير تلقائي، حافة البطاقة المجاورة ظاهرة،
/// تكبير للبطاقة المركزية ومؤشر نقاط تتمدد المختارة منها كبسولة ذهبية.
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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      if (widget.banners.isEmpty) return;
      final next = (_page + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
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
                  scale: 1 - _distanceFromCenter(index) * .08,
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (banner.localizedSubtitle != null)
                                  Text(
                                    banner.localizedSubtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: .9),
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
                  gradient: i == _page ? AppColors.goldGradient : null,
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

/// صف التصنيفات الأربعة — مربعات بحواف مدوّرة بتفاعل ضغط.
class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm + 4),
        itemBuilder: (context, index) {
          final category = categories[index];
          return SizedBox(
            width: 78,
            child: Entrance(
              index: index,
              child: Pressable(
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.categoryProducts,
                  arguments: category,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(AppRadius.md - 2),
                          boxShadow: AppShadows.card,
                        ),
                        child: AppNetworkImage(
                          category.imageUrl,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(AppRadius.md - 2),
                          fallbackIcon: category.icon,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        category.localizedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
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
    );
  }
}
