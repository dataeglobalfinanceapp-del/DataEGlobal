import 'package:savetep/domain/models/employee_payroll_setting.dart';

import 'payroll_models.dart';

class PayrollPayPeriod {
  final DateTime start;
  final DateTime end;

  const PayrollPayPeriod({required this.start, required this.end});

  String get displayText {
    return '${PayrollPeriodCalculator.formatShortDate(start)} - '
        '${PayrollPeriodCalculator.formatShortDate(end)}';
  }
}

class PayrollPeriodCalculator {
  const PayrollPeriodCalculator._();

  static EmployeePayrollSetting? defaultSettingForDateHire(String dateHire) {
    final DateTime? hireDate = parseEmployeeDate(dateHire);
    if (hireDate == null) return null;

    const EmployeePayrollEndingDay endingDay = EmployeePayrollEndingDay.sunday;
    return EmployeePayrollSetting(
      schedule: EmployeePayrollSchedule.biWeekly,
      endingDay: endingDay,
      firstPeriodEndDate: firstPeriodEndDateForEndingDay(
        hireDate: hireDate,
        endingDay: endingDay,
      ),
    );
  }

  static PayrollPayPeriod? currentPeriodForEmployee(
    PayrollEmployee employee, {
    required DateTime asOf,
  }) {
    return currentPeriod(
      dateHire: employee.dateHire,
      setting: employee.payrollSetting,
      asOf: asOf,
    );
  }

  static PayrollPayPeriod? currentPeriod({
    required String dateHire,
    required EmployeePayrollSetting? setting,
    required DateTime asOf,
  }) {
    final DateTime? hireDate = parseEmployeeDate(dateHire);
    if (hireDate == null || setting == null) return null;

    final DateTime firstPeriodEnd = _dateOnly(setting.firstPeriodEndDate);
    if (firstPeriodEnd.isBefore(hireDate) ||
        firstPeriodEnd.weekday != setting.endingDay.weekday) {
      return null;
    }

    final DateTime activeDate = _dateOnly(asOf);
    if (!activeDate.isAfter(firstPeriodEnd)) {
      return PayrollPayPeriod(start: hireDate, end: firstPeriodEnd);
    }

    final int daysAfterFirstPeriod = activeDate
        .difference(firstPeriodEnd)
        .inDays;
    final int periodIndex =
        ((daysAfterFirstPeriod - 1) ~/ setting.schedule.periodLengthDays) + 1;
    final DateTime start = firstPeriodEnd.add(
      Duration(
        days: ((periodIndex - 1) * setting.schedule.periodLengthDays) + 1,
      ),
    );
    final DateTime end = firstPeriodEnd.add(
      Duration(days: periodIndex * setting.schedule.periodLengthDays),
    );

    return PayrollPayPeriod(start: start, end: end);
  }

  static DateTime firstPeriodEndDateForEndingDay({
    required DateTime hireDate,
    required EmployeePayrollEndingDay endingDay,
  }) {
    final DateTime start = _dateOnly(hireDate);
    final int daysUntilEndingDay = (endingDay.weekday - start.weekday) % 7;
    return start.add(Duration(days: daysUntilEndingDay));
  }

  static DateTime? parseEmployeeDate(String value) {
    final String text = value.trim();
    if (text.isEmpty) return null;

    final DateTime? isoDate = DateTime.tryParse(text);
    if (isoDate != null) return _dateOnly(isoDate);

    final List<String> parts = text.split('/');
    if (parts.length != 3) return null;

    final int? month = int.tryParse(parts[0]);
    final int? day = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);
    if (month == null || day == null || year == null) return null;

    return DateTime(year < 100 ? 2000 + year : year, month, day);
  }

  static String formatShortDate(DateTime date) {
    final DateTime value = _dateOnly(date);
    final String year = (value.year % 100).toString().padLeft(2, '0');
    return '${value.month.toString().padLeft(2, '0')}/'
        '${value.day.toString().padLeft(2, '0')}/$year';
  }

  static DateTime dateOnly(DateTime value) => _dateOnly(value);

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
