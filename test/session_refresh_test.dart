import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/widgets/session_refresh.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/l10n/core_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => session.lastError = null);

  testWidgets('refresh button ignores repeated taps while loading', (
    WidgetTester tester,
  ) async {
    final completer = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              SessionRefreshButton(
                onRefresh: () {
                  calls += 1;
                  return completer.future;
                },
              ),
            ],
          ),
        ),
      ),
    );

    final button = find.byKey(const ValueKey('session_refresh_button'));
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();

    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });

  testWidgets('refresh errors are shown and loading always clears', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              SessionRefreshButton(
                onRefresh: () => Future<void>.error(StateError('offline')),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('session_refresh_button')));
    await tester.pumpAndSettle();

    expect(find.text(CoreStrings.refreshFailed), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });
}
