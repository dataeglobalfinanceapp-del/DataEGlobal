import 'temporary_employee_document.dart';

class TemporaryEmployeeSensitiveData {
  final String socialSecurityNumber;
  final TemporaryEmployeeDocument? w4Document;

  const TemporaryEmployeeSensitiveData({
    this.socialSecurityNumber = '',
    this.w4Document,
  });

  bool get hasSocialSecurityNumber => normalizedSocialSecurityNumber.isNotEmpty;

  bool get hasW4Document => w4Document != null;

  String get normalizedSocialSecurityNumber {
    return socialSecurityNumber.replaceAll(RegExp(r'\D'), '');
  }

  String get formattedSocialSecurityNumber {
    final String digits = normalizedSocialSecurityNumber;
    if (digits.length != 9) return socialSecurityNumber.trim();

    return '${digits.substring(0, 3)}-'
        '${digits.substring(3, 5)}-'
        '${digits.substring(5)}';
  }

  String get maskedSocialSecurityNumber {
    final String digits = normalizedSocialSecurityNumber;
    if (digits.length < 4) return '***-**-****';

    return '***-**-${digits.substring(digits.length - 4)}';
  }

  TemporaryEmployeeSensitiveData copyWith({
    String? socialSecurityNumber,
    TemporaryEmployeeDocument? w4Document,
    bool clearW4Document = false,
  }) {
    return TemporaryEmployeeSensitiveData(
      socialSecurityNumber: socialSecurityNumber ?? this.socialSecurityNumber,
      w4Document: clearW4Document ? null : w4Document ?? this.w4Document,
    );
  }
}
