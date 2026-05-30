import 'package:flutter/foundation.dart';

class AppClock {
  AppClock._();

  static final ValueNotifier<DateTime?> _override = ValueNotifier<DateTime?>(
    null,
  );

  static DateTime get now => _override.value ?? DateTime.now();

  static bool get isOverridden => _override.value != null;

  static ValueListenable<DateTime?> get listenable => _override;

  static void set(DateTime value) {
    _override.value = value;
  }

  static void reset() {
    _override.value = null;
  }

  static void shiftDays(int days) {
    set(now.add(Duration(days: days)));
  }

  static void shiftMonths(int months) {
    final current = now;
    final totalMonths = current.year * 12 + current.month - 1 + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final day = _minInt(current.day, _daysInMonth(year, month));
    set(
      DateTime(
        year,
        month,
        day,
        current.hour,
        current.minute,
        current.second,
        current.millisecond,
        current.microsecond,
      ),
    );
  }

  static void shiftYears(int years) {
    shiftMonths(years * 12);
  }

  static DateTime withDate(DateTime date) {
    final current = now;
    return DateTime(
      date.year,
      date.month,
      date.day,
      current.hour,
      current.minute,
      current.second,
      current.millisecond,
      current.microsecond,
    );
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static int _minInt(int a, int b) => a < b ? a : b;
}
