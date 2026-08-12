import 'models.dart';

LoyaltySummary loyaltySummaryFromRpc(
  Object? value, {
  String Function(String path)? referenceImageUrlForPath,
  String Function(String bucket, String path)? reservationImageUrlForObject,
}) {
  final row = _singleMap(value);
  final tiers =
      _list(row['tiers'])
          .map(_tierFromJson)
          .whereType<LoyaltyTierDefinition>()
          .toList(growable: false)
        ..sort((a, b) => a.threshold.compareTo(b.threshold));
  final currentTier = _tierFromJson(_mapOrNull(row['currentTier']));
  final nextTier = _nextTierFromJson(
    _mapOrNull(row['nextTier']),
    fallbackPointsNeeded: row['pointsToNextTier'],
  );
  final recentEntries =
      _list(row['recentEntries'] ?? row['entries'])
          .map(_entryFromJson)
          .whereType<LoyaltyPointEntry>()
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final benefitRequests =
      _list(row['recentBenefitRequests'])
          .map(
            (value) => _benefitRequestFromJson(
              value,
              referenceImageUrlForPath: referenceImageUrlForPath,
            ),
          )
          .whereType<LoyaltyBenefitRequest>()
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final stockReservations =
      _list(row['recentStockReservations'] ?? row['recent_stock_reservations'])
          .map(
            (value) => _stockReservationFromJson(
              value,
              imageUrlForObject: reservationImageUrlForObject,
            ),
          )
          .whereType<StockReservation>()
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return LoyaltySummary(
    programEnabled: _bool(row['programEnabled']),
    pointsPerSoldUnit: _nonNegativeInt(row['pointsPerSoldUnit']),
    totalPoints: _nonNegativeInt(row['totalPoints']),
    completedUnits: _nonNegativeInt(row['completedUnits']),
    currentTier: currentTier,
    nextTier: nextTier,
    pointsToNextTier: _nullableNonNegativeInt(
      row['pointsToNextTier'] ?? nextTier?.pointsNeeded,
    ),
    tiers: List<LoyaltyTierDefinition>.unmodifiable(tiers),
    recentEntries: List<LoyaltyPointEntry>.unmodifiable(recentEntries),
    recentBenefitRequests: List<LoyaltyBenefitRequest>.unmodifiable(
      benefitRequests,
    ),
    recentStockReservations: List<StockReservation>.unmodifiable(
      stockReservations,
    ),
  );
}

StockReservation stockReservationFromRpc(
  Object? value, {
  String Function(String bucket, String path)? imageUrlForObject,
}) {
  final response = _singleMap(value);
  final reservation = _stockReservationFromJson(
    response['reservation'] ?? response['stockReservation'] ?? response,
    imageUrlForObject: imageUrlForObject,
  );
  if (reservation == null) {
    throw const FormatException('Invalid stock reservation response.');
  }
  return reservation;
}

LoyaltyTierDefinition? _tierFromJson(Object? value) {
  final row = _mapOrNull(value);
  if (row == null) return null;
  final code = _tierCode(row['code']);
  if (code == null) return null;
  return LoyaltyTierDefinition(
    code: code,
    nameAr: _text(row['nameAr'], fallback: _fallbackTierName(code, 'ar')),
    nameCkb: _text(row['nameCkb'], fallback: _fallbackTierName(code, 'ckb')),
    nameEn: _text(row['nameEn'], fallback: _fallbackTierName(code, 'en')),
    threshold: _nonNegativeInt(row['threshold']),
    rewardEnabled: _bool(row['rewardEnabled']),
    rewardType: _text(row['rewardType']),
    rewardValue: _nonNegativeInt(row['rewardValue']),
    rewardValidDays: _nullableNonNegativeInt(row['rewardValidDays']),
    benefits: List<LoyaltyTierBenefit>.unmodifiable(
      _list(
        row['benefits'],
      ).map(_benefitFromJson).whereType<LoyaltyTierBenefit>(),
    ),
    stockReservation: _stockReservationEntitlementFromJson(
      row['stockReservation'] ?? row['stock_reservation'],
    ),
  );
}

StockReservationEntitlement? _stockReservationEntitlementFromJson(
  Object? value,
) {
  final row = _mapOrNull(value);
  if (row == null) return null;
  return StockReservationEntitlement(
    enabled: _bool(row['enabled']),
    maxActiveUnits: _nonNegativeInt(
      row['maxActiveUnits'] ?? row['max_active_units'],
    ),
    maxPerReservation: _nonNegativeInt(
      row['maxPerReservation'] ?? row['max_per_reservation'],
    ),
    holdHours: _nonNegativeInt(row['holdHours'] ?? row['hold_hours']),
    activeUnits: _nonNegativeInt(row['activeUnits'] ?? row['active_units']),
    remainingUnits: _nonNegativeInt(
      row['remainingUnits'] ?? row['remaining_units'],
    ),
  );
}

StockReservation? _stockReservationFromJson(
  Object? value, {
  String Function(String bucket, String path)? imageUrlForObject,
}) {
  final row = _mapOrNull(value);
  if (row == null) return null;
  final id = _text(row['id']);
  final variantId = _text(row['variantId'] ?? row['variant_id']);
  final productId = _text(row['productId'] ?? row['product_id']);
  final createdAt = _date(row['createdAt'] ?? row['created_at']);
  final expiresAt = _date(row['expiresAt'] ?? row['expires_at']);
  final status = _stockReservationStatus(row['status']);
  if (id.isEmpty ||
      variantId.isEmpty ||
      productId.isEmpty ||
      createdAt == null ||
      expiresAt == null ||
      status == null) {
    return null;
  }

  final explicitImageUrl = _text(row['imageUrl'] ?? row['image_url']);
  final coverBucket = _text(row['coverBucket'] ?? row['cover_bucket']);
  final coverPath = _text(row['coverPath'] ?? row['cover_path']);
  final resolvedImageUrl = explicitImageUrl.isNotEmpty
      ? explicitImageUrl
      : coverBucket.isNotEmpty && coverPath.isNotEmpty
      ? imageUrlForObject?.call(coverBucket, coverPath) ?? ''
      : '';

  final quantity = _nonNegativeInt(row['quantity']);
  final consumedQuantity = _nonNegativeInt(
    row['consumedQuantity'] ?? row['consumed_quantity'],
  );
  final releasedQuantity = _nonNegativeInt(
    row['releasedQuantity'] ?? row['released_quantity'],
  );
  final fallbackRemaining = (quantity - consumedQuantity - releasedQuantity)
      .clamp(0, quantity)
      .toInt();

  return StockReservation(
    id: id,
    reservationNumber: _nonNegativeInt(
      row['reservationNumber'] ?? row['reservation_number'],
    ),
    variantId: variantId,
    productId: productId,
    productName: _text(row['productName'] ?? row['product_name']),
    variantName: _text(row['variantName'] ?? row['variant_name']),
    imageUrl: resolvedImageUrl,
    quantity: quantity,
    consumedQuantity: consumedQuantity,
    releasedQuantity: releasedQuantity,
    remainingQuantity:
        row['remainingQuantity'] == null && row['remaining_quantity'] == null
        ? fallbackRemaining
        : _nonNegativeInt(
            row['remainingQuantity'] ?? row['remaining_quantity'],
          ).clamp(0, quantity).toInt(),
    status: status,
    expiresAt: expiresAt,
    createdAt: createdAt,
  );
}

StockReservationStatus? _stockReservationStatus(Object? value) =>
    switch (_text(value).toLowerCase()) {
      'active' => StockReservationStatus.active,
      'consumed' => StockReservationStatus.consumed,
      'released' => StockReservationStatus.released,
      'expired' => StockReservationStatus.expired,
      _ => null,
    };

LoyaltyTierBenefit? _benefitFromJson(Object? value) {
  final row = _mapOrNull(value);
  if (row == null) return null;
  final type = switch (_text(row['type'])) {
    'product_sourcing' => LoyaltyBenefitType.productSourcing,
    'custom_photography' => LoyaltyBenefitType.customPhotography,
    _ => null,
  };
  if (type == null) return null;
  final monthlyLimit = _nonNegativeInt(row['monthlyLimit']);
  return LoyaltyTierBenefit(
    type: type,
    enabled: _bool(row['enabled']),
    monthlyLimit: monthlyLimit,
    maxPerRequest: _nonNegativeInt(row['maxPerRequest']),
    usedThisMonth: _nonNegativeInt(row['usedThisMonth']),
    remainingThisMonth: row['remainingThisMonth'] == null
        ? null
        : _nonNegativeInt(row['remainingThisMonth']),
  );
}

LoyaltyBenefitRequest? _benefitRequestFromJson(
  Object? value, {
  String Function(String path)? referenceImageUrlForPath,
}) {
  final row = _mapOrNull(value);
  if (row == null) return null;
  final id = _text(row['id']);
  final createdAt = _date(row['createdAt']);
  final updatedAt = _date(row['updatedAt']) ?? createdAt;
  final tierCode = _tierCode(row['tierCode']);
  final benefitType = switch (_text(row['benefitType'])) {
    'product_sourcing' => LoyaltyBenefitType.productSourcing,
    'custom_photography' => LoyaltyBenefitType.customPhotography,
    _ => null,
  };
  final status = switch (_text(row['status'])) {
    'pending' => LoyaltyBenefitRequestStatus.pending,
    'approved' => LoyaltyBenefitRequestStatus.approved,
    'in_progress' => LoyaltyBenefitRequestStatus.inProgress,
    'completed' => LoyaltyBenefitRequestStatus.completed,
    'rejected' => LoyaltyBenefitRequestStatus.rejected,
    'cancelled' => LoyaltyBenefitRequestStatus.cancelled,
    _ => null,
  };
  final referenceImagePath = _nullableText(row['referenceImagePath']);
  final contentKind = switch (_nullableText(row['contentKind'])) {
    'photo' => LoyaltyContentKind.photo,
    'video' => LoyaltyContentKind.video,
    _ => null,
  };
  if (id.isEmpty ||
      createdAt == null ||
      updatedAt == null ||
      tierCode == null ||
      benefitType == null ||
      status == null) {
    return null;
  }
  return LoyaltyBenefitRequest(
    id: id,
    requestNumber: _nonNegativeInt(row['requestNumber']),
    tierCode: tierCode,
    benefitType: benefitType,
    productId: _nullableText(row['productId']),
    productName: _nullableText(row['productName']),
    itemName: _nullableText(row['itemName']),
    referenceImagePath: referenceImagePath,
    referenceImageUrl: referenceImagePath == null
        ? null
        : referenceImageUrlForPath?.call(referenceImagePath),
    contentKind: contentKind,
    details: _text(row['details']),
    requestedQuantity: _nonNegativeInt(row['requestedQuantity']),
    status: status,
    adminResponse: _nullableText(row['adminResponse']),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

LoyaltyNextTier? _nextTierFromJson(
  Object? value, {
  Object? fallbackPointsNeeded,
}) {
  final row = _mapOrNull(value);
  if (row == null) return null;
  final code = _tierCode(row['code']);
  if (code == null) return null;
  return LoyaltyNextTier(
    code: code,
    nameAr: _text(row['nameAr'], fallback: _fallbackTierName(code, 'ar')),
    nameCkb: _text(row['nameCkb'], fallback: _fallbackTierName(code, 'ckb')),
    nameEn: _text(row['nameEn'], fallback: _fallbackTierName(code, 'en')),
    threshold: _nonNegativeInt(row['threshold']),
    pointsNeeded: _nonNegativeInt(row['pointsNeeded'] ?? fallbackPointsNeeded),
  );
}

LoyaltyPointEntry? _entryFromJson(Object? value) {
  final row = _mapOrNull(value);
  if (row == null) return null;
  final id = _text(row['id']);
  final createdAt = _date(row['createdAt']);
  if (id.isEmpty || createdAt == null) return null;
  return LoyaltyPointEntry(
    id: id,
    type: _text(row['type']),
    points: _int(row['points']),
    orderId: _nullableText(row['orderId']),
    orderNumber: _nullableText(row['orderNumber']),
    soldUnits: _nonNegativeInt(row['soldUnits']),
    description: _text(row['description']),
    createdAt: createdAt,
  );
}

LoyaltyTierCode? _tierCode(Object? value) {
  final normalized = _text(value).toLowerCase().replaceFirst('loyalty_', '');
  return switch (normalized) {
    'bronze' => LoyaltyTierCode.bronze,
    'silver' => LoyaltyTierCode.silver,
    'gold' => LoyaltyTierCode.gold,
    'diamond' => LoyaltyTierCode.diamond,
    _ => null,
  };
}

String _fallbackTierName(LoyaltyTierCode code, String language) {
  if (language == 'ckb') {
    return switch (code) {
      LoyaltyTierCode.bronze => 'برۆنز',
      LoyaltyTierCode.silver => 'زیو',
      LoyaltyTierCode.gold => 'زێڕ',
      LoyaltyTierCode.diamond => 'ئەڵماس',
    };
  }
  if (language == 'en') {
    return switch (code) {
      LoyaltyTierCode.bronze => 'Bronze',
      LoyaltyTierCode.silver => 'Silver',
      LoyaltyTierCode.gold => 'Gold',
      LoyaltyTierCode.diamond => 'Diamond',
    };
  }
  return switch (code) {
    LoyaltyTierCode.bronze => 'برونزي',
    LoyaltyTierCode.silver => 'فضي',
    LoyaltyTierCode.gold => 'ذهبي',
    LoyaltyTierCode.diamond => 'ألماسي',
  };
}

Map<String, dynamic> _singleMap(Object? value) {
  if (value is List) {
    if (value.isEmpty) return <String, dynamic>{};
    return _mapOrNull(value.first) ?? <String, dynamic>{};
  }
  return _mapOrNull(value) ?? <String, dynamic>{};
}

Map<String, dynamic>? _mapOrNull(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

List<Object?> _list(Object? value) =>
    value is List ? List<Object?>.from(value) : const <Object?>[];

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(Object? value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

int _int(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String text => int.tryParse(text) ?? 0,
  _ => 0,
};

int _nonNegativeInt(Object? value) =>
    _int(value).clamp(0, 0x7fffffffffffffff).toInt();

int? _nullableNonNegativeInt(Object? value) =>
    value == null ? null : _nonNegativeInt(value);

bool _bool(Object? value) => value == true || value == 1 || value == 'true';

DateTime? _date(Object? value) => value is DateTime
    ? value.toLocal()
    : DateTime.tryParse(value?.toString() ?? '')?.toLocal();
