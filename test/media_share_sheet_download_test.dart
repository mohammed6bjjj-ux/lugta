import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/background_media_downloads.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_app/core/widgets/primary_button.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/features/product/media_share_sheet.dart';
import 'package:flutter_app/features/product/product_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final product = Product(
    id: 'download-product',
    nameAr: 'ساعة',
    categoryId: 'watches',
    description: '',
    specs: const {},
    variants: const [],
    media: const [
      MediaItem(
        id: 'photo',
        type: MediaType.image,
        url: 'https://example.test/photo.jpg',
      ),
    ],
    wholesalePrice: 6500,
    suggestedPrice: 15000,
    createdAt: DateTime(2026),
  );

  for (final dark in [false, true]) {
    testWidgets(
      'download stays single-flight and reports after sheet closes (dark=$dark)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        appSettings.language = AppLanguage.ar;
        AppNetworkImage.debugImageProvider = (_) => MemoryImage(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          ),
        );
        final gate = Completer<void>();
        var enqueues = 0;
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(BackgroundMediaDownloads.channel, (
          call,
        ) async {
          if (call.method == 'supported') return true;
          if (call.method == 'lookup') return null;
          enqueues++;
          await gate.future;
          return {'state': 'queued'};
        });
        addTearDown(() {
          messenger.setMockMethodCallHandler(
            BackgroundMediaDownloads.channel,
            null,
          );
          debugDefaultTargetPlatformOverride = null;
          AppNetworkImage.debugImageProvider = null;
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            builder: (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showMediaShareSheet(context, product),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text(ProductStrings.downloadToDevice), findsOneWidget);
        await tester.tap(find.text(ProductStrings.downloadToDevice));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
        expect(button.loading, true);
        expect(button.onPressed, null);
        expect(enqueues, 1);
        // Closing the route must not discard the result or cancel the transfer.
        navigator.currentState!.pop();
        await tester.pump(const Duration(milliseconds: 400));
        gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(ProductStrings.viewDownloads), findsOneWidget);
        expect(find.textContaining('للتنزيل بالخلفية'), findsOneWidget);
        expect(enqueues, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
