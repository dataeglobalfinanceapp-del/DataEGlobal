enum HomePeriodType {
  day('Day'),
  week('Week'),
  month('Month'),
  quarter('3 Months');

  const HomePeriodType(this.label);

  final String label;
}

class HomeDateRange {
  final DateTime start;
  final DateTime end;

  const HomeDateRange({required this.start, required this.end});
}

class HomeMonthOption {
  final int month;
  final String label;

  const HomeMonthOption({required this.month, required this.label});
}

class HomeQuarterOption {
  final int quarter;
  final String label;

  const HomeQuarterOption({required this.quarter, required this.label});
}

class HomeDateRangeCalculator {
  const HomeDateRangeCalculator._();

  static const int firstMonth = 1;
  static const int monthsInQuarter = 3;
  static const int weekLookbackDays = 6;

  static HomeDateRange rangeFor({
    required HomePeriodType period,
    required int selectedMonth,
    required int selectedQuarter,
    required DateTime today,
  }) {
    final currentDay = dateOnly(today);

    return switch (period) {
      HomePeriodType.day => HomeDateRange(start: currentDay, end: currentDay),
      HomePeriodType.week => HomeDateRange(
        start: currentDay.subtract(const Duration(days: weekLookbackDays)),
        end: currentDay,
      ),
      HomePeriodType.month => _monthRange(
        month: clampMonth(selectedMonth, currentDay),
        today: currentDay,
      ),
      HomePeriodType.quarter => _quarterRange(
        quarter: clampQuarter(selectedQuarter, currentDay),
        today: currentDay,
      ),
    };
  }

  static List<HomeMonthOption> availableMonthOptions(DateTime today) {
    final currentDay = dateOnly(today);
    return List<HomeMonthOption>.generate(currentDay.month, (index) {
      final month = index + 1;
      return HomeMonthOption(month: month, label: monthNames[month]);
    }, growable: false);
  }

  static List<HomeQuarterOption> availableQuarterOptions(DateTime today) {
    final current = currentQuarter(today);
    return List<HomeQuarterOption>.generate(current, (index) {
      final quarter = index + 1;
      return HomeQuarterOption(quarter: quarter, label: 'Q$quarter');
    }, growable: false);
  }

  static int currentQuarter(DateTime date) {
    return ((dateOnly(date).month - 1) ~/ monthsInQuarter) + 1;
  }

  static int clampMonth(int month, DateTime today) {
    return month.clamp(firstMonth, dateOnly(today).month).toInt();
  }

  static int clampQuarter(int quarter, DateTime today) {
    return quarter.clamp(1, currentQuarter(today)).toInt();
  }

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static HomeDateRange _monthRange({
    required int month,
    required DateTime today,
  }) {
    final start = DateTime(today.year, month);
    final isCurrentMonth = month == today.month;
    return HomeDateRange(
      start: start,
      end: isCurrentMonth ? today : DateTime(today.year, month + 1, 0),
    );
  }

  static HomeDateRange _quarterRange({
    required int quarter,
    required DateTime today,
  }) {
    final startMonth = ((quarter - 1) * monthsInQuarter) + firstMonth;
    final endMonth = startMonth + monthsInQuarter - 1;
    final start = DateTime(today.year, startMonth);
    final isCurrentQuarter = quarter == currentQuarter(today);
    return HomeDateRange(
      start: start,
      end: isCurrentQuarter ? today : DateTime(today.year, endMonth + 1, 0),
    );
  }
}

const monthNames = <String>[
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
