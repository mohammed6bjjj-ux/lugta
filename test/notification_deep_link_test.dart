import 'package:flutter_app/data/notification_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts current app paths and legacy custom scheme links', () {
    expect(
      parseTrustedNotificationDeepLink('/promotions')?.kind,
      NotificationDeepLinkKind.promotions,
    );
    expect(
      parseTrustedNotificationDeepLink('nawl://referrals')?.kind,
      NotificationDeepLinkKind.referrals,
    );
    expect(
      parseTrustedNotificationDeepLink('/loyalty')?.kind,
      NotificationDeepLinkKind.loyalty,
    );
    final product = parseTrustedNotificationDeepLink(
      'nawl://products/product_42',
    );
    expect(product?.kind, NotificationDeepLinkKind.product);
    expect(product?.entityId, 'product_42');

    final order = parseTrustedNotificationDeepLink('/orders/order-7');
    expect(order?.kind, NotificationDeepLinkKind.order);
    expect(order?.entityId, 'order-7');
  });

  test('rejects external, malformed, and non-allowlisted routes', () {
    const rejected = <String>[
      'https://example.com/promotions',
      'javascript:alert(1)',
      'nawl://admin/users',
      'nawl://products/product%2Fsecret',
      '/products/product-1?redirect=/admin',
      '/orders/../../admin',
      'promotions',
    ];

    for (final value in rejected) {
      expect(parseTrustedNotificationDeepLink(value), isNull, reason: value);
    }
  });
}
