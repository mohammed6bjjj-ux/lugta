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
}
