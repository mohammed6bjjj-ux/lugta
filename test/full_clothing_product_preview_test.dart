import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/product/product_detail_screen.dart';
import 'package:flutter_app/features/product/product_size_options.dart';
import 'package:flutter_app/features/product/product_strings.dart';

// Illustrative product data used ONLY in this test. This renders the unmodified
// production ProductDetailScreen, rather than a recreated product-page mockup.
// The existing test image hook supplies a local photo without network requests.
const _photoUrl = 'https://preview.invalid/clothing-shirt.webp';
const _photoPath = String.fromEnvironment(
  'PRODUCT_PREVIEW_IMAGE',
  defaultValue: 'test/fixtures/clothing/clothing-shirt-black.webp',
);

final _product = Product(
  id: 'preview-clothing-product',
  nameAr: 'تيشيرت رياضي أسود',
  categoryId: 'preview-clothing',
  description:
      'تيشيرت أسود بطباعة أمامية. اختر المقاس المناسب من الخيارات المتوفرة أعلاه.',
  specs: const {
    'نوع المنتج': 'تيشيرت',
    'اللون': 'أسود',
    'المقاسات': 'S · M · L · XL · XXL',
  },
  media: const [
    MediaItem(id: 'preview-shirt-cover', type: MediaType.image, url: _photoUrl),
  ],
  variants: const [
    ProductVariant(
      id: 'preview-black-s',
      nameAr: 'أسود / S',
      size: 'S',
      imageUrl: '',
      stock: 6,
      colorHex: 0xFF202035,
    ),
    ProductVariant(
      id: 'preview-black-m',
      nameAr: 'أسود / Medium',
      size: 'Medium',
      imageUrl: '',
      stock: 4,
      colorHex: 0xFF202035,
    ),
    ProductVariant(
      id: 'preview-black-l',
      nameAr: 'أسود / Large',
      size: 'Large',
      imageUrl: '',
      stock: 0,
      colorHex: 0xFF202035,
    ),
    ProductVariant(
      id: 'preview-black-xl',
      nameAr: 'أسود / XLarge',
      size: 'XLarge',
      imageUrl: '',
      stock: 5,
      colorHex: 0xFF202035,
    ),
    ProductVariant(
      id: 'preview-black-xxl',
      nameAr: 'أسود / XXL',
      size: 'XXL',
      imageUrl: '',
      stock: 3,
      colorHex: 0xFF202035,
    ),
  ],
  wholesalePrice: 14000,
  suggestedPrice: 20000,
  minSalePrice: 15000,
  maxSalePrice: 30000,
  createdAt: DateTime(2026, 9, 11),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryImage productPhoto;

  setUpAll(() async {
    await (FontLoader('Zain')
          ..addFont(rootBundle.load('assets/fonts/Zain-ExtraLight.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Zain-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Zain-Bold.ttf')))
        .load();
    var flutterCache = File(Platform.resolvedExecutable).parent;
    while (flutterCache.path.split(Platform.pathSeparator).last != 'cache') {
      final parent = flutterCache.parent;
      if (parent.path == flutterCache.path) {
        throw StateError('Unable to locate the Flutter cache directory.');
      }
      flutterCache = parent;
    }
    final iconBytes = await File(
      '${flutterCache.path}/artifacts/material_fonts/materialicons-regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(iconBytes)))).load();
    productPhoto = MemoryImage(await File(_photoPath).readAsBytes());
  });

  testWidgets('actual full product page, XL selection and details at 390x844', (
    tester,
  ) async {
    final previousProducts = session.products;
    final previousCategories = session.categories;
    final previousCart = session.cartItems;
    final previousImageProvider = AppNetworkImage.debugImageProvider;
    final previousLanguage = appSettings.language;
    final previousPalette = AppColors.p;
    session.products = [_product];
    session.categories = const [
      Category(
        id: 'preview-clothing',
        nameAr: 'ملابس',
        icon: Icons.checkroom_outlined,
        imageUrl: _photoUrl,
      ),
    ];
    session.cartItems = [];
    appSettings.language = AppLanguage.ar;
    AppColors.p = AppPalette.light;
    AppNetworkImage.debugImageProvider = (_) => productPhoto;
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 24, bottom: 24)
      ..viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(() {
      session.products = previousProducts;
      session.categories = previousCategories;
      session.cartItems = previousCart;
      AppNetworkImage.debugImageProvider = previousImageProvider;
      appSettings.language = previousLanguage;
      AppColors.p = previousPalette;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.view.resetViewPadding();
    });

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: ProductDetailScreen(product: _product),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        productPhoto,
        tester.element(find.byType(ProductDetailScreen)),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text(_product.nameAr), findsOneWidget);
    expect(find.text(formatIqd(14000)), findsOneWidget);
    expect(find.text(formatIqd(20000)), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/clothing/full-product-top.png'),
    );

    // Scroll the actual screen and tap the production size selector.
    final mainScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    mainScroll.position.jumpTo(420);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('product_size_XL')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ProductSizeOptions>(find.byType(ProductSizeOptions))
          .selectedId,
      'preview-black-xl',
    );
    expect(
      find.textContaining(ProductStrings.variantInStock(formatNumber(5))),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/clothing/full-product-xl.png'),
    );
    mainScroll.position.jumpTo(mainScroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text(ProductStrings.descriptionTitle), findsOneWidget);
    expect(find.text(ProductStrings.downloadAndShareMedia), findsOneWidget);
    final downloadButton = tester.getRect(
      find.text(ProductStrings.downloadAndShareMedia),
    );
    expect(downloadButton.top, greaterThan(80));
    expect(
      downloadButton.bottom,
      lessThan(728),
      reason: 'Keep the last content action above the real sticky cart bar.',
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/clothing/full-product-details.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
