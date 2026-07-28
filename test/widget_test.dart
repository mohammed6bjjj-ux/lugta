import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/ckb_localizations.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_app/data/backend.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/auth/auth_strings.dart';
import 'package:flutter_app/features/auth/login_screen.dart';
import 'package:flutter_app/features/auth/onboarding_screen.dart';
import 'package:flutter_app/features/auth/splash_screen.dart';
import 'package:flutter_app/features/shell/main_shell.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('renders the Flutter splash before bootstrap completes', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bootstrap = Completer<void>();

    await tester.pumpWidget(SellerApp(bootstrap: () => bootstrap.future));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);

    bootstrap.complete();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('startup failure stays visible and offers retry', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var attempts = 0;

    await tester.pumpWidget(
      SellerApp(
        bootstrap: () async {
          attempts += 1;
          throw StateError('offline');
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('startup-retry')), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('startup-retry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(attempts, 2);
    expect(find.byKey(const Key('startup-retry')), findsOneWidget);
  });

  testWidgets('splash navigates to onboarding', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SellerApp());
    expect(find.byType(OnboardingScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text(AuthStrings.next), findsOneWidget);
  });

  testWidgets('login validates fields then opens the main shell', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // LoginScreen authenticates through appBackend; configure the UI session
    // with that same repository set so the protected destination is guarded
    // exactly like it is after production bootstrap.
    await session.configure(
      appBackend.repositories,
      deviceTokens: appBackend.deviceTokens,
      loadInitialData: false,
    );

    await tester.pumpWidget(_loginTestApp());
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));

    await tester.tap(find.text(AuthStrings.loginTitle));
    await tester.pump();

    expect(find.text(validateIraqiPhone('')!), findsOneWidget);
    expect(find.text(validateLoginPassword('')!), findsOneWidget);

    await tester.enterText(fields.at(0), '07712345678');
    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.text(AuthStrings.loginTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MainShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _loginTestApp() {
  AppColors.p = AppPalette.light;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
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
    home: const LoginScreen(),
  );
}
