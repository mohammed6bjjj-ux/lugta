import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_app/core/widgets/product_card.dart';
import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/catalog/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
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
      zainRegular.load(),
      zainBold.load(),
      materialIcons.load(),
    ]);
  });

  const category = Category(
    id: 'reactive-category',
    nameAr: 'Reactive category',
    nameEn: 'Reactive category',
    icon: Icons.category_outlined,
    imageUrl: '',
  );
  const banner = PromoBanner(
    id: 'reactive-banner',
    imageUrl: '',
    title: 'Reactive banner',
  );
  setUp(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
    session.categories = [];
    session.banners = [];
    session.products = [];
  });

  tearDown(() async {
    session.categories = List.of(MockData.categories);
    session.banners = List.of(MockData.banners);
    session.products = List.of(MockData.products);
    await session.configure(createDemoRepositories(), loadInitialData: false);
  });

  testWidgets('late catalog content rebuilds banners and categories', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const HomeScreen()));

    expect(find.text(banner.title), findsNothing);
    expect(find.text(category.nameAr), findsNothing);

    session.banners = const [banner];
    session.categories = const [category];
    await tester.runAsync(
      () => session.configure(createDemoRepositories(), loadInitialData: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(banner.title), findsOneWidget);
    expect(find.text(category.nameAr), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-category-reactive-category')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-category-art-reactive-category')),
      findsOneWidget,
    );
    expect(find.byIcon(category.icon), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('category rail stays readable with many items at 200% text', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    session.categories = List.generate(
      8,
      (index) => Category(
        id: 'category-$index',
        nameAr: 'تصنيف ساعات باسم طويل $index',
        icon: index.isEven ? Icons.watch_rounded : Icons.diamond_outlined,
        imageUrl: '',
      ),
    );

    await tester.pumpWidget(
      _testApp(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(tester.takeException(), isNull);
    final first = find.byKey(const ValueKey('home-category-category-0'));
    final second = find.byKey(const ValueKey('home-category-category-1'));
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(tester.getSize(first).width, inInclusiveRange(104, 136));
    expect(tester.getSize(first).height, greaterThanOrEqualTo(48));
    expect(
      tester.getTopLeft(first).dx,
      greaterThan(tester.getTopLeft(second).dx),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'تصنيف ساعات باسم طويل 0' &&
            widget.properties.button == true,
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('category cards keep Lugta identity when artwork is missing', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    session.categories = const [
      Category(
        id: 'men-watches',
        nameAr: 'ساعات رجالية',
        icon: Icons.watch_rounded,
        imageUrl: '',
        stickerKey: CategoryStickerKey.premium,
      ),
      Category(
        id: 'women-watches',
        nameAr: 'ساعات نسائية',
        icon: Icons.watch_outlined,
        imageUrl: '',
        stickerKey: CategoryStickerKey.favorite,
      ),
      Category(
        id: 'smart-watches',
        nameAr: 'ساعات ذكية',
        icon: Icons.watch_outlined,
        imageUrl: '',
      ),
      Category(
        id: 'glasses',
        nameAr: 'نظارات',
        icon: Icons.visibility_outlined,
        imageUrl: '',
        stickerKey: CategoryStickerKey.none,
      ),
    ];

    await tester.pumpWidget(
      _testApp(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('home-category-sticker-men-watches-premium')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-category-sticker-glasses-none')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('home-category-sticker-smart-watches-auto')),
      findsOneWidget,
    );
    await expectLater(
      find.byKey(const ValueKey('home-category-list')),
      matchesGoldenFile('goldens/lugta/home-categories-fallback-light.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('selected sticker overlays a category network image', (
    tester,
  ) async {
    session.categories = const [
      Category(
        id: 'category-with-image',
        nameAr: 'هدايا',
        icon: Icons.redeem_rounded,
        imageUrl: 'https://example.invalid/category.png',
        stickerKey: CategoryStickerKey.gift,
      ),
    ];

    await tester.pumpWidget(_testApp(const HomeScreen()));
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('home-category-sticker-category-with-image-gift'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  // Superseded intent: the card used to contain the photo so nothing was ever
  // cropped, but catalog photos arrive in mixed aspect ratios, so each tile
  // ended up with a different band of empty surface and the grid read as
  // ragged. Uniform tiles were chosen over never cropping.
  testWidgets('product cards fill their tile so the grid stays uniform', (
    tester,
  ) async {
    final source = MockData.products.first;
    final product = Product(
      id: source.id,
      nameAr: source.nameAr,
      categoryId: source.categoryId,
      description: source.description,
      specs: source.specs,
      media: const [],
      variants: source.variants,
      wholesalePrice: source.wholesalePrice,
      suggestedPrice: source.suggestedPrice,
      createdAt: source.createdAt,
    );
    await tester.pumpWidget(
      _testApp(
        Center(
          child: SizedBox(
            width: ProductCard.horizontalWidth,
            height: ProductCard.horizontalHeight,
            child: ProductCard(product: product),
          ),
        ),
      ),
    );

    final image = tester.widget<AppNetworkImage>(
      find.byWidgetPredicate(
        (widget) =>
            widget is AppNetworkImage && widget.url == product.coverImage,
      ),
    );
    expect(image.fit, BoxFit.cover);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _testApp(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light(),
  onGenerateRoute: AppRouter.onGenerateRoute,
  home: home,
);
