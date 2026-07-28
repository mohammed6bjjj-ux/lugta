import 'package:flutter_app/features/catalog/recent_search_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts empty, deduplicates terms, and enforces its bound', () {
    final history = RecentSearchHistory(maximumEntries: 3);
    history.bindOwner('seller-a');

    expect(history.items, isEmpty);
    history
      ..add(' first ')
      ..add('second')
      ..add('third')
      ..add('first')
      ..add('fourth');

    expect(history.items, ['fourth', 'first', 'third']);
  });

  test('clears terms whenever the authenticated identity changes', () {
    final history = RecentSearchHistory()..bindOwner('seller-a');
    history.add('private search');

    history.bindOwner('seller-b');
    expect(history.items, isEmpty);

    history.add('other account');
    history.bindOwner('');
    expect(history.items, isEmpty);
    history.add('ignored while signed out');
    expect(history.items, isEmpty);
  });
}
