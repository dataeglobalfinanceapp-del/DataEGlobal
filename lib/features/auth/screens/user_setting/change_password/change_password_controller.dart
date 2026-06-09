import 'package:flutter/material.dart';

typedef ChangePasswordRequest = Future<void> Function(String newPassword);

class ChangePasswordController extends ChangeNotifier {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final ChangePasswordRequest _changePassword;

  ChangePasswordState _state = const ChangePasswordState();

  ChangePasswordController({ChangePasswordRequest? changePassword})
    : _changePassword = changePassword ?? _defaultChangePassword {
    newPasswordController.addListener(_syncStateFromFields);
    confirmPasswordController.addListener(_syncStateFromFields);
  }

  ChangePasswordState get state => _state;

  void toggleNewPasswordVisibility() {
    _setState(_state.copyWith(obscureNewPassword: !_state.obscureNewPassword));
  }

  void toggleConfirmPasswordVisibility() {
    _setState(
      _state.copyWith(obscureConfirmPassword: !_state.obscureConfirmPassword),
    );
  }

  Future<bool> submit() async {
    _syncStateFromFields(submitted: true);
    if (!_state.canSubmit) return false;

    _setState(_state.copyWith(isSubmitting: true, clearSubmitError: true));
    try {
      await _changePassword(newPasswordController.text);
      _setState(_state.copyWith(isSubmitting: false));
      return true;
    } catch (error) {
      _setState(
        _state.copyWith(
          isSubmitting: false,
          submitError: 'Unable to save password. Please try again.',
        ),
      );
      return false;
    }
  }

  void _syncStateFromFields({bool? submitted}) {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;
    _setState(
      _state.copyWith(
        newPassword: newPassword,
        confirmPassword: confirmPassword,
        newPasswordTouched: _state.newPasswordTouched || newPassword.isNotEmpty,
        confirmPasswordTouched:
            _state.confirmPasswordTouched || confirmPassword.isNotEmpty,
        submitted: submitted ?? _state.submitted,
        clearSubmitError: true,
      ),
    );
  }

  void _setState(ChangePasswordState nextState) {
    if (_state == nextState) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    newPasswordController
      ..removeListener(_syncStateFromFields)
      ..dispose();
    confirmPasswordController
      ..removeListener(_syncStateFromFields)
      ..dispose();
    super.dispose();
  }

  static Future<void> _defaultChangePassword(String newPassword) async {}
}

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

class ChangePasswordRules {
  static const int requirementCount = 3;

  final bool hasMinimumLength;
  final bool hasMixedCase;
  final bool hasDigitAndSpecialCharacter;

  const ChangePasswordRules({
    required this.hasMinimumLength,
    required this.hasMixedCase,
    required this.hasDigitAndSpecialCharacter,
  });

  factory ChangePasswordRules.fromPassword(String password) {
    return ChangePasswordRules(
      hasMinimumLength: password.length >= 12,
      hasMixedCase:
          RegExp(r'[A-Z]').hasMatch(password) &&
          RegExp(r'[a-z]').hasMatch(password),
      hasDigitAndSpecialCharacter:
          RegExp(r'\d').hasMatch(password) &&
          RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    );
  }

  bool get isValid {
    return hasMinimumLength && hasMixedCase && hasDigitAndSpecialCharacter;
  }

  int get completedCount {
    return [
      hasMinimumLength,
      hasMixedCase,
      hasDigitAndSpecialCharacter,
    ].where((isComplete) => isComplete).length;
  }
}
