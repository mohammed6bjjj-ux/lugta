import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_app/data/repositories/storefront_repository.dart';
import 'package:flutter_app/data/repositories/supabase_repositories.dart';
import 'package:flutter_app/data/repositories/supabase_storefront_repository.dart';
import 'package:flutter_app/data/storefront_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Auth extends GoTrueClient {
  _Auth() : super(autoRefreshToken: false);
  String? userId = 'user-a';
  @override
  User? get currentUser => userId == null
      ? null
      : User(
          id: userId!,
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: '2026-09-11T00:00:00Z',
        );
}

class _Client extends SupabaseClient {
  _Client(this.currentAuth, http.Client transport)
    : super(
        'http://localhost',
        'test-key',
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
  final _Auth currentAuth;
  @override
  GoTrueClient get auth => currentAuth;
}

Map<String, Object?> snapshot() => {
  'eligible': true,
  'eligible_order_count': 10,
  'storefront': {
    'id': 'store-a',
    'brand_name': 'Brand',
    'slug': 'brand',
    'logo_path': 'user-a/logo.png',
    'theme_id': 'theme1',
    'published': true,
    'active_until': '2026-09-12T00:00:00Z',
    'items': [
      {
        'id': 'listing-a',
        'product_id': 'product-a',
        'variant_id': 'variant-a',
        'sale_price': 20000,
        'is_active': true,
      },
    ],
  },
};

void main() {
  for (final mode in ['ok', 'denied', 'account-changed']) {
    test(
      'request photo is private, variant-specific and optional: $mode',
      () async {
        final auth = _Auth();
        const product = '00000000-0000-4000-8000-000000000002';
        const variant = '00000000-0000-4000-8000-000000000003';
        var mediaCalls = 0;
        final client = _Client(
          auth,
          MockClient((request) async {
            Object payload;
            if (request.url.path.endsWith('/product_media')) {
              mediaCalls++;
              expect(request.method, 'GET');
              expect(
                request.url.queryParameters['product_id'],
                contains(product),
              );
              expect(
                request.url.queryParameters['bucket_name'],
                'eq.catalog-media',
              );
              if (mode == 'account-changed') auth.userId = 'user-b';
              if (mode == 'denied') {
                return http.Response(
                  '{"message":"denied"}',
                  403,
                  request: request,
                );
              }
              payload = [
                {
                  'id': 'generic',
                  'product_id': product,
                  'variant_id': null,
                  'object_path': 'product/cover.jpg',
                },
                {
                  'id': 'other',
                  'product_id': product,
                  'variant_id': 'other',
                  'object_path': 'product/wrong.jpg',
                },
                {
                  'id': 'chosen',
                  'product_id': product,
                  'variant_id': variant,
                  'object_path': 'product/black.jpg',
                },
              ];
            } else {
              payload = {
                'id': 'request-a',
                'request_number': 'WEB-internal',
                'status': 'pending',
                'version': 1,
                'customer_name': 'Fixture',
                'customer_phone': '07700000000',
                'sale_total': 20000,
                'delivery_fee': 5000,
                'total_collect_amount': 25000,
                'created_at': '2026-09-17T00:00:00Z',
                'items': [
                  {
                    'product_id': product,
                    'variant_id': variant,
                    'product_name': 'Watch',
                    'variant_name': 'Black',
                    'quantity': 1,
                    'unit_sale_price': 20000,
                  },
                ],
              };
            }
            return http.Response(
              jsonEncode(payload),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }),
        );
        addTearDown(() async {
          await client.dispose();
          auth.dispose();
        });
        final future = SupabaseStorefrontRepository(
          client,
        ).fetchRequest('request-a');
        if (mode == 'account-changed') {
          await expectLater(future, throwsA(isA<StorefrontException>()));
        } else {
          final result = await future;
          expect(result.total, 25000);
          expect(result.items.single.unitSalePrice, 20000);
          expect(
            result.items.single.imageUrl,
            mode == 'denied'
                ? isEmpty
                : 'http://localhost/storage/v1/object/authenticated/catalog-media/product/black.jpg',
          );
        }
        expect(mediaCalls, 1);
      },
    );
  }
  test(
    'palette save is ownerless; legacy draft keeps compatible RPC',
    () async {
      final auth = _Auth();
      final calls = <http.Request>[];
      final client = _Client(
        auth,
        MockClient((request) async {
          calls.add(request);
          return http.Response(
            jsonEncode(snapshot()),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final repository = SupabaseStorefrontRepository(client);
      const draft = StorefrontDraft(
        themeId: 'future-design',
        paletteId: 'navy',
        brandName: 'Brand',
        slug: 'brand',
        logoPath: 'user-a/logo.png',
      );
      await repository.save(draft);
      expect(calls.single.url.path, '/rest/v1/rpc/save_my_storefront_design');
      expect(jsonDecode(calls.single.body), {
        'p_slug': 'brand',
        'p_brand_name': 'Brand',
        'p_logo_path': 'user-a/logo.png',
        'p_design_id': 'future-design',
        'p_palette_id': 'navy',
      });
      calls.clear();
      await repository.save(draft.copyWith(themeId: 'theme1', paletteId: ''));
      expect(calls.single.url.path, '/rest/v1/rpc/save_my_storefront');
      expect(jsonDecode(calls.single.body)['p_theme_id'], 'theme1');
    },
  );
  test('selected media saves IDs only in a single ownerless RPC', () async {
    final auth = _Auth();
    final calls = <http.Request>[];
    final client = _Client(
      auth,
      MockClient((request) async {
        calls.add(request);
        return http.Response(
          jsonEncode(snapshot()),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(() async {
      await client.dispose();
      auth.dispose();
    });
    await SupabaseStorefrontRepository(client).saveProduct(
      productId: 'product-a',
      variantIds: ['variant-a'],
      retailPrice: 18000,
      coverMediaId: 'photo2',
      variantMedia: {'variant-a': 'photo1'},
    );
    expect(calls.length, 1);
    expect(
      calls.single.url.path,
      '/rest/v1/rpc/save_my_storefront_product_media',
    );
    expect(jsonDecode(calls.single.body), {
      'p_product_id': 'product-a',
      'p_variant_ids': ['variant-a'],
      'p_sale_price': 18000,
      'p_cover_media_id': 'photo2',
      'p_variant_media': {'variant-a': 'photo1'},
    });
  });
  test(
    'atomic group adapter sends one ownerless RPC and reads historical progress',
    () async {
      final auth = _Auth();
      final calls = <http.Request>[];
      final client = _Client(
        auth,
        MockClient((request) async {
          calls.add(request);
          final result = snapshot()
            ..['order_progress'] = [
              {'id': 'o', 'number': 'ORD-OLD', 'status': 'delivered'},
            ];
          return http.Response(
            jsonEncode(result),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final result = await SupabaseStorefrontRepository(client).saveProduct(
        productId: 'product-a',
        variantIds: ['a', 'b'],
        retailPrice: 15000,
      );
      expect(calls.length, 1);
      expect(calls.single.url.path, '/rest/v1/rpc/save_my_storefront_product');
      expect(jsonDecode(calls.single.body), {
        'p_product_id': 'product-a',
        'p_variant_ids': ['a', 'b'],
        'p_sale_price': 15000,
      });
      expect(result.orderProgress.single.number, 'ORD-OLD');
      expect(result.orderProgress.single.status, 'delivered');
    },
  );
  test('request transport times out once without duplicate request', () async {
    final auth = _Auth();
    final gate = Completer<void>();
    var calls = 0;
    final client = _Client(
      auth,
      MockClient((request) async {
        calls++;
        await gate.future;
        return http.Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(() async {
      await client.dispose();
      auth.dispose();
    });
    final repo = SupabaseStorefrontRepository(
      client,
      requestTimeout: const Duration(milliseconds: 15),
    );
    await expectLater(
      repo.fetchRequest('request-a'),
      throwsA(
        isA<StorefrontException>().having(
          (e) => e.code,
          'code',
          'request_timeout',
        ),
      ),
    );
    expect(calls, 1);
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, 1);
  });
  test(
    'removal only deactivates the owned listing and inactive rows disappear',
    () async {
      final auth = _Auth();
      final calls = <http.Request>[];
      final client = _Client(
        auth,
        MockClient((request) async {
          calls.add(request);
          final result = snapshot();
          if (request.url.path.endsWith('/upsert_my_storefront_item')) {
            final body = jsonDecode(request.body) as Map;
            expect(body, {
              'p_variant_id': 'variant-a',
              'p_sale_price': 20000,
              'p_is_active': false,
              'p_sort_order': 0,
            });
            final store = result['storefront'] as Map;
            (store['items'] as List).first['is_active'] = false;
          }
          return http.Response(
            jsonEncode(result),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final result = await SupabaseStorefrontRepository(
        client,
      ).removeListing('listing-a');
      expect(result.listings, isEmpty);
      expect(calls.map((r) => r.url.path), [
        '/rest/v1/rpc/get_my_storefront',
        '/rest/v1/rpc/upsert_my_storefront_item',
      ]);
    },
  );
  test('slow listing RPC times out without replaying the write', () async {
    final auth = _Auth();
    final gate = Completer<void>();
    var writes = 0;
    final client = _Client(
      auth,
      MockClient((request) async {
        writes++;
        await gate.future;
        return http.Response(
          jsonEncode(snapshot()),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(() async {
      await client.dispose();
      auth.dispose();
    });
    final repo = SupabaseStorefrontRepository(
      client,
      requestTimeout: const Duration(milliseconds: 15),
    );
    await expectLater(
      repo.saveListing(
        productId: 'product-a',
        variantId: 'variant-a',
        retailPrice: 20000,
      ),
      throwsA(
        isA<StorefrontException>().having(
          (e) => e.code,
          'code',
          'request_timeout',
        ),
      ),
    );
    expect(writes, 1);
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(writes, 1);
  });
  test(
    'canonical order source maps and survives status copies; old rows remain valid',
    () async {
      final auth = _Auth();
      String? source;
      final client = _Client(
        auth,
        MockClient((request) async {
          expect(request.url.path, '/rest/v1/orders');
          // The incumbent wildcard select includes the additive nullable column.
          expect(request.url.queryParameters['select'], startsWith('*,'));
          return http.Response(
            jsonEncode({
              'id': 'order-a',
              'order_number': 'ORD-1',
              'created_at': '2026-09-11T00:00:00Z',
              'storefront_request_id': ?source,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final repository = SupabaseOrdersRepository(client);
      expect(
        (await repository.fetchOrder('order-a')).storefrontRequestId,
        isNull,
      );
      source = 'request-a';
      final linked = await repository.fetchOrder('order-a');
      expect(linked.storefrontRequestId, 'request-a');
      expect(
        linked.copyWith(status: linked.status).storefrontRequestId,
        'request-a',
      );
    },
  );
  test(
    'save uses constrained logo path, no arbitrary logo URL or owner id',
    () async {
      final auth = _Auth();
      final client = _Client(
        auth,
        MockClient((request) async {
          expect(request.url.path, '/rest/v1/rpc/save_my_storefront');
          expect(jsonDecode(request.body), {
            'p_slug': 'brand',
            'p_brand_name': 'Brand',
            'p_logo_path': 'user-a/logo.png',
            'p_theme_id': 'theme1',
          });
          return http.Response(
            jsonEncode(snapshot()),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final result = await SupabaseStorefrontRepository(client).save(
        const StorefrontDraft(
          slug: 'brand',
          brandName: 'Brand',
          logoPath: 'user-a/logo.png',
          themeId: 'theme1',
        ),
      );
      expect(
        result.store!.logoUrl,
        contains('/storefront-logos/user-a/logo.png'),
      );
      expect(result.store!.publicUrl, 'https://brand.lugta.app');
    },
  );
  test(
    'account switch during remove read never sends the second mutation',
    () async {
      final auth = _Auth();
      var writes = 0;
      final client = _Client(
        auth,
        MockClient((request) async {
          if (request.url.path.endsWith('/get_my_storefront')) {
            auth.userId = 'user-b';
          } else {
            writes++;
          }
          return http.Response(
            jsonEncode(snapshot()),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      await expectLater(
        SupabaseStorefrontRepository(client).removeListing('listing-a'),
        throwsA(isA<StorefrontException>()),
      );
      expect(writes, 0);
    },
  );
  test(
    'logo adapter rejects forged MIME and oversized files before networking',
    () async {
      final auth = _Auth();
      var calls = 0;
      final client = _Client(
        auth,
        MockClient((request) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      addTearDown(() async {
        await client.dispose();
        auth.dispose();
      });
      final repo = SupabaseStorefrontRepository(client);
      await expectLater(
        repo.uploadLogo(Uint8List.fromList('<svg/>'.codeUnits), 'image/png'),
        throwsA(isA<StorefrontException>()),
      );
      await expectLater(
        repo.uploadLogo(Uint8List(2 * 1024 * 1024 + 1), 'image/jpeg'),
        throwsA(isA<StorefrontException>()),
      );
      expect(calls, 0);
    },
  );
  test('paged request adapter forwards both cursor components', () async {
    final auth = _Auth();
    final client = _Client(
      auth,
      MockClient((request) async {
        final body = jsonDecode(request.body) as Map;
        expect(body['p_limit'], 25);
        expect(body['p_before_id'], 'request-last');
        expect(body['p_before_created_at'], '2026-09-11T00:00:00.000Z');
        return http.Response(
          jsonEncode({'requests': [], 'next_cursor': null}),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(() async {
      await client.dispose();
      auth.dispose();
    });
    final result = await SupabaseStorefrontRepository(client).fetchRequests(
      before: StorefrontRequestCursor(
        createdAt: DateTime.utc(2026, 9, 11),
        id: 'request-last',
      ),
    );
    expect(result.requests, isEmpty);
    expect(result.nextCursor, isNull);
  });
}
