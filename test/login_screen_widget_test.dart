import 'package:savetep/features/auth/screens/login_screen/login/controllers/login_controller.dart';
import 'package:savetep/features/auth/screens/login_screen/login/login_screen.dart';
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
    expect(find.text('A valid email is required'), findsOneWidget);
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

    controller.emailController.text = ' sunny@example.com ';
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
}
