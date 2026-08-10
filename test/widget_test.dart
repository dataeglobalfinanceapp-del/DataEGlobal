// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/models/account_profile.dart';
import 'package:savetep/features/auth/screens/user_setting/user_settings_routes.dart';
import 'package:savetep/features/auth/services/account_profile_service.dart';
import 'package:savetep/features/auth/widgets/app_bottom_navigation_bar.dart';
import 'package:savetep/main.dart';
import 'package:savetep/providers/account_profile_provider.dart';

void main() {
  testWidgets('App builds a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App delays startup focus until after first layout', (
    WidgetTester tester,
  ) async {
    const Key gateKey = Key('startup-focus-gate');

    await tester.pumpWidget(_buildApp());
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
    await tester.pumpWidget(_buildApp());
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
      await tester.pumpWidget(_buildApp(initialRoute: '/home'));
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
    await tester.pumpWidget(_buildApp(initialRoute: '/scan-expense'));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('EXPENSE DATA'), findsOneWidget);
    expect(find.text('CHECK NUMBER:'), findsNothing);
    expect(find.text('TIPS & GRATUITY'), findsOneWidget);
    expect(find.text('Enter Manually'), findsNothing);
    expect(find.text('Extract Automatically'), findsNothing);
  });

  testWidgets('App shell hides bottom navigation on auth routes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp());
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

Widget _buildApp({String? initialRoute}) {
  return ProviderScope(
    overrides: [
      accountProfileRepositoryProvider.overrideWithValue(
        _FakeAccountProfileRepository(),
      ),
    ],
    child: SaveTepApp(initialRoute: initialRoute),
  );
}

class _FakeAccountProfileRepository implements AccountProfileRepository {
  AccountProfile profile = const AccountProfile(
    fullName: 'Sunny Nguyen',
    businessNameOnboardingCompleted: true,
  );

  @override
  Future<AccountProfile> load() async => profile;

  @override
  Future<void> save(AccountProfile profile) async {
    this.profile = profile;
  }
}

class _AuthRouteCase {
  final String routeName;
  final Object? arguments;

  const _AuthRouteCase(this.routeName, {this.arguments});
}
