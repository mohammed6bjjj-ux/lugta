import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_app/core/widgets/pressable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exposes button semantics and a 48px tap target', (tester) async {
    var taps = 0;
    const targetKey = ValueKey('favorite-target');
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Pressable(
              key: targetKey,
              onTap: () => taps++,
              minimumSize: const Size.square(48),
              semanticLabel: 'Add to favorites',
              semanticToggled: false,
              child: const SizedBox(width: 30, height: 30),
            ),
          ),
        ),
      ),
    );

    final target = find.descendant(
      of: find.byKey(targetKey),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Add to favorites',
      ),
    );
    expect(tester.getSize(target), const Size(48, 48));
    final node = tester.getSemantics(find.bySemanticsLabel('Add to favorites'));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isToggled, Tristate.isFalse);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(find.byKey(targetKey));
    expect(taps, 1);
    semantics.dispose();
  });
}
