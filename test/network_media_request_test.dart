import 'dart:async';

import 'package:flutter_app/core/network_media_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const privateUrl =
      'https://project.supabase.co/storage/v1/object/authenticated/catalog-media/products/p1/photo.webp';
  const publicUrl =
      'https://project.supabase.co/storage/v1/object/public/public-content/banner.webp';

  tearDown(NetworkMediaRequest.reset);

  test('attaches current auth only to the private Supabase route', () {
    NetworkMediaRequest.configure(
      headersProvider: () => const {
        'apikey': 'publishable',
        'Authorization': 'Bearer current-jwt',
      },
      scopeProvider: () => 'seller-1',
    );

    expect(
      NetworkMediaRequest.headersFor(privateUrl)['Authorization'],
      'Bearer current-jwt',
    );
    expect(NetworkMediaRequest.cacheScopeFor(privateUrl), 'seller-1');
    expect(NetworkMediaRequest.headersFor(publicUrl), isEmpty);
    expect(NetworkMediaRequest.cacheScopeFor(publicUrl), isNull);
  });

  test('coalesces simultaneous authorization refresh requests', () async {
    final release = Completer<void>();
    var calls = 0;
    NetworkMediaRequest.configure(
      headersProvider: () => const {},
      scopeProvider: () => 'seller-1',
      refreshAuthorization: () async {
        calls += 1;
        await release.future;
      },
    );

    final first = NetworkMediaRequest.refreshAuthorization();
    final second = NetworkMediaRequest.refreshAuthorization();
    expect(calls, 1);
    expect(identical(first, second), isTrue);

    release.complete();
    await Future.wait([first, second]);
    await NetworkMediaRequest.refreshAuthorization();
    expect(calls, 2);
  });
}
