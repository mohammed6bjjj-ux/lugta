import 'models.dart';

PromotionGrant promotionGrantFromJson(
  Map<String, dynamic> row, {
  DateTime? now,
}) {
  final promotionRow = _mapOrEmpty(
    row['promotions'] ?? row['promotion'] ?? row['promotion_snapshot'],
  );
  final expiresAt = _dateOrNull(row['expires_at']);
  final consumedAt = _dateOrNull(row['consumed_at']);
  final status = _grantStatus(
    _text(row['status']),
    expiresAt: expiresAt,
    consumedAt: consumedAt,
    now: (now ?? DateTime.now()).toUtc(),
  );
  final promotionId = _text(
    row['promotion_id'],
    fallback: _text(promotionRow['id']),
  );

  return PromotionGrant(
    id: _text(row['id']),
    promotionId: promotionId,
    sellerId: _text(row['seller_id']),
    promotion: promotionRow.isEmpty
        ? null
        : promotionFromJson(promotionRow, fallbackId: promotionId),
    sourceProfileId: _nullableText(row['source_profile_id']),
    sourceOrderId: _nullableText(row['source_order_id']),
    sourceKey: _nullableText(row['source_key']),
    rewardOrdinal: _int(row['reward_ordinal'] ?? row['ordinal'], fallback: 1),
    rewardType: _text(
      row['reward_type'] ?? row['reward_type_snapshot'],
      fallback: _text(promotionRow['reward_type']),
    ),
    rewardValue: _int(
      row['reward_value'] ?? row['reward_value_snapshot'],
      fallback: _int(promotionRow['reward_value']),
    ),
    status: status,
    expiresAt: expiresAt,
    consumedAt: consumedAt,
    consumedOrderId: _nullableText(row['consumed_order_id']),
    walletEntryId: _nullableText(row['wallet_entry_id']),
    createdAt:
        _dateOrNull(row['created_at'] ?? row['granted_at']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}

Promotion promotionFromJson(
  Map<String, dynamic> row, {
  String fallbackId = '',
}) => Promotion(
  id: _text(row['id'], fallback: fallbackId),
  nameAr: _text(
    row['name_ar'],
    fallback: _text(row['title_ar'], fallback: 'عرض'),
  ),
  nameCkb: _nullableText(row['name_ckb'] ?? row['title_ckb']),
  nameEn: _nullableText(row['name_en'] ?? row['title_en']),
  descriptionAr: _text(row['description_ar'], fallback: _text(row['body_ar'])),
  descriptionCkb: _nullableText(row['description_ckb'] ?? row['body_ckb']),
  descriptionEn: _nullableText(row['description_en'] ?? row['body_en']),
  audienceType: _text(row['audience_type']),
  newAccountDays: _intOrNull(row['new_account_days']),
  triggerType: _text(row['trigger_type']),
  triggerThreshold: _intOrNull(row['trigger_threshold']),
  beneficiary: _text(row['beneficiary']),
  rewardType: _text(row['reward_type']),
  rewardValue: _int(row['reward_value']),
  rewardValidDays: _intOrNull(row['reward_valid_days']),
  startsAt: _dateOrNull(row['starts_at']),
  endsAt: _dateOrNull(row['ends_at']),
  isActive: _bool(row['is_active'], fallback: true),
  priority: _int(row['priority']),
  showPopup: _bool(row['show_popup']),
  showInbox: _bool(row['show_inbox']),
  sendPush: _bool(row['send_push']),
);

ReferralSummary referralSummaryFromRpc(Object? value) {
  final row = switch (value) {
    Map<dynamic, dynamic> map => Map<String, dynamic>.from(map),
    List<dynamic> list when list.isNotEmpty && list.first is Map =>
      Map<String, dynamic>.from(list.first as Map),
    _ => const <String, dynamic>{},
  };
  return ReferralSummary(
    referralCode: _text(row['referral_code']),
    referredBy: _nullableText(row['referred_by']),
    referredByName: _nullableText(
      row['referred_by_name'] ?? row['referrer_store_name'],
    ),
    invitedCount: _nonNegativeInt(
      row['invited_count'] ?? row['referred_accounts'],
    ),
    qualifiedCount: _nonNegativeInt(
      row['qualified_count'] ?? row['qualified_referrals'],
    ),
    rewardedCount: _nonNegativeInt(row['rewarded_count']),
    completedReferredOrders: _nonNegativeInt(row['completed_referred_orders']),
    availableFreeDeliveries: _nonNegativeInt(row['available_free_deliveries']),
    walletRewardsEarned: _nonNegativeInt(row['wallet_rewards_earned']),
  );
}

PromotionGrantStatus _grantStatus(
  String raw, {
  required DateTime? expiresAt,
  required DateTime? consumedAt,
  required DateTime now,
}) {
  if (consumedAt != null || const {'used', 'consumed'}.contains(raw)) {
    return PromotionGrantStatus.used;
  }
  if (expiresAt != null && !expiresAt.toUtc().isAfter(now)) {
    return PromotionGrantStatus.expired;
  }
  if (const {'expired', 'revoked', 'cancelled', 'canceled'}.contains(raw)) {
    return PromotionGrantStatus.expired;
  }
  return PromotionGrantStatus.available;
}

Map<String, dynamic> _mapOrEmpty(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _intOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

int _nonNegativeInt(Object? value) {
  final parsed = _int(value);
  return parsed < 0 ? 0 : parsed;
}

bool _bool(Object? value, {bool fallback = false}) => switch (value) {
  bool boolean => boolean,
  num number => number != 0,
  String text when text.toLowerCase() == 'true' || text == '1' => true,
  String text when text.toLowerCase() == 'false' || text == '0' => false,
  _ => fallback,
};

DateTime? _dateOrNull(Object? value) {
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc();
}
