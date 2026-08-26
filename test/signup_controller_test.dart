import 'package:savetep/features/auth/screens/login_screen/signup/controllers/signup_controller.dart';
import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignUpController', () {
    test('validate reports required fields, password policy, and terms', () {
      final SignUpController controller = SignUpController(
        signUp:
            ({required email, required password, required fullName}) async =>
                const AuthSignUpAttempt(
                  needsConfirmation: true,
                  codeDelivery: null,
                ),
      );
      addTearDown(controller.dispose);

      controller.emailController.text = 'bad-email';
      controller.passwordController.text = 'short';
      controller.confirmController.text = 'different';

      expect(controller.validate(), isFalse);
      expect(controller.state.nameInvalid, isTrue);
      expect(controller.state.emailInvalid, isTrue);
      expect(controller.state.phoneInvalid, isTrue);
      expect(controller.state.passwordInvalid, isTrue);
      expect(controller.state.confirmInvalid, isTrue);
      expect(controller.state.errors, contains('Username is required'));
      expect(controller.state.errors, contains('A valid email is required'));
      expect(
        controller.state.errors,
        contains('A valid phone number is required'),
      );
      expect(
        controller.state.errors,
        contains('Password must be at least 8 characters'),
      );
      expect(
        controller.state.errors,
        contains('Password must contain at least one uppercase letter'),
      );
      expect(
        controller.state.errors,
        contains('Password must contain at least one number'),
      );
      expect(controller.state.errors, contains('Passwords do not match'));
      expect(
        controller.state.errors,
        contains('Please accept the terms and conditions'),
      );
    });

    test('submit sends trimmed email for a valid form', () async {
      String? submittedEmail;
      String? submittedPassword;
      String? submittedFullName;
      final SignUpController controller = SignUpController(
        signUp:
            ({
              required String email,
              required String password,
              required String fullName,
            }) async {
              submittedEmail = email;
              submittedPassword = password;
              submittedFullName = fullName;
              return const AuthSignUpAttempt(
                needsConfirmation: true,
                codeDelivery: null,
              );
            },
      );
      addTearDown(controller.dispose);

      controller.nameController.text = 'Sunny';
      controller.emailController.text = ' sunny@example.com ';
      controller.phoneController.text = '123456789';
      controller.passwordController.text = 'Password1!';
      controller.confirmController.text = 'Password1!';
      controller.setAgreedToTerms(true);
      controller.setCountryCode('+1');

      final AuthSignUpAttempt? result = await controller.submit();

      expect(result?.needsConfirmation, isTrue);
      expect(submittedEmail, 'sunny@example.com');
      expect(submittedPassword, 'Password1!');
      expect(submittedFullName, 'Sunny');
      expect(controller.state.countryCode, '+1');
      expect(controller.state.errors, isEmpty);
    });
  });
}
