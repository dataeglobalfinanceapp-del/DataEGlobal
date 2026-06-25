import 'package:savetep/features/auth/screens/user_setting/change_password/change_password_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ChangePasswordRules require length, mixed case, digit, and special',
    () {
      final weak = ChangePasswordRules.fromPassword('Password1');
      expect(weak.hasMinimumLength, isFalse);
      expect(weak.hasMixedCase, isTrue);
      expect(weak.hasDigitAndSpecialCharacter, isFalse);
      expect(weak.isValid, isFalse);

      final strong = ChangePasswordRules.fromPassword('SecurePass12!');
      expect(strong.hasMinimumLength, isTrue);
      expect(strong.hasMixedCase, isTrue);
      expect(strong.hasDigitAndSpecialCharacter, isTrue);
      expect(strong.isValid, isTrue);
    },
  );

  test('ChangePasswordController enables submit only when passwords match', () {
    final controller = ChangePasswordController();
    addTearDown(controller.dispose);

    controller.newPasswordController.text = 'SecurePass12!';
    controller.confirmPasswordController.text = 'SecurePass12';

    expect(controller.state.rules.isValid, isTrue);
    expect(controller.state.passwordsMatch, isFalse);
    expect(controller.state.canSubmit, isFalse);
    expect(controller.state.confirmPasswordError, 'Passwords do not match.');

    controller.confirmPasswordController.text = 'SecurePass12!';

    expect(controller.state.passwordsMatch, isTrue);
    expect(controller.state.canSubmit, isTrue);
  });
}
