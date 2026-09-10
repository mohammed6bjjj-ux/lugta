import 'dart:convert';

import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/repositories/supabase_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _WalletAuth extends GoTrueClient {
  _WalletAuth() : super(autoRefreshToken: false);
  @override
  Session? get currentSession => null;
  @override
  User get currentUser => const User(
    id: 'seller',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-09-09T00:00:00Z',
  );
}

class _WalletClient extends SupabaseClient {
  _WalletClient(this.walletAuth, http.Client transport)
    : super(
        'http://localhost',
        'test-key',
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
  final _WalletAuth walletAuth;
  @override
  GoTrueClient get auth => walletAuth;
}

void main() {
  for (final settled in [false, true]) {
    test(
      'wallet HTTP read retains pending history: settled=$settled',
      () async {
        final auth = _WalletAuth();
        final checked = <String>{};
        final client = _WalletClient(
          auth,
          MockClient((request) async {
            final table = request.url.pathSegments.last;
            Object response = [];
            if (table == 'seller_wallet_summary' ||
                table == 'seller_wallet_ledger') {
              expect(request.url.queryParameters['seller_id'], 'eq.seller');
              checked.add(table);
            }
            if (table == 'seller_wallet_summary') {
              response = {
                'available_balance': settled ? 12000 : 0,
                'pending_balance': settled ? 0 : 12000,
                'total_earned': settled ? 12000 : 0,
              };
            } else if (table == 'seller_wallet_ledger') {
              expect(
                request.url.queryParameters['order'],
                'created_at.desc.nullslast,id.desc.nullslast',
              );
              Map<String, Object> row(
                String id,
                String type,
                String bucket,
                int amount,
              ) => {
                'id': id,
                'entry_type': type,
                'bucket': bucket,
                'amount': amount,
                'order_id': 'order-1',
                'order_number': 'ORD-1',
                'created_at': '2026-09-09T08:00:00Z',
              };
              response = [
                if (settled) ...[
                  row('release', 'profit_release', 'available', 12000),
                  row('counter', 'profit_release', 'pending', -12000),
                ],
                row('initial', 'profit_pending', 'pending', 12000),
              ];
            } else if (table == 'content_entries') {
              response = {
                'payload': {'minimum_withdrawal_amount': 4000},
              };
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
        final wallet = await SupabaseWalletRepository(client)
            .fetchWallet()
            .catchError((Object error) {
              if (error is BackendException) {
                fail('Wallet read failed: ${error.cause}');
              }
              throw error;
            });
        expect(checked, {'seller_wallet_summary', 'seller_wallet_ledger'});
        expect(wallet.available, settled ? 12000 : 0);
        expect(wallet.pending, settled ? 0 : 12000);
        expect(wallet.minimumWithdrawal, 4000);
        expect(wallet.transactions, hasLength(settled ? 2 : 1));
        expect(
          wallet.transactions
              .where((t) => t.type == WalletTxType.pendingProfit)
              .single
              .amount,
          12000,
        );
        if (settled) {
          expect(
            wallet.transactions
                .where((t) => t.type == WalletTxType.profitReleased)
                .single
                .amount,
            12000,
          );
        }
      },
    );
  }
}
