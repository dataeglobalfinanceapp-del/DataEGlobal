import 'dart:async';

import 'package:savetep/features/auth/screens/login_screen/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginController', () {
    test('validate rejects invalid email and short password', () {
      final LoginController controller = LoginController(
        signIn: (_, _) async => true,
      );
      addTearDown(controller.dispose);

      controller.emailController.text = 'sunny';
      controller.passwordController.text = 'short';

      expect(controller.validate(), isFalse);
      expect(controller.state.emailInvalid, isTrue);
      expect(controller.state.passwordInvalid, isTrue);
      expect(controller.state.errors, contains('A valid email is required'));
      expect(
        controller.state.errors,
        contains('Password must be at least 8 characters'),
      );
    });

    test('submit trims email and exposes loading while pending', () async {
      final Completer<bool> signInCompleter = Completer<bool>();
      String? submittedEmail;
      String? submittedPassword;
      final LoginController controller = LoginController(
        signIn: (String email, String password) {
          submittedEmail = email;
          submittedPassword = password;
          return signInCompleter.future;
        },
      );
      addTearDown(controller.dispose);

      controller.emailController.text = ' sunny@example.com ';
      controller.passwordController.text = 'Password1!';

      final Future<bool> result = controller.submit();

      expect(controller.state.isLoading, isTrue);
      expect(submittedEmail, 'sunny@example.com');
      expect(submittedPassword, 'Password1!');

      signInCompleter.complete(true);

      expect(await result, isTrue);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errors, isEmpty);
    });
  });
}
