import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/content_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('terms version is independent from policy row order', () {
    final terms = <String, dynamic>{
      'kind': 'policy',
      'key': 'terms',
      'title_ar': 'الشروط',
      'body_ar': 'نص الشروط',
      'version': 'terms-v7',
    };
    final privacy = <String, dynamic>{
      'kind': 'policy',
      'key': 'privacy',
      'title_ar': 'الخصوصية',
      'body_ar': 'نص الخصوصية',
      'version': 'privacy-v99',
    };

    for (final rows in [
      [terms, privacy],
      [privacy, terms],
    ]) {
      final result = parsePolicyContent(rows, language: AppLanguage.ar);
      expect(result.termsVersion, 'terms-v7');
      expect(result.combinedText, contains('نص الشروط'));
      expect(result.combinedText, contains('نص الخصوصية'));
    }
  });

  test('banner target prefers canonical product target', () {
    final target = parseContentTarget({
      'target_type': 'product',
      'target_id': 'new-product',
      'product_id': 'legacy-product',
    });

    expect(target.productId, 'new-product');
    expect(target.categoryId, isNull);
  });

  test('banner target supports canonical category and legacy keys', () {
    final category = parseContentTarget({
      'target_type': 'category',
      'target_id': 'category-1',
    });
    final legacy = parseContentTarget({'product_id': 'product-1'});

    expect(category.categoryId, 'category-1');
    expect(category.productId, isNull);
    expect(legacy.productId, 'product-1');
  });

  test('missing canonical terms never invents an acceptance version', () {
    final result = parsePolicyContent([
      {
        'kind': 'policy',
        'key': 'privacy',
        'body_ar': 'سياسة الخصوصية',
        'version': 'privacy-v3',
      },
    ], language: AppLanguage.ar);

    expect(result.termsVersion, isEmpty);
  });
}
