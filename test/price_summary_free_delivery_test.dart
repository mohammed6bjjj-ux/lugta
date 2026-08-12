import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_app/core/widgets/price_summary_card.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/l10n/core_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'free delivery shows the regular 5,000 fee and an explicit matching discount',
    (tester) async {
      final previousLanguage = appSettings.language;
      final previousDarkMode = appSettings.darkMode;
      appSettings.language = AppLanguage.ar;
      appSettings.darkMode = false;
      addTearDown(() {
        appSettings.language = previousLanguage;
        appSettings.darkMode = previousDarkMode;
      });
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: PriceSummaryCard(
                  wholesaleTotal: 20000,
                  saleTotal: 30000,
                  deliveryFee: 0,
                  baseDeliveryFee: 5000,
                  quantity: 1,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final deliveryRow = find.byKey(
        const ValueKey('price_summary_delivery_fee'),
      );
      final discountRow = find.byKey(
        const ValueKey('price_summary_delivery_discount'),
      );
      expect(deliveryRow, findsOneWidget);
      expect(discountRow, findsOneWidget);
      expect(
        find.descendant(of: deliveryRow, matching: find.text(formatIqd(5000))),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: discountRow,
          matching: find.text(CoreStrings.deliveryDiscount),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: discountRow,
          matching: find.text('- ${formatIqd(5000)}'),
        ),
        findsOneWidget,
      );
      expect(find.text(formatIqd(30000)), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('paid delivery does not show a free-delivery discount', (
    tester,
  ) async {
    final previousLanguage = appSettings.language;
    appSettings.language = AppLanguage.ar;
    addTearDown(() => appSettings.language = previousLanguage);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: PriceSummaryCard(
            wholesaleTotal: 10000,
            saleTotal: 15000,
            deliveryFee: 5000,
            baseDeliveryFee: 5000,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('price_summary_delivery_fee')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('price_summary_delivery_discount')),
      findsNothing,
    );
    expect(find.text(formatIqd(20000)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seller delivery share lowers both customer fee and net profit', (
    tester,
  ) async {
    final previousLanguage = appSettings.language;
    appSettings.language = AppLanguage.ar;
    addTearDown(() => appSettings.language = previousLanguage);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: PriceSummaryCard(
              wholesaleTotal: 7000,
              saleTotal: 15000,
              baseDeliveryFee: 5000,
              deliveryFee: 2500,
              sellerDeliveryContribution: 2500,
            ),
          ),
        ),
      ),
    );

    final contributionRow = find.byKey(
      const ValueKey('price_summary_seller_delivery_contribution'),
    );
    final customerFeeRow = find.byKey(
      const ValueKey('price_summary_customer_delivery_final'),
    );
    expect(contributionRow, findsOneWidget);
    expect(customerFeeRow, findsOneWidget);
    expect(
      find.descendant(
        of: contributionRow,
        matching: find.text('- ${formatIqd(2500)}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: customerFeeRow, matching: find.text(formatIqd(2500))),
      findsOneWidget,
    );
    expect(find.text(formatIqd(5500)), findsOneWidget);
    expect(find.text(formatIqd(17500)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
