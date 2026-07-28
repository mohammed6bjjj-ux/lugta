import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// اللغة الكوردية السورانية (ckb) غير مدعومة في ترجمات Material الرسمية،
/// فنوفّر لها Delegates تعيد نصوص Material/Widgets/Cupertino العربية —
/// نفس الاتجاه RTL ونفس الحرف، بينما نصوص التطبيق نفسها كوردية كاملة
/// من نظام النصوص الخاص بنا.
class CkbMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const CkbMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(CkbMaterialLocalizationsDelegate old) => false;
}

class CkbWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const CkbWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(CkbWidgetsLocalizationsDelegate old) => false;
}

class CkbCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const CkbCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(CkbCupertinoLocalizationsDelegate old) => false;
}
