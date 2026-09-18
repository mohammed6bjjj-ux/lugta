import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/promotion_mapper.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/loyalty/loyalty_strings.dart';
import 'package:flutter_app/features/promotions/engagement_strings.dart';
import 'package:flutter_app/features/promotions/promotions_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Zain')
          ..addFont(rootBundle.load('assets/fonts/Zain-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Zain-Bold.ttf')))
        .load();
    var flutterCache = File(Platform.resolvedExecutable).parent;
    while (flutterCache.path.split(Platform.pathSeparator).last != 'cache') {
      final parent = flutterCache.parent;
      if (parent.path == flutterCache.path) {
        throw StateError('Unable to locate the Flutter cache directory.');
      }
      flutterCache = parent;
    }
    final materialIconBytes = await File(
      '${flutterCache.path}/artifacts/material_fonts/materialicons-regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(materialIconBytes)))).load();
  });

  setUp(() {
    session
      ..promotionGrantsLoaded = true
      ..promotionGrantsLoading = false
      ..promotionGrantsError = null;
  });

  tearDown(() {
    appSettings.language = AppLanguage.ar;
    appSettings.darkMode = false;
    AppColors.p = AppPalette.light;
    session.promotionGrants = [];
  });

  testWidgets('admin copy renders on the card without changing its balance', (tester) async {
    final promotion = promotionFromJson({'name_ar':'original', 'promotion_display_copy':{'copy':{
      'title_ar':'هدية خصم التوصيل','label_ar':'خصم حتى ٢٬٥٠٠ د.ع','description_ar':'نص الشروط من الإدارة',
    }}});
    session.promotionGrants = [_grant(promotion:promotion)];
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('هدية خصم التوصيل'),findsOneWidget);
    expect(find.text('خصم حتى ٢٬٥٠٠ د.ع'),findsOneWidget);
    expect(find.text('نص الشروط من الإدارة'),findsOneWidget);
    expect(session.promotionGrants.single.rewardValue,1);
    expect(tester.takeException(),isNull);
  });

  for (final language in AppLanguage.values) {
    test(
      'referral and loyalty copy describe discounts in ${language.name}',
      () {
        appSettings.language = language;
        final copy = [
          EngagementStrings.referralSignupTitle,
          EngagementStrings.referralSignupBody,
          EngagementStrings.availableFreeDeliveries,
          EngagementStrings.deliveryDiscount,
          LoyaltyStrings.freeDeliveryReward(1),
          LoyaltyStrings.freeDeliveryReward(3),
        ];
        for (final value in copy) {
          expect(value, isNot(matches(_freeDeliveryClaim)));
        }
        expect(LoyaltyStrings.freeDeliveryReward(1), contains('1'));
        expect(LoyaltyStrings.freeDeliveryReward(3), contains('3'));
        expect(LoyaltyStrings.freeDeliveryReward(1), isNot(contains('IQD')));
        expect(LoyaltyStrings.freeDeliveryReward(1), isNot(contains('د.ع')));
      },
    );

    for (final viewport in [
      (size: const Size(375, 900), scale: 1.0),
      (size: const Size(320, 900), scale: 2.0),
      (size: const Size(800, 375), scale: 2.0),
    ]) {
      for (final dark in [false, true]) {
        testWidgets(
          'legacy delivery reward remains a discount in every status '
          '${language.name} ${viewport.size} scale=${viewport.scale} dark=$dark',
          (tester) async {
            appSettings.language = language;
            appSettings.darkMode = dark;
            tester.view.physicalSize = viewport.size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            session.promotionGrants = [
              for (final status in PromotionGrantStatus.values)
                _grant(status: status, promotion: _serverPromotion),
            ];

            await tester.pumpWidget(
              _app(textScale: viewport.scale, dark: dark),
            );
            await tester.pump();

            for (final status in PromotionGrantStatus.values) {
              final chip = find.byKey(
                ValueKey('promotion_status_${status.name}'),
              );
              await tester.scrollUntilVisible(
                chip,
                120,
                scrollable: find.descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable),
                ),
              );
              await tester.pumpAndSettle();
              await tester.tap(chip);
              await tester.pumpAndSettle();

              final grant = session.promotionGrants.singleWhere(
                (item) => item.status == status,
              );
              final value = tester.widget<Text>(
                find.byKey(ValueKey('promotion_reward_value_${grant.id}')),
              );
              expect(value.data, EngagementStrings.deliveryDiscount);
              // A legacy snapshot of 1 is one use. It is never 1 IQD, and the
              // current cap must not be invented for historical used rewards.
              expect(value.data, isNot(contains('1')));
              expect(value.data, isNot(contains('2,500')));
              expect(grant.rewardValue, 1);
              expect(grant.rewardType, 'free_delivery');
              expect(
                find.text(_serverPromotion.localizedDescription),
                findsOneWidget,
              );
              expect(find.text(_serverPromotion.localizedName), findsOneWidget);
              expect(
                tester
                    .widgetList<Text>(find.byType(Text))
                    .map((text) => text.data ?? '')
                    .join(' '),
                isNot(matches(_freeDeliveryClaim)),
              );
              expect(tester.takeException(), isNull);
              if (language == AppLanguage.ar &&
                  !dark &&
                  viewport.size.width < 400 &&
                  status == PromotionGrantStatus.available) {
                await expectLater(
                  find.byType(MaterialApp),
                  matchesGoldenFile(
                    'goldens/delivery-rewards/welcome-ar-light-'
                    '${viewport.size.width.toInt()}-'
                    '${(viewport.scale * 100).toInt()}.png',
                  ),
                );
              }
            }
          },
        );
      }
    }

    testWidgets(
      'missing promotion has a non-monetary fallback ${language.name}',
      (tester) async {
        appSettings.language = language;
        session.promotionGrants = [_grant()];
        await tester.pumpWidget(_app());
        await tester.pump();
        expect(find.text(EngagementStrings.deliveryDiscount), findsNWidgets(2));
        expect(find.text(formatIqd(1)), findsNothing);
        expect(find.textContaining('2,500'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('monetary delivery credit uses its own cap ${language.name}', (
      tester,
    ) async {
      appSettings.language = language;
      session.promotionGrants = [
        _grant(rewardType: 'delivery_credit', rewardValue: 1250),
      ];
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(
        find.text(EngagementStrings.deliveryDiscountUpTo(formatIqd(1250))),
        findsNWidgets(2),
      );
      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
      expect(find.textContaining('2,500'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

final _freeDeliveryClaim = RegExp(
  r'توصيل مجاني|خۆڕایی|free deliver',
  caseSensitive: false,
);

Widget _app({double textScale = 1, bool dark = false}) {
  AppColors.p = dark ? AppPalette.dark : AppPalette.light;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark() : AppTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: Directionality(
        textDirection: appSettings.language.isRtl
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child!,
      ),
    ),
    home: const PromotionsScreen(),
  );
}

PromotionGrant _grant({
  PromotionGrantStatus status = PromotionGrantStatus.available,
  String rewardType = 'free_delivery',
  int rewardValue = 1,
  Promotion? promotion,
}) => PromotionGrant(
  id: 'delivery-${status.name}',
  promotionId: 'delivery-promotion',
  sellerId: 'seller',
  rewardOrdinal: 1,
  rewardType: rewardType,
  rewardValue: rewardValue,
  status: status,
  promotion: promotion,
  createdAt: DateTime.utc(2026, 9, 11),
  expiresAt: status == PromotionGrantStatus.expired
      ? DateTime.utc(2026, 9, 10)
      : null,
  consumedAt: status == PromotionGrantStatus.used
      ? DateTime.utc(2026, 9, 11)
      : null,
);

const _serverPromotion = Promotion(
  id: 'delivery-promotion',
  nameAr: 'خصم توصيل — هدية الترحيب',
  nameCkb: 'دیاریی داشکاندنی گەیاندن',
  nameEn: 'Your delivery discount reward',
  descriptionAr:
      'المكافأة غير المستخدمة تمنحك حالياً خصم توصيل حتى ٢٬٥٠٠ د.ع عند وصول مجموع الجملة إلى ١٠٬٠٠٠ د.ع أو أكثر. تدفع باقي أجرة التوصيل. تُستخدم مرة واحدة بعد تفعيل الحساب وضمن تاريخ صلاحيتها. الطلبات السابقة لا تتغير.',
  descriptionCkb:
      'داشکاندنی ئێستای دیارییە بەکارنەهاتووەکان تا 2,500 د.ع ـە بۆ داواکاری بە کۆی کۆمەڵی 10,000 د.ع یان زیاتر. داواکارییە کۆنەکان ناگۆڕدرێن.',
  descriptionEn:
      'Unused rewards currently discount delivery by up to 2,500 IQD on orders with a wholesale total of 10,000 IQD or more. Historical orders remain unchanged.',
  audienceType: 'all',
  triggerType: 'immediate',
  beneficiary: 'seller',
  rewardType: 'free_delivery',
  rewardValue: 1,
  startsAt: null,
  endsAt: null,
  isActive: true,
  priority: 1,
  showPopup: false,
  showInbox: true,
  sendPush: false,
);
