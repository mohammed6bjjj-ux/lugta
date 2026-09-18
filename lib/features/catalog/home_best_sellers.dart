import '../../data/models.dart';

List<Product> homeBestSellers(Iterable<Product> products) {
  final all = products.toList();
  final selected = all
      .where(
        (p) =>
            p.homeDisplayOrder != null &&
            p.homeDisplayOrder! >= 1 &&
            p.homeDisplayOrder! <= 6,
      )
      .toList();
  if (selected.isNotEmpty) {
    selected.sort((a, b) {
      final rank = a.homeDisplayOrder!.compareTo(b.homeDisplayOrder!);
      return rank != 0 ? rank : a.id.compareTo(b.id);
    });
    return selected.take(6).toList();
  }
  all.sort((a, b) {
    final orders = b.ordersCount.compareTo(a.ordersCount);
    if (orders != 0) return orders;
    final newest = b.createdAt.compareTo(a.createdAt);
    return newest != 0 ? newest : a.id.compareTo(b.id);
  });
  return all.take(6).toList();
}
