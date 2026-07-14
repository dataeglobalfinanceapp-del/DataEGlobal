import 'package:savetep/services/app_clock.dart';

class PayrollPayDateValidator {
  static const int firstSelectableOffsetDays = 1;

  const PayrollPayDateValidator._();

  static DateTime firstSelectablePayDate({DateTime? today}) {
    return _dateOnly(
      today ?? AppClock.now,
    ).add(const Duration(days: firstSelectableOffsetDays));
  }

  static bool isSelectablePayDate(DateTime date, {DateTime? today}) {
    return !_dateOnly(date).isBefore(firstSelectablePayDate(today: today));
  }

  static DateTime normalizePayDate(DateTime date, {DateTime? today}) {
    final DateTime normalizedDate = _dateOnly(date);
    final DateTime firstSelectableDate = firstSelectablePayDate(today: today);
    if (normalizedDate.isBefore(firstSelectableDate)) {
      return firstSelectableDate;
    }

    return normalizedDate;
  }
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
