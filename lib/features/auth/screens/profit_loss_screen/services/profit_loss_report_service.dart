import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/recurrence_schedule.dart';
import 'package:savetep/services/tax_estimator.dart';

import '../models/profit_loss_models.dart';

class ProfitLossReportService {
  static const String _businessName = 'Save Tep';

  const ProfitLossReportService();

  ProfitLossReport buildReport({
    required ProfitLossData data,
    required int year,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime currentDate,
  }) {
    final DateTime rangeStart = RecurrenceSchedule.dateOnly(periodStart);
    final DateTime rangeEnd = RecurrenceSchedule.dateOnly(periodEnd);
    final List<DepositRecord> rangeDeposits = data.deposits
        .where(
          (DepositRecord record) =>
              _isInDateRange(record.transactionDate, rangeStart, rangeEnd),
        )
        .toList(growable: false);
    final double grossIncome = rangeDeposits.fold<double>(
      0,
      (double sum, DepositRecord record) => sum + record.totalAmount,
    );
    final List<ProfitLossExpenseLine> expenseLines =
        _ProfitLossExpenseCatalog.buildLines(
          data.expenses,
          periodStart: rangeStart,
          periodEnd: rangeEnd,
        );
    final double totalExpenses = expenseLines.fold<double>(
      0,
      (double sum, ProfitLossExpenseLine line) => sum + line.amount,
    );
    final double netIncomeBeforeTaxes = grossIncome - totalExpenses;
    final int taxProjectionMonth = year == currentDate.year
        ? currentDate.month
        : 12;
    final TaxEstimate estimate = TaxEstimator.calculate(
      totalReserve: netIncomeBeforeTaxes,
      currentMonth: taxProjectionMonth,
    );

    return ProfitLossReport(
      year: year,
      periodStart: rangeStart,
      periodEnd: rangeEnd,
      businessName: _businessName,
      grossIncome: grossIncome,
      expenseLines: expenseLines,
      totalExpenses: totalExpenses,
      netIncomeBeforeTaxes: netIncomeBeforeTaxes,
      estimatedTaxPercentage: estimate.bracket.rate,
      estimatedTaxAmount: estimate.taxDue,
      netIncomeAfterTaxes: estimate.remaining,
    );
  }

  static bool _isInDateRange(DateTime value, DateTime start, DateTime end) {
    final DateTime date = RecurrenceSchedule.dateOnly(value);
    return !date.isBefore(start) && !date.isAfter(end);
  }
}

class _ProfitLossExpenseDefinition {
  final String label;
  final List<String> categories;
  final bool trackedInApp;
  final bool includeUnmapped;
  final bool prorateFixedCost;

  const _ProfitLossExpenseDefinition(
    this.label, {
    this.categories = const <String>[],
    this.trackedInApp = false,
    this.includeUnmapped = false,
    this.prorateFixedCost = false,
  });

  String? get reportCategory {
    if (includeUnmapped || categories.length != 1) return null;
    final String category = categories.single.trim();
    return category.isEmpty ? null : category;
  }
}

class _ProfitLossExpenseCatalog {
  const _ProfitLossExpenseCatalog._();

  static const List<_ProfitLossExpenseDefinition>
  definitions = <_ProfitLossExpenseDefinition>[
    _ProfitLossExpenseDefinition(
      'Food Purchase',
      categories: <String>['Food Purchase'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition(
      'merchant accounting fees',
      categories: <String>['merchant accounting fees'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition(
      'professional fees',
      categories: <String>['professional fees'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition(
      'Advertising',
      categories: <String>['Advertising'],
    ),
    _ProfitLossExpenseDefinition(
      'Insurance',
      categories: <String>['Insurance'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition(
      'Maintenance and Repairs',
      categories: <String>['Maintenance and Repairs'],
    ),
    _ProfitLossExpenseDefinition(
      'Payroll',
      categories: <String>['Payroll'],
      trackedInApp: true,
      prorateFixedCost: true,
    ),
    _ProfitLossExpenseDefinition(
      'gas',
      categories: <String>['gas'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition(
      'water',
      categories: <String>['water'],
      trackedInApp: true,
      prorateFixedCost: true,
    ),
    _ProfitLossExpenseDefinition(
      'electric',
      categories: <String>['electric'],
      trackedInApp: true,
      prorateFixedCost: true,
    ),
    _ProfitLossExpenseDefinition(
      'donation',
      categories: <String>['donation'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition('Postage', categories: <String>['Postage']),
    _ProfitLossExpenseDefinition(
      'Rent',
      categories: <String>['Rent'],
      trackedInApp: true,
      prorateFixedCost: true,
    ),
    _ProfitLossExpenseDefinition('Licenses', categories: <String>['Licenses']),
    _ProfitLossExpenseDefinition('Taxes', categories: <String>['Taxes']),
    _ProfitLossExpenseDefinition(
      'Telephone',
      categories: <String>['Telephone'],
    ),
    _ProfitLossExpenseDefinition(
      'Travel/Transportation',
      categories: <String>['Travel/Transportation'],
    ),
    _ProfitLossExpenseDefinition(
      'Other (excluding depreciation/amortization)',
      categories: <String>['Other'],
      includeUnmapped: true,
    ),
  ];

  static List<ProfitLossExpenseLine> buildLines(
    List<ExpenseRecord> expenses, {
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final DateTime rangeStart = RecurrenceSchedule.dateOnly(periodStart);
    final DateTime rangeEndExclusive = RecurrenceSchedule.dateOnly(
      periodEnd,
    ).add(const Duration(days: 1));
    final Set<String> mappedCategories = definitions
        .where(
          (_ProfitLossExpenseDefinition definition) =>
              !definition.includeUnmapped,
        )
        .expand(
          (_ProfitLossExpenseDefinition definition) => definition.categories,
        )
        .map(_normalize)
        .toSet();

    return definitions
        .map((_ProfitLossExpenseDefinition definition) {
          final double amount = definition.includeUnmapped
              ? _sumUnmappedExpenses(
                  expenses,
                  mappedCategories,
                  rangeStart,
                  rangeEndExclusive,
                )
              : _sumExpenses(
                  expenses,
                  definition.categories,
                  rangeStart,
                  rangeEndExclusive,
                  prorateFixedCost: definition.prorateFixedCost,
                );

          return ProfitLossExpenseLine(
            label: definition.label,
            amount: amount,
            trackedInApp: definition.trackedInApp,
            reportCategory: definition.reportCategory,
            periodStart: rangeStart,
            periodEnd: rangeEndExclusive.subtract(const Duration(days: 1)),
          );
        })
        .toList(growable: false);
  }

  static double _sumExpenses(
    List<ExpenseRecord> expenses,
    List<String> categories,
    DateTime rangeStart,
    DateTime rangeEndExclusive, {
    required bool prorateFixedCost,
  }) {
    if (!rangeStart.isBefore(rangeEndExclusive)) return 0;
    final Set<String> categoryKeys = categories.map(_normalize).toSet();
    return expenses
        .where(
          (ExpenseRecord record) =>
              categoryKeys.contains(_normalize(record.category)),
        )
        .fold<double>(
          0,
          (double sum, ExpenseRecord record) =>
              sum +
              _expenseAmountForRange(
                record,
                rangeStart,
                rangeEndExclusive,
                expenses,
                prorateFixedCost: prorateFixedCost,
              ),
        );
  }

  static double _sumUnmappedExpenses(
    List<ExpenseRecord> expenses,
    Set<String> mappedCategories,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
  ) {
    if (!rangeStart.isBefore(rangeEndExclusive)) return 0;
    return expenses
        .where(
          (ExpenseRecord record) =>
              !mappedCategories.contains(_normalize(record.category)),
        )
        .fold<double>(
          0,
          (double sum, ExpenseRecord record) =>
              sum +
              _expenseAmountForRange(
                record,
                rangeStart,
                rangeEndExclusive,
                expenses,
                prorateFixedCost: _isFixedCostCategory(record.category),
              ),
        );
  }

  static double _expenseAmountForRange(
    ExpenseRecord expense,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
    List<ExpenseRecord> allExpenses, {
    required bool prorateFixedCost,
  }) {
    if (expense.isRecurring) {
      return _recurringExpenseAmountForRange(
        expense,
        rangeStart,
        rangeEndExclusive,
        allExpenses,
      );
    }
    if (prorateFixedCost) {
      return _monthlyFixedCostAmountForRange(
        expense,
        rangeStart,
        rangeEndExclusive,
      );
    }
    return _oneTimeExpenseAmountForRange(
      expense,
      rangeStart,
      rangeEndExclusive,
    );
  }

  static double _oneTimeExpenseAmountForRange(
    ExpenseRecord expense,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
  ) {
    final DateTime expenseDate = RecurrenceSchedule.dateOnly(
      expense.transactionDate,
    );
    if (expenseDate.isBefore(rangeStart) ||
        !expenseDate.isBefore(rangeEndExclusive)) {
      return 0;
    }
    return expense.totalAmount;
  }

  static double _monthlyFixedCostAmountForRange(
    ExpenseRecord expense,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
  ) {
    final DateTime expenseDate = RecurrenceSchedule.dateOnly(
      expense.transactionDate,
    );
    final DateTime periodStart = DateTime(expenseDate.year, expenseDate.month);
    final DateTime periodEndExclusive = DateTime(
      expenseDate.year,
      expenseDate.month + 1,
    );
    return _proratedAmountForOverlap(
      amount: expense.totalAmount,
      periodStart: periodStart,
      periodEndExclusive: periodEndExclusive,
      rangeStart: rangeStart,
      rangeEndExclusive: rangeEndExclusive,
    );
  }

  static double _recurringExpenseAmountForRange(
    ExpenseRecord expense,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
    List<ExpenseRecord> allExpenses,
  ) {
    final DateTime periodStart = RecurrenceSchedule.dateOnly(
      expense.transactionDate,
    );
    final DateTime periodEndExclusive = _recurringExpensePeriodEndExclusive(
      expense,
      allExpenses,
    );
    return _proratedAmountForOverlap(
      amount: expense.totalAmount,
      periodStart: periodStart,
      periodEndExclusive: periodEndExclusive,
      rangeStart: rangeStart,
      rangeEndExclusive: rangeEndExclusive,
    );
  }

  static double _proratedAmountForOverlap({
    required double amount,
    required DateTime periodStart,
    required DateTime periodEndExclusive,
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
  }) {
    final int periodDays = periodEndExclusive.difference(periodStart).inDays;
    if (periodDays <= 0) return 0;

    final DateTime overlapStart = _laterDate(periodStart, rangeStart);
    final DateTime overlapEnd = _earlierDate(
      periodEndExclusive,
      rangeEndExclusive,
    );
    final int overlapDays = overlapEnd.difference(overlapStart).inDays;
    if (overlapDays <= 0) return 0;

    final double dailyRate = amount / periodDays;
    return dailyRate * overlapDays;
  }

  static DateTime _recurringExpensePeriodEndExclusive(
    ExpenseRecord expense,
    List<ExpenseRecord> allExpenses,
  ) {
    final DateTime occurrenceDate = RecurrenceSchedule.dateOnly(
      expense.transactionDate,
    );
    final String frequency = expense.normalizedRecurringFrequency;
    final DateTime seriesStartDate = _recurringSeriesStartDate(
      expense,
      allExpenses,
    );
    final DateTime searchThrough = _recurringSearchThrough(
      occurrenceDate,
      frequency,
    );
    final List<DateTime> dates = RecurrenceSchedule.dueDates(
      startDate: seriesStartDate,
      through: searchThrough,
      frequency: frequency,
    );

    for (final DateTime date in dates) {
      if (date.isAfter(occurrenceDate)) return date;
    }

    return _fallbackRecurringPeriodEnd(occurrenceDate, frequency);
  }

  static DateTime _recurringSeriesStartDate(
    ExpenseRecord expense,
    List<ExpenseRecord> allExpenses,
  ) {
    DateTime startDate = RecurrenceSchedule.dateOnly(expense.transactionDate);
    for (final ExpenseRecord record in allExpenses) {
      if (record.recurringSeriesId != expense.recurringSeriesId) continue;
      final DateTime recordDate = RecurrenceSchedule.dateOnly(
        record.transactionDate,
      );
      if (recordDate.isBefore(startDate)) startDate = recordDate;
    }
    return startDate;
  }

  static DateTime _recurringSearchThrough(DateTime date, String frequency) {
    return switch (frequency) {
      RecurrenceSchedule.weekly => date.add(const Duration(days: 14)),
      RecurrenceSchedule.biweekly => date.add(const Duration(days: 28)),
      RecurrenceSchedule.semiMonthly => _addMonthsClamped(date, 2),
      RecurrenceSchedule.quarterly => _addMonthsClamped(date, 6),
      RecurrenceSchedule.yearly => _addMonthsClamped(date, 24),
      _ => _addMonthsClamped(date, 2),
    };
  }

  static DateTime _fallbackRecurringPeriodEnd(DateTime date, String frequency) {
    return switch (frequency) {
      RecurrenceSchedule.weekly => date.add(const Duration(days: 7)),
      RecurrenceSchedule.biweekly => date.add(const Duration(days: 14)),
      RecurrenceSchedule.semiMonthly => date.add(const Duration(days: 15)),
      RecurrenceSchedule.quarterly => _addMonthsClamped(date, 3),
      RecurrenceSchedule.yearly => _addMonthsClamped(date, 12),
      _ => _addMonthsClamped(date, 1),
    };
  }

  static DateTime _addMonthsClamped(DateTime date, int months) {
    final int totalMonths = date.year * 12 + date.month - 1 + months;
    final int year = totalMonths ~/ 12;
    final int month = totalMonths % 12 + 1;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final int day = date.day < daysInMonth ? date.day : daysInMonth;
    return DateTime(year, month, day);
  }

  static DateTime _laterDate(DateTime left, DateTime right) {
    return left.isAfter(right) ? left : right;
  }

  static DateTime _earlierDate(DateTime left, DateTime right) {
    return left.isBefore(right) ? left : right;
  }

  static bool _isFixedCostCategory(String value) {
    return switch (_normalize(value)) {
      'payroll' || 'rent' || 'water' || 'electric' => true,
      _ => false,
    };
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
