import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/app/routes.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_app/data/storefront_models.dart';
import 'package:flutter_app/features/storefront/storefront_request_screen.dart';
import 'package:flutter_app/features/storefront/storefront_requests_view_model.dart';
import 'package:flutter_app/features/storefront/storefront_screen.dart';
import 'package:flutter_app/features/storefront/storefront_strings.dart';
import 'package:flutter_app/features/storefront/storefront_view_model.dart';
import 'package:flutter_app/features/storefront/storefront_widgets.dart';
import 'package:flutter_app/features/product/product_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'storefront_test_support.dart';

Future<void> pumpStore(
  WidgetTester tester,
  Widget screen, {
  double width = 390,
  double height = 900,
  double scale = 1,
  bool dark = false,
  Map<String, WidgetBuilder> routes = const {},
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  AppColors.p = dark ? AppPalette.dark : AppPalette.light;
  appSettings.language = AppLanguage.ar;
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('storefront_visual_surface'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: routes,
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  if (images.isNotEmpty) {
    final imageContext = tester.element(find.byType(Image).first);
    await tester.runAsync(() async {
      for (final image in images) {
        await precacheImage(image.image, imageContext);
      }
    });
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final size in [
    (375.0, 1.0, false, 'compact'),
    (320.0, 2.0, true, 'accessible'),
  ]) {
    testWidgets('image-led request review ${size.$4}', (tester) async {
      final bytes = await tester.runAsync(
        () => File('test/fixtures/product-images/product-1.jpg').readAsBytes(),
      );
      AppNetworkImage.debugImageProvider = (_) => MemoryImage(bytes!);
      addTearDown(() => AppNetworkImage.debugImageProvider = null);
      final repo = TestStorefrontRepository();
      repo.request = StorefrontRequest(
        id: testRequest.id,
        number: 'WEB-19001D84D97D42B7B5A6495ECB01D93D',
        status: 'pending',
        version: 1,
        customerName: 'زبون تجريبي',
        customerPhone: '07700000000',
        address: 'النجف · حي الجامعة',
        saleTotal: 20000,
        deliveryFee: 5000,
        total: 25000,
        createdAt: DateTime.utc(2026, 9, 17, 15, 2),
        items: const [
          StorefrontRequestItem(
            productName: 'ساعة نسائية',
            variantName: 'أسود',
            quantity: 1,
            unitSalePrice: 20000,
            imageUrl: 'https://fixture.invalid/watch.jpg',
          ),
        ],
      );
      final model = StorefrontRequestsViewModel(
        repository: repo,
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      await pumpStore(
        tester,
        StorefrontRequestScreen(requestId: testRequest.id, viewModel: model),
        width: size.$1,
        scale: size.$2,
        dark: size.$3,
      );
      expect(find.textContaining('WEB-'), findsNothing);
      expect(find.byType(AppNetworkImage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/storefront/request-redesign-${size.$4}.png'),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('approve_storefront_request')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('visual walkthrough real product, edit, add variant and remove', (
    tester,
  ) async {
    final bytes = await tester.runAsync(
      () => File('test/fixtures/product-images/product-1.jpg').readAsBytes(),
    );
    AppNetworkImage.debugImageProvider = (_) => MemoryImage(bytes!);
    addTearDown(() => AppNetworkImage.debugImageProvider = null);
    final product = Product(
      id: 'visual-watch',
      nameAr: 'ساعة رجالية معدن',
      categoryId: 'c',
      description: 'مثال توضيحي للمراجعة البصرية، وليس منتجاً منشوراً.',
      specs: const {},
      media: const [
        MediaItem(
          id: 'photo',
          type: MediaType.image,
          url: 'https://fixture.invalid/watch.jpg',
        ),
      ],
      variants: const [
        ProductVariant(id: 'black', nameAr: 'أزرق', imageUrl: '', stock: 10),
        ProductVariant(id: 'brown', nameAr: 'لون آخر', imageUrl: '', stock: 10),
      ],
      wholesalePrice: 6500,
      suggestedPrice: 15000,
      createdAt: DateTime.utc(2026),
    );
    final repo = TestStorefrontRepository(
      snapshot: StorefrontSnapshot(
        eligible: true,
        completedOrders: 10,
        store: testStore,
        listings: const [
          StoreListing(
            id: 'listing-black',
            productId: 'visual-watch',
            variantId: 'black',
            retailPrice: 23000,
          ),
        ],
      ),
    );
    final model = StorefrontViewModel(
      repository: repo,
      drafts: MemoryStorefrontDrafts(),
      isCurrentUser: () => true,
    );
    addTearDown(model.dispose);
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('storefront_visual_surface')),
        matchesGoldenFile('goldens/storefront/walkthrough/$name.png'),
      );
    }

    await pumpStore(
      tester,
      ProductDetailScreen(product: product),
      width: 390,
      height: 844,
      routes: {
        Routes.myStore: (_) =>
            StorefrontScreen(product: product, viewModel: model),
      },
    );
    await capture('01-product');
    await tester.drag(find.byType(ListView).first, const Offset(0, -520));
    await capture('01b-product-details');
    await tester.tap(find.byKey(const ValueKey('product_add_to_store')));
    await capture('02-existing');
    await tester.ensureVisible(find.byKey(const ValueKey('storefront_price')));
    await tester.enterText(
      find.byKey(const ValueKey('storefront_price')),
      '25000',
    );
    tester.testTextInput.hide();
    await tester.ensureVisible(
      find.byKey(const ValueKey('save_storefront_listing')),
    );
    await capture('03-edit-price');
    await tester.tap(find.byKey(const ValueKey('save_storefront_listing')));
    await capture('04-saved');
    expect(repo.current.listings.single.retailPrice, 25000);
    await tester.ensureVisible(
      find.byKey(const ValueKey('store_variant_brown')),
    );
    await tester.tap(find.byKey(const ValueKey('store_variant_brown')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('save_storefront_listing')),
    );
    await capture('05-another-color');
    await tester.ensureVisible(
      find.byKey(const ValueKey('store_variant_black')),
    );
    await tester.tap(find.byKey(const ValueKey('store_variant_black')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('remove_storefront_listing')),
    );
    await tester.tap(find.byKey(const ValueKey('remove_storefront_listing')));
    await capture('06-confirm-removal');
    await tester.tap(find.widgetWithText(TextButton, StorefrontStrings.remove));
    await capture('07-removed');
    expect(repo.current.listings, isEmpty);
    expect(find.text(StorefrontStrings.listingRemoved), findsOneWidget);
    expect(find.text(StorefrontStrings.listingUpdated), findsNothing);
  });
  Product managedProduct({int stock = 5}) => Product(
    id: 'managed-product',
    nameAr: 'ساعة الاختبار',
    categoryId: 'c',
    description: '',
    specs: const {},
    media: const [],
    variants: [
      ProductVariant(id: 'black', nameAr: 'أسود', imageUrl: '', stock: stock),
      const ProductVariant(id: 'brown', nameAr: 'جوزي', imageUrl: '', stock: 5),
    ],
    wholesalePrice: 6500,
    suggestedPrice: 15000,
    createdAt: DateTime.utc(2026),
  );
  TestStorefrontRepository managedRepo() => TestStorefrontRepository(
    snapshot: StorefrontSnapshot(
      eligible: true,
      completedOrders: 10,
      store: testStore,
      listings: const [
        StoreListing(
          id: 'listing-black',
          productId: 'managed-product',
          variantId: 'black',
          retailPrice: 23000,
        ),
      ],
    ),
  );
  StorefrontViewModel managedModel(TestStorefrontRepository repo) {
    final model = StorefrontViewModel(
      repository: repo,
      drafts: MemoryStorefrontDrafts(),
      isCurrentUser: () => true,
    );
    addTearDown(model.dispose);
    return model;
  }

  testWidgets(
    'reopening a listed product restores its variant and price; edit does not duplicate',
    (tester) async {
      final repo = managedRepo();
      final model = managedModel(repo);
      await pumpStore(
        tester,
        StorefrontScreen(product: managedProduct(), viewModel: model),
      );
      expect(find.text(StorefrontStrings.listingHelp), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('store_variant_black')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('storefront_price')),
            )
            .controller!
            .text,
        '23000',
      );
      expect(
        tester
            .widget<StorefrontAction>(
              find.byKey(const ValueKey('save_storefront_listing')),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('storefront_price')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('storefront_price')),
        '٢٥٠٠٠',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('save_storefront_listing')),
      );
      await tester.tap(find.byKey(const ValueKey('save_storefront_listing')));
      await tester.pumpAndSettle();
      expect(repo.listingCalls, 1);
      expect(repo.current.listings.single.retailPrice, 25000);
      expect(find.text(StorefrontStrings.listingUpdated), findsOneWidget);
      expect(
        find.byKey(const ValueKey('remove_storefront_listing')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      final reopened = managedModel(repo);
      await pumpStore(
        tester,
        StorefrontScreen(product: managedProduct(), viewModel: reopened),
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('storefront_price')),
            )
            .controller!
            .text,
        '25000',
      );
    },
  );
  testWidgets(
    'removal requires confirmation; failure preserves listing; success allows adding again',
    (tester) async {
      final repo = managedRepo();
      await pumpStore(
        tester,
        StorefrontScreen(
          product: managedProduct(),
          viewModel: managedModel(repo),
        ),
      );
      final remove = find.byKey(const ValueKey('remove_storefront_listing'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, StorefrontStrings.cancel),
      );
      await tester.pumpAndSettle();
      expect(repo.removeCalls, 0);
      repo.failRemoval = true;
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, StorefrontStrings.remove),
      );
      await tester.pumpAndSettle();
      expect(repo.current.listings, hasLength(1));
      expect(find.text(StorefrontStrings.loadError), findsOneWidget);
      repo.failRemoval = false;
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, StorefrontStrings.remove),
      );
      await tester.pumpAndSettle();
      expect(repo.current.listings, isEmpty);
      expect(remove, findsNothing);
      expect(
        tester
            .widget<StorefrontAction>(
              find.byKey(const ValueKey('save_storefront_listing')),
            )
            .label,
        StorefrontStrings.addProduct,
      );
    },
  );
  testWidgets('sold out listed variant remains selectable for removal', (
    tester,
  ) async {
    final repo = managedRepo();
    await pumpStore(
      tester,
      StorefrontScreen(
        product: managedProduct(stock: 0),
        viewModel: managedModel(repo),
      ),
    );
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('store_variant_black')))
          .selected,
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('remove_storefront_listing')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<StorefrontAction>(
            find.byKey(const ValueKey('save_storefront_listing')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('store_variant_brown')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('remove_storefront_listing')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<StorefrontAction>(
            find.byKey(const ValueKey('save_storefront_listing')),
          )
          .label,
      StorefrontStrings.save,
    );
  });
  for (final config in [
    (375.0, 1.0, false),
    (320.0, 2.0, true),
    (844.0, 1.0, false),
  ]) {
    testWidgets(
      'existing listing management fits ${config.$1} scale ${config.$2}',
      (tester) async {
        await pumpStore(
          tester,
          StorefrontScreen(
            product: managedProduct(),
            viewModel: managedModel(managedRepo()),
          ),
          width: config.$1,
          height: config.$1 == 844 ? 375 : 900,
          scale: config.$2,
          dark: config.$3,
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('remove_storefront_listing')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('remove_storefront_listing')))
              .height,
          greaterThanOrEqualTo(48),
        );
        if (config.$1 == 375) {
          await expectLater(
            find.byType(Scaffold).first,
            matchesGoldenFile('goldens/storefront/manage-product-phone.png'),
          );
        }
        if (config.$3) {
          await expectLater(
            find.byType(Scaffold).first,
            matchesGoldenFile(
              'goldens/storefront/manage-product-dark-large.png',
            ),
          );
        }
      },
    );
  }
  testWidgets(
    'save actual product selection, retain form, then activate paused store',
    (tester) async {
      final photo = await tester.runAsync(
        () => File('test/fixtures/product-images/product-1.jpg').readAsBytes(),
      );
      AppNetworkImage.debugImageProvider = (_) => MemoryImage(photo!);
      addTearDown(() => AppNetworkImage.debugImageProvider = null);
      final repo = TestStorefrontRepository(
        snapshot: StorefrontSnapshot(
          eligible: true,
          completedOrders: 0,
          store: const MerchantStore(
            id: 's1',
            slug: 'test-store',
            brandName: 'متجري',
            themeId: 'theme1',
          ),
        ),
      );
      final model = StorefrontViewModel(
        repository: repo,
        drafts: MemoryStorefrontDrafts(),
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      final product = Product(
        id: 'product-flow',
        nameAr: 'ساعة تجربة',
        categoryId: 'c',
        description: '',
        specs: const {},
        media: const [],
        variants: const [
          ProductVariant(
            id: 'black',
            nameAr: 'أسود',
            imageUrl: 'https://fixture.invalid/watch.jpg',
            stock: 5,
          ),
          ProductVariant(id: 'brown', nameAr: 'جوزي', imageUrl: '', stock: 5),
        ],
        wholesalePrice: 6500,
        suggestedPrice: 15000,
        createdAt: DateTime.utc(2026),
      );
      await pumpStore(
        tester,
        StorefrontScreen(product: product, viewModel: model),
        width: 390,
      );
      await tester.tap(find.byKey(const ValueKey('store_variant_black')));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => precacheImage(
          MemoryImage(photo!),
          tester.element(find.byType(StorefrontScreen)),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/storefront/add-product-phone.png'),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('storefront_price')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('storefront_price')),
        '٢٥٬٠٠٠',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('store_variant_brown')),
      );
      await tester.tap(find.byKey(const ValueKey('store_variant_brown')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('store_variant_black')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('storefront_price')),
            )
            .controller!
            .text,
        '٢٥٬٠٠٠',
      );
      final save = find.byKey(const ValueKey('save_storefront_listing'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.savedPrice, 25000);
      expect(repo.savedVariant, 'brown');
      expect(find.byType(StorefrontScreen), findsOneWidget);
      expect(find.text(StorefrontStrings.savedWhilePaused), findsOneWidget);
      final activate = find.widgetWithText(
        StorefrontAction,
        StorefrontStrings.activate,
      );
      await tester.ensureVisible(activate);
      await tester.tap(activate);
      await tester.pumpAndSettle();
      expect(repo.activateCalls, 1);
      expect(find.text(StorefrontStrings.publishedAfterSave), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('permanent publication has no renewal or expiry label', (
    tester,
  ) async {
    final store = MerchantStore(
      id: 'permanent',
      slug: 'test-store',
      brandName: 'متجر دائم',
      themeId: 'theme1',
      published: true,
      publicUrl: 'https://test-store.lugta.app',
      activeUntil: DateTime.parse('9999-12-31T23:59:59Z'),
    );
    expect(store.isActiveAt(DateTime.utc(2030)), isTrue);
    final model = StorefrontViewModel(
      repository: TestStorefrontRepository(
        snapshot: StorefrontSnapshot(
          eligible: true,
          completedOrders: 0,
          store: store,
        ),
      ),
      drafts: MemoryStorefrontDrafts(),
      isCurrentUser: () => true,
    );
    addTearDown(model.dispose);
    await pumpStore(
      tester,
      StorefrontScreen(viewModel: model),
      width: 320,
      scale: 2,
    );
    expect(find.text(StorefrontStrings.active), findsOneWidget);
    expect(find.text(StorefrontStrings.activate), findsNothing);
    expect(find.textContaining('24'), findsNothing);
    expect(find.textContaining('9999'), findsNothing);
    await tester.tap(find.byTooltip('خيارات النشر'));
    await tester.pumpAndSettle();
    expect(find.text('إيقاف المتجر مؤقتاً'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  late Uint8List fixtureLogo;
  setUpAll(() async {
    fixtureLogo = (await rootBundle.load(
      'assets/branding/lugta_icon_mark.png',
    )).buffer.asUint8List();
    await (FontLoader('Zain')
          ..addFont(rootBundle.load('assets/fonts/Zain-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Zain-Bold.ttf')))
        .load();
    var flutterCache = File(Platform.resolvedExecutable).parent;
    while (flutterCache.path.split(Platform.pathSeparator).last != 'cache') {
      flutterCache = flutterCache.parent;
    }
    final materialBytes = await File(
      '${flutterCache.path}/artifacts/material_fonts/materialicons-regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(materialBytes)))).load();
  });
  test('all ten real theme thumbnail and full assets are bundled', () async {
    for (final theme in storefrontThemes) {
      expect(
        (await rootBundle.load(theme.thumbnailAsset)).lengthInBytes,
        greaterThan(10000),
      );
      expect(
        (await rootBundle.load(theme.previewAsset)).lengthInBytes,
        greaterThan(10000),
      );
    }
  });
  testWidgets(
    'complete create from product: theme, identity, logo, activate and add',
    (tester) async {
      final repo = TestStorefrontRepository();
      final model = StorefrontViewModel(
        repository: repo,
        drafts: MemoryStorefrontDrafts(),
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      final product = Product(
        id: 'creation-product',
        nameAr: 'قميص رجالي',
        categoryId: 'c',
        description: '',
        specs: const {},
        media: const [],
        variants: const [
          ProductVariant(
            id: 'shirt-xl',
            nameAr: 'أسود / XL',
            imageUrl: '',
            stock: 5,
          ),
        ],
        wholesalePrice: 6500,
        suggestedPrice: 15000,
        createdAt: DateTime.utc(2026),
      );
      await pumpStore(
        tester,
        StorefrontScreen(
          product: product,
          viewModel: model,
          pickImage: () async => XFile.fromData(
            fixtureLogo,
            mimeType: 'image/png',
            name: 'logo.png',
          ),
        ),
      );
      await tester.tap(find.byType(StoreThemeCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(StorefrontStrings.select).last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('storefront_brand')),
        'متجر التجربة',
      );
      await tester.enterText(
        find.byKey(const ValueKey('storefront_slug')),
        'complete-flow',
      );
      await tester.ensureVisible(find.text(StorefrontStrings.pickLogo));
      await tester.tap(find.text(StorefrontStrings.pickLogo));
      await tester.pumpAndSettle();
      expect(repo.uploadCalls, 1);
      await tester.ensureVisible(find.text(StorefrontStrings.create));
      await tester.tap(find.text(StorefrontStrings.create));
      await tester.pumpAndSettle();
      expect(repo.saveCalls, 1);
      expect(model.snapshot!.store!.slug, 'complete-flow');
      expect(model.snapshot!.store!.published, isFalse);
      await tester.tap(find.byKey(const ValueKey('store_variant_shirt-xl')));
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('save_storefront_listing'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.listingCalls, 1);
      expect(repo.savedPrice, 15000);
      final activate = find.text(StorefrontStrings.activate);
      await tester.ensureVisible(activate);
      await tester.tap(activate);
      await tester.pumpAndSettle();
      expect(repo.activateCalls, 1);
      expect(model.snapshot!.listings.single.variantId, 'shirt-xl');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'refresh failure blocks saving, retry preserves price and validates fresh stock',
    (tester) async {
      final repo = TestStorefrontRepository(
        snapshot: StorefrontSnapshot(
          eligible: true,
          completedOrders: 10,
          store: testStore,
        ),
      );
      final model = StorefrontViewModel(
        repository: repo,
        drafts: MemoryStorefrontDrafts(),
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      Product productWithStock(int stock) => Product(
        id: 'refresh-product',
        nameAr: 'قميص',
        categoryId: 'c',
        description: '',
        specs: const {},
        media: const [],
        variants: [
          ProductVariant(id: 'v-xl', nameAr: 'XL', imageUrl: '', stock: stock),
        ],
        wholesalePrice: 6500,
        suggestedPrice: 15000,
        createdAt: DateTime.utc(2026),
      );
      var fail = true;
      await pumpStore(
        tester,
        StorefrontScreen(
          product: productWithStock(5),
          viewModel: model,
          refreshProduct: (_) async {
            if (fail) throw StateError('offline');
            return productWithStock(0);
          },
        ),
        width: 320,
        scale: 2,
      );
      final price = find.byKey(const ValueKey('storefront_price'));
      await tester.scrollUntilVisible(
        price,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(price, '22000');
      final save = find.byKey(const ValueKey('save_storefront_listing'));
      await tester.scrollUntilVisible(
        save,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<StorefrontAction>(save).onPressed, isNull);
      fail = false;
      await tester.scrollUntilVisible(
        find.text(StorefrontStrings.retry),
        -240,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text(StorefrontStrings.retry)),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(StorefrontStrings.retry));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        price,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<TextFormField>(price).controller!.text, '22000');
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('store_variant_v-xl')),
            )
            .onSelected,
        isNull,
      );
      await tester.scrollUntilVisible(
        save,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<StorefrontAction>(save).onPressed, isNull);
      expect(repo.listingCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'server-ineligible seller sees no create controls at 320dp 200%',
    (tester) async {
      final model = StorefrontViewModel(
        repository: TestStorefrontRepository(
          snapshot: StorefrontSnapshot(
            eligible: false,
            completedOrders: 9,
            orderProgress: const [
              StorefrontOrderProgress(
                id: 'historical',
                number: 'ORD-OLD',
                status: 'completed',
              ),
              StorefrontOrderProgress(
                id: 'delivered',
                number: 'ORD-WAIT',
                status: 'delivered',
              ),
              StorefrontOrderProgress(
                id: 'cancelled',
                number: 'ORD-CANCEL',
                status: 'cancelled',
              ),
            ],
          ),
        ),
        drafts: MemoryStorefrontDrafts(),
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      await pumpStore(
        tester,
        StorefrontScreen(
          viewModel: model,
          pickImage: () async => XFile.fromData(
            fixtureLogo,
            mimeType: 'image/png',
            name: 'fixture-logo.png',
          ),
        ),
        width: 320,
        scale: 2,
      );
      expect(find.text(StorefrontStrings.eligibility), findsOneWidget);
      expect(find.text(StorefrontStrings.create), findsNothing);
      await tester.scrollUntilVisible(find.text('ORD-OLD'), 200);
      expect(
        find.text(StorefrontStrings.progressReason('completed')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(find.text('ORD-WAIT'), 200);
      await tester.pumpAndSettle();
      expect(
        find.text(StorefrontStrings.progressReason('delivered')),
        findsOneWidget,
      );
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/storefront/eligibility-progress-large.png'),
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final config in [
    (390.0, 1.0, false, 'phone'),
    (320.0, 2.0, true, 'large-dark'),
  ]) {
    testWidgets('real full storefront gallery ${config.$4}', (tester) async {
      final model = StorefrontViewModel(
        repository: TestStorefrontRepository(),
        drafts: MemoryStorefrontDrafts(),
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      await pumpStore(
        tester,
        StorefrontScreen(
          viewModel: model,
          pickImage: () async => XFile.fromData(
            fixtureLogo,
            mimeType: 'image/png',
            name: 'fixture-logo.png',
          ),
        ),
        width: config.$1,
        scale: config.$2,
        dark: config.$3,
      );
      expect(find.byType(StoreThemeCard), findsWidgets);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/storefront/gallery-${config.$4}.png'),
      );
      await tester.ensureVisible(find.text(StorefrontStrings.select).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(StorefrontStrings.select).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('storefront_brand')), findsOneWidget);
      expect(model.draft.themeId, 'theme1');
      await tester.enterText(
        find.byKey(const ValueKey('storefront_brand')),
        'متجر التجربة',
      );
      await tester.enterText(
        find.byKey(const ValueKey('storefront_slug')),
        'demo-store',
      );
      await tester.scrollUntilVisible(
        find.text(StorefrontStrings.pickLogo),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(StorefrontStrings.pickLogo));
      await tester.pumpAndSettle();
      expect(model.draft.logoPath, 'user/logo.png');
      final imageContext = tester.element(find.byType(Image).first);
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      await tester.runAsync(() async {
        for (final image in images) {
          await precacheImage(image.image, imageContext);
        }
      });
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, 1800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/storefront/setup-${config.$4}.png'),
      );
    });
    testWidgets('full request detail contact actions ${config.$4}', (
      tester,
    ) async {
      final repo = TestStorefrontRepository();
      final model = StorefrontRequestsViewModel(
        repository: repo,
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      await pumpStore(
        tester,
        StorefrontRequestScreen(requestId: testRequest.id, viewModel: model),
        width: config.$1,
        scale: config.$2,
        dark: config.$3,
      );
      expect(repo.detailCalls, 1);
      expect(find.text(StorefrontRequestStrings.origin), findsOneWidget);
      expect(find.textContaining('WEB-'), findsNothing);
      expect(find.text('واتساب'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/storefront/request-${config.$4}.png'),
      );
    });
  }
  testWidgets('reject requires a reason then stores rejection', (tester) async {
    final repo = TestStorefrontRepository();
    final model = StorefrontRequestsViewModel(
      repository: repo,
      isCurrentUser: () => true,
    );
    addTearDown(model.dispose);
    await pumpStore(
      tester,
      StorefrontRequestScreen(requestId: testRequest.id, viewModel: model),
    );
    await tester.ensureVisible(find.text(StorefrontRequestStrings.reject));
    await tester.pumpAndSettle();
    await tester.tap(find.text(StorefrontRequestStrings.reject));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(StorefrontRequestStrings.reject));
    await tester.pumpAndSettle();
    await tester.tap(find.text(StorefrontRequestStrings.reject));
    await tester.pumpAndSettle();
    expect(repo.request.pending, isTrue);
    await tester.enterText(
      find.byKey(const ValueKey('storefront_rejection_reason')),
      'الزبون ألغى الطلب',
    );
    await tester.ensureVisible(find.text(StorefrontRequestStrings.reject));
    await tester.pumpAndSettle();
    await tester.tap(find.text(StorefrontRequestStrings.reject));
    await tester.pumpAndSettle();
    expect(repo.request.status, 'rejected');
    expect(repo.request.rejectionReason, 'الزبون ألغى الطلب');
  });
  testWidgets('full template preview selects the same design', (tester) async {
    final model = StorefrontViewModel(
      repository: TestStorefrontRepository(),
      drafts: MemoryStorefrontDrafts(),
      isCurrentUser: () => true,
    );
    addTearDown(model.dispose);
    await pumpStore(tester, StorefrontScreen(viewModel: model));
    await tester.tap(find.byType(StoreThemeCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(StoreThemePreviewScreen), findsOneWidget);
    await tester.tap(find.text(StorefrontStrings.select).last);
    await tester.pumpAndSettle();
    expect(model.draft.themeId, 'theme1');
    expect(find.byKey(const ValueKey('storefront_brand')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('returning from product catalog refreshes store listings', (
    tester,
  ) async {
    final repo = TestStorefrontRepository(
      snapshot: StorefrontSnapshot(
        eligible: true,
        completedOrders: 10,
        store: testStore,
      ),
    );
    final model = StorefrontViewModel(
      repository: repo,
      drafts: MemoryStorefrontDrafts(),
      isCurrentUser: () => true,
    );
    addTearDown(model.dispose);
    await pumpStore(
      tester,
      StorefrontScreen(viewModel: model),
      routes: {
        Routes.products: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('return from catalog'),
          ),
        ),
      },
    );
    final before = repo.fetchCalls;
    await tester.scrollUntilVisible(
      find.text(StorefrontStrings.browse),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(StorefrontStrings.browse));
    await tester.pumpAndSettle();
    await tester.tap(find.text('return from catalog'));
    await tester.pumpAndSettle();
    expect(repo.fetchCalls, before + 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('resumes setup and recovers only its pending logo picker', (
    tester,
  ) async {
    final repo = TestStorefrontRepository();
    final drafts = MemoryStorefrontDrafts()
      ..value = const StorefrontDraft(
        brandName: 'مسودة محفوظة',
        slug: 'saved-store',
        themeId: 'theme3',
      )
      ..pending = true;
    final model = StorefrontViewModel(
      repository: repo,
      drafts: drafts,
      isCurrentUser: () => true,
    );
    addTearDown(model.dispose);
    var recoverCalls = 0;
    await pumpStore(
      tester,
      StorefrontScreen(
        viewModel: model,
        recoverLostData: () async {
          recoverCalls++;
          return LostDataResponse(
            files: [
              XFile.fromData(
                fixtureLogo,
                mimeType: 'image/png',
                name: 'logo.png',
              ),
            ],
            type: RetrieveType.image,
          );
        },
      ),
    );
    expect(recoverCalls, 1);
    expect(repo.uploadCalls, 1);
    expect(drafts.pending, isFalse);
    expect(model.draft.brandName, 'مسودة محفوظة');
    expect(model.draft.themeId, 'theme3');
    expect(model.draft.logoPath, 'user/logo.png');
    expect(tester.takeException(), isNull);
  });
  testWidgets('approve button stays disabled while acceptance in flight', (
    tester,
  ) async {
    final repo = TestStorefrontRepository()..mutationGate = Completer();
    final model = StorefrontRequestsViewModel(
      repository: repo,
      isCurrentUser: () => true,
    );
    addTearDown(model.dispose);
    await pumpStore(
      tester,
      StorefrontRequestScreen(requestId: testRequest.id, viewModel: model),
    );
    final button = find.byKey(const ValueKey('approve_storefront_request'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(repo.approveCalls, 1);
    await tester.pumpWidget(const SizedBox());
    repo.mutationGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'product choice respects exact size and variant wholesale override',
    (tester) async {
      final repo = TestStorefrontRepository(
        snapshot: StorefrontSnapshot(
          eligible: true,
          completedOrders: 10,
          store: testStore,
        ),
      );
      final model = StorefrontViewModel(
        repository: repo,
        drafts: MemoryStorefrontDrafts(),
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      final product = Product(
        id: 'unique-product',
        nameAr: 'قميص اختبار',
        categoryId: 'test',
        description: '',
        specs: const {},
        media: const [],
        variants: const [
          ProductVariant(
            id: 'xl',
            nameAr: 'أسود',
            size: 'XL',
            imageUrl: '',
            stock: 3,
            wholesalePriceOverride: 20000,
          ),
          ProductVariant(
            id: 'm',
            nameAr: 'أسود',
            size: 'M',
            imageUrl: '',
            stock: 0,
          ),
        ],
        wholesalePrice: 10000,
        suggestedPrice: 25000,
        createdAt: DateTime.utc(2026),
      );
      await pumpStore(
        tester,
        StorefrontScreen(product: product, viewModel: model),
        width: 320,
        scale: 2,
      );
      await tester.tap(find.byKey(const ValueKey('store_variant_xl')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('storefront_price')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('storefront_price')),
        '15000',
      );
      await tester.ensureVisible(find.byType(StorefrontAction).last);
      await tester.tap(find.byType(StorefrontAction).last);
      await tester.pumpAndSettle();
      expect(repo.savedVariant, isNull);
      expect(find.text(StorefrontStrings.invalidPrice), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
