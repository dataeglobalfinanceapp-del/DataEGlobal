import 'package:savetep/features/auth/screens/user_setting/change_password/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChangePasswordScreen updates requirements and enables save', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));

    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('COMPLEXITY REQUIREMENTS'), findsOneWidget);
    expect(find.text('Security Strength: None'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Save Password'),
          )
          .enabled,
      isFalse,
    );

    await tester.enterText(
      find.byKey(const Key('new-password-field')),
      'SecurePass12!',
    );
    await tester.pump();

    expect(find.text('Security Strength: Strong'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Save Password'),
          )
          .enabled,
      isFalse,
    );

    await tester.enterText(
      find.byKey(const Key('confirm-new-password-field')),
      'SecurePass12!',
    );
    await tester.pump();

    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Save Password'),
          )
          .enabled,
      isTrue,
    );
  });

  testWidgets('ChangePasswordScreen shows mismatch error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));

    await tester.enterText(
      find.byKey(const Key('new-password-field')),
      'SecurePass12!',
    );
    await tester.enterText(
      find.byKey(const Key('confirm-new-password-field')),
      'SecurePass13!',
    );
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });
}
