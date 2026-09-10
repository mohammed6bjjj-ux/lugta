import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/data/repositories/supabase_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/features/order_wizard/wizard_strings.dart';
import 'package:flutter_app/data/app_settings.dart';

void main() {
  for (final mode in ['v2', 'legacy', 'denied']) {
    test(
      'delivery preview: $mode uses correct RPC and preserves policy values',
      () async {
        final calls = <String>[];
        final client = SupabaseClient(
          'http://localhost',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
            calls.add(request.url.path);
            expect(jsonDecode(request.body)['p_order_wholesale_total'], 7500);
            if (request.url.path.endsWith('_v2') && mode != 'v2') {
              return http.Response(
                jsonEncode({
                  'code': mode == 'legacy' ? 'PGRST202' : '42501',
                  'message': 'test',
                }),
                mode == 'legacy' ? 404 : 403,
                request: request,
                headers: {'content-type': 'application/json'},
              );
            }
            final quote = {
              'base_delivery_fee': 5000,
              'delivery_fee': 5000,
              'delivery_discount': 0,
              if (mode == 'v2') ...{
                'reward_available': true,
                'reward_discount_cap': 2500,
                'remaining_wholesale': 2500,
              },
            };
            return http.Response(
              jsonEncode(mode == 'v2' ? quote : [quote]),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        addTearDown(client.dispose);
        final result = SupabaseCatalogRepository(
          client,
        ).quoteDeliveryFee('zone', orderWholesaleTotal: 7500);
        if (mode == 'denied') {
          await expectLater(result, throwsA(anything));
          expect(
            calls,
            hasLength(1),
            reason:
                'An authorization error must not trigger a legacy fallback.',
          );
        } else {
          final quote = await result.catchError((Object error) {
            if (error is BackendException) {
              fail('Quote failed: ${error.cause}');
            }
            throw error;
          });
          expect(quote.deliveryFee, 5000);
          expect(quote.rewardAvailable, mode == 'v2');
          expect(quote.rewardDiscountCap, mode == 'v2' ? 2500 : 0);
          expect(quote.remainingWholesale, mode == 'v2' ? 2500 : 0);
          expect(calls, hasLength(mode == 'legacy' ? 2 : 1));
        }
      },
    );
  }
  test('Arabic delivery copy shows exact discount and remaining wholesale', () {
    final previous = appSettings.language;
    addTearDown(() => appSettings.language = previous);
    appSettings.language = AppLanguage.ar;
    expect(
      WizardStrings.deliveryDiscountAmount('2,500 د.ع'),
      'خصم التوصيل: 2,500 د.ع',
    );
    expect(
      WizardStrings.deliveryRewardRemaining('1,000 د.ع', '2,500 د.ع'),
      contains('باقي 1,000 د.ع'),
    );
  });
}
