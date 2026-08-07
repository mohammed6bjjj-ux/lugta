import 'dart:ui';

import 'package:flutter/material.dart';

/// لوحة ألوان كاملة — نسختان من هوية لُگطة الرسمية.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.gold,
    required this.goldDark,
    required this.goldSoft,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.success,
    required this.successSoft,
    required this.error,
    required this.errorSoft,
    required this.warning,
    required this.warningSoft,
    required this.info,
    required this.infoSoft,
    required this.neutralChip,
    required this.disabledFill,
    required this.glassFill,
    required this.glassBorder,
    required this.shadowBase,
  });

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color gold;
  final Color goldDark;
  final Color goldSoft;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color success;
  final Color successSoft;
  final Color error;
  final Color errorSoft;
  final Color warning;
  final Color warningSoft;
  final Color info;
  final Color infoSoft;
  final Color neutralChip;
  final Color disabledFill;
  final Color glassFill;
  final Color glassBorder;
  final Color shadowBase;

  /// اللوحة الفاتحة — حبر لُگطة، أخضر العلامة، والخلفية الكريمية.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF191713),
    onPrimary: Colors.white,
    gold: Color(0xFF1B9E6A),
    goldDark: Color(0xFF147B52),
    goldSoft: Color(0xFFE8F4EF),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF3EFE7),
    textPrimary: Color(0xFF191713),
    textSecondary: Color(0xFF6D6861),
    divider: Color(0xFFE8E3D7),
    success: Color(0xFF1B9E6A),
    successSoft: Color(0xFFE8F4EF),
    error: Color(0xFFD64545),
    errorSoft: Color(0xFFFBE9E9),
    warning: Color(0xFFE08F1F),
    warningSoft: Color(0xFFFCF1DF),
    info: Color(0xFF3B82C4),
    infoSoft: Color(0xFFE7F0F9),
    neutralChip: Color(0xFFEDE8DD),
    disabledFill: Color(0xFFD9D4C9),
    // شبه معتم — مظهر زجاجي خفيف بلا مفاجآت رندرة.
    glassFill: Color(0xF5FFFFFF),
    glassBorder: Color(0x8CFFFFFF),
    shadowBase: Color(0xFF191713),
  );

  /// اللوحة الداكنة — أسود دافئ بنفس أخضر العلامة.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    // في الداكن: الزر الرئيسي عاجي فاتح بنص داكن (انعكاس أنيق).
    primary: Color(0xFFFAF6ED),
    onPrimary: Color(0xFF191713),
    gold: Color(0xFF1B9E6A),
    goldDark: Color(0xFF59D29D),
    goldSoft: Color(0xFF15392B),
    background: Color(0xFF191713),
    surface: Color(0xFF23211D),
    surfaceAlt: Color(0xFF2D2A24),
    textPrimary: Color(0xFFFAF6ED),
    textSecondary: Color(0xFFB6AFA3),
    divider: Color(0xFF3B3730),
    success: Color(0xFF59D29D),
    successSoft: Color(0xFF15392B),
    error: Color(0xFFE36A6A),
    errorSoft: Color(0xFF33201F),
    warning: Color(0xFFE8A23D),
    warningSoft: Color(0xFF32291B),
    info: Color(0xFF6BA6E3),
    infoSoft: Color(0xFF1C2733),
    neutralChip: Color(0xFF333029),
    disabledFill: Color(0xFF48433A),
    // رصاصي داكن شبه معتم — أفتح قليلاً من الخلفية ليتمايز الشريط.
    glassFill: Color(0xF72D2A24),
    glassBorder: Color(0x1FFFFFFF),
    shadowBase: Colors.black,
  );
}

/// رموز الألوان الموحّدة — تقرأ من اللوحة الحالية [p] التي يبدّلها
/// جذر التطبيق عند تغيير الوضع الداكن. (الأسماء gold* تاريخية —
/// تحمل أخضر العلامة والكريمي، انظر هوية لُگطة.)
class AppColors {
  AppColors._();

  /// اللوحة الحالية — يضبطها جذر التطبيق قبل بناء الشجرة.
  static AppPalette p = AppPalette.light;

  static bool get isDark => p.brightness == Brightness.dark;

  static Color get primary => p.primary;
  static Color get onPrimary => p.onPrimary;
  static Color get gold => p.gold;
  static Color get onGold => Colors.white;
  static Color get goldDark => p.goldDark;
  static Color get goldSoft => p.goldSoft;
  static Color get background => p.background;
  static Color get surface => p.surface;
  static Color get surfaceAlt => p.surfaceAlt;
  static Color get textPrimary => p.textPrimary;
  static Color get textSecondary => p.textSecondary;
  static Color get divider => p.divider;
  static Color get success => p.success;
  static Color get successSoft => p.successSoft;
  static Color get error => p.error;
  static Color get errorSoft => p.errorSoft;
  static Color get warning => p.warning;
  static Color get warningSoft => p.warningSoft;
  static Color get info => p.info;
  static Color get infoSoft => p.infoSoft;
  static Color get neutralChip => p.neutralChip;

  /// كبسولة التبويب المختار في شريط التنقل السفلي:
  /// سوداء في الفاتح، ورصاصية فاتحة (لا بيضاء) في الداكن.
  static Color get selectedNavPill =>
      isDark ? const Color(0xFF3D372E) : p.primary;

  /// لون نص/أيقونة الكبسولة المختارة — أبيض في الوضعين
  /// (الكبسولة داكنة/رصاصية دائماً).
  static Color get onSelectedNavPill => isDark ? Colors.white : p.onPrimary;

  /// تعبئة خضراء مسطّحة. أبقينا النوع Gradient لتوافق المكوّنات الحالية.
  static LinearGradient get goldGradient => LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [p.gold, p.gold],
  );

  /// حبر العلامة المسطّح لبطاقات الرصيد والترويسات.
  static LinearGradient get darkGradient => const LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF191713), Color(0xFF191713)],
  );

  /// تدرج خفيف لخلفيات الشاشات.
  static LinearGradient get pageGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [p.surface, p.background],
  );
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
}

/// مدد وحركات موحّدة للأنيميشن.
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 450);
}

class AppCurves {
  AppCurves._();
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

/// ظلال ناعمة متكيفة مع الوضع (أقوى قليلاً في الداكن لتبقى محسوسة).
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.p.shadowBase.withValues(
        alpha: AppColors.isDark ? .4 : .05,
      ),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.p.shadowBase.withValues(
        alpha: AppColors.isDark ? .25 : .03,
      ),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get floating => [
    BoxShadow(
      color: AppColors.p.shadowBase.withValues(
        alpha: AppColors.isDark ? .55 : .14,
      ),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: AppColors.gold.withValues(alpha: .35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

/// انتقال صفحات حديث: تلاشٍ + انزلاق طفيف للأعلى + تكبير ناعم.
class _ModernPageTransitionsBuilder extends PageTransitionsBuilder {
  const _ModernPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppCurves.emphasized,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .04),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: .985, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _from(AppPalette.light);

  static ThemeData dark() => _from(AppPalette.dark);

  static ThemeData _from(AppPalette c) {
    final scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.gold,
      onSecondary: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      error: c.error,
      onError: Colors.white,
    );

    // خط الواجهة الرسمي مضمن محلياً كي لا يعتمد أول تشغيل على الشبكة.
    final typography = Typography.material2021();
    final base =
        (c.brightness == Brightness.dark ? typography.white : typography.black)
            .apply(
              fontFamily: 'IBMPlexSansArabic',
              bodyColor: c.textPrimary,
              displayColor: c.textPrimary,
            );

    final textTheme = base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.35,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.55),
      bodySmall: base.bodySmall?.copyWith(height: 1.5, color: c.textSecondary),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      // تعميم خط IBM Plex Sans Arabic الرسمي على كل نصوص الواجهة.
      fontFamily: 'IBMPlexSansArabic',
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _ModernPageTransitionsBuilder(),
          TargetPlatform.iOS: _ModernPageTransitionsBuilder(),
          TargetPlatform.windows: _ModernPageTransitionsBuilder(),
          TargetPlatform.macOS: _ModernPageTransitionsBuilder(),
          TargetPlatform.linux: _ModernPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          color: c.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.disabledFill,
          disabledForegroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          backgroundColor: c.surface,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: c.divider, width: 1.2),
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.goldDark,
          textStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.gold, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.error, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.neutralChip,
        selectedColor: c.primary,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: c.goldSoft,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c.goldDark
                : c.textSecondary,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.brightness == Brightness.dark
            ? c.surfaceAlt
            : c.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.brightness == Brightness.dark ? c.textPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.textPrimary,
        unselectedLabelColor: c.textSecondary,
        indicatorColor: c.gold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: textTheme.titleSmall,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg + 4),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: c.textPrimary),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.textSecondary,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
      ),
    );
  }
}

/// لوحة زجاجية مموّهة (Glassmorphism) — تتكيف مع الوضع الداكن.
class FrostedPanel extends StatelessWidget {
  const FrostedPanel({
    super.key,
    required this.child,
    this.borderRadius,
    this.fillAlpha,
    this.blur = 18,
  });

  final Widget child;
  final BorderRadius? borderRadius;

  /// شفافية التعبئة — الافتراضي من اللوحة الحالية.
  final double? fillAlpha;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.xl);
    final fill = fillAlpha == null
        ? AppColors.p.glassFill
        : (AppColors.isDark ? Colors.black : Colors.white).withValues(
            alpha: fillAlpha!,
          );
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: AppColors.p.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
