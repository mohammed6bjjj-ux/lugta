import 'package:intl/intl.dart';

import '../data/app_settings.dart';

final NumberFormat _thousands = NumberFormat('#,###', 'en_US');

String get _currency => switch (appSettings.language) {
  AppLanguage.ar => 'د.ع',
  AppLanguage.ckb => 'د.ع',
  AppLanguage.en => 'IQD',
};

/// تنسيق مبلغ بالدينار العراقي بلغة التطبيق: 64,000 د.ع / 64,000 IQD
String formatIqd(num value) => '${_thousands.format(value)} $_currency';

/// تنسيق رقم بفواصل الآلاف بدون عملة.
String formatNumber(num value) => _thousands.format(value);

const List<String> _arMonths = [
  'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
  'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول', //
];

const List<String> _ckbMonths = [
  'کانوونی دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران',
  'تەممووز',
  'ئاب',
  'ئەیلوول',
  'تشرینی یەکەم',
  'تشرینی دووەم',
  'کانوونی یەکەم', //
];

const List<String> _enMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

String _month(int m) => switch (appSettings.language) {
  AppLanguage.ar => _arMonths[m - 1],
  AppLanguage.ckb => _ckbMonths[m - 1],
  AppLanguage.en => _enMonths[m - 1],
};

/// تاريخ مقروء بلغة التطبيق: 18 تموز 2026 / 18 Jul 2026
String formatDate(DateTime d) => switch (appSettings.language) {
  AppLanguage.en => '${_month(d.month)} ${d.day}, ${d.year}',
  _ => '${d.day} ${_month(d.month)} ${d.year}',
};

/// تاريخ ووقت.
String formatDateTime(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final period = switch (appSettings.language) {
    AppLanguage.ar => d.hour >= 12 ? 'م' : 'ص',
    AppLanguage.ckb => d.hour >= 12 ? 'د.ن' : 'پ.ن',
    AppLanguage.en => d.hour >= 12 ? 'PM' : 'AM',
  };
  final minutes = d.minute.toString().padLeft(2, '0');
  return '${formatDate(d)} — $hour12:$minutes $period';
}

/// وقت نسبي بلغة التطبيق: منذ 5 دقائق / ٥ خولەک لەمەوبەر / 5m ago
String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  return switch (appSettings.language) {
    AppLanguage.ar => _timeAgoAr(diff, d),
    AppLanguage.ckb => _timeAgoCkb(diff, d),
    AppLanguage.en => _timeAgoEn(diff, d),
  };
}

String _timeAgoAr(Duration diff, DateTime d) {
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    if (m == 1) return 'منذ دقيقة';
    if (m == 2) return 'منذ دقيقتين';
    if (m <= 10) return 'منذ $m دقائق';
    return 'منذ $m دقيقة';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    if (h == 1) return 'منذ ساعة';
    if (h == 2) return 'منذ ساعتين';
    if (h <= 10) return 'منذ $h ساعات';
    return 'منذ $h ساعة';
  }
  final days = diff.inDays;
  if (days == 1) return 'منذ يوم';
  if (days == 2) return 'منذ يومين';
  if (days <= 10) return 'منذ $days أيام';
  if (days < 30) return 'منذ $days يوماً';
  return formatDate(d);
}

String _timeAgoCkb(Duration diff, DateTime d) {
  if (diff.inMinutes < 1) return 'ئێستا';
  if (diff.inMinutes < 60) return '${diff.inMinutes} خولەک لەمەوبەر';
  if (diff.inHours < 24) return '${diff.inHours} کاتژمێر لەمەوبەر';
  final days = diff.inDays;
  if (days < 30) return '$days ڕۆژ لەمەوبەر';
  return formatDate(d);
}

String _timeAgoEn(Duration diff, DateTime d) {
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  final days = diff.inDays;
  if (days == 1) return 'yesterday';
  if (days < 30) return '$days days ago';
  return formatDate(d);
}

String _t(String ar, String ckb, String en) => switch (appSettings.language) {
  AppLanguage.ar => ar,
  AppLanguage.ckb => ckb,
  AppLanguage.en => en,
};

/// تحقق من رقم هاتف عراقي بصيغة 07XXXXXXXXX (11 خانة).
String? validateIraqiPhone(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) {
    return _t(
      'رقم الهاتف مطلوب',
      'ژمارەی مۆبایل پێویستە',
      'Phone number is required',
    );
  }
  if (!RegExp(r'^07[0-9]{9}$').hasMatch(v)) {
    return _t(
      'أدخل رقماً عراقياً صحيحاً يبدأ بـ 07 (11 خانة)',
      'ژمارەیەکی عێراقی دروست بنووسە کە بە 07 دەست پێ دەکات (11 ژمارە)',
      'Enter a valid Iraqi number starting with 07 (11 digits)',
    );
  }
  return null;
}

/// تحقق من حقل نصي إلزامي.
String? validateRequired(String? value, {String? message}) {
  if ((value ?? '').trim().isEmpty) {
    return message ??
        _t('هذا الحقل مطلوب', 'ئەم خانەیە پێویستە', 'This field is required');
  }
  return null;
}

/// Login accepts existing accounts regardless of their historical password
/// length. Password strength is enforced only when creating or resetting it.
String? validateLoginPassword(String? value) {
  final raw = value ?? '';
  if (raw.trim().isEmpty) {
    return _t(
      'كلمة المرور مطلوبة',
      'وشەی نهێنی پێویستە',
      'Password is required',
    );
  }
  if (raw != raw.trim()) {
    return _t(
      'لا تضع مسافة في بداية أو نهاية كلمة المرور',
      'لە سەرەتا یان کۆتایی وشەی نهێنی بۆشایی مەهێڵە',
      'Do not add spaces before or after the password',
    );
  }
  return null;
}

/// تحقق من كلمة المرور (8 خانات فأكثر)، بما يطابق سياسة الخادم.
String? validatePassword(String? value) {
  final requiredError = validateLoginPassword(value);
  if (requiredError != null) return requiredError;
  final raw = value!;
  if (raw.length < 8) {
    return _t(
      'كلمة المرور 8 خانات على الأقل',
      'وشەی نهێنی بەلایەنی کەمەوە 8 پیت بێت',
      'Password must be at least 8 characters',
    );
  }
  return null;
}
