import 'package:biztrack/features/auth/screens/user_setting/user_setting_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('User settings shows account menu actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: UserSettingsScreen()));

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
    await tester.pumpWidget(
      MaterialApp(
        home: const UserSettingsScreen(),
        routes: {
          UserSettingsRoutes.businessManagement: (context) =>
              const BusinessManagementScreen(),
        },
      ),
    );

    await tester.tap(find.text('Business Management'));
    await tester.pumpAndSettle();

    expect(find.byType(BusinessManagementScreen), findsOneWidget);
  });
}
