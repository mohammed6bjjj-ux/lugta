import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'catalog_strings.dart';
import 'product_filters_sheet.dart';

/// شاشة منتجات تصنيف محدد مع فلاتر (فرز، سعر جملة، متوفر فقط).
class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final Category category;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  static const double _gridAspectRatio = ProductCard.gridAspectRatio;

  ProductFilters _filters = const ProductFilters();

  List<Product> get _categoryProducts => session.products
      .where((p) => p.categoryId == widget.category.id)
      .toList();

  Future<void> _openFilters() async {
    final result = await showProductFiltersSheet(
      context,
      _filters,
      showCategoryChips: false,
    );
    if (result != null && mounted) {
      setState(() => _filters = result);
    }
  }

  void _resetFilters() => setState(() => _filters = const ProductFilters());

  /// أوصاف الفلاتر الفعالة — تُعرض كبسولات ذهبية أعلى الشبكة.
  List<String> get _activeFilterLabels => [
    if (_filters.sort != SortOption.newest) _filters.sort.labelAr,
    if (_filters.minPrice > ProductFilters.priceFloor ||
        _filters.maxPrice < ProductFilters.priceCeil)
      '${formatIqd(_filters.minPrice.round())} — ${formatIqd(_filters.maxPrice.round())}',
    if (_filters.inStockOnly) CatalogStrings.inStockOnly,
  ];

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = !_filters.isDefault;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.localizedName),
        actions: [
          IconButton(
            tooltip: CatalogStrings.filtersAndSort,
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: hasActiveFilters,
              smallSize: 8,
              backgroundColor: AppColors.accentStrong,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final theme = Theme.of(context);
          final products = applyFilters(_categoryProducts, _filters);
          return SessionRefreshIndicator(
            onRefresh: session.refreshCatalog,
            child: products.isEmpty
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: hasActiveFilters
                            ? EmptyState(
                                icon: Icons.filter_alt_off_outlined,
                                title: CatalogStrings.noProductsMatchFilters,
                                subtitle:
                                    CatalogStrings.noProductsMatchFiltersHint,
                                actionLabel: CatalogStrings.resetFilters,
                                onAction: _resetFilters,
                              )
                            : EmptyState(
                                icon: widget.category.icon,
                                title: CatalogStrings.emptyCategoryTitle,
                                subtitle: CatalogStrings.emptyCategorySubtitle,
                              ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Entrance(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  CatalogStrings.productsCount(
                                    formatNumber(products.length),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (hasActiveFilters)
                                TextButton.icon(
                                  onPressed: _resetFilters,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                  label: Text(CatalogStrings.resetTheFilters),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (hasActiveFilters)
                        Entrance(
                          index: 1,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.xs,
                              AppSpacing.md,
                              0,
                            ),
                            child: Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs + 2,
                              children: [
                                for (final label in _activeFilterLabels)
                                  _ActiveFilterPill(label: label),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: AppSpacing.sm + 4,
                                crossAxisSpacing: AppSpacing.sm + 4,
                                childAspectRatio: _gridAspectRatio,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) => Entrance(
                            index: index,
                            child: ProductCard(product: products[index]),
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

/// كبسولة فلتر فعال — خلفية ذهبية ناعمة وحواف كاملة الاستدارة.
class _ActiveFilterPill extends StatelessWidget {
  const _ActiveFilterPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.accentStrong,
        ),
      ),
    );
  }
}
