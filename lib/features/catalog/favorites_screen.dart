import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/session.dart';
import 'catalog_strings.dart';

/// شاشة المفضلة — تعرض منتجات البائع وتتحدث فورياً.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const double _gridAspectRatio = ProductCard.gridAspectRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(CatalogStrings.favorites)),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final products = session.products
              .where((p) => session.favoriteIds.contains(p.id))
              .toList();

          final outOfStockCount = products.where((p) => !p.inStock).length;

          return SessionRefreshIndicator(
            onRefresh: session.refreshCatalog,
            child: products.isEmpty
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.favorite_border_rounded,
                          title: CatalogStrings.favoritesEmptyTitle,
                          subtitle: CatalogStrings.favoritesEmptySubtitle,
                          actionLabel: CatalogStrings.browseProducts,
                          onAction: () => Navigator.pop(context),
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
                          child: Text(
                            outOfStockCount > 0
                                ? CatalogStrings.productsCountWithOutOfStock(
                                    formatNumber(products.length),
                                    formatNumber(outOfStockCount),
                                  )
                                : CatalogStrings.productsCount(
                                    formatNumber(products.length),
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
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
