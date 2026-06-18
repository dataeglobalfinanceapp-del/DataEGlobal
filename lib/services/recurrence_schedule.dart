class RecurrenceSchedule {
  const RecurrenceSchedule._();

  static const String weekly = 'Weekly';
  static const String biweekly = 'Biweekly';
  static const String semiMonthly = 'Semi-monthly';
  static const String monthly = 'Monthly';
  static const String quarterly = 'Quarterly';
  static const String yearly = 'Yearly';

  static bool isRecurringFrequency(String value) {
    return switch (value.trim().toLowerCase()) {
      'weekly' ||
      'biweekly' ||
      'semi-monthly' ||
      'monthly' ||
      'quarterly' ||
      'yearly' => true,
      _ => false,
    };
  }

  static List<DateTime> dueDates({
    required DateTime startDate,
    required DateTime through,
    required String frequency,
  }) {
    final start = dateOnly(startDate);
    final end = dateOnly(through);
    if (start.isAfter(end)) return const <DateTime>[];

    final dates = <DateTime>[];
    for (var year = start.year; year <= end.year; year++) {
      dates.addAll(
        occurrenceDatesForYear(
          startDate: start,
          frequency: frequency,
          year: year,
        ).where((date) => !date.isBefore(start) && !date.isAfter(end)),
      );
    }
    dates.sort();
    return List<DateTime>.unmodifiable(dates);
  }

  static List<DateTime> occurrenceDatesForYear({
    required DateTime startDate,
    required String frequency,
    required int year,
  }) {
    final start = dateOnly(startDate);
    if (year < start.year) return const <DateTime>[];

    final startOfYear = DateTime(year);
    final endOfYear = DateTime(year, 12, 31);
    final normalizedFrequency = frequency.toLowerCase();

    if (normalizedFrequency == 'weekly' || normalizedFrequency == 'biweekly') {
      final intervalDays = normalizedFrequency == 'weekly' ? 7 : 14;
      var date = start;
      if (date.isBefore(startOfYear)) {
        final difference = startOfYear.difference(date).inDays;
        final offset = difference % intervalDays == 0
            ? 0
            : intervalDays - (difference % intervalDays);
        date = startOfYear.add(Duration(days: offset));
      }

      final dates = <DateTime>[];
      while (!date.isAfter(endOfYear)) {
        dates.add(dateOnly(date));
        date = date.add(Duration(days: intervalDays));
      }
      return dates;
    }

    if (normalizedFrequency == 'semi-monthly') {
      return _semiMonthlyDatesForYear(start, year);
    }

    final intervalMonths = switch (normalizedFrequency) {
      'monthly' => 1,
      'quarterly' => 3,
      'yearly' => 12,
      _ => 0,
    };
    if (intervalMonths == 0) return const <DateTime>[];

    final dates = <DateTime>[];
    for (var index = 0; index < 1200; index++) {
      final date = _addMonthsClamped(start, index * intervalMonths);
      if (date.year > year) break;
      if (date.year == year) dates.add(date);
    }
    return dates;
  }

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static List<DateTime> _semiMonthlyDatesForYear(DateTime startDate, int year) {
    final dates = <DateTime>[];
    final firstMonth = year == startDate.year ? startDate.month : 1;
    final anchorDays = _semiMonthlyAnchorDays(startDate.day);

    for (var month = firstMonth; month <= 12; month++) {
      for (final day in anchorDays) {
        final date = _clampedDate(year, month, day);
        if (date.isBefore(startDate) || _containsDate(dates, date)) continue;
        dates.add(date);
      }
    }

    return dates;
  }

  static List<int> _semiMonthlyAnchorDays(int startDay) {
    final pairedDay = startDay > 15 ? startDay - 15 : startDay + 15;
    return <int>[startDay, pairedDay]..sort();
  }

  static DateTime _clampedDate(int year, int month, int day) {
    return DateTime(year, month, _minInt(day, _daysInMonth(year, month)));
  }

  static bool _containsDate(List<DateTime> dates, DateTime date) {
    return dates.any((entry) => isSameDate(entry, date));
  }

  static DateTime _addMonthsClamped(DateTime date, int months) {
    final totalMonths = date.year * 12 + date.month - 1 + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final day = _minInt(date.day, _daysInMonth(year, month));
    return DateTime(year, month, day);
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static int _minInt(int a, int b) => a < b ? a : b;
}
