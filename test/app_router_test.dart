import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/ckb_localizations.dart';
import 'package:flutter_app/app/routes.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/l10n/core_strings.dart';

void main() {
  setUp(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
  });

  final invalidRoutes = <String, Object?>{
    Routes.categoryProducts: null,
    Routes.productDetail: 'not a product',
    Routes.orderWizard: null,
    Routes.orderSuccess: Object(),
    Routes.orderDetail: null,
    Routes.otp: const {'phone': 123, 'purpose': 'register'},
    Routes.accountBlocked: const {'isRejected': 'no', 'reason': 5},
    Routes.mediaViewer: const {'media': [], 'initialIndex': 0},
  };

  for (final entry in invalidRoutes.entries) {
    testWidgets('${entry.key} rejects malformed arguments safely', (
      tester,
    ) async {
      await tester.pumpWidget(_routerTestApp(entry.key, entry.value));

      await tester.tap(find.byKey(const ValueKey('open_route')));
      await tester.pumpAndSettle();

      expect(find.text(CoreStrings.unknownRouteTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _routerTestApp(String routeName, Object? arguments) {
  AppColors.p = AppPalette.light;
  return MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('ckb'), Locale('en')],
    localizationsDelegates: const [
      CkbMaterialLocalizationsDelegate(),
      CkbWidgetsLocalizationsDelegate(),
      CkbCupertinoLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    onGenerateRoute: AppRouter.onGenerateRoute,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const ValueKey('open_route'),
            onPressed: () =>
                Navigator.pushNamed(context, routeName, arguments: arguments),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}
