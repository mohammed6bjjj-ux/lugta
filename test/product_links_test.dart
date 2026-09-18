import 'package:flutter_app/data/product_links.dart';
import 'package:flutter_app/data/storefront_validation.dart';
import 'package:flutter_app/app/product_link_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = '22222222-2222-4222-8222-222222222222';
  const second = '33333333-3333-4333-8333-333333333333';
  test(
    'canonical link roundtrips exact product without a database mapping',
    () {
      final url = ProductLinks.forProduct(id)!;
      expect(
        url.toString(),
        'https://product.lugta.app/p/IiIiIiIiQiKCIiIiIiIiIg',
      );
      expect(ProductLinks.parse(url), id);
      expect(ProductLinks.forProduct(id.toUpperCase()), url);
      expect(ProductLinks.forProduct('demo-product'), isNull);
      expect(
        ProductLinks.forProduct('00000000-0000-0000-0000-000000000000'),
        isNull,
      );
      expect(isValidStorefrontSlug('product'), false);
      expect(isValidStorefrontSlug('celoraiq'), true);
    },
  );
  test(
    'rejects other hosts, schemes, paths, query injection and malformed codes',
    () {
      final url = ProductLinks.forProduct(id)!;
      for (final raw in [
        '$url/',
        '$url?next=https://evil.test',
        '$url#x',
        url.replace(host: 'product.lugta.app.evil.test').toString(),
        url.replace(scheme: 'http').toString(),
        url.replace(host: 'celoraiq.lugta.app').toString(),
        'https://user@product.lugta.app${url.path}',
        'https://product.lugta.app:444${url.path}',
        'https://product.lugta.app/p/A7K92',
        'https://product.lugta.app/p/AAAAAAAAAAAAAAAAAAAAAA',
        'https://product.lugta.app/p/IiIiIiIiQiKCIiIiIiIiIh',
        'nawl://auth/callback?code=private',
      ]) {
        expect(ProductLinks.parse(Uri.parse(raw)), isNull, reason: raw);
      }
    },
  );
  test(
    'cold link waits for consumer; duplicate taps do not duplicate navigation',
    () {
      final inbox = ProductLinkInbox();
      addTearDown(inbox.dispose);
      var notifications = 0;
      inbox.addListener(() => notifications++);
      inbox.accept(ProductLinks.forProduct(id)!);
      inbox.accept(ProductLinks.forProduct(id)!);
      expect(notifications, 1);
      expect(inbox.pending, id);
      expect(inbox.take(), id);
      expect(inbox.take(), isNull);
      inbox.accept(Uri.parse('nawl://auth/callback?code=private'));
      expect(inbox.pending, isNull);
      inbox.accept(ProductLinks.forProduct(second)!);
      expect(inbox.pending, second);
      expect(notifications, 2);
    },
  );
  test('latest valid tap wins while login or approval remains on screen', () {
    final inbox = ProductLinkInbox();
    addTearDown(inbox.dispose);
    inbox.accept(ProductLinks.forProduct(id)!);
    inbox.accept(ProductLinks.forProduct(second)!);
    inbox.accept(Uri.parse('https://evil.test/'));
    expect(inbox.take(), second);
  });
}
