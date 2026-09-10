import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_app/features/promotions/promotion_notification_popup.dart';
import 'package:flutter_app/features/promotions/engagement_strings.dart';
import 'package:flutter_app/features/promotions/promotions_screen.dart';
import 'package:flutter_app/features/profile/notifications_screen.dart';
import 'package:flutter_app/features/referrals/referral_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(320, 900), const Size(800, 375)]) {
    for (final dark in [false, true]) {
      testWidgets(
        'signup delivery gift is RTL and large-text safe at $size dark=$dark',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          session
            ..referralSummaryLoaded = true
            ..referralSummaryLoading = false
            ..referralSummaryError = null;
          for (final flags in [
            (true, false),
            (true, true),
            (false, true),
            (false, false),
          ]) {
            session.referralSummary = ReferralSummary(
              referralCode: 'LUGTA123',
              invitedCount: 0,
              qualifiedCount: 0,
              rewardedCount: 0,
              signupDeliveryActive: flags.$1,
              signupDeliveryEarned: flags.$2,
            );
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark() : AppTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: child!,
                  ),
                ),
                home: const ReferralScreen(),
              ),
            );
            expect(
              find.byKey(const ValueKey('referral_signup_offer')),
              flags.$1 || flags.$2 ? findsOneWidget : findsNothing,
            );
            expect(
              find.text(EngagementStrings.referralSignupBody),
              flags.$1 ? findsOneWidget : findsNothing,
            );
            expect(
              find.text(EngagementStrings.referralSignupEarned),
              flags.$2 ? findsOneWidget : findsNothing,
            );
            expect(
              find.text(EngagementStrings.referralSignupPaused),
              !flags.$1 && flags.$2 ? findsOneWidget : findsNothing,
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
  testWidgets(
    'profit-share offer shows withdrawable reward and survives pausing at 320dp',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      session
        ..referralSummary = const ReferralSummary(
          referralCode: 'LUGTA123',
          invitedCount: 1,
          qualifiedCount: 1,
          rewardedCount: 1,
          profitShareActive: true,
          profitShareEarned: 1000,
          profitShareOrders: 1,
        )
        ..referralSummaryLoaded = true
        ..referralSummaryLoading = false
        ..referralSummaryError = null;
      await tester.pumpWidget(const MaterialApp(home: ReferralScreen()));
      expect(
        find.byKey(const ValueKey('referral_profit_offer')),
        findsOneWidget,
      );
      expect(find.text('اربح 1٪ من أرباح أصدقائك'), findsOneWidget);
      expect(find.text('1,000 د.ع'), findsOneWidget);
      expect(tester.takeException(), isNull);
      session.referralSummary = const ReferralSummary(
        referralCode: 'LUGTA123',
        invitedCount: 1,
        qualifiedCount: 1,
        rewardedCount: 1,
        profitShareActive: false,
        profitShareEarned: 1000,
        profitShareOrders: 1,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const MaterialApp(home: ReferralScreen()));
      expect(
        find.text('العرض متوقف حالياً، وأرباحك السابقة محفوظة في محفظتك.'),
        findsOneWidget,
      );
      expect(find.text('1,000 د.ع'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'configured rewards render fractional rate and pending balances at 320dp',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      session
        ..referralSummary = const ReferralSummary(
          referralCode: 'TEST',
          invitedCount: 1,
          qualifiedCount: 0,
          rewardedCount: 0,
          rewardKind: 'profit_percent',
          rewardValue: 2.5,
          referralEnabled: true,
          pendingCash: 250,
          pendingPoints: 15,
          pendingDelivery: 2500,
        )
        ..referralSummaryLoaded = true
        ..referralSummaryLoading = false
        ..referralSummaryError = null;
      await tester.pumpWidget(const MaterialApp(home: ReferralScreen()));
      expect(find.text('2.5٪ من ربح طلب الإحالة'), findsOneWidget);
      expect(find.text('مكافآت نقدية معلّقة: 250 د.ع'), findsOneWidget);
      expect(find.text('نقاط معلّقة: 15'), findsOneWidget);
      expect(find.text('خصومات توصيل معلّقة: 2,500 د.ع'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('referral screen exposes code and all server metrics', (
    tester,
  ) async {
    session
      ..referralSummary = const ReferralSummary(
        referralCode: 'LUGTA-TEST',
        invitedCount: 8,
        qualifiedCount: 4,
        rewardedCount: 2,
        completedReferredOrders: 13,
        availableFreeDeliveries: 3,
        walletRewardsEarned: 25000,
      )
      ..referralSummaryLoaded = true
      ..referralSummaryLoading = false
      ..referralSummaryError = null;

    await tester.pumpWidget(const MaterialApp(home: ReferralScreen()));

    expect(find.text('LUGTA-TEST'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('referral_invited_count')),
      findsOneWidget,
    );
    expect(find.text('8'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('referral_completed_orders_count')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('referral_available_deliveries_count')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('referral_wallet_rewards_amount')),
      findsOneWidget,
    );
    expect(find.text('13'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('25,000 د.ع'), findsOneWidget);
    expect(find.byKey(const ValueKey('copy_referral_code')), findsOneWidget);
    expect(find.byKey(const ValueKey('share_referral_code')), findsOneWidget);
  });

  testWidgets('rewards screen lists available server grant details', (
    tester,
  ) async {
    session
      ..promotionGrants = List.of(MockData.promotionGrants)
      ..promotionGrantsLoaded = true
      ..promotionGrantsLoading = false
      ..promotionGrantsError = null;

    await tester.pumpWidget(const MaterialApp(home: PromotionsScreen()));

    expect(
      find.byKey(const ValueKey('promotion_grant_grant-demo-free-delivery')),
      findsOneWidget,
    );
    expect(find.text('توصيل مجاني'), findsOneWidget);
  });

  testWidgets('server notification popup shows durable notification copy', (
    tester,
  ) async {
    final notification = AppNotification(
      id: 'promo-popup',
      title: 'هدية لك',
      body: 'حصلت على توصيل مجاني',
      type: NotificationType.promotion,
      at: _fixedDate,
      showPopup: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => unawaited(
              showPromotionNotificationPopup(context, notification),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('هدية لك'), findsOneWidget);
    expect(find.text('حصلت على توصيل مجاني'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('promotion_popup_close')));
    await tester.pumpAndSettle();
    expect(find.text('هدية لك'), findsNothing);
  });

  testWidgets(
    'rich notification image works in popup and inbox at 320dp with large text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      AppNetworkImage.debugImageProvider = (_) => MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
      addTearDown(() => AppNetworkImage.debugImageProvider = null);

      final notification = AppNotification(
        id: 'rich-promo',
        title: 'عرض جديد مرتب وواضح',
        body: 'افتح العرض وشاهد تفاصيل المنتج والسعر قبل انتهاء المدة.',
        type: NotificationType.product,
        at: _fixedDate,
        imageUrl: 'https://example.test/product.webp',
        imageAlt: 'صورة المنتج المشمول بالعرض',
        showPopup: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () => unawaited(
                showPromotionNotificationPopup(context, notification),
              ),
              child: const Text('open rich'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open rich'));
      await tester.pumpAndSettle();
      expect(find.byType(AppNetworkImage), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('promotion_popup_close_icon')),
      );
      await tester.pumpAndSettle();
      session.notifications = [notification];
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: const NotificationsScreen(),
        ),
      );
      await tester.pump();
      expect(find.byType(AppNetworkImage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('popup-only notification stays out of the durable inbox UI', (
    tester,
  ) async {
    session.notifications = [
      AppNotification(
        id: 'hidden-popup',
        title: 'Popup only',
        body: 'Hidden from inbox',
        type: NotificationType.promotion,
        at: _fixedDate,
        showPopup: true,
        showInbox: false,
        popupPriority: 10,
      ),
      AppNotification(
        id: 'visible-inbox',
        title: 'Visible inbox',
        body: 'Visible body',
        type: NotificationType.system,
        at: _fixedDate,
      ),
    ];

    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));

    expect(find.text('Popup only'), findsNothing);
    expect(find.text('Visible inbox'), findsOneWidget);
    expect(session.nextPopupNotification?.id, 'hidden-popup');
  });

  test('expired promotion notification never becomes a pending popup', () {
    final notification = AppNotification(
      id: 'expired-popup',
      title: 'Expired',
      body: 'Expired body',
      type: NotificationType.promotion,
      at: _fixedDate,
      showPopup: true,
      expiresAt: DateTime.utc(2026, 8, 7),
    );

    expect(notification.hasPendingPopupAt(DateTime.utc(2026, 8, 6)), isTrue);
    expect(notification.hasPendingPopupAt(DateTime.utc(2026, 8, 7)), isFalse);
    expect(notification.hasPendingPopupAt(DateTime.utc(2026, 8, 8)), isFalse);
  });

  testWidgets('referral metrics remain usable at 320dp and large Arabic text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    session
      ..referralSummary = const ReferralSummary(
        referralCode: 'LUGTA-LARGE-TEXT',
        invitedCount: 8,
        qualifiedCount: 4,
        rewardedCount: 2,
        completedReferredOrders: 13,
        availableFreeDeliveries: 3,
        walletRewardsEarned: 25000,
      )
      ..referralSummaryLoaded = true
      ..referralSummaryLoading = false
      ..referralSummaryError = null;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
        home: const ReferralScreen(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('referral_wallet_rewards_amount')),
      findsOneWidget,
    );
  });

  testWidgets(
    'engagement refresh waits until protected route build completes',
    (tester) async {
      await _configureSignedInDemo(tester);
      session
        ..promotionGrants = []
        ..promotionGrantsLoaded = false
        ..promotionGrantsLoading = false
        ..promotionGrantsError = null;

      await tester.pumpWidget(
        _underSessionRouteListener(const PromotionsScreen()),
      );
      expect(tester.takeException(), isNull);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());

      session
        ..referralSummary = null
        ..referralSummaryLoaded = false
        ..referralSummaryLoading = false
        ..referralSummaryError = null;

      await tester.pumpWidget(
        _underSessionRouteListener(const ReferralScreen()),
      );
      expect(tester.takeException(), isNull);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

final _fixedDate = DateTime(2026, 8, 6);

Future<void> _configureSignedInDemo(WidgetTester tester) async {
  final repositories = createDemoRepositories();
  await tester.runAsync(() async {
    await repositories.auth.signIn(phone: '07800000000', password: 'password');
    await session.configure(repositories, loadInitialData: false);
  });
}

Widget _underSessionRouteListener(Widget child) => MaterialApp(
  home: ListenableBuilder(listenable: session, builder: (context, _) => child),
);
