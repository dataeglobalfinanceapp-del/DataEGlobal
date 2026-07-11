import 'employee_form_data.dart';

class EmployeePayrollSetupValidators {
  const EmployeePayrollSetupValidators._();

  static String? validatePaidAfterDays(String? value) {
    return _validateWholeNumberRange(value, min: 0, max: 20);
  }

  static String? validateRemindAfterDays(String? value) {
    return _validateWholeNumberRange(value, min: 0, max: 7);
  }

  static String? validatePayrollRate(String? value) {
    return EmployeeFormValidators.validateRequiredRate(value);
  }

  static String? _validateWholeNumberRange(
    String? value, {
    required int min,
    required int max,
  }) {
    final int? number = int.tryParse(value?.trim() ?? '');
    if (number == null) return 'Enter a whole number';
    if (number < min || number > max) return 'Enter $min-$max';
    return null;
  }
}
