import 'package:url_launcher/url_launcher.dart';

Future<bool> launchPhoneNumber(String phone) {
  final normalized = phone.replaceAll(RegExp(r'[^+0-9]'), '');
  if (normalized.isEmpty) return Future.value(false);
  return launchUrl(Uri(scheme: 'tel', path: normalized));
}

Future<bool> launchWhatsApp(String phone, {String? message}) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = '964${digits.substring(1)}';
  if (digits.isEmpty) return Future.value(false);
  final uri = Uri.https(
    'wa.me',
    '/$digits',
    message == null || message.trim().isEmpty ? null : {'text': message.trim()},
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> launchInstagramProfile(String value) {
  final target = instagramProfileUri(value);
  if (target == null) return Future.value(false);
  return launchUrl(target, mode: LaunchMode.externalApplication);
}

/// Returns one canonical Instagram profile URL or null for malformed input.
String? normalizeInstagramProfile(String value) {
  final handle = instagramProfileHandle(value);
  return handle == null
      ? null
      : Uri.https('instagram.com', '/$handle').toString();
}

/// Extracts and validates a single Instagram username.
String? instagramProfileHandle(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  var candidate = trimmed;
  var parsed = Uri.tryParse(trimmed);
  final startsWithInstagramHost = RegExp(
    r'^(?:www\.|m\.)?instagram\.com(?:/|$)',
    caseSensitive: false,
  ).hasMatch(trimmed);
  if ((parsed == null || !parsed.hasScheme) && startsWithInstagramHost) {
    parsed = Uri.tryParse('https://$trimmed');
  }
  if (parsed != null && parsed.hasScheme) {
    final scheme = parsed.scheme.toLowerCase();
    final host = parsed.host.toLowerCase();
    final isInstagramHost =
        host == 'instagram.com' ||
        host == 'www.instagram.com' ||
        host == 'm.instagram.com';
    if ((scheme != 'https' && scheme != 'http') || !isInstagramHost) {
      return null;
    }
    final segments = parsed.pathSegments
        .where((part) => part.isNotEmpty)
        .toList();
    if (segments.length != 1) return null;
    candidate = segments.single;
  } else {
    if (candidate.contains(RegExp(r'[/?#]'))) return null;
  }

  final handle = candidate.replaceFirst(RegExp(r'^@'), '').trim();
  if (!RegExp(
    r'^(?!\.)(?!.*\.\.)(?!.*\.$)[A-Za-z0-9._]{1,30}$',
  ).hasMatch(handle)) {
    return null;
  }
  return handle;
}

/// Builds a safe Instagram URL and rejects unrelated or executable schemes.
Uri? instagramProfileUri(String value) {
  final normalized = normalizeInstagramProfile(value);
  return normalized == null ? null : Uri.parse(normalized);
}
