import 'app_settings.dart';

class PolicyContentBundle {
  const PolicyContentBundle({
    required this.combinedText,
    required this.termsVersion,
  });

  final String combinedText;
  final String termsVersion;
}

typedef ContentTarget = ({String? productId, String? categoryId});

ContentTarget parseContentTarget(Map<String, dynamic> payload) {
  String? value(String key) {
    final text = payload[key]?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  final type = value('target_type');
  final id = value('target_id');
  return (
    productId: type == 'product' ? id : value('product_id'),
    categoryId: type == 'category' ? id : value('category_id'),
  );
}

/// Combines every active policy for display, while deriving the acceptance
/// version exclusively from the canonical `terms` entry.
PolicyContentBundle parsePolicyContent(
  Iterable<Map<String, dynamic>> rows, {
  required AppLanguage language,
  String fallbackTermsVersion = '',
}) {
  final sections = <String>[];
  var termsVersion = fallbackTermsVersion;
  for (final row in rows) {
    if (row['kind']?.toString() != 'policy') continue;
    final title = _localized(row, 'title', language);
    final body = _localized(row, 'body', language);
    if (title.isNotEmpty && body.isNotEmpty) {
      sections.add('$title\n\n$body');
    } else if (body.isNotEmpty) {
      sections.add(body);
    }
    if (row['key']?.toString() == 'terms') {
      final version = row['version']?.toString().trim() ?? '';
      if (version.isNotEmpty) termsVersion = version;
    }
  }
  return PolicyContentBundle(
    combinedText: sections.join('\n\n──────────\n\n'),
    termsVersion: termsVersion,
  );
}

String _localized(
  Map<String, dynamic> row,
  String prefix,
  AppLanguage language,
) {
  final preferred = row['${prefix}_${language.name}']?.toString().trim() ?? '';
  if (preferred.isNotEmpty) return preferred;
  return row['${prefix}_ar']?.toString().trim() ?? '';
}
