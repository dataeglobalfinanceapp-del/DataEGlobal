class AuthFormValidators {
  const AuthFormValidators._();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _phonePattern = RegExp(r'^\d{9,10}$');

  static bool isValidEmail(String value) {
    return _emailPattern.hasMatch(value.trim());
  }

  static bool isValidLoginPassword(String value) {
    return value.length >= 8;
  }

  static bool isValidPhoneNumber(String value) {
    return _phonePattern.hasMatch(value.trim());
  }

  static PasswordValidation validatePassword(String value) {
    return PasswordValidation(
      hasMinLength: value.length >= 8,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(value),
      hasLowercase: RegExp(r'[a-z]').hasMatch(value),
      hasNumber: RegExp(r'\d').hasMatch(value),
      hasSpecial: RegExp(r'[!@#$%^&*]').hasMatch(value),
    );
  }
}

class PasswordValidation {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecial;

  const PasswordValidation({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecial,
  });

  bool get isValid {
    return hasMinLength &&
        hasUppercase &&
        hasLowercase &&
        hasNumber &&
        hasSpecial;
  }

  List<String> get errors {
    return <String>[
      if (!hasMinLength) 'Password must be at least 8 characters',
      if (!hasUppercase) 'Password must contain at least one uppercase letter',
      if (!hasLowercase) 'Password must contain at least one lowercase letter',
      if (!hasNumber) 'Password must contain at least one number',
      if (!hasSpecial)
        'Password must contain at least one special character (!@#\$%^&*)',
    ];
  }
}
