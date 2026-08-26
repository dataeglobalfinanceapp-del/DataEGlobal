import 'package:savetep/features/auth/screens/saving_screen/saving_rollover_calculator.dart';
import 'package:savetep/features/auth/screens/saving_screen/saving_screen_models.dart';

class SavingPlanCalculator {
  const SavingPlanCalculator._();

  static List<SavingPeriodRow> buildRows({
    required SavingPeriod period,
    required int year,
    required double totalTarget,
    required Map<DateTime, double> dailySavedAmounts,
    required DateTime today,
  }) {
    final rows = switch (period) {
      SavingPeriod.day => _buildDailyRows(year, totalTarget),
      SavingPeriod.week => _buildWeeklyRows(year, totalTarget),
      SavingPeriod.month => _buildMonthlyRows(year, totalTarget),
    };

    final requiredAmounts = calculateSavingRequiredAmounts(
      periods: [
        for (final row in rows)
          SavingRolloverPeriod(
            end: row.end,
            requiredAmount: row.requiredAmount,
            savedAmount: savedAmountInRange(
              dailySavedAmounts,
              row.start,
              row.end,
            ),
          ),
      ],
      today: today,
    );

    return [
      for (var index = 0; index < rows.length; index++)
        rows[index].copyWith(requiredAmount: requiredAmounts[index]),
    ];
  }

  static List<SavingPeriodRow> visibleRows({
    required List<SavingPeriodRow> rows,
    required DateTime today,
    required bool showPastPeriods,
  }) {
    if (showPastPeriods) return rows;
    return rows.where((row) => !isPast(row, today)).toList();
  }

  static List<SavingPeriodRow> pastRows({
    required List<SavingPeriodRow> rows,
    required DateTime today,
  }) {
    return rows.where((row) => isPast(row, today)).toList();
  }

  static bool isPast(SavingPeriodRow row, DateTime today) {
    return dateOnly(row.end).isBefore(dateOnly(today));
  }

  static double savedAmountInRange(
    Map<DateTime, double> dailySavedAmounts,
    DateTime start,
    DateTime end,
  ) {
    return _datesInRange(
      start,
      end,
    ).fold<double>(0, (sum, date) => sum + (dailySavedAmounts[date] ?? 0));
  }

  static Map<DateTime, double> recordSavedAmount({
    required Map<DateTime, double> dailySavedAmounts,
    required DateTime start,
    required DateTime end,
    required double amount,
  }) {
    final dates = _datesInRange(start, end);
    if (dates.isEmpty) return Map<DateTime, double>.of(dailySavedAmounts);

    final updatedAmounts = Map<DateTime, double>.of(dailySavedAmounts);
    final share = amount / dates.length;
    for (final date in dates) {
      if (share == 0) {
        updatedAmounts.remove(date);
      } else {
        updatedAmounts[date] = share;
      }
    }
    return updatedAmounts;
  }

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static List<SavingPeriodRow> _buildDailyRows(int year, double totalTarget) {
    final start = DateTime(year);
    final days = DateTime(year + 1).difference(start).inDays;
    final requiredAmount = days == 0 ? 0.0 : totalTarget / days;

    return List.generate(days, (index) {
      final date = start.add(Duration(days: index));
      return SavingPeriodRow(
        key: '$year-day-$index',
        start: date,
        end: date,
        requiredAmount: requiredAmount,
      );
    });
  }

  static List<SavingPeriodRow> _buildWeeklyRows(int year, double totalTarget) {
    final spans = _weekSpansForYear(year);
    final requiredAmount = spans.isEmpty ? 0.0 : totalTarget / spans.length;

    return List.generate(spans.length, (index) {
      final span = spans[index];
      return SavingPeriodRow(
        key: '$year-week-$index',
        start: span.start,
        end: span.end,
        requiredAmount: requiredAmount,
      );
    });
  }

  static List<SavingPeriodRow> _buildMonthlyRows(int year, double totalTarget) {
    const months = 12;
    final requiredAmount = totalTarget / months;

    return List.generate(months, (index) {
      final month = index + 1;
      return SavingPeriodRow(
        key: '$year-month-$month',
        start: DateTime(year, month),
        end: DateTime(year, month + 1, 0),
        requiredAmount: requiredAmount,
      );
    });
  }

  static List<_DateSpan> _weekSpansForYear(int year) {
    final firstDay = DateTime(year);
    final lastDay = DateTime(year, 12, 31);
    final weeks = <_DateSpan>[];

    var start = firstDay;
    while (!start.isAfter(lastDay)) {
      final end = start.add(const Duration(days: 6));
      weeks.add(
        _DateSpan(start: start, end: end.isAfter(lastDay) ? lastDay : end),
      );
      start = start.add(const Duration(days: 7));
    }
    return weeks;
  }

  static List<DateTime> _datesInRange(DateTime start, DateTime end) {
    final first = dateOnly(start);
    final last = dateOnly(end);
    final dayCount = last.difference(first).inDays + 1;
    if (dayCount <= 0) return const [];

    return List.generate(dayCount, (index) => first.add(Duration(days: index)));
  }
}

class _DateSpan {
  final DateTime start;
  final DateTime end;

  const _DateSpan({required this.start, required this.end});
}
