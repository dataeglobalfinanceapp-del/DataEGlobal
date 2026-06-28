import 'package:savetep/features/auth/screens/user_setting/user_setting_screens.dart';
import 'package:savetep/data/local/local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetep/theme/dark_contrast.dart';

void main() {
  tearDown(LocalStore.resetOverridesForTesting);

  testWidgets('User settings shows account menu actions', (
    WidgetTester tester,
  ) async {
    await _pumpUserSettingsScreen(tester);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Settings')),
      findsOneWidget,
    );
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Business Management'), findsOneWidget);
    expect(find.text('Enterprise Code ID'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Institution Support'), findsOneWidget);
    expect(find.text('Manage partner'), findsOneWidget);
    expect(find.text('Deactivate Access'), findsOneWidget);
  });

  testWidgets('User settings menu opens a function screen', (
    WidgetTester tester,
  ) async {
    await _pumpUserSettingsScreen(
      tester,
      routes: {
        UserSettingsRoutes.businessManagement: (context) =>
            const BusinessManagementScreen(),
      },
    );

    await tester.tap(find.text('Business Management'));
    await tester.pumpAndSettle();

    expect(find.byType(BusinessManagementScreen), findsOneWidget);
  });

  testWidgets('User settings toggles and persists dark contrast', (
    WidgetTester tester,
  ) async {
    final values = <String, String>{};
    LocalStore.setOverridesForTesting(
      read: (key) async => values[key],
      write: (key, value) async {
        values[key] = value;
      },
    );

    final controller = await _pumpUserSettingsScreen(tester);

    expect(controller.enabled, isFalse);
    expect(
      find.byKey(const ValueKey('settings.darkContrastSwitch')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('settings.darkContrastSwitch')));
    await tester.pumpAndSettle();

    expect(controller.enabled, isTrue);
    expect(values[DarkContrastController.storageKey], 'true');
  });
}

Future<DarkContrastController> _pumpUserSettingsScreen(
  WidgetTester tester, {
  Map<String, WidgetBuilder>? routes,
}) async {
  final controller = DarkContrastController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    DarkContrastScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return MaterialApp(
            theme: buildSaveTepTheme(darkContrastEnabled: controller.enabled),
            home: const UserSettingsScreen(),
            routes: routes ?? const {},
          );
        },
      ),
    ),
  );

  return controller;
}
