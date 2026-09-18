import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/app/routes.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_app/features/assistant/assistant_screen.dart';
import 'package:flutter_app/features/assistant/assistant_service.dart';
import 'package:flutter_app/features/assistant/assistant_strings.dart';

Future<void> pumpAssistant(
  WidgetTester tester,
  AssistantSend send, {
  double width = 390,
  double height = 844,
  double scale = 1,
  bool dark = false,
  Future<Product> Function(String)? loadProduct,
  RouteFactory? onGenerateRoute,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  appSettings.language = AppLanguage.ar;
  AppColors.p = dark ? AppPalette.dark : AppPalette.light;
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('assistant-capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateRoute: onGenerateRoute,
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
        home: AssistantScreen(
          send: send,
          loadProduct: loadProduct ?? loadAssistantProduct,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> consent(WidgetTester tester) async {
  final button = find.text(AssistantStrings.start);
  await tester.scrollUntilVisible(button, 200);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> send(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byTooltip(AssistantStrings.send));
  await tester.pump();
}

final fixtureProduct = Product(
  id: 'preview-watch',
  nameAr: 'ساعة نسائية — معاينة',
  categoryId: 'watches',
  description: '',
  specs: const {},
  media: const [
    MediaItem(
      id: 'preview-image',
      type: MediaType.image,
      url: 'https://fixture.invalid/watch.jpg',
    ),
  ],
  variants: const [],
  wholesalePrice: 7000,
  suggestedPrice: 18000,
  createdAt: DateTime(2026),
);
void main() {
  late List<int> productImage;
  setUpAll(() async {
    productImage = await File('test/fixtures/product-images/product-1.jpg').readAsBytes();
    await (FontLoader('Zain')
          ..addFont(rootBundle.load('assets/fonts/Zain-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Zain-Bold.ttf')))
        .load();
    var cache = File(Platform.resolvedExecutable).parent;
    while (cache.path.split(Platform.pathSeparator).last != 'cache') {
      cache = cache.parent;
    }
    final bytes = await File(
      '${cache.path}/artifacts/material_fonts/materialicons-regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  });
  setUp(() { AppNetworkImage.debugImageProvider = (_) => MemoryImage(Uint8List.fromList(productImage)); });
  tearDown(() { AppNetworkImage.debugImageProvider = null; });
  testWidgets(
    'consent required; double tap sends once; context stays bounded',
    (tester) async {
      var calls = 0;
      final pending = Completer<AssistantAnswer>();
      await pumpAssistant(tester, (message, history) {
        calls++;
        expect(history, isEmpty);
        return pending.future;
      });
      expect(calls, 0);
      expect(find.byType(TextField), findsNothing);
      await consent(tester);
      await send(tester, 'اقترحلي ساعة');
      await tester.tap(find.byTooltip(AssistantStrings.send));
      await tester.pump();
      expect(calls, 1);
      expect(find.text(AssistantStrings.thinking), findsOneWidget);
      pending.complete(const AssistantAnswer('هلا بيك'));
      await tester.pumpAndSettle();
      expect(find.text('هلا بيك'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );
  testWidgets('failure preserves draft and allows deliberate retry', (
    tester,
  ) async {
    var calls = 0;
    await pumpAssistant(tester, (_, _) async {
      calls++;
      throw StateError('offline');
    });
    await consent(tester);
    await send(tester, 'شلون أسوّق؟');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'شلون أسوّق؟',
    );
    expect(find.text(AssistantStrings.error), findsOneWidget);
    await tester.tap(find.byTooltip(AssistantStrings.send));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
  testWidgets(
    'product card refreshes exact ID and opens existing detail route once',
    (tester) async {
      var loads = 0, routes = 0;
      final pending = Completer<Product>();
      await pumpAssistant(
        tester,
        (_, _) async => AssistantAnswer('اقتراح', products: [fixtureProduct]),
        loadProduct: (id) {
          expect(id, fixtureProduct.id);
          loads++;
          return pending.future;
        },
        onGenerateRoute: (settings) {
          expect(settings.name, Routes.productDetail);
          expect(identical(settings.arguments, fixtureProduct), isTrue);
          routes++;
          return MaterialPageRoute<void>(
            builder: (_) =>
                const Scaffold(body: Text('Product detail destination')),
          );
        },
      );
      await consent(tester);
      await send(tester, 'ساعة');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AssistantStrings.openProduct));
      await tester.pump();
      await tester.tap(find.text(AssistantStrings.openProduct));
      await tester.pump();
      expect(loads, 1);
      expect(routes, 0);
      pending.complete(fixtureProduct);
      await tester.pumpAndSettle();
      expect(routes, 1);
      expect(find.text('Product detail destination'), findsOneWidget);
    },
  );
  testWidgets('unavailable product never navigates and shows recovery', (
    tester,
  ) async {
    await pumpAssistant(
      tester,
      (_, _) async => AssistantAnswer('اقتراح', products: [fixtureProduct]),
      loadProduct: (_) async => throw StateError('unavailable'),
    );
    await consent(tester);
    await send(tester, 'ساعة');
    await tester.pumpAndSettle();
    await tester.tap(find.text(AssistantStrings.openProduct));
    await tester.pumpAndSettle();
    expect(find.text(AssistantStrings.unavailable), findsOneWidget);
  });
  testWidgets(
    'late answer never crosses a changed account even when original returns',
    (tester) async {
      final original = session.seller;
      addTearDown(() => session.seller = original);
      final pending = Completer<AssistantAnswer>();
      await pumpAssistant(tester, (_, _) => pending.future);
      await consent(tester);
      await send(tester, 'سؤالي');
      session.seller = Seller(
        id: 'another-user',
        name: '',
        phone: '',
        storeName: '',
        instagramUrl: '',
        governorateId: '',
        status: AccountStatus.approved,
        joinedAt: DateTime(2026),
      );
      // Test identity notification, without accessing authentication or production.
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      session.notifyListeners();
      await tester.pump();
      session.seller = original;
      pending.complete(const AssistantAnswer('private late response'));
      await tester.pumpAndSettle();
      expect(find.text('private late response'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    },
  );
  for (final config in [
    (390.0, 844.0, 1.0, false, 'phone'),
    (320.0, 844.0, 2.0, true, 'accessible'),
    (844.0, 390.0, 1.0, false, 'landscape'),
  ]) {
    testWidgets('assistant rendered ${config.$5}', (tester) async {
      final bytes = await tester.runAsync(
        () => File('test/fixtures/product-images/product-1.jpg').readAsBytes(),
      );
      AppNetworkImage.debugImageProvider = (_) => MemoryImage(bytes!);
      addTearDown(() => AppNetworkImage.debugImageProvider = null);
      await pumpAssistant(
        tester,
        (_, _) async => AssistantAnswer(
          'أكدر أقترحلك هالساعة. افتح المنتج حتى تشوف الصور والألوان والتفاصيل.',
          products: [fixtureProduct],
        ),
        width: config.$1,
        height: config.$2,
        scale: config.$3,
        dark: config.$4,
      );
      expect(tester.takeException(), isNull);
      if (config.$5 == 'phone') {
        await expectLater(
          find.byKey(const ValueKey('assistant-capture')),
          matchesGoldenFile('goldens/assistant/consent-phone.png'),
        );
      }
      await consent(tester);
      await send(tester, 'اقترحلي ساعة');
      await tester.pumpAndSettle();
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      if (images.isNotEmpty) {
        final context = tester.element(find.byType(Image).first);
        await tester.runAsync(() async {
          for (final image in images) {
            await precacheImage(image.image, context);
          }
        });
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(AssistantProductRow), findsOneWidget);
      await expectLater(
        find.byKey(const ValueKey('assistant-capture')),
        matchesGoldenFile('goldens/assistant/chat-${config.$5}.png'),
      );
    });
  }
}
