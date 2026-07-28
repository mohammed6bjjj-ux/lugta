import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_app/core/network_image_cache.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appNetworkImageCacheKey', () {
    test('ignores rotating token for the same Supabase Storage object', () {
      const first =
          'https://xmlqrvvdhlhqixinaecg.supabase.co/storage/v1/object/sign/catalog-media/products/p1/photo.webp?token=first-token';
      const second =
          'https://xmlqrvvdhlhqixinaecg.supabase.co/storage/v1/object/sign/catalog-media/products/p1/photo.webp?token=second-token';

      expect(appNetworkImageCacheKey(first), appNetworkImageCacheKey(second));
    });

    test('preserves non-token transformation parameters', () {
      const first =
          'https://xmlqrvvdhlhqixinaecg.supabase.co/storage/v1/object/sign/catalog-media/products/p1/photo.webp?width=480&quality=75&token=first';
      const second =
          'https://xmlqrvvdhlhqixinaecg.supabase.co/storage/v1/object/sign/catalog-media/products/p1/photo.webp?width=960&quality=75&token=second';

      expect(appNetworkImageCacheKey(first), contains('width=480'));
      expect(
        appNetworkImageCacheKey(first),
        isNot(appNetworkImageCacheKey(second)),
      );
    });

    test('does not alter token parameters on non-Supabase URLs', () {
      const url =
          'https://cdn.example.com/storage/v1/object/sign/photo.webp?token=keep-me';

      expect(appNetworkImageCacheKey(url), url);
    });

    test('keeps different Supabase Storage object paths isolated', () {
      const first =
          'https://project.supabase.co/storage/v1/object/sign/catalog-media/products/p1/a.webp?token=token';
      const second =
          'https://project.supabase.co/storage/v1/object/sign/catalog-media/products/p1/b.webp?token=token';

      expect(
        appNetworkImageCacheKey(first),
        isNot(appNetworkImageCacheKey(second)),
      );
    });

    test('scopes authenticated private objects per signed-in account', () {
      const url =
          'https://project.supabase.co/storage/v1/object/authenticated/catalog-media/products/p1/a.webp';

      expect(
        appNetworkImageCacheKey(url, authenticatedScopeKey: 'seller-a'),
        isNot(appNetworkImageCacheKey(url, authenticatedScopeKey: 'seller-b')),
      );
      expect(
        appNetworkImageCacheKey(url, authenticatedScopeKey: 'seller-a'),
        contains('auth-scope:seller-a'),
      );
    });
  });

  group('persistent resized image keys', () {
    test('quantizes nearby phone sizes into the same disk bucket', () {
      expect(appNetworkImageDiskDimension(481), 640);
      expect(appNetworkImageDiskDimension(639), 640);
      expect(appNetworkImageDiskDimension(961), 1280);
      expect(appNetworkImageDiskDimension(4000), 1600);
    });

    test('matches flutter_cache_manager resized key format', () {
      expect(
        appNetworkImageResizedCacheKey(
          'catalog/products/photo.webp',
          maxWidth: 640,
          maxHeight: 320,
        ),
        'resized_w640_h320_catalog/products/photo.webp',
      );
      expect(
        appNetworkImageResizedCacheKey('catalog/products/photo.webp'),
        'catalog/products/photo.webp',
      );
    });

    test('avoids unsupported repeated WebP disk resize work', () {
      expect(
        appNetworkImageSupportsDiskResize(
          'https://example.test/photo.webp?version=1',
        ),
        isFalse,
      );
      expect(
        appNetworkImageSupportsDiskResize('https://example.test/photo.jpg'),
        isTrue,
      );
    });
  });

  test('shared cache manager can actually resize on disk', () {
    // Building the manager resolves its cache directory through path_provider,
    // which has no plugin on the test host and would fail asynchronously.
    TestWidgetsFlutterBinding.ensureInitialized();
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      pathProvider,
      (call) async => Directory.systemTemp.path,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(pathProvider, null));
    // cached_network_image asserts `cacheManager is ImageCacheManager` as soon
    // as maxWidthDiskCache/maxHeightDiskCache is supplied, and AppNetworkImage
    // supplies them for every JPEG/PNG. A plain CacheManager therefore breaks
    // every such image in debug builds and drops the resize in release.
    expect(appNetworkImageCacheManager, isA<ImageCacheManager>());
  });
}
