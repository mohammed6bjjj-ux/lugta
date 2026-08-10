import 'models.dart';

LoyaltySummary loyaltySummaryFromRpc(Object? value) {
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
  );
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
    _ => null,
  };
}

String _fallbackTierName(LoyaltyTierCode code, String language) =>
    switch ((code, language)) {
      (LoyaltyTierCode.bronze, 'ckb') => 'برۆنز',
      (LoyaltyTierCode.silver, 'ckb') => 'زیو',
      (LoyaltyTierCode.gold, 'ckb') => 'زێڕ',
      (LoyaltyTierCode.bronze, 'en') => 'Bronze',
      (LoyaltyTierCode.silver, 'en') => 'Silver',
      (LoyaltyTierCode.gold, 'en') => 'Gold',
      (LoyaltyTierCode.bronze, _) => 'برونزي',
      (LoyaltyTierCode.silver, _) => 'فضي',
      (LoyaltyTierCode.gold, _) => 'ذهبي',
    };

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
