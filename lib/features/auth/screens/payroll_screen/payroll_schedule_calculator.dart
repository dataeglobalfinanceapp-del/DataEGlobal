import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/recurrence_schedule.dart';

class PayrollPayPeriod {
  final DateTime start;
  final DateTime end;

  const PayrollPayPeriod({required this.start, required this.end});
}

class PayrollScheduleCalculator {
  static const int biweeklyPeriodDays = 14;

  const PayrollScheduleCalculator._();

  static DateTime defaultBiweeklyPeriodBeginDate({DateTime? today}) {
    return RecurrenceSchedule.dateOnly(
      today ?? AppClock.now,
    ).subtract(const Duration(days: biweeklyPeriodDays));
  }

  static DateTime earliestBiweeklyPeriodBeginDate({DateTime? today}) {
    final DateTime currentMonth = _monthStart(today ?? AppClock.now);
    return DateTime(currentMonth.year, currentMonth.month - 1);
  }

  static DateTime latestBiweeklyPeriodBeginDate({DateTime? today}) {
    final DateTime currentMonth = _monthStart(today ?? AppClock.now);
    return DateTime(currentMonth.year, currentMonth.month + 2, 0);
  }

  static bool isSelectableBiweeklyPeriodBeginDate(
    DateTime date, {
    DateTime? today,
  }) {
    final DateTime normalizedDate = RecurrenceSchedule.dateOnly(date);
    return !normalizedDate.isBefore(
          earliestBiweeklyPeriodBeginDate(today: today),
        ) &&
        !normalizedDate.isAfter(latestBiweeklyPeriodBeginDate(today: today));
  }

  static DateTime normalizeBiweeklyPeriodBeginDate(
    DateTime? date, {
    DateTime? today,
  }) {
    if (date == null) return defaultBiweeklyPeriodBeginDate(today: today);

    final DateTime normalizedDate = RecurrenceSchedule.dateOnly(date);
    if (isSelectableBiweeklyPeriodBeginDate(normalizedDate, today: today)) {
      return normalizedDate;
    }

    return defaultBiweeklyPeriodBeginDate(today: today);
  }

  static PayrollPayPeriod calculateBiweeklyPayPeriod({
    required DateTime beginDate,
  }) {
    final DateTime startDate = RecurrenceSchedule.dateOnly(beginDate);
    return PayrollPayPeriod(
      start: startDate,
      end: startDate.add(const Duration(days: biweeklyPeriodDays - 1)),
    );
  }

  static PayrollPayPeriod calculateMonthlyPayPeriod({
    required DateTime payDate,
  }) {
    final DateTime normalizedPayDate = RecurrenceSchedule.dateOnly(payDate);
    final DateTime previousMonth = DateTime(
      normalizedPayDate.year,
      normalizedPayDate.month - 1,
    );

    return PayrollPayPeriod(
      start: DateTime(previousMonth.year, previousMonth.month),
      end: DateTime(normalizedPayDate.year, normalizedPayDate.month, 0),
    );
  }

  static DateTime _monthStart(DateTime date) {
    final DateTime normalizedDate = RecurrenceSchedule.dateOnly(date);
    return DateTime(normalizedDate.year, normalizedDate.month);
  }
}
