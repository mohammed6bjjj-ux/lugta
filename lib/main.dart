import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_bootstrap.dart';
import 'app/app_lifecycle_reconciler.dart';
import 'app/app_router.dart';
import 'app/ckb_localizations.dart';
import 'app/theme.dart';
import 'data/app_settings.dart';
import 'features/auth/splash_screen.dart';
import 'l10n/core_strings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SellerApp(bootstrap: appBootstrap.initialize));
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key, this.bootstrap});

  final Future<void> Function()? bootstrap;

  @override
  Widget build(BuildContext context) {
    // إعادة بناء التطبيق من جذره عند تغيير اللغة أو الوضع الداكن.
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        // ضبط اللوحة الحالية قبل بناء الشجرة — كل رموز AppColors تقرأ منها.
        AppColors.p = appSettings.darkMode ? AppPalette.dark : AppPalette.light;

        return MaterialApp(
          title: CoreStrings.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: appSettings.themeMode,
          locale: appSettings.language.locale,
          supportedLocales: const [Locale('ar'), Locale('ckb'), Locale('en')],
          localizationsDelegates: const [
            // بدائل الكوردية أولاً كي تلتقط ckb قبل الـ Delegates العامة.
            CkbMaterialLocalizationsDelegate(),
            CkbWidgetsLocalizationsDelegate(),
            CkbCupertinoLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) =>
              AppLifecycleReconciler(child: child ?? const SizedBox.shrink()),
          home: SplashScreen(bootstrap: bootstrap),
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
