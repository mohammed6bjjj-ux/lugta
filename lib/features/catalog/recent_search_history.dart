class RecentSearchHistory {
  RecentSearchHistory({this.maximumEntries = 8});

  final int maximumEntries;
  final List<String> _items = [];
  String? _ownerId;

  List<String> get items => List<String>.unmodifiable(_items);

  /// Keeps history only for the currently active identity. Moving to another
  /// account (including logout's empty identity) removes the previous user's
  /// terms instead of retaining them in process-wide memory.
  void bindOwner(String ownerId) {
    final normalizedOwnerId = ownerId.trim();
    if (_ownerId == normalizedOwnerId) return;
    _ownerId = normalizedOwnerId;
    _items.clear();
  }

  void add(String value) {
    final term = value.trim();
    if (term.isEmpty || (_ownerId?.isEmpty ?? true)) return;
    _items
      ..remove(term)
      ..insert(0, term);
    if (_items.length > maximumEntries) {
      _items.removeRange(maximumEntries, _items.length);
    }
  }

  void remove(String value) => _items.remove(value);

  void clear() => _items.clear();
}

final RecentSearchHistory recentSearchHistory = RecentSearchHistory();
