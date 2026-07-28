import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import 'wallet_strings.dart';

String? validatePayoutAccountIdentifier({
  required String provider,
  required String value,
}) {
  final normalized = value.trim();
  if (provider == 'zain_cash') return validateIraqiPhone(normalized);

  final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return provider == 'superqi'
        ? WalletStrings.superQiNumberRequired
        : WalletStrings.cardNumberRequired;
  }
  if (provider == 'mastercard' && digits.length != 16) {
    return WalletStrings.cardNumberInvalid;
  }
  return null;
}

List<TextInputFormatter> payoutAccountInputFormatters(String provider) => [
  FilteringTextInputFormatter.digitsOnly,
  if (provider == 'zain_cash') LengthLimitingTextInputFormatter(11),
  if (provider == 'superqi') LengthLimitingTextInputFormatter(128),
  if (provider == 'mastercard') LengthLimitingTextInputFormatter(16),
];
