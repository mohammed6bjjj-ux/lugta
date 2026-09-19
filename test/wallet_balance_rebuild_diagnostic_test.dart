import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_app/core/widgets/primary_button.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/wallet/wallet_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Wallet implements WalletRepository {
  int available = 0;
  int pending = 0;
  int earned = 0;
  @override
  Stream<void> watchWalletChanges() => const Stream.empty();
  @override
  Future<WalletSnapshot> fetchWallet() async => WalletSnapshot(
    available: available,
    pending: pending,
    totalEarned: earned,
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

void main() {
  testWidgets(
    'wallet card refreshes balances and withdrawal eligibility without remounting',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final wallet = _Wallet();
      await tester.runAsync(() async {
        final base = createDemoRepositories();
        await base.auth.signIn(phone: '07700000000', password: 'test-password');
        await session.configure(
          AppRepositories(
            auth: base.auth,
            profile: base.profile,
            catalog: base.catalog,
            orders: base.orders,
            wallet: wallet,
            notifications: base.notifications,
            isDemo: false,
          ),
          loadInitialData: false,
        );
        await session.refreshCurrentProfile();
        await session.refreshWallet();
      });
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const WalletScreen()),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PrimaryButton>(find.byType(PrimaryButton).first)
            .onPressed,
        isNull,
      );
      wallet.available = 45000;
      wallet.pending = 20000;
      wallet.earned = 110000;
      await tester.runAsync(() => session.refreshWallet());
      await tester.pumpAndSettle();
      expect(session.availableBalance, 45000);
      expect(find.text(formatIqd(45000)), findsOneWidget);
      expect(find.text(formatIqd(20000)), findsOneWidget);
      expect(find.text(formatIqd(110000)), findsOneWidget);
      expect(
        tester
            .widget<PrimaryButton>(find.byType(PrimaryButton).first)
            .onPressed,
        isNotNull,
      );
      wallet.available = 0;
      wallet.pending = 5000;
      await tester.runAsync(() => session.refreshWallet());
      await tester.pumpAndSettle();
      expect(find.text(formatIqd(45000)), findsNothing);
      expect(find.text(formatIqd(5000)), findsOneWidget);
      expect(find.text(formatIqd(110000)), findsOneWidget);
      expect(
        tester
            .widget<PrimaryButton>(find.byType(PrimaryButton).first)
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () =>
            session.configure(createDemoRepositories(), loadInitialData: false),
      );
    },
  );
}
