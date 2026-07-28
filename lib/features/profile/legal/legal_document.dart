import 'package:flutter/foundation.dart';

/// نص قصير مترجم يُستخدم في فهرس المركز القانوني.
@immutable
class LegalLocalizedText {
  const LegalLocalizedText({
    required this.ar,
    required this.ku,
    required this.en,
  });

  final String ar;
  final String ku;
  final String en;

  String resolve(String languageCode) {
    return switch (languageCode.toLowerCase()) {
      'en' => en,
      'ku' || 'ckb' => ku,
      _ => ar,
    };
  }
}

/// قسم واحد داخل وثيقة قانونية.
@immutable
class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}

/// وثيقة قابلة للعرض داخل المركز القانوني.
@immutable
class LegalDocument {
  const LegalDocument({
    required this.id,
    required this.title,
    required this.summary,
    required this.sections,
  });

  /// معرّف ثابت يصلح للروابط ومفاتيح الاختبار.
  final String id;
  final LegalLocalizedText title;
  final LegalLocalizedText summary;

  /// متن الوثائق قانوني عربي معتمد، حتى عندما تكون لغة الواجهة مختلفة.
  final List<LegalSection> sections;
}
