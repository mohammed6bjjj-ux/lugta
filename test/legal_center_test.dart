import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/features/profile/legal/legal_document_screen.dart';
import 'package:flutter_app/features/profile/legal/legal_documents.dart';
import 'package:flutter_app/features/profile/policies_screen.dart';

void main() {
  setUp(() {
    AppColors.p = AppPalette.light;
    appSettings.language = AppLanguage.ar;
  });

  tearDown(() {
    appSettings.language = AppLanguage.ar;
    AppColors.p = AppPalette.light;
  });

  test('published legal bundle is complete and contains no draft material', () {
    expect(LegalDocuments.all, hasLength(7));
    expect(
      LegalDocuments.all.map((document) => document.id).toSet(),
      hasLength(7),
    );

    final publishedText = LegalDocuments.all
        .expand((document) => document.sections)
        .map((section) => '${section.title}\n${section.body}')
        .join('\n');

    expect(publishedText, contains('Nawl Ltd'));
    expect(publishedText, contains('لكطة (Lugta)'));
    expect(publishedText, contains('0773 882 2202'));
    expect(publishedText, contains('10,000'));
    expect(publishedText, contains('خمسة أيام'));
    expect(publishedText, isNot(contains('ملاحظات إدارية')));
    expect(publishedText, isNot(matches(RegExp(r'\[[^\]]+\]'))));
  });

  testWidgets('legal center opens a lazily rendered document', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(const PoliciesScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('legal_center_screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('legal_document_card_terms')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('legal_document_card_terms')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('legal_document_screen_terms')),
      findsOneWidget,
    );

    const laterSectionIndex = 5;
    final laterSectionKey = ValueKey(
      'legal_section_${LegalDocumentIds.terms}_$laterSectionIndex',
    );
    expect(find.byKey(laterSectionKey), findsNothing);

    final documentScroll = find.byKey(
      const ValueKey('legal_document_scroll_terms'),
    );
    for (
      var attempt = 0;
      attempt < 20 && find.byKey(laterSectionKey).evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(documentScroll, const Offset(0, -500));
      await tester.pump();
    }
    expect(find.byKey(laterSectionKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Arabic legal text stays RTL with English interface and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      appSettings.language = AppLanguage.en;

      await tester.pumpWidget(
        _testApp(
          LegalDocumentScreen(document: LegalDocuments.privacy),
          locale: const Locale('en'),
          textScale: 1.5,
        ),
      );
      await tester.pump();

      final privacyScroll = find.byKey(
        const ValueKey('legal_document_scroll_privacy'),
      );
      for (
        var attempt = 0;
        attempt < 4 &&
            find
                .byKey(const ValueKey('legal_section_body_privacy_0'))
                .evaluate()
                .isEmpty;
        attempt++
      ) {
        await tester.drag(privacyScroll, const Offset(0, -250));
        await tester.pump();
      }

      final firstBody = tester.widget<SelectableText>(
        find.byKey(const ValueKey('legal_section_body_privacy_0')),
      );
      expect(firstBody.textDirection, TextDirection.rtl);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _testApp(
  Widget home, {
  Locale locale = const Locale('ar'),
  double textScale = 1,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      );
    },
    home: home,
  );
}
