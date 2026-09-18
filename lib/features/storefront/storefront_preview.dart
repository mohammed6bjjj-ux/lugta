import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../app/theme.dart';
import '../../data/storefront_models.dart';
import 'storefront_widgets.dart';
import 'storefront_design_widgets.dart';
import 'storefront_strings.dart';
import '../../data/models.dart';
import 'storefront_image_picker.dart';
import 'storefront_request_details.dart';

@Preview(
  name: 'Website order product row',
  group: 'Storefront',
  size: Size(375, 230),
)
Widget storefrontRequestItemPreview() => MaterialApp(
  theme: AppTheme.light(),
  home: const Scaffold(
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: StorefrontRequestItemRow(
          item: StorefrontRequestItem(
            productName: 'ساعة نسائية — معاينة',
            variantName: 'أسود',
            quantity: 2,
            unitSalePrice: 20000,
          ),
        ),
      ),
    ),
  ),
);

@Preview(
  name: 'Store product management',
  group: 'Storefront',
  size: Size(375, 420),
)
Widget storefrontManagementTilePreview() => MaterialApp(
  home: Scaffold(
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StorefrontProductTile(
          name: 'ساعة نسائية',
          imageUrl: '',
          price: '20,000 د.ع',
          variants: const ['فضي', 'ذهبي'],
          onEdit: () {},
          onRemove: () {},
        ),
      ),
    ),
  ),
);

@Preview(
  name: 'Existing product images — empty state',
  group: 'Storefront',
  size: Size(375, 300),
)
Widget storefrontImagesPreview() => MaterialApp(
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: StatefulBuilder(
        builder: (context, setState) => StorefrontImagePicker(
          title: 'صورة غلاف المنتج',
          images: const <MediaItem>[],
          value: null,
          keyPrefix: 'preview_cover',
          onChanged: (_) {},
        ),
      ),
    ),
  ),
);

@Preview(
  name: 'Add product — pending and saved action',
  group: 'Storefront',
  size: Size(320, 520),
)
Widget storefrontSaveActionPreview() => const StorefrontSaveActionFixture();

@Preview(
  name: 'Manage existing listing — edit and remove',
  group: 'Storefront',
  size: Size(375, 650),
)
Widget storefrontEditActionPreview() =>
    const StorefrontSaveActionFixture(editing: true);

/// Network-free preview of the actual shared submission control. Complete
/// screen/creation behavior is covered by storefront_widgets_test.dart.
class StorefrontSaveActionFixture extends StatefulWidget {
  const StorefrontSaveActionFixture({super.key, this.editing = false});
  final bool editing;
  @override
  State<StorefrontSaveActionFixture> createState() =>
      _StorefrontSaveActionFixtureState();
}

class _StorefrontSaveActionFixtureState
    extends State<StorefrontSaveActionFixture> {
  bool selected = false;
  bool loading = false;
  bool saved = false;
  bool removed = false;
  bool changed = false;

  Future<void> submit() async {
    setState(() => loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      loading = false;
      saved = true;
      removed = false;
      changed = false;
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.editing && !removed) ...[
              Text(StorefrontStrings.listingHelp),
              TextFormField(
                initialValue: '23000',
                decoration: InputDecoration(labelText: StorefrontStrings.price),
                onChanged: (_) => setState(() {
                  changed = true;
                  saved = false;
                }),
              ),
              const SizedBox(height: 20),
            ],
            Text(StorefrontStrings.savedWhilePaused),
            const SizedBox(height: 20),
            ChoiceChip(
              label: const Text('أسود / XL'),
              selected: selected,
              onSelected: loading
                  ? null
                  : (value) => setState(() {
                      selected = value;
                      saved = false;
                    }),
            ),
            const SizedBox(height: 20),
            StorefrontAction(
              label: saved
                  ? StorefrontStrings.added
                  : widget.editing && !removed
                  ? StorefrontStrings.save
                  : StorefrontStrings.addProduct,
              loading: loading,
              onPressed:
                  (widget.editing && !removed ? changed : selected && !saved)
                  ? submit
                  : null,
            ),
            if (widget.editing && !removed) ...[
              const SizedBox(height: 16),
              StorefrontRemoveAction(
                onPressed: loading
                    ? null
                    : () => setState(() {
                        removed = true;
                        saved = false;
                      }),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

@Preview(
  name: 'Permanent activation — Arabic',
  group: 'Storefront',
  size: Size(320, 420),
)
Widget storefrontPermanentActivationPreview() {
  var active = false;
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  active ? StorefrontStrings.active : StorefrontStrings.paused,
                ),
                const SizedBox(height: 12),
                Text(StorefrontStrings.activationBody),
                const SizedBox(height: 20),
                StorefrontAction(
                  label: active
                      ? 'إيقاف المتجر مؤقتاً'
                      : StorefrontStrings.activate,
                  onPressed: () => setState(() => active = !active),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

@Preview(
  name: 'Store theme — Arabic phone',
  group: 'Storefront',
  size: Size(375, 860),
)
Widget storefrontThemePreview() => const StorefrontThemeFixture();

@Preview(
  name: 'Store theme — 320dp dark 200%',
  group: 'Storefront',
  size: Size(320, 960),
)
Widget storefrontThemeLargePreview() =>
    const StorefrontThemeFixture(dark: true, textScale: 2);

class StorefrontThemeFixture extends StatelessWidget {
  const StorefrontThemeFixture({
    super.key,
    this.dark = false,
    this.textScale = 1,
  });
  final bool dark;
  final double textScale;
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: dark ? AppTheme.dark() : AppTheme.light(),
    home: Scaffold(
      body: Builder(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: ListView(
              padding: const EdgeInsetsDirectional.all(16),
              children: [
                const StorefrontSetupProgress(step: 1),
                const SizedBox(height: 16),
                StoreThemeCard(
                  theme: const StoreTheme(
                    id: 'theme1',
                    name: 'القالب الأول',
                    thumbnailAsset: 'assets/storefronts/theme-1-thumb.png',
                    previewAsset: 'assets/storefronts/theme-1-full.png',
                  ),
                  selected: true,
                  onSelect: () {},
                  onPreview: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const StoreThemePreviewScreen(
                        theme: StoreTheme(
                          id: 'theme1',
                          name: 'القالب الأول',
                          thumbnailAsset:
                              'assets/storefronts/theme-1-thumb.png',
                          previewAsset: 'assets/storefronts/theme-1-full.png',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
