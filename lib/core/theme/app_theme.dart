import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Escala tipográfica del diseño: Space Grotesk para titulares y cifras,
/// Plus Jakarta Sans para cuerpo y etiquetas.
abstract final class AppText {
  static TextStyle _grotesk(double size, FontWeight w, double lh, double ls) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: w,
        height: lh / size,
        letterSpacing: ls * size,
        color: AppColors.onSurface,
      );

  static TextStyle _jakarta(double size, FontWeight w, double lh, double ls) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        height: lh / size,
        letterSpacing: ls * size,
        color: AppColors.onSurface,
      );

  static final headlineXl = _grotesk(34, FontWeight.w700, 40, -0.03);
  static final headlineXlMobile = _grotesk(28, FontWeight.w700, 34, -0.02);
  static final headlineLg = _grotesk(24, FontWeight.w600, 30, -0.02);
  static final headlineMd = _grotesk(20, FontWeight.w600, 26, -0.01);
  static final numericStat = _grotesk(22, FontWeight.w700, 26, -0.02);
  static final titleSm = _jakarta(16, FontWeight.w600, 22, 0);
  static final labelLg = _jakarta(13, FontWeight.w600, 18, 0.01);
  static final labelSm = _jakarta(11, FontWeight.w700, 14, 0.04);
  static final bodyLg = _jakarta(16, FontWeight.w400, 24, 0);
  static final bodyMd = _jakarta(14, FontWeight.w400, 20, 0);
  static final bodySm = _jakarta(12, FontWeight.w400, 16, 0);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const margin = 20.0;
  static const gutter = 16.0;
}

abstract final class AppRadius {
  static const sm = 4.0;
  static const lg = 8.0;
  static const xl = 12.0;
  static const full = 9999.0;
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.primaryFixed,
    surfaceDim: AppColors.surfaceDim,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.surface,
  );

  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.onSurface, displayColor: AppColors.onSurface),
    splashFactory: InkSparkle.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      hintStyle: AppText.bodyMd.copyWith(
        color: AppColors.outline.withValues(alpha: 0.7),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: const BorderSide(
          color: AppColors.secondaryFixedDim,
          width: 2,
        ),
      ),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 6,
      inactiveTrackColor: AppColors.surfaceContainerHighest,
      overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.secondary
            : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: AppColors.outline, width: 1.5),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.inverseSurface,
      contentTextStyle: AppText.bodyMd.copyWith(
        color: AppColors.inverseOnSurface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),
  );
}
