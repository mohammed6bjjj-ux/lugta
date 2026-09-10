import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/data/repositories/supabase_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';

Future<T> _read<T>(Future<T> operation) async {
  try {
    return await operation;
  } on BackendException catch (error) {
    fail(
      'Catalog read failed: ${error.cause}\n'
      '${error.cause is Error ? (error.cause as Error).stackTrace : ""}',
    );
  }
}

class _CatalogAuth extends GoTrueClient {
  _CatalogAuth(this.signedIn) : super(autoRefreshToken: false);
  final bool signedIn;
  @override
  Session? get currentSession => null;
  @override
  User? get currentUser => signedIn
      ? const User(
          id: 'seller',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-09-09T00:00:00Z',
        )
      : null;
}

class _CatalogClient extends SupabaseClient {
  _CatalogClient(this.catalogAuth, http.Client transport)
    : super(
        'http://localhost',
        'test-key',
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
  final _CatalogAuth catalogAuth;
  @override
  GoTrueClient get auth => catalogAuth;
}

void main() {
  for (final signedIn in [true, false]) {
    for (final detail in [true, false]) {
      test('size fetch: signedIn=$signedIn detail=$detail', () async {
        var variantQueries = 0;
        final auth = _CatalogAuth(signedIn);
        final client = _CatalogClient(
          auth,
          MockClient((request) async {
            Object response = [];
            if (request.url.path.endsWith('/products')) {
              const product = {
                'id': 'shirt',
                'name_ar': 'قميص',
                'category_id': 'clothing',
                'wholesale_price': 6500,
                'suggested_price': 15000,
              };
              response = detail ? product : [product];
            } else if (request.url.path.endsWith('/product_variants')) {
              variantQueries++;
              final columns = request.url.queryParameters['select']!;
              expect(
                columns.contains('option_values'),
                signedIn,
                reason: 'Guests retain their existing column-level grant.',
              );
              response = [
                {
                  'id': 'black-m',
                  'product_id': 'shirt',
                  'name_ar': 'أسود / M',
                  'stock_on_hand': 10,
                  'stock_reserved': 2,
                  if (signedIn) 'option_values': {'size': 'M'},
                },
              ];
            }
            return http.Response(
              jsonEncode(response),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        addTearDown(() async {
          await client.dispose();
          auth.dispose();
        });
        final repository = SupabaseCatalogRepository(client);
        final product = detail
            ? await _read(repository.fetchProduct('shirt'))
            : (await _read(repository.fetchProducts())).single;
        expect(variantQueries, 1);
        expect(product.variants.single.size, signedIn ? 'M' : null);
        expect(product.variants.single.localizedName, 'أسود / M');
        expect(product.variants.single.stock, 8);
      });
    }
  }
}
