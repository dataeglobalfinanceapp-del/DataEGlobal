import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/recurrence_schedule.dart';

class PayrollPayDateValidator {
  static const int firstSelectableOffsetDays = 1;

  const PayrollPayDateValidator._();

  static DateTime firstSelectablePayDate({DateTime? today}) {
    return RecurrenceSchedule.dateOnly(
      today ?? AppClock.now,
    ).add(const Duration(days: firstSelectableOffsetDays));
  }

  static bool isSelectablePayDate(DateTime date, {DateTime? today}) {
    return !RecurrenceSchedule.dateOnly(
      date,
    ).isBefore(firstSelectablePayDate(today: today));
  }

  static DateTime normalizePayDate(DateTime date, {DateTime? today}) {
    final DateTime normalizedDate = RecurrenceSchedule.dateOnly(date);
    final DateTime firstSelectableDate = firstSelectablePayDate(today: today);
    if (normalizedDate.isBefore(firstSelectableDate)) {
      return firstSelectableDate;
    }

    return normalizedDate;
  }
}
