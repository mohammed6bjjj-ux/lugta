/*
THESIS: Lugta turns a dense reseller workflow into one bright, legible path; it refuses the previous green/cream visual world and generic card decoration.
OWN-WORLD: PDF-authored royal purple, vivid yellow, white/lavender working surfaces, Zain type, compact rounded geometry, and the smiling bag mark.
STORY: Sellers discover a product, understand price and profit, submit delivery details, and follow the order without losing context.
FIRST VIEWPORT: A clear task title and high-value action lead; operational content stays above an ergonomic branded navigation dock.
FORM: User-pinned Lugta identity, Operate mode, seed e3218c44.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md
*/

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Lugta's complete colour system.
///
/// The two brand colours are fixed by the supplied identity. Semantic colours
/// remain deliberately independent so success, warning, and error never rely
/// on purple/yellow alone.
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.accentStrong,
    required this.accentSoft,
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
    required this.navigation,
    required this.shadowBase,
  });

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color onAccent;
  final Color accentStrong;
  final Color accentSoft;
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
  final Color navigation;
  final Color shadowBase;

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF37379B),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFFCC803),
    onAccent: Color(0xFF201D12),
    // Contrast-safe yellow ink for text/icons on pale yellow surfaces.
    accentStrong: Color(0xFF6A5600),
    accentSoft: Color(0xFFFFF4BF),
    background: Color(0xFFF8F8FD),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0EFF9),
    textPrimary: Color(0xFF202035),
    textSecondary: Color(0xFF67667A),
    divider: Color(0xFFE2E1EE),
    success: Color(0xFF167A52),
    successSoft: Color(0xFFE4F4EC),
    error: Color(0xFFC53D4B),
    errorSoft: Color(0xFFFCE9EC),
    warning: Color(0xFF9A5A00),
    warningSoft: Color(0xFFFFF0D2),
    info: Color(0xFF3566C2),
    infoSoft: Color(0xFFE8EFFC),
    neutralChip: Color(0xFFECEBF5),
    disabledFill: Color(0xFFD8D7E3),
    navigation: Color(0xFFFFFFFF),
    shadowBase: Color(0xFF24213B),
  );

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFFBEB8FF),
    onPrimary: Color(0xFF19162E),
    accent: Color(0xFFFCCD27),
    onAccent: Color(0xFF211D0B),
    accentStrong: Color(0xFFFFDC55),
    accentSoft: Color(0xFF3B3210),
    background: Color(0xFF11111A),
    surface: Color(0xFF191925),
    surfaceAlt: Color(0xFF242438),
    textPrimary: Color(0xFFF6F5FC),
    textSecondary: Color(0xFFBDBBCC),
    divider: Color(0xFF37364A),
    success: Color(0xFF62CEA0),
    successSoft: Color(0xFF15372A),
    error: Color(0xFFFF7C88),
    errorSoft: Color(0xFF401F26),
    warning: Color(0xFFFFBE5C),
    warningSoft: Color(0xFF3C2D16),
    info: Color(0xFF8DB4FF),
    infoSoft: Color(0xFF1C2B49),
    neutralChip: Color(0xFF2B2A40),
    disabledFill: Color(0xFF464559),
    navigation: Color(0xFF1E1D2D),
    shadowBase: Color(0xFF000000),
  );
}

/// Semantic access to the active palette.
abstract final class AppColors {
  static AppPalette p = AppPalette.light;

  static bool get isDark => p.brightness == Brightness.dark;
  static Color get primary => p.primary;
  static Color get onPrimary => p.onPrimary;
  static Color get accent => p.accent;
  static Color get onAccent => p.onAccent;
  static Color get accentStrong => p.accentStrong;
  static Color get accentSoft => p.accentSoft;
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
  static Color get disabledFill => p.disabledFill;

  static Color get selectedNavPill =>
      isDark ? const Color(0xFF37379B) : const Color(0xFF37379B);
  static Color get onSelectedNavPill => const Color(0xFFFFFFFF);

  static LinearGradient get accentGradient => LinearGradient(
    // Physical alignment also works when callers paint the gradient directly
    // inside a ShaderMask without a Directionality ancestor (e.g. tests).
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accent,
      isDark ? const Color(0xFFE6B700) : const Color(0xFFEAB900),
    ],
  );

  static LinearGradient get darkGradient => LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: isDark
        ? const [Color(0xFF2E2B78), Color(0xFF1C1A49)]
        : const [Color(0xFF37379B), Color(0xFF5555B6)],
  );

  static LinearGradient get pageGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, background],
  );
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 22;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
}

abstract final class AppCurves {
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

abstract final class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.p.shadowBase.withValues(
        alpha: AppColors.isDark ? .24 : .075,
      ),
      blurRadius: 20,
      offset: const Offset(0, 7),
    ),
  ];

  static List<BoxShadow> get floating => [
    BoxShadow(
      color: AppColors.p.shadowBase.withValues(
        alpha: AppColors.isDark ? .38 : .14,
      ),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get accentGlow => [
    BoxShadow(
      color: AppColors.accent.withValues(alpha: .26),
      blurRadius: 18,
      offset: const Offset(0, 7),
    ),
  ];
}

abstract final class AppTheme {
  static ThemeData light() => _from(AppPalette.light);
  static ThemeData dark() => _from(AppPalette.dark);

  static ThemeData _from(AppPalette c) {
    final generated = ColorScheme.fromSeed(
      seedColor: const Color(0xFF37379B),
      brightness: c.brightness,
    );
    final scheme = generated.copyWith(
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.brightness == Brightness.light
          ? const Color(0xFFE8E6FF)
          : const Color(0xFF343274),
      onPrimaryContainer: c.brightness == Brightness.light
          ? const Color(0xFF25236A)
          : const Color(0xFFF0EFFF),
      secondary: c.accent,
      onSecondary: c.onAccent,
      secondaryContainer: c.accentSoft,
      onSecondaryContainer: c.brightness == Brightness.light
          ? const Color(0xFF3C3100)
          : const Color(0xFFFFE68C),
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surfaceAlt,
      surfaceContainerHigh: c.surfaceAlt,
      surfaceContainerHighest: c.neutralChip,
      outline: c.textSecondary,
      outlineVariant: c.divider,
      error: c.error,
      onError: const Color(0xFFFFFFFF),
      errorContainer: c.errorSoft,
      onErrorContainer: c.error,
    );

    const baseText = TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.28,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.34,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.36,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.42,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.52,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.65,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.62,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.58,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.45,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.45,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.45,
        letterSpacing: 0,
      ),
    );
    final textTheme = baseText.apply(
      fontFamily: 'Zain',
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    );

    final compactShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      fontFamily: 'Zain',
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.disabledFill,
          disabledForegroundColor: c.textSecondary,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          shape: compactShape,
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.disabledFill,
          disabledForegroundColor: c.textSecondary,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          shape: compactShape,
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          backgroundColor: c.surface,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          side: BorderSide(color: c.divider),
          shape: compactShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: const Size.square(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 15, 16, 15),
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: c.primary,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.neutralChip,
        selectedColor: c.primary,
        secondarySelectedColor: c.primary,
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: c.onPrimary),
        side: BorderSide(color: c.divider),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.navigation,
        indicatorColor: c.primary,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? c.primary
                : c.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c.accent
                : c.textSecondary,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.brightness == Brightness.dark
            ? c.surfaceAlt
            : const Color(0xFF26233B),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFFFFFFF),
        ),
        actionTextColor: c.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.primary,
        unselectedLabelColor: c.textSecondary,
        indicatorColor: c.accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.textSecondary,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.primary,
        textColor: c.textPrimary,
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.textSecondary,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceAlt,
        circularTrackColor: c.surfaceAlt,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.onPrimary
              : c.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.primary : c.neutralChip,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: c.accent,
        textColor: c.onAccent,
        textStyle: textTheme.labelSmall,
      ),
    );
  }
}

/// Compatibility wrapper retained for existing call sites.
///
/// The previous implementation used decorative blur. The rebrand uses an
/// opaque, readable navigation surface so lower-end Android devices avoid an
/// unnecessary backdrop-filter cost.
class FrostedPanel extends StatelessWidget {
  const FrostedPanel({
    super.key,
    required this.child,
    this.borderRadius,
    this.fillAlpha,
    this.blur = 0,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final double? fillAlpha;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.xl);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.p.navigation.withValues(alpha: fillAlpha ?? 1),
        borderRadius: radius,
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}
