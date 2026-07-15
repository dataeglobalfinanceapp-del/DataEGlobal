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
    return null;
  }

  static EmployeePayrollSetting? settingForSchedule({
    required String dateHire,
    required EmployeePayrollSchedule schedule,
    EmployeePayrollSetting? base,
  }) {
    final DateTime? hireDate = parseEmployeeDate(dateHire);
    if (hireDate == null || schedule == EmployeePayrollSchedule.none) {
      return null;
    }

    final EmployeePayDateSetting payDateSetting =
        base?.payDateSetting ?? EmployeePayDateSetting.afterPeriodEnd;
    final EmployeeProcessPayrollSetting processPayrollSetting =
        base?.processPayrollSetting ??
        EmployeeProcessPayrollSetting.manualReview;
    final int paidAfterPeriodEndDays = base?.paidAfterPeriodEndDays ?? 0;
    final int remindAfterPeriodEndDays = base?.remindAfterPeriodEndDays ?? 0;

    if (schedule.usesWeekdayEndingDay) {
      final EmployeePayrollEndingDay endingDay =
          base?.endingDay ?? EmployeePayrollEndingDay.sunday;
      return EmployeePayrollSetting(
        schedule: schedule,
        endingDay: endingDay,
        firstPeriodEndDate: firstPeriodEndDateForEndingDay(
          hireDate: hireDate,
          endingDay: endingDay,
        ),
        payDateSetting: payDateSetting,
        processPayrollSetting: processPayrollSetting,
        paidAfterPeriodEndDays: paidAfterPeriodEndDays,
        remindAfterPeriodEndDays: remindAfterPeriodEndDays,
      );
    }

    if (schedule.usesMonthlyEndingDay) {
      final int endingDay = _normalizedMonthDay(
        base?.monthlyEndingDay ?? hireDate.day,
      );
      return EmployeePayrollSetting(
        schedule: schedule,
        monthlyEndingDay: endingDay,
        firstPeriodEndDate: firstPeriodEndDateForMonthlyEndingDay(
          hireDate: hireDate,
          endingDay: endingDay,
        ),
        payDateSetting: payDateSetting,
        processPayrollSetting: processPayrollSetting,
        paidAfterPeriodEndDays: paidAfterPeriodEndDays,
        remindAfterPeriodEndDays: remindAfterPeriodEndDays,
      );
    }

    final int firstEndingDay = _normalizedMonthDay(
      base?.firstSemiMonthlyEndingDay ?? 15,
    );
    int secondEndingDay = _normalizedMonthDay(
      base?.secondSemiMonthlyEndingDay ?? 30,
    );
    if (secondEndingDay == firstEndingDay) {
      secondEndingDay = firstEndingDay == 15 ? 30 : 15;
    }

    return EmployeePayrollSetting(
      schedule: schedule,
      firstSemiMonthlyEndingDay: firstEndingDay,
      secondSemiMonthlyEndingDay: secondEndingDay,
      firstPeriodEndDate: firstPeriodEndDateForSemiMonthlyEndingDays(
        hireDate: hireDate,
        firstEndingDay: firstEndingDay,
        secondEndingDay: secondEndingDay,
      ),
      payDateSetting: payDateSetting,
      processPayrollSetting: processPayrollSetting,
      paidAfterPeriodEndDays: paidAfterPeriodEndDays,
      remindAfterPeriodEndDays: remindAfterPeriodEndDays,
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
    if (hireDate == null ||
        setting == null ||
        setting.schedule == EmployeePayrollSchedule.none) {
      return null;
    }

    final DateTime? firstPeriodEnd = calculatedFirstPeriodEndDate(
      hireDate: hireDate,
      setting: setting,
    );
    if (firstPeriodEnd == null || firstPeriodEnd.isBefore(hireDate)) {
      return null;
    }

    final DateTime activeDate = _dateOnly(asOf);
    if (!activeDate.isAfter(firstPeriodEnd)) {
      return PayrollPayPeriod(start: hireDate, end: firstPeriodEnd);
    }

    DateTime start = firstPeriodEnd.add(const Duration(days: 1));
    DateTime? end = nextPeriodEndAfter(firstPeriodEnd, setting);
    int guard = 0;
    while (end != null && activeDate.isAfter(end) && guard < 2400) {
      start = end.add(const Duration(days: 1));
      end = nextPeriodEndAfter(end, setting);
      guard += 1;
    }

    if (end == null || guard >= 2400) return null;
    return PayrollPayPeriod(start: start, end: end);
  }

  static DateTime? calculatedFirstPeriodEndDate({
    required DateTime hireDate,
    required EmployeePayrollSetting setting,
  }) {
    final DateTime start = _dateOnly(hireDate);
    if (setting.schedule.usesWeekdayEndingDay) {
      final EmployeePayrollEndingDay? endingDay = setting.endingDay;
      if (endingDay == null) return null;
      return firstPeriodEndDateForEndingDay(
        hireDate: start,
        endingDay: endingDay,
      );
    }

    if (setting.schedule.usesMonthlyEndingDay) {
      final int? endingDay = setting.monthlyEndingDay;
      if (!_isValidMonthDay(endingDay)) return null;
      return firstPeriodEndDateForMonthlyEndingDay(
        hireDate: start,
        endingDay: endingDay!,
      );
    }

    if (setting.schedule.usesSemiMonthlyEndingDays) {
      final int? firstEndingDay = setting.firstSemiMonthlyEndingDay;
      final int? secondEndingDay = setting.secondSemiMonthlyEndingDay;
      if (!_isValidMonthDay(firstEndingDay) ||
          !_isValidMonthDay(secondEndingDay) ||
          firstEndingDay == secondEndingDay) {
        return null;
      }
      return firstPeriodEndDateForSemiMonthlyEndingDays(
        hireDate: start,
        firstEndingDay: firstEndingDay!,
        secondEndingDay: secondEndingDay!,
      );
    }

    return null;
  }

  static DateTime? nextPeriodEndAfter(
    DateTime previousEnd,
    EmployeePayrollSetting setting,
  ) {
    final DateTime end = _dateOnly(previousEnd);
    if (setting.schedule.usesWeekdayEndingDay) {
      final int? days = setting.schedule.periodLengthDays;
      if (days == null) return null;
      return end.add(Duration(days: days));
    }

    if (setting.schedule.usesMonthlyEndingDay) {
      final int? endingDay = setting.monthlyEndingDay;
      if (!_isValidMonthDay(endingDay)) return null;
      return _clampedMonthDate(end.year, end.month + 1, endingDay!);
    }

    if (setting.schedule.usesSemiMonthlyEndingDays) {
      final int? firstEndingDay = setting.firstSemiMonthlyEndingDay;
      final int? secondEndingDay = setting.secondSemiMonthlyEndingDay;
      if (!_isValidMonthDay(firstEndingDay) ||
          !_isValidMonthDay(secondEndingDay) ||
          firstEndingDay == secondEndingDay) {
        return null;
      }

      for (int monthOffset = 0; monthOffset < 3; monthOffset += 1) {
        final List<DateTime> candidates = _semiMonthlyEndsForMonth(
          end.year,
          end.month + monthOffset,
          firstEndingDay!,
          secondEndingDay!,
        );
        for (final DateTime candidate in candidates) {
          if (candidate.isAfter(end)) return candidate;
        }
      }
    }

    return null;
  }

  static DateTime firstPeriodEndDateForEndingDay({
    required DateTime hireDate,
    required EmployeePayrollEndingDay endingDay,
  }) {
    final DateTime start = _dateOnly(hireDate);
    final int daysUntilEndingDay = (endingDay.weekday - start.weekday) % 7;
    return start.add(Duration(days: daysUntilEndingDay));
  }

  static DateTime firstPeriodEndDateForMonthlyEndingDay({
    required DateTime hireDate,
    required int endingDay,
  }) {
    final DateTime start = _dateOnly(hireDate);
    DateTime candidate = _clampedMonthDate(start.year, start.month, endingDay);
    if (candidate.isBefore(start)) {
      candidate = _clampedMonthDate(start.year, start.month + 1, endingDay);
    }
    return candidate;
  }

  static DateTime firstPeriodEndDateForSemiMonthlyEndingDays({
    required DateTime hireDate,
    required int firstEndingDay,
    required int secondEndingDay,
  }) {
    final DateTime start = _dateOnly(hireDate);
    final List<DateTime> hireMonthCandidates = _semiMonthlyEndsForMonth(
      start.year,
      start.month,
      firstEndingDay,
      secondEndingDay,
    );
    for (final DateTime candidate in hireMonthCandidates) {
      if (!candidate.isBefore(start)) return candidate;
    }

    return _semiMonthlyEndsForMonth(
      start.year,
      start.month + 1,
      firstEndingDay,
      secondEndingDay,
    ).first;
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

  static bool _isValidMonthDay(int? day) {
    return day != null && day >= 1 && day <= 31;
  }

  static int _normalizedMonthDay(int day) {
    if (day < 1) return 1;
    if (day > 31) return 31;
    return day;
  }

  static DateTime _clampedMonthDate(int year, int month, int day) {
    final DateTime firstOfMonth = DateTime(year, month);
    final int normalizedDay = _normalizedMonthDay(day);
    final int lastDayOfMonth = DateTime(
      firstOfMonth.year,
      firstOfMonth.month + 1,
      0,
    ).day;
    return DateTime(
      firstOfMonth.year,
      firstOfMonth.month,
      normalizedDay > lastDayOfMonth ? lastDayOfMonth : normalizedDay,
    );
  }

  static List<DateTime> _semiMonthlyEndsForMonth(
    int year,
    int month,
    int firstEndingDay,
    int secondEndingDay,
  ) {
    final DateTime first = _clampedMonthDate(year, month, firstEndingDay);
    final DateTime second = _clampedMonthDate(year, month, secondEndingDay);
    final List<DateTime> dates = <DateTime>[first, second]
      ..sort((DateTime left, DateTime right) => left.compareTo(right));

    if (dates.first == dates.last) {
      return <DateTime>[dates.first];
    }
    return dates;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
