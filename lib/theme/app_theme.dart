import 'package:flutter/material.dart';

class AppThemePalette {
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color elevatedSurface = Colors.white;
  static const Color border = Color(0xFFD7DEC9);
  static const Color primary = Color(0xFF2563EB);
  static const Color accent = Color(0xFF0E5E54);
  static const Color text = Colors.black87;
  static const Color mutedText = Color(0xFF64748B);

  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);
  static const Color primaryFixed = Color(0xFFDBEAFE);
  static const Color primaryFixedDim = Color(0xFFBFDBFE);
  static const Color onPrimaryFixed = Color(0xFF1E3A8A);
  static const Color onPrimaryFixedVariant = Color(0xFF1D4ED8);
  static const Color secondary = accent;
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFDFF7EA);
  static const Color onSecondaryContainer = Color(0xFF064E3B);
  static const Color secondaryFixed = Color(0xFFDFF7EA);
  static const Color secondaryFixedDim = Color(0xFF99F6E4);
  static const Color onSecondaryFixed = Color(0xFF064E3B);
  static const Color onSecondaryFixedVariant = Color(0xFF0F766E);
  static const Color tertiary = Color(0xFF7C3AED);
  static const Color onTertiary = Colors.white;
  static const Color tertiaryContainer = Color(0xFFEDE9FE);
  static const Color onTertiaryContainer = Color(0xFF4C1D95);
  static const Color tertiaryFixed = Color(0xFFEDE9FE);
  static const Color tertiaryFixedDim = Color(0xFFC4B5FD);
  static const Color onTertiaryFixed = Color(0xFF4C1D95);
  static const Color onTertiaryFixedVariant = Color(0xFF6D28D9);
  static const Color error = Color(0xFFDC2626);
  static const Color onError = Colors.white;
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF7F1D1D);
  static const Color surfaceDim = Color(0xFFE5E7EB);
  static const Color surfaceBright = Colors.white;
  static const Color surfaceContainerLowest = Colors.white;
  static const Color surfaceContainerLow = Color(0xFFFAFAFA);
  static const Color surfaceContainer = Color(0xFFF5F5F5);
  static const Color surfaceContainerHigh = Color(0xFFF2F5ED);
  static const Color surfaceContainerHighest = Color(0xFFE5E7EB);
  static const Color onSurface = text;
  static const Color onSurfaceVariant = mutedText;
  static const Color outline = border;
  static const Color outlineVariant = Color(0xFFE5E7EB);
  static const Color shadow = Color(0x18000000);
  static const Color scrim = Colors.black54;
  static const Color inverseSurface = Color(0xFF202124);
  static const Color onInverseSurface = Colors.white;
  static const Color inversePrimary = Color(0xFF93C5FD);
  static const Color surfaceTint = primary;
}

ThemeData buildSaveTepTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppThemePalette.primary,
    onPrimary: AppThemePalette.onPrimary,
    primaryContainer: AppThemePalette.primaryContainer,
    onPrimaryContainer: AppThemePalette.onPrimaryContainer,
    primaryFixed: AppThemePalette.primaryFixed,
    primaryFixedDim: AppThemePalette.primaryFixedDim,
    onPrimaryFixed: AppThemePalette.onPrimaryFixed,
    onPrimaryFixedVariant: AppThemePalette.onPrimaryFixedVariant,
    secondary: AppThemePalette.secondary,
    onSecondary: AppThemePalette.onSecondary,
    secondaryContainer: AppThemePalette.secondaryContainer,
    onSecondaryContainer: AppThemePalette.onSecondaryContainer,
    secondaryFixed: AppThemePalette.secondaryFixed,
    secondaryFixedDim: AppThemePalette.secondaryFixedDim,
    onSecondaryFixed: AppThemePalette.onSecondaryFixed,
    onSecondaryFixedVariant: AppThemePalette.onSecondaryFixedVariant,
    tertiary: AppThemePalette.tertiary,
    onTertiary: AppThemePalette.onTertiary,
    tertiaryContainer: AppThemePalette.tertiaryContainer,
    onTertiaryContainer: AppThemePalette.onTertiaryContainer,
    tertiaryFixed: AppThemePalette.tertiaryFixed,
    tertiaryFixedDim: AppThemePalette.tertiaryFixedDim,
    onTertiaryFixed: AppThemePalette.onTertiaryFixed,
    onTertiaryFixedVariant: AppThemePalette.onTertiaryFixedVariant,
    error: AppThemePalette.error,
    onError: AppThemePalette.onError,
    errorContainer: AppThemePalette.errorContainer,
    onErrorContainer: AppThemePalette.onErrorContainer,
    surface: AppThemePalette.surface,
    onSurface: AppThemePalette.onSurface,
    surfaceDim: AppThemePalette.surfaceDim,
    surfaceBright: AppThemePalette.surfaceBright,
    surfaceContainerLowest: AppThemePalette.surfaceContainerLowest,
    surfaceContainerLow: AppThemePalette.surfaceContainerLow,
    surfaceContainer: AppThemePalette.surfaceContainer,
    surfaceContainerHigh: AppThemePalette.surfaceContainerHigh,
    surfaceContainerHighest: AppThemePalette.surfaceContainerHighest,
    onSurfaceVariant: AppThemePalette.onSurfaceVariant,
    outline: AppThemePalette.outline,
    outlineVariant: AppThemePalette.outlineVariant,
    shadow: AppThemePalette.shadow,
    scrim: AppThemePalette.scrim,
    inverseSurface: AppThemePalette.inverseSurface,
    onInverseSurface: AppThemePalette.onInverseSurface,
    inversePrimary: AppThemePalette.inversePrimary,
    surfaceTint: AppThemePalette.surfaceTint,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppThemePalette.background,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppThemePalette.surface,
      foregroundColor: AppThemePalette.text,
      elevation: 0,
    ),
    useMaterial3: true,
  );
}
