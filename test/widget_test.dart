// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/features/auth/screens/user_setting/user_settings_routes.dart';
import 'package:savetep/features/auth/widgets/app_bottom_navigation_bar.dart';
import 'package:savetep/main.dart';
import 'package:savetep/theme/dark_contrast.dart';

void main() {
  late Map<String, String> localStoreValues;

  setUp(() {
    localStoreValues = <String, String>{};
    LocalStore.setOverridesForTesting(
      read: (key) async => localStoreValues[key],
      write: (key, value) async {
        localStoreValues[key] = value;
      },
    );
  });

  tearDown(LocalStore.resetOverridesForTesting);

  testWidgets('App builds a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const SaveTepApp());

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App delays startup focus until after first layout', (
    WidgetTester tester,
  ) async {
    const Key gateKey = Key('startup-focus-gate');

    await tester.pumpWidget(const SaveTepApp());
    expect(tester.takeException(), isNull);

    FocusScope gate = tester.widget<FocusScope>(find.byKey(gateKey));
    expect(gate.canRequestFocus, isFalse);
    expect(gate.descendantsAreFocusable, isFalse);
    expect(gate.descendantsAreTraversable, isFalse);

    await tester.pump();
    expect(tester.takeException(), isNull);

    gate = tester.widget<FocusScope>(find.byKey(gateKey));
    expect(gate.canRequestFocus, isTrue);
    expect(gate.descendantsAreFocusable, isTrue);
    expect(gate.descendantsAreTraversable, isTrue);

    final traversal = tester.widget<FocusTraversalGroup>(
      find
          .descendant(
            of: find.byKey(gateKey),
            matching: find.byType(FocusTraversalGroup),
          )
          .first,
    );

    expect(traversal.policy, isA<WidgetOrderTraversalPolicy>());
  });

  testWidgets('App shell shows bottom navigation on app routes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SaveTepApp());
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushReplacementNamed(UserSettingsRoutes.settings);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.byType(AppBottomNavigationBar), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);

    navigator.pushReplacementNamed('/login');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.byType(AppBottomNavigationBar), findsNothing);
  });

  testWidgets(
    'App shell restores an app route without build-phase nav errors',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SaveTepApp(initialRoute: '/home'));
      expect(tester.takeException(), isNull);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      expect(find.byType(AppBottomNavigationBar), findsOneWidget);
    },
  );

  testWidgets('scan expense route opens editable auto form directly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SaveTepApp(initialRoute: '/scan-expense'));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    await tester.tap(find.text("Don't allow"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('EXPENSE DATA'), findsOneWidget);
    expect(find.text('CHECK NUMBER:'), findsOneWidget);
    expect(find.text('Enter Manually'), findsNothing);
    expect(find.text('Extract Automatically'), findsNothing);
  });

  testWidgets('App loads saved dark contrast preference', (
    WidgetTester tester,
  ) async {
    localStoreValues[DarkContrastController.storageKey] = 'true';

    await tester.pumpWidget(
      const SaveTepApp(initialRoute: UserSettingsRoutes.settings),
    );
    expect(tester.takeException(), isNull);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.brightness, Brightness.dark);

    final switchWidget = tester.widget<Switch>(
      find.byKey(const ValueKey('settings.darkContrastSwitch')),
    );
    expect(switchWidget.value, isTrue);
  });

  testWidgets('App shell hides bottom navigation on auth routes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SaveTepApp());
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.byType(AppBottomNavigationBar), findsNothing);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    const authRoutes = <_AuthRouteCase>[
      _AuthRouteCase('/login'),
      _AuthRouteCase('/signup'),
      _AuthRouteCase('/forgot-password'),
      _AuthRouteCase('/confirm-signup', arguments: 'person@example.com'),
      _AuthRouteCase('/confirm-reset', arguments: 'person@example.com'),
    ];

    for (final authRoute in authRoutes) {
      navigator.pushReplacementNamed(UserSettingsRoutes.settings);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AppBottomNavigationBar), findsOneWidget);

      navigator.pushReplacementNamed(
        authRoute.routeName,
        arguments: authRoute.arguments,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: authRoute.routeName);

      expect(
        find.byType(AppBottomNavigationBar),
        findsNothing,
        reason: authRoute.routeName,
      );
    }
  });
}

class _AuthRouteCase {
  final String routeName;
  final Object? arguments;

  const _AuthRouteCase(this.routeName, {this.arguments});
}
