part of 'liability_service.dart';

class SaveFutureExpense {
  const SaveFutureExpense._();

  static List<ExpenseRecord> createDueMonthlyExpenses({
    required String checkNumber,
    required double totalAmount,
    required DateTime transactionDate,
    required String category,
    required String payee,
    required bool isManual,
    required DateTime now,
  }) {
    final recurringSeriesId = LiabilityService._newId('recurring-expense');
    return _dueMonthlyDates(startDate: transactionDate, now: now)
        .map(
          (date) => ExpenseRecord(
            id: LiabilityService._newId('expense-${date.year}-${date.month}'),
            checkNumber: checkNumber,
            totalAmount: totalAmount,
            transactionDate: date,
            category: category,
            payee: payee,
            isManual: isManual,
            recurringSeriesId: recurringSeriesId,
            recurringIndex: _recurringIndex(transactionDate, date),
          ),
        )
        .toList();
  }

  static bool syncDueMonthlyExpenses(DateTime now) {
    var changed = _removeUnstartedRecurringExpenses(now);
    final seriesIds = LiabilityService._expenses
        .where((record) => record.isRecurring)
        .map((record) => record.recurringSeriesId)
        .toSet();

    for (final seriesId in seriesIds) {
      final records =
          LiabilityService._expenses
              .where((record) => record.recurringSeriesId == seriesId)
              .toList()
            ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
      if (records.isEmpty) continue;

      final template = records.first;
      for (final date in _dueMonthlyDates(
        startDate: template.transactionDate,
        now: now,
      )) {
        if (_hasRecurringOccurrence(seriesId, date.year, date.month)) {
          continue;
        }

        LiabilityService._addExpense(
          _expenseFromTemplate(template: template, date: date),
        );
        changed = true;
      }
    }

    return changed;
  }

  static bool _removeUnstartedRecurringExpenses(DateTime now) {
    final currentMonth = _monthKey(now);
    final expensesToRemove = LiabilityService._expenses
        .where(
          (record) =>
              record.isRecurring &&
              _monthKey(record.transactionDate) > currentMonth,
        )
        .toList();
    if (expensesToRemove.isEmpty) return false;

    final expenseIds = expensesToRemove.map((record) => record.id).toSet();
    LiabilityService._expenses.removeWhere(
      (record) => expenseIds.contains(record.id),
    );
    LiabilityService._liabilities.removeWhere(
      (record) =>
          expenseIds.any(
            (expenseId) => record.source == 'expense:$expenseId',
          ) ||
          expensesToRemove.any(
            (expense) =>
                LiabilityService._isLegacyExpenseLiability(record, expense),
          ),
    );
    return true;
  }

  static List<DateTime> _dueMonthlyDates({
    required DateTime startDate,
    required DateTime now,
  }) {
    final startMonth = _monthKey(startDate);
    final currentMonth = _monthKey(now);
    if (startMonth > currentMonth) return [];

    return [
      startDate,
      for (var monthKey = startMonth + 1; monthKey <= currentMonth; monthKey++)
        _dateFromMonthKey(monthKey),
    ];
  }

  static bool _hasRecurringOccurrence(String seriesId, int year, int month) {
    return LiabilityService._expenses.any(
      (record) =>
          record.recurringSeriesId == seriesId &&
          record.transactionDate.year == year &&
          record.transactionDate.month == month,
    );
  }

  static ExpenseRecord _expenseFromTemplate({
    required ExpenseRecord template,
    required DateTime date,
  }) {
    return ExpenseRecord(
      id: LiabilityService._newId(
        'expense-${template.recurringSeriesId}-${date.year}-${date.month}',
      ),
      checkNumber: template.checkNumber,
      totalAmount: template.totalAmount,
      transactionDate: date,
      category: template.category,
      payee: template.payee,
      isManual: template.isManual,
      recurringSeriesId: template.recurringSeriesId,
      recurringIndex: _recurringIndex(template.transactionDate, date),
    );
  }

  static int _monthKey(DateTime date) => date.year * 12 + date.month;

  static DateTime _dateFromMonthKey(int monthKey) {
    final year = (monthKey - 1) ~/ 12;
    final month = (monthKey - 1) % 12 + 1;
    return DateTime(year, month);
  }

  static int _recurringIndex(DateTime startDate, DateTime occurrenceDate) {
    return (occurrenceDate.year - startDate.year) * 12 +
        occurrenceDate.month -
        startDate.month;
  }
}
