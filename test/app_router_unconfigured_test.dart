import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/routes.dart';
import 'package:flutter_app/app/theme.dart';

void main() {
  testWidgets(
    'protected initial route stays neutral before session bootstrap',
    (tester) async {
      AppColors.p = AppPalette.light;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const SizedBox.shrink(),
          initialRoute: Routes.withdrawRequest,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('session_initializing_gate')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('withdrawal_amount_field')),
        findsNothing,
      );
    },
  );

  testWidgets('legal center remains public before session bootstrap', (
    tester,
  ) async {
    AppColors.p = AppPalette.light;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const SizedBox.shrink(),
        initialRoute: Routes.policies,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('legal_center_screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('session_initializing_gate')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
