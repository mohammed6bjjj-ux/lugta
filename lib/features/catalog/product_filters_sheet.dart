import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/app_settings.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'catalog_strings.dart';

/// خيارات ترتيب المنتجات في الكتالوج.
enum SortOption { newest, popular, priceAsc, priceDesc }

extension SortOptionX on SortOption {
  String get labelAr => switch (appSettings.language) {
    AppLanguage.ar => switch (this) {
      SortOption.newest => 'الأحدث أولاً',
      SortOption.popular => 'الأكثر طلباً',
      SortOption.priceAsc => 'سعر الجملة: من الأقل إلى الأعلى',
      SortOption.priceDesc => 'سعر الجملة: من الأعلى إلى الأقل',
    },
    AppLanguage.ckb => switch (this) {
      SortOption.newest => 'نوێترین لە پێشەوە',
      SortOption.popular => 'زۆرترین داواکراو',
      SortOption.priceAsc => 'نرخی کۆمەڵ: لە کەمەوە بۆ زۆر',
      SortOption.priceDesc => 'نرخی کۆمەڵ: لە زۆرەوە بۆ کەم',
    },
    AppLanguage.en => switch (this) {
      SortOption.newest => 'Newest first',
      SortOption.popular => 'Most ordered',
      SortOption.priceAsc => 'Wholesale price: low to high',
      SortOption.priceDesc => 'Wholesale price: high to low',
    },
  };

  /// تسمية مختصرة لأزرار الشريط العلوي.
  String get shortLabelAr => switch (appSettings.language) {
    AppLanguage.ar => switch (this) {
      SortOption.newest => 'الأحدث',
      SortOption.popular => 'الأكثر طلباً',
      SortOption.priceAsc => 'الأرخص أولاً',
      SortOption.priceDesc => 'الأغلى أولاً',
    },
    AppLanguage.ckb => switch (this) {
      SortOption.newest => 'نوێترین',
      SortOption.popular => 'زۆرترین داواکراو',
      SortOption.priceAsc => 'هەرزانترین لە پێشەوە',
      SortOption.priceDesc => 'گرانترین لە پێشەوە',
    },
    AppLanguage.en => switch (this) {
      SortOption.newest => 'Newest',
      SortOption.popular => 'Most ordered',
      SortOption.priceAsc => 'Cheapest first',
      SortOption.priceDesc => 'Priciest first',
    },
  };
}

/// فلاتر تصفية المنتجات — القيم الافتراضية تعرض كل شيء.
class ProductFilters {
  const ProductFilters({
    this.categoryId,
    this.minPrice = priceFloor,
    this.maxPrice = priceCeil,
    this.inStockOnly = false,
    this.sort = SortOption.newest,
  });

  /// حدا نطاق سعر الجملة المعتمدان في الواجهة.
  static const double priceFloor = 0;
  static const double priceCeil = 100000;

  final String? categoryId;
  final double minPrice;
  final double maxPrice;
  final bool inStockOnly;
  final SortOption sort;

  static const Object _unset = Object();

  ProductFilters copyWith({
    Object? categoryId = _unset,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    SortOption? sort,
  }) => ProductFilters(
    categoryId: identical(categoryId, _unset)
        ? this.categoryId
        : categoryId as String?,
    minPrice: minPrice ?? this.minPrice,
    maxPrice: maxPrice ?? this.maxPrice,
    inStockOnly: inStockOnly ?? this.inStockOnly,
    sort: sort ?? this.sort,
  );

  /// هل الفلاتر بوضعها الافتراضي (لا تصفية فعلية)؟
  bool get isDefault =>
      categoryId == null &&
      minPrice <= priceFloor &&
      maxPrice >= priceCeil &&
      !inStockOnly &&
      sort == SortOption.newest;
}

/// تطبيق الفلاتر والترتيب على قائمة منتجات وإرجاع قائمة جديدة.
List<Product> applyFilters(List<Product> products, ProductFilters filters) {
  final result = products.where((p) {
    if (filters.categoryId != null && p.categoryId != filters.categoryId) {
      return false;
    }
    if (p.wholesalePrice < filters.minPrice ||
        p.wholesalePrice > filters.maxPrice) {
      return false;
    }
    if (filters.inStockOnly && !p.inStock) return false;
    return true;
  }).toList();

  final comparator = switch (filters.sort) {
    SortOption.newest => (Product a, Product b) => b.createdAt.compareTo(
      a.createdAt,
    ),
    SortOption.popular => (Product a, Product b) => b.ordersCount.compareTo(
      a.ordersCount,
    ),
    SortOption.priceAsc => (Product a, Product b) => a.wholesalePrice.compareTo(
      b.wholesalePrice,
    ),
    SortOption.priceDesc =>
      (Product a, Product b) => b.wholesalePrice.compareTo(a.wholesalePrice),
  };
  return result..sort(comparator);
}

/// فتح ورقة الفلاتر. تُعيد [ProductFilters] عند الضغط على «تطبيق»
/// أو null إذا أُغلقت دون تطبيق.
///
/// [showCategoryChips] تُخفى شرائح التصنيف داخل شاشة تصنيف محدد
/// (التصنيف محسوم مسبقاً هناك).
Future<ProductFilters?> showProductFiltersSheet(
  BuildContext context,
  ProductFilters current, {
  bool showCategoryChips = true,
}) {
  return showModalBottomSheet<ProductFilters>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ProductFiltersSheet(
      current: current,
      showCategoryChips: showCategoryChips,
    ),
  );
}

class _ProductFiltersSheet extends StatefulWidget {
  const _ProductFiltersSheet({
    required this.current,
    required this.showCategoryChips,
  });

  final ProductFilters current;
  final bool showCategoryChips;

  @override
  State<_ProductFiltersSheet> createState() => _ProductFiltersSheetState();
}

class _ProductFiltersSheetState extends State<_ProductFiltersSheet> {
  String? _categoryId;
  late RangeValues _range;
  late bool _inStockOnly;
  late SortOption _sort;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _categoryId = c.categoryId;
    final start = c.minPrice
        .clamp(ProductFilters.priceFloor, ProductFilters.priceCeil)
        .toDouble();
    final end = c.maxPrice
        .clamp(ProductFilters.priceFloor, ProductFilters.priceCeil)
        .toDouble();
    _range = RangeValues(start, end < start ? start : end);
    _inStockOnly = c.inStockOnly;
    _sort = c.sort;
  }

  void _reset() {
    setState(() {
      _categoryId = null;
      _range = const RangeValues(
        ProductFilters.priceFloor,
        ProductFilters.priceCeil,
      );
      _inStockOnly = false;
      _sort = SortOption.newest;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      ProductFilters(
        categoryId: widget.showCategoryChips
            ? _categoryId
            : widget.current.categoryId,
        minPrice: _range.start,
        maxPrice: _range.end,
        inStockOnly: _inStockOnly,
        sort: _sort,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  CatalogStrings.filtersAndSort,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (widget.showCategoryChips) ...[
                _sectionTitle(CatalogStrings.categorySection),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final category in session.categories)
                      _ChoicePill(
                        label: category.localizedName,
                        selected: _categoryId == category.id,
                        onTap: () => setState(
                          () => _categoryId = _categoryId == category.id
                              ? null
                              : category.id,
                        ),
                      ),
                  ],
                ),
              ],
              _sectionTitle(CatalogStrings.wholesalePricePerPiece),
              Row(
                children: [
                  _PricePill(label: formatIqd(_range.start.round())),
                  const Spacer(),
                  _PricePill(label: formatIqd(_range.end.round())),
                ],
              ),
              RangeSlider(
                values: _range,
                min: ProductFilters.priceFloor,
                max: ProductFilters.priceCeil,
                divisions: 20,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.divider,
                labels: RangeLabels(
                  formatIqd(_range.start.round()),
                  formatIqd(_range.end.round()),
                ),
                onChanged: (values) => setState(() => _range = values),
              ),
              SwitchListTile(
                value: _inStockOnly,
                onChanged: (value) => setState(() => _inStockOnly = value),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  CatalogStrings.inStockOnly,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  CatalogStrings.hideOutOfStock,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _sectionTitle(CatalogStrings.sortSection),
              for (final option in SortOption.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Pressable(
                    onTap: () => setState(() => _sort = option),
                    child: AnimatedContainer(
                      duration: AppDurations.base,
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm + 2,
                        horizontal: AppSpacing.sm + 4,
                      ),
                      decoration: BoxDecoration(
                        color: _sort == option
                            ? AppColors.accentSoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sort == option
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            size: 22,
                            color: _sort == option
                                ? AppColors.accentStrong
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              option.labelAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: _sort == option
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
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: CatalogStrings.apply,
                      onPressed: _apply,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: _reset,
                    child: Text(CatalogStrings.reset),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريحة اختيار كبسولة بانتقال لوني ناعم بين حالتي الاختيار.
class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.base,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.neutralChip,
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: AppDurations.base,
          curve: Curves.easeOut,
          style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.onPrimary : AppColors.textPrimary,
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

/// كبسولة ذهبية لعرض قيمة من نطاق السعر.
class _PricePill extends StatelessWidget {
  const _PricePill({required this.label});

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
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.accentStrong,
        ),
      ),
    );
  }
}
