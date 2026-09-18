import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/features/assistant/assistant_screen.dart';
import 'package:flutter_app/features/assistant/assistant_strings.dart';
import 'package:flutter_app/features/profile/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in AppLanguage.values) {
    testWidgets('My account opens assistant directly: ${language.name}', (
      tester,
    ) async {
      final originalLanguage = appSettings.language;
      addTearDown(() => appSettings.language = originalLanguage);
      appSettings.language = language;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? openedRoute;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => Directionality(
            textDirection: language == AppLanguage.en
                ? TextDirection.ltr
                : TextDirection.rtl,
            child: child!,
          ),
          home: const ProfileScreen(),
          onGenerateRoute: (settings) {
            openedRoute = settings.name;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const AssistantScreen(),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      final entry = find.byKey(const ValueKey('profile_assistant_item'));
      await tester.scrollUntilVisible(entry, 250);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: entry, matching: find.text(AssistantStrings.title)),
        findsOneWidget,
      );
      expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
      final store = find.byKey(const ValueKey('profile_my_store_item'));
      expect(
        tester.getTopLeft(entry).dy,
        lessThan(tester.getTopLeft(store).dy),
      );
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(openedRoute, Routes.assistant);
      expect(find.byType(AssistantScreen), findsOneWidget);
      await tester.scrollUntilVisible(find.text(AssistantStrings.start), 200);
      await tester.pumpAndSettle();
      expect(find.text(AssistantStrings.start), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
