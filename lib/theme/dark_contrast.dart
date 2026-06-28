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
}

ThemeData buildSaveTepTheme({required bool darkContrastEnabled}) {
  if (!darkContrastEnabled) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }

  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: DarkContrastPalette.primary,
        brightness: Brightness.dark,
      ).copyWith(
        surface: DarkContrastPalette.surface,
        primary: DarkContrastPalette.primary,
        secondary: DarkContrastPalette.accent,
        onSurface: DarkContrastPalette.text,
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
