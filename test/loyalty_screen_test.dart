import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/loyalty/loyalty_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loyalty screen exposes level, progress, rewards, and ledger', (
    tester,
  ) async {
    session
      ..loyaltySummary = MockData.loyaltySummary
      ..loyaltySummaryLoaded = true
      ..loyaltySummaryLoading = false
      ..loyaltySummaryError = null;

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LoyaltyScreen()),
    );

    expect(find.text('المستويات والمكافآت'), findsOneWidget);
    expect(find.text('برونزي'), findsWidgets);
    expect(find.textContaining('640'), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await tester.scrollUntilVisible(
      find.text('ORD-0001042'),
      400,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('ORD-0001042'), findsOneWidget);
  });

  testWidgets('loyalty screen remains usable at 320dp and 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    session
      ..loyaltySummary = MockData.loyaltySummary
      ..loyaltySummaryLoaded = true
      ..loyaltySummaryLoading = false
      ..loyaltySummaryError = null;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
        home: const LoyaltyScreen(),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('ORD-0001042'),
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('ORD-0001042'), findsOneWidget);
  });
}
