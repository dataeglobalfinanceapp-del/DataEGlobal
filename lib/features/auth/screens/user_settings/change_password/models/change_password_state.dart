import 'change_password_rules.dart';

class ChangePasswordState {
  final String newPassword;
  final String confirmPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final bool newPasswordTouched;
  final bool confirmPasswordTouched;
  final bool submitted;
  final bool isSubmitting;
  final String? submitError;

  const ChangePasswordState({
    this.newPassword = '',
    this.confirmPassword = '',
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
    this.newPasswordTouched = false,
    this.confirmPasswordTouched = false,
    this.submitted = false,
    this.isSubmitting = false,
    this.submitError,
  });

  ChangePasswordRules get rules =>
      ChangePasswordRules.fromPassword(newPassword);

  bool get passwordsMatch {
    return confirmPassword.isNotEmpty && newPassword == confirmPassword;
  }

  bool get canSubmit {
    return rules.isValid && passwordsMatch && !isSubmitting;
  }

  String? get newPasswordError {
    if (!submitted && !newPasswordTouched) return null;
    if (newPassword.isEmpty) return 'Enter a new password.';
    if (!rules.isValid) {
      return 'Password must meet every complexity requirement.';
    }
    return null;
  }

  String? get confirmPasswordError {
    if (!submitted && !confirmPasswordTouched) return null;
    if (confirmPassword.isEmpty) return 'Confirm your new password.';
    if (newPassword.isNotEmpty && confirmPassword != newPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  double get strengthProgress {
    if (rules.completedCount == 0) return 0;
    return rules.completedCount / ChangePasswordRules.requirementCount;
  }

  String get strengthLabel {
    return switch (rules.completedCount) {
      0 => 'None',
      1 => 'Weak',
      2 => 'Medium',
      _ => 'Strong',
    };
  }

  ChangePasswordState copyWith({
    String? newPassword,
    String? confirmPassword,
    bool? obscureNewPassword,
    bool? obscureConfirmPassword,
    bool? newPasswordTouched,
    bool? confirmPasswordTouched,
    bool? submitted,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return ChangePasswordState(
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscureNewPassword: obscureNewPassword ?? this.obscureNewPassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      newPasswordTouched: newPasswordTouched ?? this.newPasswordTouched,
      confirmPasswordTouched:
          confirmPasswordTouched ?? this.confirmPasswordTouched,
      submitted: submitted ?? this.submitted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChangePasswordState &&
        other.newPassword == newPassword &&
        other.confirmPassword == confirmPassword &&
        other.obscureNewPassword == obscureNewPassword &&
        other.obscureConfirmPassword == obscureConfirmPassword &&
        other.newPasswordTouched == newPasswordTouched &&
        other.confirmPasswordTouched == confirmPasswordTouched &&
        other.submitted == submitted &&
        other.isSubmitting == isSubmitting &&
        other.submitError == submitError;
  }

  @override
  int get hashCode {
    return Object.hash(
      newPassword,
      confirmPassword,
      obscureNewPassword,
      obscureConfirmPassword,
      newPasswordTouched,
      confirmPasswordTouched,
      submitted,
      isSubmitting,
      submitError,
    );
  }
}
