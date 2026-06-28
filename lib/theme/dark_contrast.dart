import 'package:flutter/material.dart';

import 'package:savetep/data/local/local_store.dart';

class DarkContrastController extends ChangeNotifier {
  static const String storageKey = 'dark_contrast_enabled';

  bool _enabled = false;

  bool get enabled => _enabled;

  Future<void> load() async {
    final rawValue = await LocalStore.read(storageKey);
    final savedEnabled = rawValue == 'true';
    if (_enabled == savedEnabled) return;

    _enabled = savedEnabled;
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    if (_enabled != enabled) {
      _enabled = enabled;
      notifyListeners();
    }

    await LocalStore.write(storageKey, enabled ? 'true' : 'false');
  }

  Future<void> toggle() => setEnabled(!_enabled);
}

class DarkContrastScope extends InheritedNotifier<DarkContrastController> {
  const DarkContrastScope({
    super.key,
    required DarkContrastController controller,
    required super.child,
  }) : super(notifier: controller);

  static DarkContrastController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DarkContrastScope>();
    assert(
      scope != null,
      'DarkContrastScope was not found in the widget tree.',
    );
    return scope!.notifier!;
  }
}

class DarkContrastPalette {
  static const Color background = Color(0xFF05070C);
  static const Color surface = Color(0xFF0D1320);
  static const Color elevatedSurface = Color(0xFF121A2A);
  static const Color border = Color(0xFF30415F);
  static const Color primary = Color(0xFFFFD166);
  static const Color accent = Color(0xFF4FD1C5);
  static const Color text = Color(0xFFF8FAFC);
  static const Color mutedText = Color(0xFFC7D2E3);

  static const Color onPrimary = Color(0xFF111827);
  static const Color primaryContainer = Color(0xFF4D3B10);
  static const Color onPrimaryContainer = Color(0xFFFFECB3);
  static const Color primaryFixed = Color(0xFFFFECB3);
  static const Color primaryFixedDim = Color(0xFFFFD166);
  static const Color onPrimaryFixed = Color(0xFF241A00);
  static const Color onPrimaryFixedVariant = Color(0xFF4D3B10);
  static const Color secondary = accent;
  static const Color onSecondary = Color(0xFF042F2E);
  static const Color secondaryContainer = Color(0xFF134E4A);
  static const Color onSecondaryContainer = Color(0xFFCCFBF1);
  static const Color secondaryFixed = Color(0xFFCCFBF1);
  static const Color secondaryFixedDim = Color(0xFF5EEAD4);
  static const Color onSecondaryFixed = Color(0xFF042F2E);
  static const Color onSecondaryFixedVariant = Color(0xFF115E59);
  static const Color tertiary = Color(0xFFA78BFA);
  static const Color onTertiary = Color(0xFF1E1B4B);
  static const Color tertiaryContainer = Color(0xFF312E81);
  static const Color onTertiaryContainer = Color(0xFFEDE9FE);
  static const Color tertiaryFixed = Color(0xFFEDE9FE);
  static const Color tertiaryFixedDim = Color(0xFFC4B5FD);
  static const Color onTertiaryFixed = Color(0xFF1E1B4B);
  static const Color onTertiaryFixedVariant = Color(0xFF4C1D95);
  static const Color error = Color(0xFFFF6B6B);
  static const Color onError = Color(0xFF3B0A0A);
  static const Color errorContainer = Color(0xFF7F1D1D);
  static const Color onErrorContainer = Color(0xFFFEE2E2);
  static const Color surfaceDim = background;
  static const Color surfaceBright = Color(0xFF1E293B);
  static const Color surfaceContainerLowest = Color(0xFF030712);
  static const Color surfaceContainerLow = surface;
  static const Color surfaceContainer = elevatedSurface;
  static const Color surfaceContainerHigh = Color(0xFF1A2537);
  static const Color surfaceContainerHighest = Color(0xFF24324A);
  static const Color onSurface = text;
  static const Color onSurfaceVariant = mutedText;
  static const Color outline = border;
  static const Color outlineVariant = Color(0xFF24324A);
  static const Color shadow = Colors.black;
  static const Color scrim = Colors.black;
  static const Color inverseSurface = Color(0xFFE2E8F0);
  static const Color onInverseSurface = Color(0xFF0F172A);
  static const Color inversePrimary = Color(0xFF0F766E);
  static const Color surfaceTint = primary;
}

class LightPalette {
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

ThemeData buildSaveTepTheme({required bool darkContrastEnabled}) {
  if (!darkContrastEnabled) {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: LightPalette.primary,
      onPrimary: LightPalette.onPrimary,
      primaryContainer: LightPalette.primaryContainer,
      onPrimaryContainer: LightPalette.onPrimaryContainer,
      primaryFixed: LightPalette.primaryFixed,
      primaryFixedDim: LightPalette.primaryFixedDim,
      onPrimaryFixed: LightPalette.onPrimaryFixed,
      onPrimaryFixedVariant: LightPalette.onPrimaryFixedVariant,
      secondary: LightPalette.secondary,
      onSecondary: LightPalette.onSecondary,
      secondaryContainer: LightPalette.secondaryContainer,
      onSecondaryContainer: LightPalette.onSecondaryContainer,
      secondaryFixed: LightPalette.secondaryFixed,
      secondaryFixedDim: LightPalette.secondaryFixedDim,
      onSecondaryFixed: LightPalette.onSecondaryFixed,
      onSecondaryFixedVariant: LightPalette.onSecondaryFixedVariant,
      tertiary: LightPalette.tertiary,
      onTertiary: LightPalette.onTertiary,
      tertiaryContainer: LightPalette.tertiaryContainer,
      onTertiaryContainer: LightPalette.onTertiaryContainer,
      tertiaryFixed: LightPalette.tertiaryFixed,
      tertiaryFixedDim: LightPalette.tertiaryFixedDim,
      onTertiaryFixed: LightPalette.onTertiaryFixed,
      onTertiaryFixedVariant: LightPalette.onTertiaryFixedVariant,
      error: LightPalette.error,
      onError: LightPalette.onError,
      errorContainer: LightPalette.errorContainer,
      onErrorContainer: LightPalette.onErrorContainer,
      surface: LightPalette.surface,
      onSurface: LightPalette.onSurface,
      surfaceDim: LightPalette.surfaceDim,
      surfaceBright: LightPalette.surfaceBright,
      surfaceContainerLowest: LightPalette.surfaceContainerLowest,
      surfaceContainerLow: LightPalette.surfaceContainerLow,
      surfaceContainer: LightPalette.surfaceContainer,
      surfaceContainerHigh: LightPalette.surfaceContainerHigh,
      surfaceContainerHighest: LightPalette.surfaceContainerHighest,
      onSurfaceVariant: LightPalette.onSurfaceVariant,
      outline: LightPalette.outline,
      outlineVariant: LightPalette.outlineVariant,
      shadow: LightPalette.shadow,
      scrim: LightPalette.scrim,
      inverseSurface: LightPalette.inverseSurface,
      onInverseSurface: LightPalette.onInverseSurface,
      inversePrimary: LightPalette.inversePrimary,
      surfaceTint: LightPalette.surfaceTint,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LightPalette.background,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: LightPalette.surface,
        foregroundColor: LightPalette.text,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }

  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: DarkContrastPalette.primary,
    onPrimary: DarkContrastPalette.onPrimary,
    primaryContainer: DarkContrastPalette.primaryContainer,
    onPrimaryContainer: DarkContrastPalette.onPrimaryContainer,
    primaryFixed: DarkContrastPalette.primaryFixed,
    primaryFixedDim: DarkContrastPalette.primaryFixedDim,
    onPrimaryFixed: DarkContrastPalette.onPrimaryFixed,
    onPrimaryFixedVariant: DarkContrastPalette.onPrimaryFixedVariant,
    secondary: DarkContrastPalette.secondary,
    onSecondary: DarkContrastPalette.onSecondary,
    secondaryContainer: DarkContrastPalette.secondaryContainer,
    onSecondaryContainer: DarkContrastPalette.onSecondaryContainer,
    secondaryFixed: DarkContrastPalette.secondaryFixed,
    secondaryFixedDim: DarkContrastPalette.secondaryFixedDim,
    onSecondaryFixed: DarkContrastPalette.onSecondaryFixed,
    onSecondaryFixedVariant: DarkContrastPalette.onSecondaryFixedVariant,
    tertiary: DarkContrastPalette.tertiary,
    onTertiary: DarkContrastPalette.onTertiary,
    tertiaryContainer: DarkContrastPalette.tertiaryContainer,
    onTertiaryContainer: DarkContrastPalette.onTertiaryContainer,
    tertiaryFixed: DarkContrastPalette.tertiaryFixed,
    tertiaryFixedDim: DarkContrastPalette.tertiaryFixedDim,
    onTertiaryFixed: DarkContrastPalette.onTertiaryFixed,
    onTertiaryFixedVariant: DarkContrastPalette.onTertiaryFixedVariant,
    error: DarkContrastPalette.error,
    onError: DarkContrastPalette.onError,
    errorContainer: DarkContrastPalette.errorContainer,
    onErrorContainer: DarkContrastPalette.onErrorContainer,
    surface: DarkContrastPalette.surface,
    onSurface: DarkContrastPalette.onSurface,
    surfaceDim: DarkContrastPalette.surfaceDim,
    surfaceBright: DarkContrastPalette.surfaceBright,
    surfaceContainerLowest: DarkContrastPalette.surfaceContainerLowest,
    surfaceContainerLow: DarkContrastPalette.surfaceContainerLow,
    surfaceContainer: DarkContrastPalette.surfaceContainer,
    surfaceContainerHigh: DarkContrastPalette.surfaceContainerHigh,
    surfaceContainerHighest: DarkContrastPalette.surfaceContainerHighest,
    onSurfaceVariant: DarkContrastPalette.onSurfaceVariant,
    outline: DarkContrastPalette.outline,
    outlineVariant: DarkContrastPalette.outlineVariant,
    shadow: DarkContrastPalette.shadow,
    scrim: DarkContrastPalette.scrim,
    inverseSurface: DarkContrastPalette.inverseSurface,
    onInverseSurface: DarkContrastPalette.onInverseSurface,
    inversePrimary: DarkContrastPalette.inversePrimary,
    surfaceTint: DarkContrastPalette.surfaceTint,
  );

  return ThemeData(
    colorScheme: colorScheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DarkContrastPalette.background,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: DarkContrastPalette.surface,
      foregroundColor: DarkContrastPalette.text,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? DarkContrastPalette.primary
            : DarkContrastPalette.mutedText;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? DarkContrastPalette.primary.withValues(alpha: 0.42)
            : DarkContrastPalette.border;
      }),
    ),
    useMaterial3: true,
  );
}
