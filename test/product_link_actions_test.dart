import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/features/product/product_link_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Zain')
          ..addFont(rootBundle.load('assets/fonts/Zain-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Zain-Bold.ttf')))
        .load();
    var cache = File(Platform.resolvedExecutable).parent;
    while (cache.path.split(Platform.pathSeparator).last != 'cache') {
      final parent = cache.parent;
      if (parent.path == cache.path) {
        throw StateError('Flutter cache not found');
      }
      cache = parent;
    }
    final bytes = await File(
      '${cache.path}/artifacts/material_fonts/materialicons-regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  });
  const id = '22222222-2222-4222-8222-222222222222';
  const url = 'https://product.lugta.app/p/IiIiIiIiQiKCIiIiIiIiIg';
  testWidgets('copy shares only canonical product link', (tester) async {
    String? copied;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = call.arguments['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductLinkActions(productId: id, productName: 'ساعة'),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('copy_product_link')));
    await tester.pump();
    expect(copied, url);
    expect(tester.takeException(), isNull);
  });
  testWidgets('share is single-flight and includes title and exact link', (
    tester,
  ) async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger = tester.binding.defaultBinaryMessenger;
    final gate = Completer<String>();
    var calls = 0;
    String? shared;
    Map<dynamic, dynamic>? shareArguments;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      shareArguments = call.arguments as Map<dynamic, dynamic>;
      shared = call.arguments['text'] as String?;
      return gate.future;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductLinkActions(productId: id, productName: 'ساعة'),
        ),
      ),
    );
    final button = find.byKey(const ValueKey('share_product_link'));
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(calls, 1);
    expect(shared, 'ساعة\n$url');
    // iPad requires a non-empty share-sheet popover anchor.
    expect(shareArguments!['originWidth'], greaterThan(0));
    expect(shareArguments!['originHeight'], greaterThan(0));
    expect(shareArguments!['originX'], greaterThanOrEqualTo(0));
    expect(shareArguments!['originY'], greaterThanOrEqualTo(0));
    gate.complete('dev.fluttercommunity.plus/share/unavailable');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    testWidgets('link actions RTL small width and large text dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 240);
      tester.view.devicePixelRatio = 1;
      appSettings.language = AppLanguage.ar;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: const Scaffold(
            body: ProductLinkActions(productId: id, productName: 'ساعة'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('share_product_link')), findsOneWidget);
      expect(find.byKey(const ValueKey('copy_product_link')), findsOneWidget);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/product-links-${dark ? "dark" : "light"}.png',
        ),
      );
    });
  }
}
