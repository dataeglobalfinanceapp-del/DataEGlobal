import 'package:savetep/services/money_formatter.dart';

import 'payroll_models.dart';

class EmployeeFormData {
  final String fullName;
  final String birthday;
  final String phone;
  final String address;
  final String dateHire;
  final String jobType;
  final double rate;
  final String payMethod;
  final String linkW4;

  const EmployeeFormData({
    required this.fullName,
    required this.birthday,
    required this.phone,
    required this.address,
    required this.dateHire,
    required this.jobType,
    required this.rate,
    required this.payMethod,
    required this.linkW4,
  });

  factory EmployeeFormData.fromInput({
    required String fullName,
    required String birthday,
    required String phone,
    required String address,
    required String dateHire,
    required String jobType,
    required String rateText,
    required String payMethod,
    required String linkW4,
  }) {
    return EmployeeFormData(
      fullName: fullName.trim(),
      birthday: birthday.trim(),
      phone: phone.trim(),
      address: address.trim(),
      dateHire: dateHire.trim(),
      jobType: jobType.trim(),
      rate: parseMoney(rateText),
      payMethod: payMethod.trim(),
      linkW4: linkW4.trim(),
    );
  }

  PayrollEmployee toPayrollEmployee({String id = ''}) {
    return PayrollEmployee(
      id: id,
      name: fullName,
      rate: rate,
      birthday: birthday,
      phone: phone,
      address: address,
      dateHire: dateHire,
      jobType: jobType,
      payMethod: payMethod,
      linkW4: linkW4,
    );
  }
}

class EmployeeFormValidators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  const EmployeeFormValidators._();

  static String? validateRequiredName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  static String? validateRequiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  static String? validateRequiredRate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (parseMoney(value) <= 0) return 'Enter a valid rate';
    return null;
  }

  static String? validateOptionalPhone(String? value) {
    return null;
  }

  static String? validateEmailAddress(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  static String? validateOptionalSocialSecurityNumber(String? value) {
    final String entered = value?.trim() ?? '';
    if (entered.isEmpty) return null;

    if (socialSecurityNumberDigits(entered).length != 9) {
      return 'Enter a valid SSN';
    }
    return null;
  }

  static String socialSecurityNumberDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}
