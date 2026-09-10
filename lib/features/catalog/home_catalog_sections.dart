import '../../data/models.dart';

/// Home is a preview of the existing catalog, not a second catalog fetch.
class HomeCatalogSection {
  const HomeCatalogSection({required this.category, required this.products});

  final Category category;
  final List<Product> products;
}

List<HomeCatalogSection> homeCatalogSections(
  List<Category> categories,
  List<Product> products,
) {
  final newest = [...products]
    ..sort((a, b) {
      final date = b.createdAt.compareTo(a.createdAt);
      return date != 0 ? date : a.id.compareTo(b.id);
    });
  final previews = <String, List<Product>>{};
  for (final product in newest) {
    final group = previews.putIfAbsent(product.categoryId, () => []);
    if (group.length < 6) group.add(product);
  }
  return [
    for (final category in categories)
      if (previews[category.id]?.isNotEmpty == true)
        HomeCatalogSection(
          category: category,
          products: List.unmodifiable(previews[category.id]!),
        ),
  ];
}
