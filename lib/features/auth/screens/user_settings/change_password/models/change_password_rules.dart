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
