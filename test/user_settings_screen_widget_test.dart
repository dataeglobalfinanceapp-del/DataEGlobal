import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/models/account_profile.dart';
import 'package:savetep/features/auth/screens/user_setting/user_setting_screens.dart';
import 'package:savetep/features/auth/services/account_profile_service.dart';
import 'package:savetep/providers/account_profile_provider.dart';

void main() {
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
    expect(find.text('Sign Out'), findsOneWidget);
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
}

Future<void> _pumpUserSettingsScreen(
  WidgetTester tester, {
  Map<String, WidgetBuilder>? routes,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountProfileRepositoryProvider.overrideWithValue(
          _FakeAccountProfileRepository(),
        ),
      ],
      child: MaterialApp(
        home: const UserSettingsScreen(),
        routes: routes ?? const {},
      ),
    ),
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
