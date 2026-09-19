import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/repositories/supabase_repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/data/withdrawal_amount_rules.dart';
import 'package:flutter_app/features/wallet/wallet_strings.dart';
import 'package:flutter_app/features/wallet/withdraw_request_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('accepts user examples and rejects fractions, zero and negatives', () {
    for (final amount in [156000, 10000, 20000, 35000]) {
      expect(isWholeThousandWithdrawal(amount), isTrue);
    }
    for (final amount in [10500, 155500, 10001, 0, -1000]) {
      expect(isWholeThousandWithdrawal(amount), isFalse);
    }
  });

  test('maximum floors the request, not the wallet balance', () {
    expect(maximumWholeThousandWithdrawal(155500), 155000);
    expect(maximumWholeThousandWithdrawal(10500), 10000);
    expect(maximumWholeThousandWithdrawal(156000), 156000);
    expect(maximumWholeThousandWithdrawal(999), 0);
    expect(maximumWholeThousandWithdrawal(-1), 0);
  });

  test(
    'repository rejects fractional requests before making an HTTP call',
    () async {
      var calls = 0;
      final client = SupabaseClient(
        'http://localhost',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((_) async {
          calls++;
          return http.Response('{}', 500);
        }),
      );
      addTearDown(client.dispose);
      final repository = SupabaseWalletRepository(client);
      for (final amount in [10500, 155500, 0, -1000]) {
        await expectLater(
          repository.requestWithdrawal(
            CreateWithdrawalRequest(
              clientRequestId: 'test-id',
              amount: amount,
              method: 'SuperQi',
              accountDetail: '12345',
              payoutAccountId: 'test-account',
            ),
          ),
          throwsA(isA<BackendException>()),
        );
      }
      expect(calls, 0);
    },
  );

  for (final language in AppLanguage.values) {
    testWidgets(
      'real withdrawal screen validates and floors maximum: ${language.name}',
      (tester) async {
        final previousLanguage = appSettings.language;
        appSettings.language = language;
        addTearDown(() async {
          appSettings.language = previousLanguage;
          await session.configure(
            createDemoRepositories(),
            loadInitialData: false,
          );
        });
        final base = createDemoRepositories();
        await tester.runAsync(() async {
          await base.auth.signIn(
            phone: '07700000000',
            password: 'test-password',
          );
          await session.configure(
            AppRepositories(
              auth: base.auth,
              profile: base.profile,
              catalog: base.catalog,
              orders: base.orders,
              wallet: _Wallet(),
              notifications: base.notifications,
              isDemo: true,
            ),
            loadInitialData: false,
          );
          await session.refreshAuthenticatedData();
        });
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            builder: (_, child) => Directionality(
              textDirection: language == AppLanguage.en
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              child: child!,
            ),
            home: const WithdrawRequestScreen(),
          ),
        );
        await tester.pumpAndSettle();
        final field = find.byKey(const ValueKey('withdrawal_amount_field'));
        for (final amount in ['10500', '155500']) {
          await tester.enterText(field, amount);
          await tester.pumpAndSettle();
          expect(
            find.text(WalletStrings.wholeThousandsRequired),
            findsOneWidget,
          );
        }
        for (final amount in ['10000', '20000', '35000', '156000']) {
          await tester.enterText(field, amount);
          await tester.pumpAndSettle();
          expect(find.text(WalletStrings.wholeThousandsRequired), findsNothing);
        }
        await tester.enterText(field, '9000');
        await tester.pumpAndSettle();
        expect(
          find.text(WalletStrings.minWithdrawalError(formatIqd(10000))),
          findsOneWidget,
        );
        await tester.tap(find.text(WalletStrings.withdrawMaximum));
        await tester.pumpAndSettle();
        final controller = tester.widget<TextFormField>(field).controller!;
        expect(controller.text, formatNumber(156000));
        expect(session.availableBalance, 156500);
        expect(find.text(WalletStrings.wholeThousandsRequired), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Wallet implements WalletRepository {
  @override
  Stream<void> watchWalletChanges() => const Stream<void>.empty();

  @override
  Future<WalletSnapshot> fetchWallet() async => const WalletSnapshot(
    available: 156500,
    pending: 0,
    totalEarned: 156500,
    minimumWithdrawal: 10000,
    transactions: [],
    withdrawals: [],
    payoutAccounts: [],
    statementLines: [],
    withdrawalSources: [],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
