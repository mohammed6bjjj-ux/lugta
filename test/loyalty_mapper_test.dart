import 'package:flutter_app/data/loyalty_mapper.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'maps the current loyalty RPC contract and keeps signed ledger points',
    () {
      final summary = loyaltySummaryFromRpc({
        'programEnabled': true,
        'pointsPerSoldUnit': 15,
        'totalPoints': 1200,
        'completedUnits': 80,
        'pointsToNextTier': 1800,
        'currentTier': {
          'code': 'bronze',
          'nameAr': 'برونزي',
          'nameCkb': 'برۆنز',
          'nameEn': 'Bronze',
          'threshold': 0,
          'rewardEnabled': true,
          'rewardType': 'free_delivery',
          'rewardValue': 1,
          'rewardValidDays': 14,
        },
        'nextTier': {
          'code': 'silver',
          'nameAr': 'فضي',
          'nameCkb': 'زیو',
          'nameEn': 'Silver',
          'threshold': 3000,
          'pointsNeeded': 1800,
        },
        'tiers': [
          {
            'code': 'silver',
            'nameAr': 'فضي',
            'threshold': 3000,
            'rewardEnabled': false,
            'rewardValue': 0,
          },
          {
            'code': 'bronze',
            'nameAr': 'برونزي',
            'threshold': 0,
            'rewardEnabled': true,
            'rewardType': 'free_delivery',
            'rewardValue': 1,
          },
        ],
        'recentEntries': [
          {
            'id': 'reversal-1',
            'type': 'order_reversed',
            'points': -30,
            'orderId': 'order-1',
            'orderNumber': 'ORD-1',
            'soldUnits': 2,
            'description': 'إلغاء نقاط طلب',
            'createdAt': '2026-08-10T10:00:00Z',
          },
        ],
      });

      expect(summary.programEnabled, isTrue);
      expect(summary.currentTier?.code, LoyaltyTierCode.bronze);
      expect(summary.nextTier?.pointsNeeded, 1800);
      expect(summary.tiers.map((tier) => tier.code), [
        LoyaltyTierCode.bronze,
        LoyaltyTierCode.silver,
      ]);
      expect(summary.recentEntries.single.points, -30);
      expect(summary.recentEntries.single.isCredit, isFalse);
    },
  );

  test('accepts staged legacy aliases and preserves bigint point totals', () {
    final summary = loyaltySummaryFromRpc({
      'programEnabled': true,
      'totalPoints': 5000000000,
      'pointsToNextTier': 42,
      'nextTier': {
        'code': 'loyalty_gold',
        'nameEn': 'Gold',
        'threshold': 5000000042,
      },
      'entries': [
        {
          'id': 'legacy-1',
          'type': 'positive_adjustment',
          'points': 5000000000,
          'soldUnits': 0,
          'createdAt': '2026-08-10T10:00:00Z',
        },
      ],
    });

    expect(summary.totalPoints, 5000000000);
    expect(summary.nextTier?.code, LoyaltyTierCode.gold);
    expect(summary.nextTier?.pointsNeeded, 42);
    expect(summary.recentEntries.single.points, 5000000000);
  });

  test('maps gold as the terminal level without a next tier', () {
    final summary = loyaltySummaryFromRpc({
      'programEnabled': true,
      'totalPoints': 9000,
      'currentTier': {
        'code': 'gold',
        'nameAr': 'ذهبي',
        'threshold': 5000,
        'rewardEnabled': true,
        'rewardType': 'wallet_credit',
        'rewardValue': 10000,
      },
      'nextTier': null,
      'recentEntries': [
        {
          'id': 'adjustment-1',
          'type': 'negative_adjustment',
          'points': -5,
          'soldUnits': 0,
          'createdAt': '2026-08-10T10:00:00Z',
        },
      ],
    });

    expect(summary.currentTier?.code, LoyaltyTierCode.gold);
    expect(summary.nextTier, isNull);
    expect(summary.progressToNextTier, 1);
    expect(summary.recentEntries.single.type, 'negative_adjustment');
    expect(summary.recentEntries.single.points, -5);
  });

  test('maps tier benefit quotas and admin-reviewed requests', () {
    final summary = loyaltySummaryFromRpc({
      'programEnabled': true,
      'currentTier': {
        'code': 'silver',
        'nameEn': 'Silver',
        'threshold': 100,
        'rewardEnabled': false,
        'benefits': [
          {
            'type': 'product_sourcing',
            'enabled': true,
            'monthlyLimit': 3,
            'maxPerRequest': 20,
            'usedThisMonth': 1,
            'remainingThisMonth': 2,
          },
          {
            'type': 'custom_photography',
            'enabled': true,
            'monthlyLimit': 2,
            'maxPerRequest': 6,
            'usedThisMonth': 2,
            'remainingThisMonth': 0,
          },
        ],
      },
      'recentBenefitRequests': [
        {
          'id': 'request-1',
          'requestNumber': 9,
          'tierCode': 'silver',
          'benefitType': 'custom_photography',
          'productId': 'product-1',
          'productName': 'Watch',
          'details': 'Three angles',
          'requestedQuantity': 3,
          'contentKind': 'video',
          'status': 'in_progress',
          'adminResponse': 'Studio booked',
          'createdAt': '2026-08-11T10:00:00Z',
          'updatedAt': '2026-08-11T11:00:00Z',
        },
      ],
    }, referenceImageUrlForPath: (path) => 'private://$path');

    expect(summary.currentTier?.benefits, hasLength(2));
    expect(summary.currentTier?.benefits.first.effectiveRemaining, 2);
    expect(summary.currentTier?.benefits.last.effectiveRemaining, 0);
    expect(
      summary.recentBenefitRequests.single.status,
      LoyaltyBenefitRequestStatus.inProgress,
    );
    expect(summary.recentBenefitRequests.single.adminResponse, 'Studio booked');
    expect(
      summary.recentBenefitRequests.single.contentKind,
      LoyaltyContentKind.video,
    );
    expect(summary.recentBenefitRequests.single.referenceImagePath, isNull);
  });

  test('maps a private reference image for product sourcing requests', () {
    final summary = loyaltySummaryFromRpc({
      'programEnabled': true,
      'recentBenefitRequests': [
        {
          'id': 'request-2',
          'requestNumber': 10,
          'tierCode': 'gold',
          'benefitType': 'product_sourcing',
          'itemName': 'Special watch',
          'requestedQuantity': 2,
          'referenceImagePath': 'sellers/user/request.webp',
          'status': 'pending',
          'createdAt': '2026-08-11T12:00:00Z',
          'updatedAt': '2026-08-11T12:00:00Z',
        },
      ],
    }, referenceImageUrlForPath: (path) => 'private://$path');

    final request = summary.recentBenefitRequests.single;
    expect(request.referenceImagePath, 'sellers/user/request.webp');
    expect(request.referenceImageUrl, 'private://sellers/user/request.webp');
    expect(request.contentKind, isNull);
  });

  test('maps Diamond stock entitlement and recent reservations', () {
    final summary = loyaltySummaryFromRpc(
      {
        'programEnabled': true,
        'totalPoints': 12000,
        'currentTier': {
          'code': 'diamond',
          'nameAr': 'ألماسي',
          'threshold': 10000,
          'rewardEnabled': false,
          'stockReservation': {
            'enabled': true,
            'maxActiveUnits': 12,
            'maxPerReservation': 4,
            'holdHours': 48,
            'activeUnits': 3,
            'remainingUnits': 9,
          },
        },
        'tiers': [
          {
            'code': 'diamond',
            'nameAr': 'ألماسي',
            'threshold': 10000,
            'rewardEnabled': false,
            'stockReservation': {
              'enabled': true,
              'maxActiveUnits': 12,
              'maxPerReservation': 4,
              'holdHours': 48,
              'activeUnits': 3,
              'remainingUnits': 9,
            },
          },
        ],
        'recentStockReservations': [
          {
            'id': 'reservation-1',
            'reservationNumber': '73',
            'variantId': 'variant-1',
            'productId': 'product-1',
            'productName': 'ساعة',
            'variantName': 'بنفسجي',
            'coverBucket': 'product-media',
            'coverPath': 'products/product-1/cover.webp',
            'quantity': 3,
            'consumedQuantity': 1,
            'releasedQuantity': 0,
            'remainingQuantity': 2,
            'status': 'active',
            'expiresAt': '2030-08-13T10:00:00Z',
            'createdAt': '2030-08-11T10:00:00Z',
          },
        ],
      },
      reservationImageUrlForObject: (bucket, path) => 'private://$bucket/$path',
    );

    expect(summary.currentTier?.code, LoyaltyTierCode.diamond);
    expect(summary.currentTier?.stockReservation?.enabled, isTrue);
    expect(summary.currentTier?.stockReservation?.maxActiveUnits, 12);
    expect(summary.tiers.single.stockReservation?.holdHours, 48);
    final reservation = summary.recentStockReservations.single;
    expect(reservation.reservationNumber, 73);
    expect(reservation.variantId, 'variant-1');
    expect(reservation.remainingQuantity, 2);
    expect(reservation.status, StockReservationStatus.active);
    expect(reservation.isActive, isTrue);
    expect(
      reservation.imageUrl,
      'private://product-media/products/product-1/cover.webp',
    );
  });

  test('ignores stock reservations with statuses outside the DB contract', () {
    final summary = loyaltySummaryFromRpc({
      'programEnabled': true,
      'recentStockReservations': [
        {
          'id': 'reservation-invalid',
          'reservationNumber': 74,
          'variantId': 'variant-1',
          'productId': 'product-1',
          'quantity': 1,
          'status': 'cancelled',
          'expiresAt': '2030-08-13T10:00:00Z',
          'createdAt': '2030-08-11T10:00:00Z',
        },
      ],
    });

    expect(summary.recentStockReservations, isEmpty);
  });
}
