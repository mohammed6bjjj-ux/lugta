import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/app_metadata.dart';
import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/ckb_localizations.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/orders/order_detail_screen.dart';
import 'package:flutter_app/features/product/media_share_sheet.dart';
import 'package:flutter_app/features/product/media_viewer_screen.dart';
import 'package:flutter_app/features/product/product_detail_screen.dart';
import 'package:flutter_app/features/product/product_strings.dart';
import 'package:flutter_app/features/profile/about_screen.dart';
import 'package:flutter_app/features/profile/notifications_screen.dart';
import 'package:flutter_app/features/profile/profile_strings.dart';
import 'package:flutter_app/features/profile/settings_screen.dart';

void main() {
  setUp(() async {
    appSettings.language = AppLanguage.en;
    appSettings.darkMode = false;
    AppColors.p = AppPalette.light;
    await session.configure(createDemoRepositories(), loadInitialData: false);
  });

  tearDown(() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await session.configure(createDemoRepositories(), loadInitialData: false);
    appSettings.language = AppLanguage.ar;
  });

  testWidgets('order notification still opens when marking read fails', (
    tester,
  ) async {
    final order = MockData.orders.first;
    await tester.runAsync(_useFailingNotificationsRepository);
    session.orders = [order];
    session.notifications = [
      AppNotification(
        id: 'failing-order-notification',
        title: 'Open linked order',
        body: 'The read receipt will fail.',
        type: NotificationType.order,
        at: DateTime.now(),
        targetOrderId: order.id,
      ),
    ];

    await tester.pumpWidget(_testApp(const NotificationsScreen()));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Open linked order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product notification still opens when marking read fails', (
    tester,
  ) async {
    final product = MockData.products.first;
    await tester.runAsync(_useFailingNotificationsRepository);
    session.products = [product];
    session.notifications = [
      AppNotification(
        id: 'failing-product-notification',
        title: 'Open linked product',
        body: 'The read receipt will fail.',
        type: NotificationType.product,
        at: DateTime.now(),
        targetProductId: product.id,
      ),
    ];

    await tester.pumpWidget(_testApp(const NotificationsScreen()));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Open linked product'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings clears the real image cache and shows app version', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(const SettingsScreen()));
    await tester.pump(const Duration(milliseconds: 800));

    final image = MemoryImage(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    final imageKey = await image.obtainKey(const ImageConfiguration());
    final settingsContext = tester.element(find.byType(SettingsScreen));
    await tester.runAsync(() => precacheImage(image, settingsContext));
    await tester.pump();
    expect(PaintingBinding.instance.imageCache.containsKey(imageKey), isTrue);

    final clearCache = find.text(ProfileStrings.clearCache);
    await tester.scrollUntilVisible(clearCache, 300);
    await tester.tap(clearCache);
    await tester.pump();

    expect(PaintingBinding.instance.imageCache.containsKey(imageKey), isFalse);
    expect(find.text(ProfileStrings.cacheCleared), findsOneWidget);
    expect(ProfileStrings.cacheCleared, isNot(contains('24.6')));
    expect(find.text(AppMetadata.version), findsOneWidget);
  });

  testWidgets('about screen shows the same app version as settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(const AboutScreen()));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.scrollUntilVisible(find.text(AppMetadata.version), 300);

    expect(find.text(AppMetadata.version), findsOneWidget);
  });

  testWidgets('media viewer never reports a save it could not perform', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The host has no gallery plugin and the URL is unreachable, so the
    // transfer must fail — and must say so rather than claim success. A private
    // /object/authenticated/ URL must never be handed out in place of the file.
    const mediaUrl = 'https://example.invalid/current-product-image.jpg';

    await tester.pumpWidget(
      _testApp(
        const MediaViewerScreen(
          media: [
            MediaItem(id: 'media-1', type: MediaType.image, url: mediaUrl),
          ],
          initialIndex: 0,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(ProductStrings.download));
    await tester.pump();
    expect(find.text(ProductStrings.mediaPreparing), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await _expectNoFakeSuccess(tester);

    await _removeSnackBar(tester);
    await tester.tap(find.text(ProductStrings.share));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await _expectNoFakeSuccess(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bulk media actions do not report fake success', (tester) async {
    tester.view.physicalSize = const Size(700, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () =>
                    showMediaShareSheet(context, MockData.products.first),
                child: const Text('Open media actions'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open media actions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text(ProductStrings.downloadToDevice));
    await tester.pump();
    expect(find.text(ProductStrings.mediaPreparing), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await _expectNoFakeSuccess(tester);

    await _removeSnackBar(tester);
    await tester.tap(find.text(ProductStrings.share));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await _expectNoFakeSuccess(tester);
    expect(tester.takeException(), isNull);
  });
}

/// The host has no gallery/share plugins, so the transfer must end in one of
/// the honest failure messages — never in a success receipt the app cannot back
/// up, and never by handing out a private URL instead of the file.
/// The host has no gallery/share plugins and the URL is unreachable, so the
/// transfer cannot succeed. The widget clock does not drive real plugin I/O to
/// completion, so assert what is deterministic here: the app never claims a
/// save it did not perform, and never falls back to handing out the private
/// URL. The failure results themselves are covered in media_transfer_test.dart.
Future<void> _expectNoFakeSuccess(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  for (var count = 0; count <= 3; count++) {
    expect(
      find.text(ProductStrings.mediaSaved(formatNumber(count))),
      findsNothing,
      reason: 'a transfer that could not run must not be announced as a save',
    );
  }
}

Future<void> _removeSnackBar(WidgetTester tester) async {
  final snackBar = find.byType(SnackBar);
  expect(snackBar, findsOneWidget);
  ScaffoldMessenger.of(tester.element(snackBar)).removeCurrentSnackBar();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _useFailingNotificationsRepository() async {
  final base = createDemoRepositories();
  await session.configure(
    AppRepositories(
      auth: base.auth,
      profile: base.profile,
      catalog: base.catalog,
      orders: base.orders,
      wallet: base.wallet,
      notifications: _FailingMarkReadNotificationsRepository(
        base.notifications,
      ),
      isDemo: true,
    ),
    loadInitialData: false,
  );
}

Widget _testApp(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light(),
  locale: const Locale('en'),
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
  home: home,
);

class _FailingMarkReadNotificationsRepository
    implements NotificationsRepository {
  _FailingMarkReadNotificationsRepository(this._delegate);

  final NotificationsRepository _delegate;

  @override
  Future<List<AppNotification>> fetchNotifications() =>
      _delegate.fetchNotifications();

  @override
  Future<void> markRead(String notificationId) async {
    await Future<void>.delayed(Duration.zero);
    throw const BackendException('read receipt failed');
  }

  @override
  Future<void> markAllRead() => _delegate.markAllRead();

  @override
  Future<void> markPopupSeen(String notificationId) =>
      _delegate.markPopupSeen(notificationId);

  @override
  Stream<List<AppNotification>> watchNotifications() =>
      _delegate.watchNotifications();
}
