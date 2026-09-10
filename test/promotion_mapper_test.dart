import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/promotion_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'configurable rewards preserve fractional rate and separate money, points and delivery',
    () {
      final summary = referralSummaryFromRpc({
        'referral_kind': 'profit_percent',
        'referral_value': '2.5',
        'referral_enabled': true,
        'referral_pending_cash': 250,
        'referral_pending_points': 15,
        'referral_pending_delivery': 2500,
        'referral_released_points': 20,
        'referral_released_delivery': 5000,
      });
      expect(summary.rewardValue, 2.5);
      expect(summary.referralEnabled, isTrue);
      expect(summary.pendingCash, 250);
      expect(summary.pendingPoints, 15);
      expect(summary.pendingDelivery, 2500);
      expect(summary.releasedPoints, 20);
      expect(summary.releasedDelivery, 5000);
      expect(referralSummaryFromRpc({}).rewardKind, isNull);
      expect(referralSummaryFromRpc({}).pendingCash, 0);
    },
  );
  test(
    'signup gift distinguishes a live offer from previously earned credit',
    () {
      final active = referralSummaryFromRpc({
        'signup_delivery_active': true,
        'signup_delivery_earned': false,
      });
      expect(active.signupDeliveryActive, isTrue);
      expect(active.signupDeliveryEarned, isFalse);
      final paused = referralSummaryFromRpc([
        {'signup_delivery_active': false, 'signup_delivery_earned': true},
      ]);
      expect(paused.signupDeliveryActive, isFalse);
      expect(paused.signupDeliveryEarned, isTrue);
      for (final legacy in [null, <String, dynamic>{}, []]) {
        expect(referralSummaryFromRpc(legacy).signupDeliveryActive, isFalse);
        expect(referralSummaryFromRpc(legacy).signupDeliveryEarned, isFalse);
      }
      expect(const ReferralSummary.empty().signupDeliveryEarned, isFalse);
    },
  );
  test(
    'maps profit-share rate separately from earned dinars and defaults safely',
    () {
      final summary = referralSummaryFromRpc({
        'referral_code': 'LUGTA123',
        'profit_share_active': true,
        'profit_share_percent': '1',
        'profit_share_earned': '1123',
        'profit_share_orders': 2,
      });
      expect(summary.profitShareActive, isTrue);
      expect(summary.profitSharePercent, 1);
      expect(summary.profitShareEarned, 1123);
      expect(summary.profitShareOrders, 2);
      expect(referralSummaryFromRpc({}).profitShareActive, isFalse);
      expect(referralSummaryFromRpc({}).profitShareEarned, 0);
    },
  );
  test('maps current promotion grant snapshot columns', () {
    final grant = promotionGrantFromJson({
      'id': 'grant-1',
      'promotion_id': 'promotion-1',
      'seller_id': 'seller-1',
      'ordinal': '2',
      'reward_type_snapshot': 'free_delivery',
      'reward_value_snapshot': '1',
      'status': 'available',
      'granted_at': '2026-08-01T09:30:00Z',
      'expires_at': '2026-08-20T00:00:00Z',
      'promotions': {
        'id': 'promotion-1',
        'name_ar': 'هدية الإحالة',
        'description_ar': 'توصيل مجاني',
        'audience_type': 'all',
        'trigger_type': 'referral',
        'beneficiary': 'referrer',
        'reward_type': 'free_delivery',
        'reward_value': 1,
        'is_active': true,
      },
    }, now: DateTime.utc(2026, 8, 6));

    expect(grant.rewardOrdinal, 2);
    expect(grant.rewardType, 'free_delivery');
    expect(grant.rewardValue, 1);
    expect(grant.status, PromotionGrantStatus.available);
    expect(grant.createdAt, DateTime.utc(2026, 8, 1, 9, 30));
    expect(grant.promotion?.nameAr, 'هدية الإحالة');
  });

  test('derives used and expired status from durable timestamps', () {
    final used = promotionGrantFromJson({
      'id': 'used',
      'promotion_id': 'p',
      'seller_id': 's',
      'consumed_at': '2026-08-01T00:00:00Z',
    }, now: DateTime.utc(2026, 8, 6));
    final expired = promotionGrantFromJson({
      'id': 'expired',
      'promotion_id': 'p',
      'seller_id': 's',
      'expires_at': '2026-08-05T00:00:00Z',
    }, now: DateTime.utc(2026, 8, 6));

    expect(used.status, PromotionGrantStatus.used);
    expect(expired.status, PromotionGrantStatus.expired);
  });

  test('referral summary accepts transitional keys and numeric strings', () {
    final summary = referralSummaryFromRpc([
      {
        'referral_code': 'LUGTA-22',
        'referred_by': 'seller-parent',
        'referrer_store_name': 'Store One',
        'referred_accounts': '12',
        'qualified_referrals': 7.0,
        'rewarded_count': null,
        'completed_referred_orders': '9',
        'available_free_deliveries': 2,
        'wallet_rewards_earned': '17500',
      },
    ]);

    expect(summary.referralCode, 'LUGTA-22');
    expect(summary.referredByName, 'Store One');
    expect(summary.invitedCount, 12);
    expect(summary.qualifiedCount, 7);
    expect(summary.rewardedCount, 0);
    expect(summary.completedReferredOrders, 9);
    expect(summary.availableFreeDeliveries, 2);
    expect(summary.walletRewardsEarned, 17500);
  });
}
