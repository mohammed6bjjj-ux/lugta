import 'dart:io';
import 'dart:async';
import 'package:flutter_app/data/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/storefront_models.dart';
import 'package:flutter_app/data/repositories/supabase_storefront_repository.dart';
import 'package:flutter_app/features/storefront/storefront_design_widgets.dart';
import 'package:flutter_app/features/storefront/storefront_screen.dart';
import 'package:flutter_app/features/storefront/storefront_widgets.dart';
import 'package:flutter_app/features/storefront/storefront_strings.dart';
import 'package:flutter_app/features/storefront/storefront_view_model.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'storefront_widgets_test.dart' show pumpStore;
import 'storefront_test_support.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Zain',
    )..addFont(rootBundle.load('assets/fonts/Zain-Regular.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(
          File(
            'D:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });
  const palettes = [
    StorePalette(
      id: 'ivory',
      name: 'عاجي',
      accent: '#66523d',
      background: '#faf8f3',
    ),
    StorePalette(
      id: 'forest',
      name: 'أخضر',
      accent: '#245a43',
      background: '#f4f8f5',
    ),
    StorePalette(
      id: 'navy',
      name: 'أزرق',
      accent: '#245284',
      background: '#f3f7fc',
    ),
    StorePalette(
      id: 'plum',
      name: 'بنفسجي',
      accent: '#674092',
      background: '#f8f4fc',
    ),
    StorePalette(
      id: 'rose',
      name: 'وردي',
      accent: '#923e5b',
      background: '#fdf4f5',
    ),
  ];
  test(
    'remote designs support future IDs and refreshed preview URLs; old DTO still parses',
    () {
      final data = {
        'designs': [
          {
            'id': 'new-design',
            'name': 'تصميم جديد',
            'renderer': 'theme8',
            'thumbnail_path': 'new.png',
            'preview_path': 'full.png',
            'palettes': [
              {
                'id': 'rose',
                'name': 'وردي',
                'tokens': {'accent': '#923e5b', 'bg': '#fdf4f5'},
              },
            ],
          },
        ],
      };
      final result = parseStorefrontSnapshot(
        data,
        designUrl: (p) => 'https://assets.test/$p',
      );
      expect(result.designs!.single.id, 'new-design');
      expect(
        result.designs!.single.thumbnailUrl,
        'https://assets.test/new.png',
      );
      expect(parseStorefrontSnapshot({}).designs, isNull);
      expect(parseStorefrontSnapshot({'designs': []}).designs, isEmpty);
      final draft = StorefrontDraft(themeId: 'new-design', paletteId: 'rose');
      expect(StorefrontDraft.fromJson(draft.toJson()).paletteId, 'rose');
    },
  );
  for (final config in [(375.0, 1.0, false), (844.0, 2.0, true)]) {
    testWidgets('five palettes and compact product management ${config.$1}', (
      tester,
    ) async {
      var choice = 'ivory', edits = 0, hides = 0;
      final bytes = await tester.runAsync(
        () => File('test/fixtures/product-images/product-1.jpg').readAsBytes(),
      );
      AppNetworkImage.debugImageProvider = (_) => MemoryImage(bytes!);
      addTearDown(() => AppNetworkImage.debugImageProvider = null);
      await pumpStore(
        tester,
        Scaffold(
          appBar: AppBar(title: const Text('إدارة متجري')),
          body: StatefulBuilder(
            builder: (context, setState) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                StorePalettePicker(
                  palettes: palettes,
                  value: choice,
                  onChanged: (p) => setState(() => choice = p),
                ),
                const SizedBox(height: 24),
                StorefrontProductTile(
                  name: 'أورينت معدن',
                  imageUrl: 'https://fixture.invalid/watch.jpg',
                  price: '20,000 د.ع',
                  variants: const ['فضي — وجه أبيض', 'ذهبي — وجه ذهبي'],
                  onEdit: () => edits++,
                  onRemove: () => hides++,
                ),
              ],
            ),
          ),
        ),
        width: config.$1,
        height: 900,
        scale: config.$2,
        dark: config.$3,
      );
      await tester.tap(find.byKey(const ValueKey('palette_rose')));
      await tester.pumpAndSettle();
      expect(choice, 'rose');
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('palette_rose')))
            .selected,
        isTrue,
      );
      await tester.ensureVisible(find.text('تعديل المنتج'));
      await tester.tap(find.text('تعديل المنتج'));
      expect(edits, 1);
      await tester.tap(find.text('إخفاء'));
      expect(hides, 1);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('storefront_visual_surface')),
        matchesGoldenFile(
          'goldens/storefront/design-management-${config.$1.toInt()}.png',
        ),
      );
    });
  }
  testWidgets(
    'remote palette flow preserves choice on reselect and saves once',
    (tester) async {
      final repo = TestStorefrontRepository(
        snapshot: StorefrontSnapshot(
          eligible: true,
          completedOrders: 10,
          store: testStore,
          designs: [
            StoreTheme(
              id: 'theme1',
              name: 'تصميم عن بُعد',
              thumbnailAsset: 'assets/storefronts/theme-1-thumb.png',
              previewAsset: 'assets/storefronts/theme-1-full.png',
              palettes: palettes,
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
      await pumpStore(
        tester,
        StorefrontScreen(viewModel: model),
        width: 375,
        height: 1100,
      );
      await tester.tap(find.text(StorefrontStrings.edit));
      await tester.pumpAndSettle();
      expect(find.byType(StorePalettePicker), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('palette_navy')));
      await tester.pumpAndSettle();
      expect(model.draft.paletteId, 'navy');
      await tester.tap(find.text(StorefrontStrings.themes));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(StorefrontStrings.selected));
      await tester.tap(find.text(StorefrontStrings.selected));
      await tester.pumpAndSettle();
    expect(model.draft.paletteId, 'navy');
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('palette_navy')))
          .selected,
      isTrue,
    );
    final imageContext = tester.element(find.byType(Image).first);
    final previewImages = tester.widgetList<Image>(find.byType(Image)).toList();
    await tester.runAsync(() async {
      for (final image in previewImages) {
        await precacheImage(image.image, imageContext);
      }
    });
    await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('storefront_visual_surface')),
        matchesGoldenFile('goldens/storefront/remote-palette-setup-phone.png'),
      );
      repo.mutationGate = Completer<void>();
      await tester.ensureVisible(find.text(StorefrontStrings.save));
      await tester.tap(find.text(StorefrontStrings.save));
      await tester.pump();
      expect(repo.saveCalls, 1);
      expect(repo.lastSavedDraft?.themeId, 'theme1');
      expect(repo.lastSavedDraft?.paletteId, 'navy');
      // A second gesture while pending must not submit a second mutation.
      await tester.tap(find.byType(StorefrontAction).last);
      await tester.pump();
      expect(repo.saveCalls, 1);
      repo.mutationGate!.complete();
      await tester.pumpAndSettle();
      expect(model.snapshot!.store!.paletteId, 'navy');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'empty remote catalog refreshes new design without a phone update',
    (tester) async {
      final repo = TestStorefrontRepository(
        snapshot: StorefrontSnapshot(
          eligible: true,
          completedOrders: 10,
          designs: const [],
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
        width: 320,
        scale: 2,
      );
      expect(find.textContaining('لا توجد تصاميم'), findsOneWidget);
      expect(find.byType(StoreThemeCard), findsNothing);
      repo.current = StorefrontSnapshot(
        eligible: true,
        completedOrders: 10,
        designs: [
          StoreTheme(
            id: 'new-after-install',
            name: 'تصميم أضيف لاحقاً',
            thumbnailAsset: 'assets/storefronts/theme-2-thumb.png',
            previewAsset: 'assets/storefronts/theme-2-full.png',
            palettes: palettes,
          ),
        ],
      );
      await tester.ensureVisible(find.text('تحديث التصاميم'));
      await tester.tap(find.text('تحديث التصاميم'));
      await tester.pumpAndSettle();
      expect(find.byType(StoreThemeCard), findsOneWidget);
      expect(find.textContaining('لا توجد تصاميم'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('remote odd-sized gallery renders last item at tablet width', (
    tester,
  ) async {
    final repo = TestStorefrontRepository(
      snapshot: StorefrontSnapshot(
        eligible: true,
        completedOrders: 10,
        designs: [
          for (var n = 1; n <= 3; n++)
            StoreTheme(
              id: 'remote$n',
              name: 'قالب $n',
              thumbnailAsset: 'assets/storefronts/theme-1-thumb.png',
              previewAsset: 'assets/storefronts/theme-1-full.png',
              palettes: palettes,
            ),
        ],
      ),
    );
    final model = StorefrontViewModel(
      repository: repo,
      drafts: MemoryStorefrontDrafts(),
      isCurrentUser: () => true,
    );
    await pumpStore(
      tester,
      StorefrontScreen(viewModel: model),
      width: 844,
      height: 1300,
    );
    await tester.scrollUntilVisible(find.text('قالب 3'), 400);
    expect(tester.takeException(), isNull);
    expect(find.text('قالب 3'), findsOneWidget);
  });
  testWidgets('missing cache product still has name and edit control', (
    tester,
  ) async {
    final bytes = await tester.runAsync(
      () => File('test/fixtures/product-images/product-1.jpg').readAsBytes(),
    );
    AppNetworkImage.debugImageProvider = (_) => MemoryImage(bytes!);
    addTearDown(() => AppNetworkImage.debugImageProvider = null);
    final repo = TestStorefrontRepository(
      snapshot: StorefrontSnapshot(
        eligible: true,
        completedOrders: 10,
        store: testStore,
        listings: const [
          StoreListing(
            id: 'listing',
            productId: 'not-cached',
            variantId: 'variant',
            retailPrice: 20000,
            productName: 'أورينت معدن',
            variantName: 'فضي',
            imageUrl: 'https://fixture.invalid/watch.jpg',
          ),
        ],
      ),
    );
    final model = StorefrontViewModel(
      repository: repo,
      drafts: MemoryStorefrontDrafts(),
      isCurrentUser: () => true,
    );
    final pending = Completer<Product>();
    var fetches = 0;
    await pumpStore(
      tester,
      StorefrontScreen(
        viewModel: model,
        refreshProduct: (_) {
          fetches++;
          return pending.future;
        },
      ),
      height: 1200,
    );
    expect(find.text('أورينت معدن'), findsOneWidget);
    expect(find.text('تعديل المنتج'), findsOneWidget);
    await expectLater(
      find.byKey(const ValueKey('storefront_visual_surface')),
      matchesGoldenFile('goldens/storefront/manage-phone.png'),
    );
    await tester.tap(find.text('تعديل المنتج'));
    await tester.pump();
    expect(find.text('جارٍ التحميل…'), findsOneWidget);
    await tester.tap(find.text('جارٍ التحميل…'));
    expect(fetches, 1);
    await expectLater(
      find.byKey(const ValueKey('storefront_visual_surface')),
      matchesGoldenFile('goldens/storefront/manage-loading-phone.png'),
    );
    pending.completeError(Exception('offline fixture'));
    await tester.pumpAndSettle();
    expect(find.text('تعديل المنتج'), findsOneWidget);
  });
}
