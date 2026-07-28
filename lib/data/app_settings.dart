import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// لغات التطبيق المدعومة.
enum AppLanguage { ar, ckb, en }

extension AppLanguageX on AppLanguage {
  Locale get locale => switch (this) {
    AppLanguage.ar => const Locale('ar'),
    AppLanguage.ckb => const Locale('ckb'),
    AppLanguage.en => const Locale('en'),
  };

  /// اسم اللغة بلغتها نفسها — لعرضه في شاشة الإعدادات.
  String get nativeName => switch (this) {
    AppLanguage.ar => 'العربية',
    AppLanguage.ckb => 'کوردیی سۆرانی',
    AppLanguage.en => 'English',
  };

  bool get isRtl => this != AppLanguage.en;
}

/// إعدادات التطبيق الحية (اللغة والوضع الداكن) — ChangeNotifier يعيد بناء
/// التطبيق من جذره عند أي تغيير. تُحفظ محلياً لاحقاً عند الربط.
class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  AppLanguage language = AppLanguage.ar;
  bool darkMode = false;

  static const _languageKey = 'app_language';
  static const _darkModeKey = 'app_dark_mode';

  Future<void>? _initialization;
  Future<void> _persistenceTail = Future<void>.value();
  int _languageGeneration = 0;
  int _darkModeGeneration = 0;

  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> get persistenceSettled => _persistenceTail;

  /// بصمة الإعدادات الحالية — يستخدمها الراوتر لإعادة بناء كل الشاشات
  /// المفتوحة من الصفر فور تغيير اللغة أو الوضع الداكن.
  String get stamp => '${language.name}-$darkMode';

  Future<void> initialize() {
    final current = _initialization;
    if (current != null) return current;
    final next = _loadPersistedSettings();
    _initialization = next;
    return next;
  }

  Future<void> _loadPersistedSettings() async {
    final languageGeneration = _languageGeneration;
    final darkModeGeneration = _darkModeGeneration;
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(_languageKey);
    final loadedLanguage = AppLanguage.values.firstWhere(
      (value) => value.name == savedLanguage,
      orElse: () => AppLanguage.ar,
    );
    final loadedDarkMode = preferences.getBool(_darkModeKey) ?? false;
    var changed = false;
    if (languageGeneration == _languageGeneration &&
        language != loadedLanguage) {
      language = loadedLanguage;
      changed = true;
    }
    if (darkModeGeneration == _darkModeGeneration &&
        darkMode != loadedDarkMode) {
      darkMode = loadedDarkMode;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void setLanguage(AppLanguage value) {
    if (language == value) return;
    language = value;
    final generation = ++_languageGeneration;
    notifyListeners();
    unawaited(
      _enqueuePersistence(() async {
        if (generation != _languageGeneration) return;
        final preferences = await SharedPreferences.getInstance();
        if (generation != _languageGeneration) return;
        await preferences.setString(_languageKey, value.name);
      }),
    );
  }

  void setDarkMode(bool value) {
    if (darkMode == value) return;
    darkMode = value;
    final generation = ++_darkModeGeneration;
    notifyListeners();
    unawaited(
      _enqueuePersistence(() async {
        if (generation != _darkModeGeneration) return;
        final preferences = await SharedPreferences.getInstance();
        if (generation != _darkModeGeneration) return;
        await preferences.setBool(_darkModeKey, value);
      }),
    );
  }

  Future<void> _enqueuePersistence(Future<void> Function() operation) {
    final previous = _persistenceTail;
    final next = () async {
      try {
        await previous;
      } catch (_) {
        // One storage failure must not poison later setting writes.
      }
      await operation();
    }();
    _persistenceTail = next;
    return next;
  }
}

/// اختصار عام للوصول للإعدادات من أي مكان.
final AppSettings appSettings = AppSettings.instance;
