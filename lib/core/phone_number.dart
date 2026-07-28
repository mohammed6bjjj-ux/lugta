import '../data/repositories/repositories.dart';

/// Converts an Iraqi local mobile number (`07xxxxxxxxx`) to E.164 (`+964...`).
/// Already-normalized numbers are accepted as well.
String normalizeIraqiPhone(String input) {
  final compact = input.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (RegExp(r'^07\d{9}$').hasMatch(compact)) {
    return '+964${compact.substring(1)}';
  }
  if (RegExp(r'^9647\d{9}$').hasMatch(compact)) return '+$compact';
  if (RegExp(r'^\+9647\d{9}$').hasMatch(compact)) return compact;
  throw const BackendException('رقم الهاتف العراقي غير صحيح.');
}
