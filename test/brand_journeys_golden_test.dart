import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/ckb_localizations.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/features/auth/login_screen.dart';
import 'package:flutter_app/features/catalog/products_screen.dart';
import 'package:flutter_app/features/order_wizard/order_wizard_screen.dart';
import 'package:flutter_app/features/product/product_detail_screen.dart';
import 'package:flutter_app/features/profile/profile_screen.dart';
import 'package:flutter_app/features/promotions/promotions_screen.dart';
import 'package:flutter_app/features/shell/main_shell.dart';
import 'package:flutter_app/features/wallet/wallet_screen.dart';

typedef _ScreenFactory = Widget Function();

class _BrandScenario {
  const _BrandScenario(this.name, this.language, this.darkMode);

  final String name;
  final AppLanguage language;
  final bool darkMode;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late final List<MemoryImage> productImages;
  setUpAll(() async {
    final zainExtraLight = FontLoader('Zain')
      ..addFont(rootBundle.load('assets/fonts/Zain-ExtraLight.ttf'));
    final zainRegular = FontLoader('Zain')
      ..addFont(rootBundle.load('assets/fonts/Zain-Regular.ttf'));
    final zainBold = FontLoader('Zain')
      ..addFont(rootBundle.load('assets/fonts/Zain-Bold.ttf'));
    var flutterCache = File(Platform.resolvedExecutable).parent;
    while (flutterCache.path.split(Platform.pathSeparator).last != 'cache') {
      final parent = flutterCache.parent;
      if (parent.path == flutterCache.path) {
        throw StateError('Unable to locate the Flutter cache directory.');
      }
      flutterCache = parent;
    }
    final materialIconBytes = await File(
      '${flutterCache.path}${Platform.pathSeparator}artifacts'
      '${Platform.pathSeparator}material_fonts${Platform.pathSeparator}'
      'materialicons-regular.otf',
    ).readAsBytes();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(Uint8List.fromList(materialIconBytes)),
        ),
      );
    await Future.wait([
      zainExtraLight.load(),
      zainRegular.load(),
      zainBold.load(),
      materialIcons.load(),
    ]);
    final fixtureDirectory = Directory(
      '${Directory.current.path}${Platform.pathSeparator}test'
      '${Platform.pathSeparator}fixtures${Platform.pathSeparator}'
      'product-images',
    );
    productImages = await Future.wait(
      fixtureDirectory.listSync().whereType<File>().map(
        (file) async => MemoryImage(await file.readAsBytes()),
      ),
    );
    AppNetworkImage.debugImageProvider = (url) {
      final index = url.hashCode.abs() % productImages.length;
      return productImages[index];
    };
    messenger.setMockMethodCallHandler(
      pathProvider,
      (call) async => Directory.systemTemp.path,
    );
  });
  tearDownAll(() {
    AppNetworkImage.debugImageProvider = null;
    messenger.setMockMethodCallHandler(pathProvider, null);
  });

  final product = MockData.products.first;
  final journeys = <String, _ScreenFactory>{
    'auth': () => const LoginScreen(),
    'home': () => const MainShell(),
    'catalog': () => const ProductsScreen(),
    'product': () => ProductDetailScreen(product: product),
    'checkout': () => OrderWizardScreen(product: product),
    'finance': () => const WalletScreen(),
    'engagement': () => const PromotionsScreen(),
    'account': () => const ProfileScreen(),
  };
  const scenarios = <_BrandScenario>[
    _BrandScenario('ar-light', AppLanguage.ar, false),
    _BrandScenario('ar-dark', AppLanguage.ar, true),
    _BrandScenario('ckb-light', AppLanguage.ckb, false),
    _BrandScenario('ckb-dark', AppLanguage.ckb, true),
    _BrandScenario('en-light', AppLanguage.en, false),
    _BrandScenario('en-dark', AppLanguage.en, true),
  ];

  for (final journey in journeys.entries) {
    for (final scenario in scenarios) {
      testWidgets('${journey.key} matches ${scenario.name} brand baseline', (
        tester,
      ) async {
        tester.view
          ..physicalSize = const Size(390, 844)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(() {
          appSettings.language = AppLanguage.ar;
          appSettings.darkMode = false;
          AppColors.p = AppPalette.light;
        });

        await tester.pumpWidget(
          _goldenApp(
            home: journey.value(),
            language: scenario.language,
            darkMode: scenario.darkMode,
          ),
        );
        await tester.pump(const Duration(milliseconds: 900));

        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/lugta/${journey.key}-${scenario.name}.png',
          ),
        );
      });
    }
  }
}

Widget _goldenApp({
  required Widget home,
  required AppLanguage language,
  required bool darkMode,
}) {
  appSettings.language = language;
  appSettings.darkMode = darkMode;
  AppColors.p = darkMode ? AppPalette.dark : AppPalette.light;

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: darkMode ? AppTheme.dark() : AppTheme.light(),
    locale: language.locale,
    supportedLocales: const [Locale('ar'), Locale('ckb'), Locale('en')],
    localizationsDelegates: const [
      CkbMaterialLocalizationsDelegate(),
      CkbWidgetsLocalizationsDelegate(),
      CkbCupertinoLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(disableAnimations: true),
        child: child!,
      );
    },
    onGenerateRoute: AppRouter.onGenerateRoute,
    home: home,
  );
}
