import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/loyalty/loyalty_screen.dart';
import 'package:flutter_app/features/loyalty/loyalty_strings.dart';
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

  testWidgets('tier benefit request opens a bounded quantity stepper', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    session
      ..loyaltySummary = MockData.loyaltySummary
      ..loyaltySummaryLoaded = true
      ..loyaltySummaryLoading = false
      ..loyaltySummaryError = null;

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LoyaltyScreen()),
    );
    final action = find.byIcon(Icons.arrow_forward_rounded).first;
    await tester.scrollUntilVisible(
      action,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.text(LoyaltyStrings.addReferenceImage), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom content request offers photo and video explicitly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    session
      ..loyaltySummary = MockData.loyaltySummary
      ..loyaltySummaryLoaded = true
      ..loyaltySummaryLoading = false
      ..loyaltySummaryError = null;

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LoyaltyScreen()),
    );
    final photographyAction = find.byIcon(Icons.arrow_forward_rounded).at(1);
    await tester.scrollUntilVisible(
      photographyAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(photographyAction);
    await tester.pumpAndSettle();

    expect(find.text(LoyaltyStrings.contentType), findsOneWidget);
    expect(find.text(LoyaltyStrings.photos), findsOneWidget);
    expect(find.text(LoyaltyStrings.video), findsOneWidget);
    final contentSelector = find.byType(SegmentedButton<LoyaltyContentKind>);
    expect(contentSelector, findsOneWidget);
    expect(
      find.descendant(
        of: contentSelector,
        matching: find.byIcon(Icons.photo_camera_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: contentSelector,
        matching: find.byIcon(Icons.videocam_outlined),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Diamond member can choose a product, variant, and bounded quantity',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      session
        ..products = List<Product>.of(MockData.products)
        ..loyaltySummary = _diamondSummary()
        ..loyaltySummaryLoaded = true
        ..loyaltySummaryLoading = false
        ..loyaltySummaryError = null;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const LoyaltyScreen(),
        ),
      );

      final openButton = find.byKey(
        const ValueKey('open_stock_reservation_button'),
      );
      await tester.scrollUntilVisible(
        openButton,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(openButton, findsOneWidget);
      expect(find.byIcon(Icons.diamond_rounded), findsWidgets);
      expect(tester.getSize(openButton).height, greaterThanOrEqualTo(48));

      await tester.tap(openButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byKey(const ValueKey('stock_reservation_sheet')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('reservation_product_selector')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byKey(const ValueKey('reservation_product_picker')),
        findsOneWidget,
      );
      await tester.tap(find.byType(ListTile).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final variant = MockData.products.first.variants.first;
      final variantTile = find.byKey(
        ValueKey('reservation_variant_${variant.id}'),
      );
      expect(variantTile, findsOneWidget);
      await tester.tap(variantTile);
      await tester.pump();

      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      final confirm = find.byKey(
        const ValueKey('confirm_stock_reservation_button'),
      );
      expect(confirm, findsOneWidget);
      expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    },
  );
}

LoyaltySummary _diamondSummary() {
  const entitlement = StockReservationEntitlement(
    enabled: true,
    maxActiveUnits: 12,
    maxPerReservation: 4,
    holdHours: 24,
    activeUnits: 2,
    remainingUnits: 10,
  );
  const diamond = LoyaltyTierDefinition(
    code: LoyaltyTierCode.diamond,
    nameAr: 'ألماسي',
    nameCkb: 'ئەڵماس',
    nameEn: 'Diamond',
    threshold: 6000,
    rewardEnabled: true,
    rewardType: 'free_delivery',
    rewardValue: 5,
    benefits: <LoyaltyTierBenefit>[],
    stockReservation: entitlement,
  );
  return LoyaltySummary(
    programEnabled: true,
    pointsPerSoldUnit: 10,
    totalPoints: 6800,
    completedUnits: 680,
    currentTier: diamond,
    tiers: const <LoyaltyTierDefinition>[diamond],
    recentEntries: MockData.loyaltySummary.recentEntries,
    recentStockReservations: <StockReservation>[
      StockReservation(
        id: 'reservation-test-1',
        reservationNumber: 41,
        variantId: MockData.products.first.variants.first.id,
        productId: MockData.products.first.id,
        productName: MockData.products.first.nameAr,
        variantName: MockData.products.first.variants.first.nameAr,
        imageUrl: MockData.products.first.coverImage,
        quantity: 2,
        consumedQuantity: 0,
        releasedQuantity: 0,
        remainingQuantity: 2,
        status: StockReservationStatus.active,
        expiresAt: DateTime.now().add(const Duration(hours: 20)),
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ],
  );
}
