import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'rapid local setting changes persist only the latest generation',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'ar',
        'app_dark_mode': false,
      });
      appSettings.language = AppLanguage.ar;
      appSettings.darkMode = false;
      await appSettings.initialize();

      appSettings
        ..setLanguage(AppLanguage.ckb)
        ..setLanguage(AppLanguage.en)
        ..setDarkMode(true)
        ..setDarkMode(false)
        ..setDarkMode(true);
      await appSettings.persistenceSettled;

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('app_language'), 'en');
      expect(preferences.getBool('app_dark_mode'), isTrue);
    },
  );
}
