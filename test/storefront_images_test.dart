import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/storefront_models.dart';
import 'package:flutter_app/data/repositories/supabase_storefront_repository.dart';
import 'package:flutter_app/features/storefront/storefront_screen.dart';
import 'package:flutter_app/features/storefront/storefront_view_model.dart';
import 'package:flutter_app/features/storefront/storefront_image_picker.dart';
import 'storefront_test_support.dart';
import 'storefront_widgets_test.dart' show pumpStore;

void main() {
  testWidgets('deleted last image can be cleared without uploading anything', (
    tester,
  ) async {
    String? chosen = 'removed';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StorefrontImagePicker(
            title: 'الغلاف',
            images: const [],
            value: chosen,
            keyPrefix: 'missing',
            onChanged: (value) => chosen = value,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('missing_clear_missing')));
    expect(chosen, isNull);
  });
  setUpAll(() async {
    final arabic = FontLoader('Zain')
      ..addFont(rootBundle.load('assets/fonts/Zain-Regular.ttf'));
    await arabic.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File(
          'D:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    await icons.load();
  });
  test('owner DTO retains chosen media IDs, old DTO remains compatible', () {
    final parsed = parseStorefrontSnapshot({
      'storefront': {
        'id': 's',
        'items': [
          {
            'id': 'i',
            'variant_id': 'v',
            'sale_price': 15000,
            'image_media_id': 'photo1',
            'cover_media_id': 'photo2',
          },
          {'id': 'j', 'variant_id': 'w', 'sale_price': 15000},
        ],
      },
    });
    expect(parsed.listings.first.imageMediaId, 'photo1');
    expect(parsed.listings.first.coverMediaId, 'photo2');
    expect(parsed.listings.last.imageMediaId, isNull);
  });
  for (final layout in [
    (375.0, 844.0, 1.0, false),
    (844.0, 375.0, 2.0, true),
  ]) {
    testWidgets(
      'existing images selection, one price, save/reopen ${layout.$1}',
      (tester) async {
        final bytes = await tester.runAsync(
          () =>
              File('test/fixtures/product-images/product-1.jpg').readAsBytes(),
        );
        AppNetworkImage.debugImageProvider = (_) => MemoryImage(bytes!);
        addTearDown(() => AppNetworkImage.debugImageProvider = null);
        final product = Product(
          id: 'p',
          nameAr: 'ساعة الاختبار',
          categoryId: 'c',
          description: '',
          specs: const {},
          media: const [
            MediaItem(
              id: 'photo1',
              type: MediaType.image,
              url: 'https://fixture.invalid/1.jpg',
            ),
            MediaItem(
              id: 'photo2',
              type: MediaType.image,
              url: 'https://fixture.invalid/2.jpg',
            ),
            MediaItem(
              id: 'video',
              type: MediaType.video,
              url: 'https://fixture.invalid/movie.mp4',
            ),
          ],
          variants: const [
            ProductVariant(
              id: 'black',
              nameAr: 'أسود',
              imageUrl: '',
              stock: 10,
            ),
            ProductVariant(id: 'gold', nameAr: 'ذهبي', imageUrl: '', stock: 10),
          ],
          wholesalePrice: 7000,
          suggestedPrice: 18000,
          createdAt: DateTime.utc(2026),
        );
        final repo = TestStorefrontRepository(
          snapshot: StorefrontSnapshot(
            eligible: true,
            completedOrders: 10,
            store: testStore,
            listings: const [
              StoreListing(
                id: 'i',
                productId: 'p',
                variantId: 'black',
                retailPrice: 18000,
              ),
              StoreListing(
                id: 'j',
                productId: 'p',
                variantId: 'gold',
                retailPrice: 18000,
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
        Future<void> open() => pumpStore(
          tester,
          StorefrontScreen(product: product, viewModel: model),
          width: layout.$1,
          height: layout.$2,
          scale: layout.$3,
          dark: layout.$4,
        );
        Future<void> tapKey(String key) async {
          final target = find.byKey(ValueKey(key));
          if (target.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              target,
              160,
              scrollable: find.byType(Scrollable).first,
            );
          }
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.pumpAndSettle();
        }

        await open();
        await tapKey('storefront_image_choices');
        await tapKey('store_cover_media_photo2');
        await tapKey('store_variant_black_media_photo1');
        await tapKey('store_variant_gold_media_photo2');
        expect(
          find.byKey(const ValueKey('store_cover_media_video')),
          findsNothing,
        );
        await tapKey('save_storefront_listing');
        expect(repo.listingCalls, 1);
        expect(repo.current.listings.map((i) => i.retailPrice), [18000, 18000]);
        expect(repo.current.listings.map((i) => i.coverMediaId), [
          'photo2',
          'photo2',
        ]);
        expect(repo.current.listings.first.imageMediaId, 'photo1');
        expect(repo.current.listings.last.imageMediaId, 'photo2');
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await open();
        await tapKey('storefront_image_choices');
        final pickers = tester.widgetList<StorefrontImagePicker>(
          find.byType(StorefrontImagePicker),
        );
        expect(pickers.first.value, 'photo2');
        expect(pickers.map((p) => p.value), ['photo2', 'photo1', 'photo2']);
        await tester.ensureVisible(
          find.byKey(const ValueKey('store_cover_media_photo2')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('storefront_visual_surface')),
          matchesGoldenFile(
            'goldens/storefront-images-${layout.$1.toInt()}.png',
          ),
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
