part of 'liability_service.dart';

class SaveFutureExpense {
  const SaveFutureExpense._();

  static ExpenseRecord createInitialRecurringExpense({
    required String checkNumber,
    required double totalAmount,
    required DateTime startDate,
    required String category,
    required String payee,
    required bool isManual,
    required String frequency,
    required String Function(String prefix) idGenerator,
    String recurringSeriesId = '',
  }) {
    final transactionDate = RecurrenceSchedule.dateOnly(startDate);
    final seriesId = recurringSeriesId.isEmpty
        ? idGenerator('recurring-expense')
        : recurringSeriesId;
    final recurringFrequency = _normalizedFrequency(frequency);
    return ExpenseRecord(
      id: idGenerator('expense-${_dateToken(transactionDate)}'),
      checkNumber: checkNumber,
      totalAmount: totalAmount,
      transactionDate: transactionDate,
      category: category,
      payee: payee,
      isManual: isManual,
      recurringSeriesId: seriesId,
      recurringIndex: 0,
      recurringFrequency: recurringFrequency,
    );
  }

  static List<ExpenseRecord> createDueRecurringExpenses({
    required String checkNumber,
    required double totalAmount,
    required DateTime startDate,
    required String category,
    required String payee,
    required bool isManual,
    required String frequency,
    required DateTime now,
    required String Function(String prefix) idGenerator,
    String recurringSeriesId = '',
  }) {
    final seriesId = recurringSeriesId.isEmpty
        ? idGenerator('recurring-expense')
        : recurringSeriesId;
    final recurringFrequency = _normalizedFrequency(frequency);
    final dates = _dueRecurringDates(
      startDate: startDate,
      now: now,
      frequency: recurringFrequency,
    );
    return [
      for (var index = 0; index < dates.length; index++)
        ExpenseRecord(
          id: idGenerator('expense-${_dateToken(dates[index])}'),
          checkNumber: checkNumber,
          totalAmount: totalAmount,
          transactionDate: dates[index],
          category: category,
          payee: payee,
          isManual: isManual,
          recurringSeriesId: seriesId,
          recurringIndex: index,
          recurringFrequency: recurringFrequency,
        ),
    ];
  }

  static List<ExpenseRecord> syncDueRecurringExpenses({
    required List<ExpenseRecord> expenses,
    required DateTime now,
    required String Function(String prefix) idGenerator,
  }) {
    final generated = <ExpenseRecord>[];
    final allExpenses = List<ExpenseRecord>.of(expenses);
    final seriesIds = allExpenses
        .where((record) => record.isRecurring)
        .map((record) => record.recurringSeriesId)
        .toSet();

    for (final seriesId in seriesIds) {
      final records =
          allExpenses
              .where((record) => record.recurringSeriesId == seriesId)
              .toList()
            ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
      if (records.isEmpty) continue;

      final recurringEndMonthKey = _seriesEndMonthKey(records);
      final startDate = records.first.transactionDate;
      final frequency = records.first.normalizedRecurringFrequency;
      for (final date in _dueRecurringDates(
        startDate: records.first.transactionDate,
        now: now,
        frequency: frequency,
        recurringEndMonthKey: recurringEndMonthKey,
      )) {
        if (_hasRecurringOccurrence(allExpenses, seriesId, date)) {
          continue;
        }

        final expense = _expenseFromTemplate(
          template: _templateForDate(records, date),
          date: date,
          recurringIndex: _recurringIndex(
            startDate: startDate,
            occurrenceDate: date,
            frequency: frequency,
          ),
          idGenerator: idGenerator,
        );
        generated.add(expense);
        allExpenses.add(expense);
        records.add(expense);
        records.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
      }
    }

    return List<ExpenseRecord>.unmodifiable(generated);
  }

  static List<DateTime> _dueRecurringDates({
    required DateTime startDate,
    required DateTime now,
    required String frequency,
    int recurringEndMonthKey = 0,
  }) {
    final currentMonth = _monthKey(now);
    final normalizedFrequency = _normalizedFrequency(frequency);
    final through =
        recurringEndMonthKey > 0 && recurringEndMonthKey <= currentMonth
        ? _lastDayOfMonthKey(recurringEndMonthKey - 1)
        : normalizedFrequency == RecurrenceSchedule.monthly
        ? _lastDayOfMonthKey(currentMonth)
        : now;
    return RecurrenceSchedule.dueDates(
      startDate: startDate,
      through: through,
      frequency: normalizedFrequency,
    );
  }

  static bool _hasRecurringOccurrence(
    Iterable<ExpenseRecord> expenses,
    String seriesId,
    DateTime date,
  ) {
    return expenses.any(
      (record) =>
          record.recurringSeriesId == seriesId &&
          RecurrenceSchedule.isSameDate(record.transactionDate, date),
    );
  }

  static ExpenseRecord _expenseFromTemplate({
    required ExpenseRecord template,
    required DateTime date,
    required int recurringIndex,
    required String Function(String prefix) idGenerator,
  }) {
    return ExpenseRecord(
      id: idGenerator(
        'expense-${template.recurringSeriesId}-${_dateToken(date)}',
      ),
      checkNumber: template.checkNumber,
      totalAmount: template.totalAmount,
      transactionDate: date,
      category: template.category,
      payee: template.payee,
      isManual: template.isManual,
      recurringSeriesId: template.recurringSeriesId,
      recurringIndex: recurringIndex,
      recurringEndMonthKey: template.recurringEndMonthKey,
      recurringFrequency: template.normalizedRecurringFrequency,
    );
  }

  static ExpenseRecord _templateForDate(
    List<ExpenseRecord> records,

    DateTime date,
  ) {
    final monthKey = _monthKey(date);
    var template = records.first;

    for (final record in records) {
      if (_monthKey(record.transactionDate) > monthKey) break;
      template = record;
    }

    return template;
  }

  static int _seriesEndMonthKey(Iterable<ExpenseRecord> records) {
    var endMonthKey = 0;
    for (final record in records) {
      final recordEndMonthKey = record.recurringEndMonthKey;
      if (recordEndMonthKey <= 0) continue;
      if (endMonthKey == 0 || recordEndMonthKey < endMonthKey) {
        endMonthKey = recordEndMonthKey;
      }
    }
    return endMonthKey;
  }

  static int _monthKey(DateTime date) => date.year * 12 + date.month;

  static DateTime _lastDayOfMonthKey(int monthKey) {
    final year = (monthKey - 1) ~/ 12;
    final month = (monthKey - 1) % 12 + 1;
    return DateTime(year, month + 1, 0);
  }

  static int _recurringIndex({
    required DateTime startDate,
    required DateTime occurrenceDate,
    required String frequency,
  }) {
    final dates = _dueRecurringDates(
      startDate: startDate,
      now: occurrenceDate,
      frequency: frequency,
    );
    return dates.indexWhere(
      (date) => RecurrenceSchedule.isSameDate(date, occurrenceDate),
    );
  }

  static String _normalizedFrequency(String value) {
    return RecurrenceSchedule.isRecurringFrequency(value)
        ? value
        : RecurrenceSchedule.monthly;
  }

  static String _dateToken(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
