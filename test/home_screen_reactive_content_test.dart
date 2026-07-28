import 'package:flutter/material.dart';
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
      find.byWidgetPredicate(
        (widget) =>
            widget is AppNetworkImage &&
            widget.fallbackIcon == category.icon &&
            widget.url.isEmpty,
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
