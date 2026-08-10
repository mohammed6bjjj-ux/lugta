import 'package:flutter/services.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/widgets/brand_logo.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/features/auth/auth_strings.dart';
import 'package:flutter_app/l10n/core_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('official Lugta names, tagline, and palette stay exact', () {
    final previousLanguage = appSettings.language;
    addTearDown(() => appSettings.language = previousLanguage);

    appSettings.language = AppLanguage.ar;
    expect(CoreStrings.appTitle, 'لكطة');
    expect(AuthStrings.splashTagline, 'كل يوم لكطة جديدة');

    appSettings.language = AppLanguage.en;
    expect(CoreStrings.appTitle, 'Lugta');
    expect(AuthStrings.splashTagline, 'A new find every day');

    expect(AppPalette.light.primary.toARGB32(), 0xFF37379B);
    expect(AppPalette.light.accent.toARGB32(), 0xFFFCC803);
    expect(AppPalette.light.surface.toARGB32(), 0xFFFFFFFF);
  });

  testWidgets('official brand artwork is bundled', (tester) async {
    for (final asset in [
      BrandAssets.icon,
      BrandAssets.appIcon,
      BrandAssets.wordmarkInk,
      BrandAssets.wordmarkWhite,
      BrandAssets.wordmarkMono,
    ]) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(1000), reason: asset);
    }
  });
}
