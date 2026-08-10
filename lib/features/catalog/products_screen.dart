import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'catalog_strings.dart';
import 'product_filters_sheet.dart';

/// صفحة المنتجات: بحث في الأعلى، ثم أزرار (الفئة، الترتيب، التصنيف)،
/// ثم شريط التخفيضات، ثم شبكة كل المنتجات.
/// تعمل كتبويب داخل الشِل (بلا bottomNavigationBar وبحشوة سفلية 120).
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const double _bottomBarClearance = 120;
  static const double _gridAspectRatio = ProductCard.gridAspectRatio;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  ProductFilters _filters = const ProductFilters();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────── البيانات ───────────────────────────

  List<Product> get _searched {
    final q = _query.trim();
    if (q.isEmpty) return session.products;
    return session.products.where((p) {
      final categoryName = session.categoryById(p.categoryId).localizedName;
      return p.localizedName.contains(q) ||
          p.localizedDescription.contains(q) ||
          categoryName.contains(q);
    }).toList();
  }

  List<Product> get _results => applyFilters(_searched, _filters);

  List<Product> get _discounted =>
      session.products.where((p) => p.hasDiscount).toList()
        ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));

  bool get _categoryActive => _filters.categoryId != null;

  bool get _sortActive => _filters.sort != SortOption.newest;

  /// هل فلاتر «التصنيف» (السعر/التوفر) مفعّلة؟ — بمعزل عن الفئة والترتيب.
  bool get _refineActive =>
      _filters.minPrice > ProductFilters.priceFloor ||
      _filters.maxPrice < ProductFilters.priceCeil ||
      _filters.inStockOnly;

  String get _categoryLabel => switch (_filters.categoryId) {
    null => CatalogStrings.categoryButton,
    final id => session.categoryById(id).localizedName,
  };

  // ─────────────────────────── الأحداث ───────────────────────────

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value);
    });
  }

  Future<void> _pickCategory() async {
    // الإغلاق بلا اختيار يعيد null، واختيار «كل الفئات» يعيد نتيجة تحمل null —
    // الغلاف [_SheetResult] هو ما يميّز الحالتين.
    final picked = await showModalBottomSheet<_SheetResult<String?>>(
      context: context,
      builder: (context) => _OptionsSheet<String?>(
        title: CatalogStrings.chooseCategory,
        options: [
          _SheetOption<String?>(
            value: null,
            label: CatalogStrings.allCategories,
          ),
          for (final c in session.categories)
            _SheetOption<String?>(
              value: c.id,
              label: c.localizedName,
              icon: c.icon,
            ),
        ],
        selected: _filters.categoryId,
      ),
    );
    if (picked == null) return;
    setState(() => _filters = _filters.copyWith(categoryId: picked.value));
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<_SheetResult<SortOption>>(
      context: context,
      builder: (context) => _OptionsSheet<SortOption>(
        title: CatalogStrings.sortProductsTitle,
        options: [
          for (final option in SortOption.values)
            _SheetOption(value: option, label: option.labelAr),
        ],
        selected: _filters.sort,
      ),
    );
    if (picked == null) return;
    setState(() => _filters = _filters.copyWith(sort: picked.value));
  }

  Future<void> _openRefineSheet() async {
    final result = await showProductFiltersSheet(
      context,
      _filters,
      showCategoryChips: false,
    );
    if (result != null) setState(() => _filters = result);
  }

  // ─────────────────────────── البناء ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final theme = Theme.of(context);
          final results = _results;
          final discounted = _discounted;
          return SessionRefreshIndicator(
            onRefresh: session.refreshCatalog,
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── البحث + فقاعتا المفضلة والإشعارات ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm + 4,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Entrance(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: AppShadows.card,
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onQueryChanged,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: CatalogStrings.searchHint,
                                    filled: false,
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      size: 21,
                                      color: AppColors.accentStrong,
                                    ),
                                    suffixIcon: _query.isEmpty
                                        ? null
                                        : IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 19,
                                            ),
                                            color: AppColors.textSecondary,
                                            onPressed: () {
                                              _searchController.clear();
                                              _debounce?.cancel();
                                              setState(() => _query = '');
                                            },
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _CircleBubble(
                              icon: Icons.favorite_border_rounded,
                              onTap: () => Navigator.pushNamed(
                                context,
                                Routes.favorites,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _CircleBubble(
                              icon: Icons.shopping_cart_outlined,
                              badgeCount: session.cartQuantity,
                              onTap: () =>
                                  Navigator.pushNamed(context, Routes.cart),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            ListenableBuilder(
                              listenable: session,
                              builder: (context, _) => _CircleBubble(
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

                  // ── أزرار الفئة / الترتيب / التصنيف ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Entrance(
                        index: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: _FilterBarButton(
                                icon: Icons.category_outlined,
                                label: _categoryLabel,
                                active: _categoryActive,
                                onTap: _pickCategory,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _FilterBarButton(
                                icon: Icons.swap_vert_rounded,
                                label: _sortActive
                                    ? _filters.sort.shortLabelAr
                                    : CatalogStrings.sortButton,
                                active: _sortActive,
                                onTap: _pickSort,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _FilterBarButton(
                                icon: Icons.tune_rounded,
                                label: CatalogStrings.refineButton,
                                active: _refineActive,
                                onTap: _openRefineSheet,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── التخفيضات ──
                  if (discounted.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.md,
                          bottom: AppSpacing.sm,
                        ),
                        child: Entrance(
                          index: 3,
                          child: SectionHeader(title: CatalogStrings.hotDeals),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: ProductCard.horizontalHeight,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          itemCount: discounted.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.sm + 4),
                          itemBuilder: (context, i) => Entrance(
                            index: 4 + i,
                            child: SizedBox(
                              width: ProductCard.horizontalWidth,
                              child: ProductCard(product: discounted[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── كل المنتجات ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.lg,
                        bottom: AppSpacing.sm,
                      ),
                      child: Entrance(
                        index: 4,
                        child: Row(
                          children: [
                            Expanded(
                              child: SectionHeader(
                                title: CatalogStrings.allProducts,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: AppSpacing.md,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSoft,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  CatalogStrings.productsCount(
                                    formatNumber(results.length),
                                  ),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accentStrong,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (results.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: CatalogStrings.noMatchingResults,
                        subtitle: CatalogStrings.noMatchingResultsHint,
                        actionLabel: CatalogStrings.resetAll,
                        onAction: () {
                          _searchController.clear();
                          _debounce?.cancel();
                          setState(() {
                            _query = '';
                            _filters = const ProductFilters();
                          });
                        },
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        _bottomBarClearance,
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
                          (context, i) => Entrance(
                            index: i,
                            child: ProductCard(product: results[i]),
                          ),
                          childCount: results.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// فقاعة أيقونة دائرية بيضاء بظل — للمفضلة والإشعارات أعلى الصفحة.
class _CircleBubble extends StatelessWidget {
  const _CircleBubble({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: .88,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppShadows.card,
        ),
        child: Badge(
          isLabelVisible: badgeCount > 0,
          label: Text('$badgeCount', style: const TextStyle(fontSize: 9)),
          backgroundColor: AppColors.accent,
          textColor: AppColors.onAccent,
          child: Icon(icon, size: 21, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// زر شريط التصفية العلوي: كبسولة بيضاء تتحول داكنة عند التفعيل
/// مع نقطة خضراء صغيرة تدل على وجود اختيار فعّال.
class _FilterBarButton extends StatelessWidget {
  const _FilterBarButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.base,
        curve: AppCurves.emphasized,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: active ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: AppDurations.fast,
                style: (theme.textTheme.labelMedium ?? const TextStyle())
                    .copyWith(
                      fontWeight: FontWeight.w800,
                      color: active
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (active) ...[
              const SizedBox(width: 5),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// خيار داخل ورقة اختيار موحّدة.
class _SheetOption<T> {
  const _SheetOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// غلاف نتيجة الاختيار — يميّز «اختار قيمة (حتى لو null)» عن «أغلق بلا اختيار».
class _SheetResult<T> {
  const _SheetResult(this.value);

  final T value;
}

/// ورقة اختيار موحّدة (تستخدم للفئة والترتيب) بصفوف راديو حديثة.
class _OptionsSheet<T> extends StatelessWidget {
  const _OptionsSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<_SheetOption<T>> options;
  final T selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Pressable(
                  onTap: () =>
                      Navigator.pop(context, _SheetResult<T>(option.value)),
                  child: AnimatedContainer(
                    duration: AppDurations.base,
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm + 2,
                      horizontal: AppSpacing.sm + 4,
                    ),
                    decoration: BoxDecoration(
                      color: option.value == selected
                          ? AppColors.accentSoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option.value == selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 22,
                          color: option.value == selected
                              ? AppColors.accentStrong
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (option.icon != null) ...[
                          Icon(
                            option.icon,
                            size: 19,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: option.value == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
