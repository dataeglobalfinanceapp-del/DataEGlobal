import 'package:savetep/features/auth/models/auth_sign_in_challenge.dart';
import 'package:savetep/features/auth/screens/login_screen/login/controllers/login_controller.dart';
import 'package:savetep/features/auth/screens/login_screen/login/login_screen.dart';
import 'package:savetep/features/auth/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoginScreen shows validation errors without calling sign in', (
    WidgetTester tester,
  ) async {
    bool signInCalled = false;
    final LoginController controller = LoginController(
      signIn: (_, _) async {
        signInCalled = true;
        return true;
      },
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(controller: controller),
        routes: <String, WidgetBuilder>{
          '/signup': (_) => const Scaffold(body: Text('Sign up')),
          '/forgot-password': (_) =>
              const Scaffold(body: Text('Forgot password')),
          '/home': (_) => const Scaffold(body: Text('Home')),
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(signInCalled, isFalse);
    expect(find.text('Username or email is required'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('LoginScreen navigates home after successful sign in', (
    WidgetTester tester,
  ) async {
    String? submittedEmail;
    final LoginController controller = LoginController(
      signIn: (String email, String password) async {
        submittedEmail = email;
        return true;
      },
    );
    addTearDown(controller.dispose);

    controller.identifierController.text = ' sunny@example.com ';
    controller.passwordController.text = 'Password1!';

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(controller: controller),
        routes: <String, WidgetBuilder>{
          '/signup': (_) => const Scaffold(body: Text('Sign up')),
          '/forgot-password': (_) =>
              const Scaffold(body: Text('Forgot password')),
          '/home': (_) => const Scaffold(body: Text('Home')),
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(submittedEmail, 'sunny@example.com');
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('LoginScreen labels its identifier field for usernames', (
    WidgetTester tester,
  ) async {
    final LoginController controller = LoginController(
      signIn: (_, _) async => false,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: controller)),
    );

    final Iterable<String> labels = tester
        .widgetList<AuthFieldLabel>(find.byType(AuthFieldLabel))
        .map((AuthFieldLabel label) => label.text);
    final TextField identifierField = tester.widget<TextField>(
      find.byType(TextField).first,
    );

    expect(labels, contains('USERNAME OR EMAIL'));
    expect(
      identifierField.decoration?.hintText,
      'e.g: demo-owner or sunny@gmail.com',
    );
    expect(identifierField.keyboardType, TextInputType.text);
  });

  testWidgets('LoginScreen completes an MFA code challenge', (
    WidgetTester tester,
  ) async {
    String? confirmedCode;
    final LoginController controller = LoginController(
      signIn: (_, _) async {
        throw AuthSignInChallengeRequired.fromStep(
          'confirmSignInWithSmsMfaCode',
          destination: '***1234',
        );
      },
      confirmSignIn: (String response) async {
        confirmedCode = response;
        return true;
      },
    );
    addTearDown(controller.dispose);
    controller.identifierController.text = 'demo-owner';
    controller.passwordController.text = 'Password1!';

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(controller: controller),
        routes: <String, WidgetBuilder>{
          '/home': (_) => const Scaffold(body: Text('Home')),
        },
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(
      find.text('Enter the verification code sent to ***1234.'),
      findsOneWidget,
    );
    final Iterable<String> challengeLabels = tester
        .widgetList<AuthFieldLabel>(find.byType(AuthFieldLabel))
        .map((AuthFieldLabel label) => label.text);
    expect(challengeLabels, contains('VERIFICATION CODE'));
    expect(challengeLabels, isNot(contains('USERNAME OR EMAIL')));

    await tester.enterText(find.byType(TextField), '654321');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(confirmedCode, '654321');
    expect(find.text('Home'), findsOneWidget);
  });
}
