import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/features/product/product_detail_screen.dart';

/// Most variants (sizes/colours) carry no dedicated photo, so the repository
/// maps them to an empty image URL. Selecting such a variant must keep showing
/// the product artwork instead of swapping it for the empty-URL placeholder.
void main() {
  final product = Product(
    id: 'product-1',
    nameAr: 'ساعة كلاسيكية',
    categoryId: 'category-1',
    description: 'وصف',
    specs: const {},
    media: const [
      MediaItem(
        id: 'cover',
        type: MediaType.image,
        url: 'https://example.test/cover.webp',
      ),
    ],
    variants: const [
      ProductVariant(
        id: 'variant-1',
        nameAr: 'أحمر',
        imageUrl: '',
        stock: 5,
      ),
    ],
    wholesalePrice: 1000,
    suggestedPrice: 1500,
    createdAt: DateTime(2026),
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    AppColors.p = AppPalette.light;
    addTearDown(() => AppColors.p = AppPalette.light);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        // The sticky call-to-action pushes routes; swallow them so a stray tap
        // surfaces as a test failure instead of an unhandled-route exception.
        onGenerateRoute: (settings) =>
            MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ProductDetailScreen(product: product),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
  }

  List<String> networkImageUrls(WidgetTester tester) => tester
      .widgetList<AppNetworkImage>(find.byType(AppNetworkImage))
      .map((image) => image.url)
      .toList();

  testWidgets('selecting an imageless variant keeps the product artwork', (
    tester,
  ) async {
    // Tall viewport so the gallery and the variant chip are laid out together:
    // scrolling would unmount the lazily built gallery and void the assertion.
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpScreen(tester);

    final gallery = find.byType(PageView);
    expect(gallery, findsOneWidget);
    expect(
      networkImageUrls(tester),
      contains('https://example.test/cover.webp'),
      reason: 'the gallery starts on the product image',
    );

    final variantChip = find.text('أحمر');
    expect(variantChip, findsOneWidget);
    await tester.tap(variantChip);
    // The shimmer placeholder animates forever, so settle with fixed pumps.
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    final urls = networkImageUrls(tester);
    expect(urls, isNotEmpty);
    expect(
      urls,
      contains('https://example.test/cover.webp'),
      reason: 'gallery must still render the product image',
    );
    expect(
      urls,
      isNot(contains('')),
      reason: 'no image may fall back to the empty-URL placeholder',
    );
  });
}
