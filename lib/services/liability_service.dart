import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:savetep/data/dto/save_deposit_request.dart';
import 'package:savetep/data/dto/save_expense_request.dart';
import 'package:savetep/data/dto/save_liability_request.dart';
import 'package:savetep/data/local/local_transaction_repository.dart';
import 'package:savetep/data/repositories/transaction_repository.dart';
import 'package:savetep/features/auth/models/budget_data.dart';
import 'package:savetep/features/auth/models/liability_model.dart';

import 'app_clock.dart';
import 'recurrence_schedule.dart';

part 'save_future_expense.dart';

class LiabilityService {
  static TransactionRepository _repository = LocalTransactionRepository();

  static int _idCounter = 0;
  static bool _disablePersistenceForTesting = false;
  static bool _seedDefaultBudgetDataForTesting = false;
  static final ValueNotifier<int> _dataVersion = ValueNotifier<int>(0);

  static ValueListenable<int> get dataVersion => _dataVersion;

  static void configureRepository(TransactionRepository repository) {
    _repository = repository;
    _seedDefaultBudgetDataForTesting = false;
  }

  static Future<void> saveDeposit({
    required String orderNumber,
    required double totalAmount,
    required double creditDeposit,
    required double cash,
    required double giftCard,
    required double other,
    required DateTime transactionDate,
    required bool isManual,
  }) async {
    await _prepareRepository();
    await _repository.saveDeposit(
      SaveDepositRequest(
        orderNumber: orderNumber,
        totalAmount: totalAmount,
        creditDeposit: creditDeposit,
        cash: cash,
        giftCard: giftCard,
        other: other,
        transactionDate: transactionDate,
        isManual: isManual,
      ),
    );
    _notifyDataChanged();
  }

  static Future<void> saveExpense({
    required String checkNumber,
    required double totalAmount,
    required DateTime transactionDate,
    required String category,
    required String payee,
    required bool isManual,
    bool isRecurringMonthly = false,
    DateTime? recurringStartDate,
    String recurringFrequency = RecurrenceSchedule.monthly,
    String recurringSeriesId = '',
  }) async {
    await _prepareRepository();

    final expenses = isRecurringMonthly
        ? [
            SaveFutureExpense.createInitialRecurringExpense(
              checkNumber: checkNumber,
              totalAmount: totalAmount,
              startDate: recurringStartDate ?? transactionDate,
              category: category,
              payee: payee,
              isManual: isManual,
              frequency: recurringFrequency,
              recurringSeriesId: recurringSeriesId,
              idGenerator: _newId,
            ),
          ]
        : [
            ExpenseRecord(
              id: _newId('expense'),
              checkNumber: checkNumber,
              totalAmount: totalAmount,
              transactionDate: transactionDate,
              category: category,
              payee: payee,
              isManual: isManual,
            ),
          ];

    for (final expense in expenses) {
      final saved = await _repository.saveExpense(_requestFromExpense(expense));
      await _saveExpenseLiability(saved);
    }

    _notifyDataChanged();
  }

  static Future<String?> syncPayrollExpense({
    required String payrollId,
    required String existingExpenseId,
    required double totalAmount,
    required DateTime payDate,
  }) async {
    final state = await _loadPreparedState();
    final String checkNumber = _payrollCheckNumber(payrollId);
    final int existingIndex = state.expenses.indexWhere(
      (ExpenseRecord record) =>
          record.id == existingExpenseId ||
          (existingExpenseId.isEmpty &&
              record.checkNumber == checkNumber &&
              record.category == 'Payroll'),
    );

    if (totalAmount <= 0) {
      if (existingIndex == -1) return null;

      final ExpenseRecord removed = state.expenses.removeAt(existingIndex);
      _removeExpenseLiabilities(state, <ExpenseRecord>[removed]);
      await _saveState(state);
      _notifyDataChanged();
      return null;
    }

    final ExpenseRecord syncedExpense = ExpenseRecord(
      id: existingIndex == -1
          ? _newId('expense-payroll')
          : state.expenses[existingIndex].id,
      checkNumber: checkNumber,
      totalAmount: totalAmount,
      transactionDate: RecurrenceSchedule.dateOnly(payDate),
      category: 'Payroll',
      payee: 'Payroll',
      isManual: true,
    );

    if (existingIndex == -1) {
      _addExpense(state, syncedExpense);
    } else {
      final ExpenseRecord oldExpense = state.expenses[existingIndex];
      _removeExpenseLiabilities(state, <ExpenseRecord>[oldExpense]);
      state.expenses[existingIndex] = syncedExpense;
      _addExpenseLiability(state, syncedExpense);
    }

    await _saveState(state);
    _notifyDataChanged();
    return syncedExpense.id;
  }

  static void _addExpense(_TransactionState state, ExpenseRecord expense) {
    state.expenses.add(expense);
    _addExpenseLiability(state, expense);
  }

  static void _addExpenseLiability(
    _TransactionState state,
    ExpenseRecord expense,
  ) {
    if (expense.category == 'Loan Obligation') {
      state.liabilities.add(_liabilityFromExpense(expense));
    }
  }

  static Future<void> _saveExpenseLiability(ExpenseRecord expense) async {
    if (expense.category != 'Loan Obligation') return;

    final liability = _liabilityFromExpense(expense);
    await _repository.saveLiability(_requestFromLiability(liability));
  }

  static Future<bool> deleteDeposit(String id) async {
    await _prepareRepository();
    final removed = await _repository.deleteDeposit(id);
    if (removed) {
      _notifyDataChanged();
    }
    return removed;
  }

  static Future<bool> updateRecurringExpenseAmount({
    required String recurringSeriesId,
    required double amount,
    DateTime? occurrenceDate,
    DateTime? fromDate,
  }) async {
    if (recurringSeriesId.isEmpty || amount <= 0) return false;

    final state = await _loadPreparedState();
    final DateTime? occurrence = occurrenceDate == null
        ? null
        : RecurrenceSchedule.dateOnly(occurrenceDate);
    final DateTime cutoff = RecurrenceSchedule.dateOnly(
      fromDate ?? AppClock.now,
    );
    final List<ExpenseRecord> seriesExpenses =
        state.expenses
            .where((record) => record.recurringSeriesId == recurringSeriesId)
            .toList()
          ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
    if (seriesExpenses.isEmpty) return false;

    final List<ExpenseRecord> expensesToUpdate = occurrence == null
        ? seriesExpenses
              .where(
                (record) => !RecurrenceSchedule.dateOnly(
                  record.transactionDate,
                ).isBefore(cutoff),
              )
              .toList(growable: false)
        : seriesExpenses
              .where(
                (record) => RecurrenceSchedule.isSameDate(
                  record.transactionDate,
                  occurrence,
                ),
              )
              .toList(growable: false);

    ExpenseRecord? newFutureExpense;
    if (occurrence == null &&
        !seriesExpenses.any(
          (record) =>
              RecurrenceSchedule.isSameDate(record.transactionDate, cutoff),
        )) {
      if (!_isRecurringSeriesActiveAt(seriesExpenses, cutoff)) return false;
      newFutureExpense = _recurringExpenseOccurrenceForDate(
        records: seriesExpenses,
        date: cutoff,
        amount: amount,
      );
      if (newFutureExpense == null) return false;
      _addExpense(state, newFutureExpense);
    }

    if (expensesToUpdate.isEmpty && newFutureExpense == null) return false;

    final Set<String> expenseIds = expensesToUpdate
        .map((record) => record.id)
        .toSet();
    _removeExpenseLiabilities(state, expensesToUpdate);

    for (var index = 0; index < state.expenses.length; index++) {
      final ExpenseRecord record = state.expenses[index];
      if (!expenseIds.contains(record.id)) continue;
      state.expenses[index] = record.copyWith(totalAmount: amount);
      _addExpenseLiability(state, state.expenses[index]);
    }

    await _saveState(state);
    _notifyDataChanged();
    return true;
  }

  static ExpenseRecord? _recurringExpenseOccurrenceForDate({
    required List<ExpenseRecord> records,
    required DateTime date,
    required double amount,
  }) {
    if (records.isEmpty) return null;

    final DateTime occurrenceDate = RecurrenceSchedule.dateOnly(date);
    final ExpenseRecord first = records.first;
    final DateTime startDate = RecurrenceSchedule.dateOnly(
      first.transactionDate,
    );
    final String frequency = first.normalizedRecurringFrequency;
    if (occurrenceDate.isBefore(startDate) ||
        !_isRecurringOccurrenceDate(
          startDate: startDate,
          date: occurrenceDate,
          frequency: frequency,
        )) {
      return null;
    }

    final ExpenseRecord? template = _latestRecurringExpenseOnOrBefore(
      records,
      occurrenceDate,
    );
    if (template == null) return null;

    return SaveFutureExpense._expenseFromTemplate(
      template: template,
      date: occurrenceDate,
      recurringIndex: SaveFutureExpense._recurringIndex(
        startDate: startDate,
        occurrenceDate: occurrenceDate,
        frequency: frequency,
      ),
      idGenerator: _newId,
    ).copyWith(totalAmount: amount);
  }

  static ExpenseRecord? _latestRecurringExpenseOnOrBefore(
    List<ExpenseRecord> records,
    DateTime date,
  ) {
    ExpenseRecord? template;
    for (final ExpenseRecord record in records) {
      if (RecurrenceSchedule.dateOnly(record.transactionDate).isAfter(date)) {
        break;
      }
      template = record;
    }
    return template;
  }

  static bool _isRecurringOccurrenceDate({
    required DateTime startDate,
    required DateTime date,
    required String frequency,
  }) {
    return RecurrenceSchedule.occurrenceDatesForYear(
      startDate: startDate,
      frequency: frequency,
      year: date.year,
    ).any((occurrence) => RecurrenceSchedule.isSameDate(occurrence, date));
  }

  static bool _isRecurringSeriesActiveAt(
    List<ExpenseRecord> records,
    DateTime date,
  ) {
    final int endMonthKey = SaveFutureExpense._seriesEndMonthKey(records);
    return endMonthKey <= 0 || SaveFutureExpense._monthKey(date) < endMonthKey;
  }

  static Future<bool> deleteExpense(String id) async {
    final state = await _loadPreparedState();
    final matching = state.expenses.where((record) => record.id == id).toList();
    if (matching.isEmpty) return false;

    final expense = matching.first;
    if (expense.isRecurring) {
      return _stopRecurringExpenseFromMonth(state, expense, AppClock.now);
    }

    final expensesToDelete = matching;
    final expenseIds = expensesToDelete.map((record) => record.id).toSet();

    state.expenses.removeWhere((record) => expenseIds.contains(record.id));
    _removeExpenseLiabilities(state, expensesToDelete);
    await _saveState(state);
    _notifyDataChanged();
    return true;
  }

  static Future<bool> deleteFutureRecurringExpenses({
    required String recurringSeriesId,
    DateTime? fromDate,
  }) async {
    if (recurringSeriesId.isEmpty) return false;

    final state = await _loadPreparedState();
    final DateTime cutoff = RecurrenceSchedule.dateOnly(
      fromDate ?? AppClock.now,
    );
    final int cutoffMonthKey = SaveFutureExpense._monthKey(cutoff);
    final List<ExpenseRecord> expensesToDelete = state.expenses
        .where(
          (record) =>
              record.recurringSeriesId == recurringSeriesId &&
              !RecurrenceSchedule.dateOnly(
                record.transactionDate,
              ).isBefore(cutoff),
        )
        .toList(growable: false);
    final List<ExpenseRecord> retainedExpenses = state.expenses
        .where(
          (record) =>
              record.recurringSeriesId == recurringSeriesId &&
              RecurrenceSchedule.dateOnly(
                record.transactionDate,
              ).isBefore(cutoff),
        )
        .toList(growable: false);

    final bool retainedEndMonthChanged = retainedExpenses.any(
      (record) =>
          _earlierRecurringEndMonthKey(
            record.recurringEndMonthKey,
            cutoffMonthKey,
          ) !=
          record.recurringEndMonthKey,
    );
    if (expensesToDelete.isEmpty && !retainedEndMonthChanged) return false;

    final Set<String> expenseIdsToDelete = expensesToDelete
        .map((record) => record.id)
        .toSet();
    state.expenses.removeWhere(
      (record) => expenseIdsToDelete.contains(record.id),
    );
    _removeExpenseLiabilities(state, expensesToDelete);

    final Set<String> retainedExpenseIds = retainedExpenses
        .map((record) => record.id)
        .toSet();
    for (var index = 0; index < state.expenses.length; index++) {
      final ExpenseRecord record = state.expenses[index];
      if (!retainedExpenseIds.contains(record.id)) continue;
      state.expenses[index] = record.copyWith(
        recurringEndMonthKey: _earlierRecurringEndMonthKey(
          record.recurringEndMonthKey,
          cutoffMonthKey,
        ),
      );
    }

    await _saveState(state);
    _notifyDataChanged();
    return true;
  }

  static Future<bool> _stopRecurringExpenseFromMonth(
    _TransactionState state,
    ExpenseRecord expense,
    DateTime month,
  ) async {
    final deleteMonthKey = SaveFutureExpense._monthKey(month);
    final seriesRecords = state.expenses
        .where(
          (record) => record.recurringSeriesId == expense.recurringSeriesId,
        )
        .toList();
    final expensesToDelete = seriesRecords
        .where(
          (record) =>
              SaveFutureExpense._monthKey(record.transactionDate) >=
              deleteMonthKey,
        )
        .toList();
    final retainedExpenseIds = seriesRecords
        .where(
          (record) =>
              SaveFutureExpense._monthKey(record.transactionDate) <
              deleteMonthKey,
        )
        .map((record) => record.id)
        .toSet();
    final retainedEndMonthChanged = seriesRecords.any(
      (record) =>
          retainedExpenseIds.contains(record.id) &&
          _earlierRecurringEndMonthKey(
                record.recurringEndMonthKey,
                deleteMonthKey,
              ) !=
              record.recurringEndMonthKey,
    );

    if (expensesToDelete.isEmpty && !retainedEndMonthChanged) return true;

    final expenseIdsToDelete = expensesToDelete
        .map((record) => record.id)
        .toSet();
    state.expenses.removeWhere(
      (record) => expenseIdsToDelete.contains(record.id),
    );
    _removeExpenseLiabilities(state, expensesToDelete);

    for (var index = 0; index < state.expenses.length; index++) {
      final record = state.expenses[index];
      if (!retainedExpenseIds.contains(record.id)) continue;
      state.expenses[index] = record.copyWith(
        recurringEndMonthKey: _earlierRecurringEndMonthKey(
          record.recurringEndMonthKey,
          deleteMonthKey,
        ),
      );
    }

    await _saveState(state);
    _notifyDataChanged();
    return true;
  }

  static int _earlierRecurringEndMonthKey(int current, int candidate) {
    if (current <= 0) return candidate;
    if (candidate <= 0) return current;
    return current < candidate ? current : candidate;
  }

  static Future<void> saveLiability({
    required LiabilityTab tab,
    required String name,
    required DateTime date,
    required double starting,
    required double minimum,
    required int percent,
  }) async {
    await _prepareRepository();
    await _repository.saveLiability(
      SaveLiabilityRequest(
        tab: tab,
        name: name,
        date: date,
        starting: starting,
        minimum: minimum,
        percent: percent,
      ),
    );
    _notifyDataChanged();
  }

  static Future<List<DepositRecord>> loadDeposits() async {
    final state = await _loadPreparedState();
    return List.unmodifiable(state.deposits);
  }

  static Future<DepositBalanceSummary> loadDepositBalanceSummary({
    required int year,
    required int month,
  }) async {
    final state = await _loadPreparedState();
    final DateTime monthStart = DateTime(year, month);
    final List<DepositBalanceSummary> summaries =
        _depositBalanceSummariesForYear(state, monthStart.year);
    return summaries[monthStart.month - 1];
  }

  static Future<List<DepositBalanceSummary>>
  loadDepositBalanceSummariesForYear({required int year}) async {
    final state = await _loadPreparedState();
    return _depositBalanceSummariesForYear(state, year);
  }

  static Future<List<ExpenseRecord>> loadExpenses() async {
    final state = await _loadPreparedState();
    return List.unmodifiable(state.expenses);
  }

  static Future<List<LiabilityRecord>> loadLiabilities() async {
    final state = await _loadPreparedState();
    return List.unmodifiable(state.liabilities);
  }

  static Future<BudgetData> loadBudgetData({
    required DateTime startDate,
    required DateTime endDate,
    required String period,
  }) async {
    final state = await _loadPreparedState();

    final deposits = state.deposits
        .where(
          (record) => _isInRange(record.transactionDate, startDate, endDate),
        )
        .toList();
    final expenses = state.expenses
        .where(
          (record) => _isInRange(record.transactionDate, startDate, endDate),
        )
        .toList();
    final budgetExpenses = _budgetExpenseAmountsForRange(
      state,
      startDate,
      endDate,
    );

    final depositTotal = deposits.fold<double>(
      0,
      (total, record) => total + record.totalAmount,
    );
    final expenseTotal = budgetExpenses.fold<double>(
      0,
      (total, entry) => total + entry.amount,
    );
    final available = depositTotal - expenseTotal;
    final total = depositTotal > 0 ? depositTotal : expenseTotal;
    final utilization = depositTotal > 0
        ? (expenseTotal / depositTotal * 100).round()
        : 0;
    final surplus = depositTotal > 0
        ? (available / depositTotal * 100).round()
        : 0;

    final categoryTotals = <String, double>{};
    for (final entry in budgetExpenses) {
      categoryTotals.update(
        entry.expense.category,
        (value) => value + entry.amount,
        ifAbsent: () => entry.amount,
      );
    }

    final categories = categoryTotals.entries
        .where((entry) => entry.value > 0 && expenseTotal > 0)
        .map(
          (entry) => BudgetCategory(
            label: entry.key,
            percentage: entry.value / expenseTotal * 100,
            color: _categoryColor(entry.key),
          ),
        )
        .toList();

    return BudgetData(
      deposit: depositTotal,
      expense: expenseTotal,
      total: total,
      period: period,
      surplusPercent: surplus,
      utilizationPercent: utilization,
      transactionCount: deposits.length + expenses.length,
      categories: categories,
    );
  }

  static Future<List<MonthlyLiability>> loadMonthlyLiabilities({
    required LiabilityTab tab,
    required int year,
  }) async {
    final state = await _loadPreparedState();

    final monthEntries = <int, List<LiabilityEntry>>{
      for (var month = 1; month <= 12; month++) month: <LiabilityEntry>[],
    };

    for (final record in state.liabilities.where(
      (record) => record.tab == tab && record.date.year == year,
    )) {
      monthEntries[record.date.month]!.add(record.toEntry());
    }

    return List.generate(12, (index) {
      final month = index + 1;
      final entries = monthEntries[month]!;
      final total = entries.fold<double>(
        0,
        (sum, entry) => sum + entry.starting,
      );

      return MonthlyLiability(
        month: month,
        total: total,
        entries: entries,
        isExpanded: entries.isNotEmpty && month == AppClock.now.month,
      );
    });
  }

  static Future<LiabilitySummary> loadLiabilitySummary(LiabilityTab tab) async {
    final state = await _loadPreparedState();

    final records = state.liabilities.where((record) => record.tab == tab);
    final totalOwed = records.fold<double>(
      0,
      (sum, record) => sum + record.starting,
    );
    final totalPayoff = records.fold<double>(
      0,
      (sum, record) => sum + record.minimum,
    );
    final balance = (totalOwed - totalPayoff).clamp(0, double.infinity);
    final percent = totalOwed == 0 ? 0.0 : totalPayoff / totalOwed * 100;

    return LiabilitySummary(
      totalOwed: totalOwed,
      percent: percent,
      totalPayoff: totalPayoff,
      balance: balance.toDouble(),
    );
  }

  @visibleForTesting
  static void resetForTesting({
    bool disablePersistence = true,
    bool seedDefaultBudgetData = false,
  }) {
    _repository = LocalTransactionRepository(
      disablePersistenceForTesting: disablePersistence,
    );
    _idCounter = 0;
    _disablePersistenceForTesting = disablePersistence;
    _seedDefaultBudgetDataForTesting = seedDefaultBudgetData;
    _notifyDataChanged();
  }

  static Future<void> _prepareRepository() async {
    await _loadPreparedState();
  }

  static Future<_TransactionState> _loadPreparedState() async {
    final snapshot = await _repository.loadSnapshot();
    final state = _TransactionState.fromSnapshot(
      snapshot ?? TransactionSnapshot.empty(),
    );
    final forceSeed = _seedDefaultBudgetDataForTesting;
    final changed = _prepareLoadedData(state, AppClock.now, forceSeed);
    if (forceSeed) {
      _seedDefaultBudgetDataForTesting = false;
    }
    if (changed) await _saveState(state);
    return state;
  }

  static bool _prepareLoadedData(
    _TransactionState state,
    DateTime createdAt,
    bool forceSeed,
  ) {
    final seeded = _seedDefaultBudgetDataIfNeeded(
      state,
      createdAt,
      force: forceSeed,
    );
    final syncedExpenses = SaveFutureExpense.syncDueRecurringExpenses(
      expenses: state.expenses,
      now: createdAt,
      idGenerator: _newId,
    );
    for (final expense in syncedExpenses) {
      _addExpense(state, expense);
    }
    return seeded || syncedExpenses.isNotEmpty;
  }

  static bool _seedDefaultBudgetDataIfNeeded(
    _TransactionState state,
    DateTime createdAt, {
    bool force = false,
  }) {
    if (_disablePersistenceForTesting && !force) return false;
    if (state.defaultBudgetSeedVersion >= DefaultBudgetSeedData.version) {
      return false;
    }
    if (state.deposits.isNotEmpty ||
        state.expenses.isNotEmpty ||
        state.liabilities.isNotEmpty) {
      return false;
    }

    var changed = false;
    for (final seed in DefaultBudgetSeedData.deposits) {
      final transactionDate = _seedDate(createdAt, seed.dayOfMonth);
      if (transactionDate == null) continue;

      state.deposits.add(
        DepositRecord(
          id: _newId('seed-deposit'),
          orderNumber: _seedOrderNumber(seed),
          totalAmount: seed.totalAmount,
          creditDeposit: seed.creditDeposit,
          cash: seed.cash,
          giftCard: seed.giftCard,
          other: seed.other,
          transactionDate: transactionDate,
          isManual: true,
        ),
      );
      changed = true;
    }

    for (final seed in DefaultBudgetSeedData.expenses) {
      final transactionDate = _seedDate(createdAt, seed.dayOfMonth);
      if (transactionDate == null) continue;
      final payee = seed.payee.trim().isEmpty ? seed.category : seed.payee;

      if (seed.isRecurringMonthly) {
        final expenses = SaveFutureExpense.createDueRecurringExpenses(
          checkNumber: _seedCheckNumber(seed),
          totalAmount: seed.amount,
          startDate: transactionDate,
          category: seed.category,
          payee: payee,
          isManual: true,
          frequency: RecurrenceSchedule.monthly,
          now: createdAt,
          idGenerator: _newId,
        );
        for (final expense in expenses) {
          _addExpense(state, expense);
        }
        changed = changed || expenses.isNotEmpty;
        continue;
      }

      _addExpense(
        state,
        ExpenseRecord(
          id: _newId('seed-expense'),
          checkNumber: _seedCheckNumber(seed),
          totalAmount: seed.amount,
          transactionDate: transactionDate,
          category: seed.category,
          payee: payee,
          isManual: true,
        ),
      );
      changed = true;
    }

    state.defaultBudgetSeedVersion = DefaultBudgetSeedData.version;
    state.defaultBudgetSeedMonth = SaveFutureExpense._monthKey(createdAt);
    return changed;
  }

  static Future<void> _saveState(_TransactionState state) async {
    await _repository.saveSnapshot(state.toSnapshot());
  }

  static DateTime? _seedDate(DateTime createdAt, int dayOfMonth) {
    if (dayOfMonth < 1) return null;
    final lastDay = DateTime(createdAt.year, createdAt.month + 1, 0).day;
    if (dayOfMonth > lastDay) return null;
    return DateTime(createdAt.year, createdAt.month, dayOfMonth);
  }

  static String _seedOrderNumber(BudgetSeedDeposit seed) {
    final day = seed.dayOfMonth.toString().padLeft(2, '0');
    return 'Seed-${_seedToken(seed.label)}-$day';
  }

  static String _seedCheckNumber(BudgetSeedExpense seed) {
    final day = seed.dayOfMonth.toString().padLeft(2, '0');
    return 'Seed-${_seedToken(seed.category)}-$day';
  }

  static String _seedToken(String value) {
    final token = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return token.isEmpty ? 'BUDGET' : token;
  }

  static bool _isInRange(DateTime value, DateTime start, DateTime end) {
    final date = DateTime(value.year, value.month, value.day);
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    return !date.isBefore(first) && !date.isAfter(last);
  }

  static List<_BudgetExpenseAmount> _budgetExpenseAmountsForRange(
    _TransactionState state,
    DateTime startDate,
    DateTime endDate,
  ) {
    final rangeStart = RecurrenceSchedule.dateOnly(startDate);
    final rangeEndExclusive = RecurrenceSchedule.dateOnly(
      endDate,
    ).add(const Duration(days: 1));
    if (!rangeStart.isBefore(rangeEndExclusive)) {
      return const <_BudgetExpenseAmount>[];
    }

    final amounts = <_BudgetExpenseAmount>[];
    for (final expense in state.expenses) {
      final amount = expense.isRecurring
          ? _recurringExpenseAmountForRange(
              state,
              expense,
              rangeStart,
              rangeEndExclusive,
            )
          : _oneTimeExpenseAmountForRange(
              expense,
              rangeStart,
              rangeEndExclusive,
            );
      if (amount <= 0) continue;
      amounts.add(_BudgetExpenseAmount(expense: expense, amount: amount));
    }
    return List<_BudgetExpenseAmount>.unmodifiable(amounts);
  }

  static double _oneTimeExpenseAmountForRange(
    ExpenseRecord expense,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
  ) {
    final expenseDate = RecurrenceSchedule.dateOnly(expense.transactionDate);
    if (expenseDate.isBefore(rangeStart) ||
        !expenseDate.isBefore(rangeEndExclusive)) {
      return 0;
    }
    return expense.totalAmount;
  }

  static double _recurringExpenseAmountForRange(
    _TransactionState state,
    ExpenseRecord expense,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
  ) {
    final periodStart = RecurrenceSchedule.dateOnly(expense.transactionDate);
    final periodEndExclusive = _recurringExpensePeriodEndExclusive(
      state,
      expense,
    );
    final periodDays = periodEndExclusive.difference(periodStart).inDays;
    if (periodDays <= 0) return 0;

    final overlapStart = _laterDate(periodStart, rangeStart);
    final overlapEnd = _earlierDate(periodEndExclusive, rangeEndExclusive);
    final overlapDays = overlapEnd.difference(overlapStart).inDays;
    if (overlapDays <= 0) return 0;

    return expense.totalAmount / periodDays * overlapDays;
  }

  static DateTime _recurringExpensePeriodEndExclusive(
    _TransactionState state,
    ExpenseRecord expense,
  ) {
    final occurrenceDate = RecurrenceSchedule.dateOnly(expense.transactionDate);
    final frequency = expense.normalizedRecurringFrequency;

    final seriesStartDate = _recurringSeriesStartDate(state, expense);
    final searchThrough = _recurringSearchThrough(occurrenceDate, frequency);
    final dates = RecurrenceSchedule.dueDates(
      startDate: seriesStartDate,
      through: searchThrough,
      frequency: frequency,
    );

    for (final date in dates) {
      if (date.isAfter(occurrenceDate)) return date;
    }

    return _fallbackRecurringPeriodEnd(occurrenceDate, frequency);
  }

  static DateTime _recurringSeriesStartDate(
    _TransactionState state,
    ExpenseRecord expense,
  ) {
    var startDate = RecurrenceSchedule.dateOnly(expense.transactionDate);
    for (final record in state.expenses) {
      if (record.recurringSeriesId != expense.recurringSeriesId) continue;
      final recordDate = RecurrenceSchedule.dateOnly(record.transactionDate);
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
    final totalMonths = date.year * 12 + date.month - 1 + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = date.day < daysInMonth ? date.day : daysInMonth;
    return DateTime(year, month, day);
  }

  static DateTime _laterDate(DateTime left, DateTime right) {
    return left.isAfter(right) ? left : right;
  }

  static DateTime _earlierDate(DateTime left, DateTime right) {
    return left.isBefore(right) ? left : right;
  }

  static List<DepositBalanceSummary> _depositBalanceSummariesForYear(
    _TransactionState state,
    int year,
  ) {
    double runningBalance =
        _sumDepositsBefore(state, DateTime(year)) -
        _sumExpensesBefore(state, DateTime(year));
    final List<DepositBalanceSummary> summaries = <DepositBalanceSummary>[];

    for (int month = 1; month <= 12; month += 1) {
      final DateTime monthStart = DateTime(year, month);
      final DateTime nextMonthStart = DateTime(year, month + 1);
      final double monthCredits = _sumDepositsInRange(
        state,
        monthStart,
        nextMonthStart,
      );
      final double monthExpenses = _sumExpensesInRange(
        state,
        monthStart,
        nextMonthStart,
      );
      final DepositBalanceSummary summary = DepositBalanceSummary(
        year: year,
        month: month,
        beginningBalance: runningBalance,
        monthCredits: monthCredits,
        monthExpenses: monthExpenses,
      );
      summaries.add(summary);
      runningBalance = summary.endingBalance;
    }

    return List<DepositBalanceSummary>.unmodifiable(summaries);
  }

  static double _sumDepositsBefore(_TransactionState state, DateTime cutoff) {
    return state.deposits
        .where(
          (DepositRecord record) => record.transactionDate.isBefore(cutoff),
        )
        .fold<double>(
          0,
          (double total, DepositRecord record) => total + record.totalAmount,
        );
  }

  static double _sumExpensesBefore(_TransactionState state, DateTime cutoff) {
    return state.expenses
        .where(
          (ExpenseRecord record) => record.transactionDate.isBefore(cutoff),
        )
        .fold<double>(
          0,
          (double total, ExpenseRecord record) => total + record.totalAmount,
        );
  }

  static double _sumDepositsInRange(
    _TransactionState state,
    DateTime start,
    DateTime end,
  ) {
    return state.deposits
        .where(
          (DepositRecord record) =>
              !record.transactionDate.isBefore(start) &&
              record.transactionDate.isBefore(end),
        )
        .fold<double>(
          0,
          (double total, DepositRecord record) => total + record.totalAmount,
        );
  }

  static double _sumExpensesInRange(
    _TransactionState state,
    DateTime start,
    DateTime end,
  ) {
    return state.expenses
        .where(
          (ExpenseRecord record) =>
              !record.transactionDate.isBefore(start) &&
              record.transactionDate.isBefore(end),
        )
        .fold<double>(
          0,
          (double total, ExpenseRecord record) => total + record.totalAmount,
        );
  }

  static String _newId(String prefix) =>
      '$prefix-${AppClock.now.microsecondsSinceEpoch}-${_idCounter++}';

  static String _payrollCheckNumber(String payrollId) => 'PAYROLL-$payrollId';

  static void _notifyDataChanged() {
    _dataVersion.value++;
  }

  static bool _isLegacyExpenseLiability(
    LiabilityRecord liability,
    ExpenseRecord expense,
  ) {
    if (liability.source != 'expense') return false;
    if (expense.category != 'Loan Obligation') return false;
    final name = expense.payee.isEmpty ? 'Loan obligation' : expense.payee;
    return liability.name == name &&
        liability.date.year == expense.transactionDate.year &&
        liability.date.month == expense.transactionDate.month &&
        liability.date.day == expense.transactionDate.day &&
        liability.starting == expense.totalAmount;
  }

  static void _removeExpenseLiabilities(
    _TransactionState state,
    Iterable<ExpenseRecord> expenses,
  ) {
    final expenseList = expenses.toList();
    final expenseIds = expenseList.map((record) => record.id).toSet();

    state.liabilities.removeWhere(
      (record) =>
          expenseIds.any(
            (expenseId) => record.source == 'expense:$expenseId',
          ) ||
          expenseList.any(
            (expense) => _isLegacyExpenseLiability(record, expense),
          ),
    );
  }

  static LiabilityRecord _liabilityFromExpense(ExpenseRecord expense) {
    return LiabilityRecord(
      id: _newId('liability-${expense.id}'),
      tab: LiabilityTab.debt,
      name: expense.payee.isEmpty ? 'Loan obligation' : expense.payee,
      date: expense.transactionDate,
      starting: expense.totalAmount,
      minimum: expense.totalAmount,
      percent: 0,
      source: 'expense:${expense.id}',
    );
  }

  static SaveExpenseRequest _requestFromExpense(ExpenseRecord expense) {
    return SaveExpenseRequest(
      checkNumber: expense.checkNumber,
      totalAmount: expense.totalAmount,
      transactionDate: expense.transactionDate,
      category: expense.category,
      payee: expense.payee,
      isManual: expense.isManual,
      recurringSeriesId: expense.recurringSeriesId,
      recurringIndex: expense.recurringIndex,
      recurringEndMonthKey: expense.recurringEndMonthKey,
      recurringFrequency: expense.recurringFrequency,
    );
  }

  static SaveLiabilityRequest _requestFromLiability(LiabilityRecord liability) {
    return SaveLiabilityRequest(
      tab: liability.tab,
      name: liability.name,
      date: liability.date,
      starting: liability.starting,
      minimum: liability.minimum,
      percent: liability.percent,
      source: liability.source,
    );
  }

  static Color _categoryColor(String category) {
    return switch (category) {
      'Payroll' => const Color(0xFF2563EB),
      'Rent' => const Color(0xFF3B82F6),
      'Insurance' => const Color(0xFF60A5FA),
      'Consumable Supplies' => const Color(0xFF93C5FD),
      'Utilities' => const Color(0xFFBFDBFE),
      'Fuel' => const Color(0xFFEF4444),
      'COGS' => const Color(0xFF1E3A5F),
      'Loan Obligation' => const Color(0xFFDC2626),
      'Equipment' => const Color(0xFF1D4ED8),
      _ => const Color(0xFF374151),
    };
  }
}

class _TransactionState {
  final List<DepositRecord> deposits;
  final List<ExpenseRecord> expenses;
  final List<LiabilityRecord> liabilities;
  int defaultBudgetSeedVersion;
  int defaultBudgetSeedMonth;

  _TransactionState({
    required this.deposits,
    required this.expenses,
    required this.liabilities,
    required this.defaultBudgetSeedVersion,
    required this.defaultBudgetSeedMonth,
  });

  factory _TransactionState.fromSnapshot(TransactionSnapshot snapshot) {
    try {
      return _TransactionState(
        deposits: snapshot.deposits.map(DepositRecord.fromJson).toList(),
        expenses: snapshot.expenses.map(ExpenseRecord.fromJson).toList(),
        liabilities: snapshot.liabilities
            .map(LiabilityRecord.fromJson)
            .toList(),
        defaultBudgetSeedVersion: snapshot.defaultBudgetSeedVersion,
        defaultBudgetSeedMonth: snapshot.defaultBudgetSeedMonth,
      );
    } catch (_) {
      return _TransactionState.empty();
    }
  }

  factory _TransactionState.empty() {
    return _TransactionState(
      deposits: <DepositRecord>[],
      expenses: <ExpenseRecord>[],
      liabilities: <LiabilityRecord>[],
      defaultBudgetSeedVersion: 0,
      defaultBudgetSeedMonth: 0,
    );
  }

  TransactionSnapshot toSnapshot() {
    return TransactionSnapshot(
      deposits: deposits.map((record) => record.toJson()),
      expenses: expenses.map((record) => record.toJson()),
      liabilities: liabilities.map((record) => record.toJson()),
      defaultBudgetSeedVersion: defaultBudgetSeedVersion,
      defaultBudgetSeedMonth: defaultBudgetSeedMonth,
    );
  }
}

class _BudgetExpenseAmount {
  final ExpenseRecord expense;
  final double amount;

  const _BudgetExpenseAmount({required this.expense, required this.amount});
}

class DepositRecord {
  final String id;
  final String orderNumber;
  final double totalAmount;
  final double creditDeposit;
  final double cash;
  final double giftCard;
  final double other;
  final DateTime transactionDate;
  final bool isManual;

  const DepositRecord({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.creditDeposit,
    required this.cash,
    required this.giftCard,
    required this.other,
    required this.transactionDate,
    required this.isManual,
  });

  factory DepositRecord.fromJson(Map<String, dynamic> json) {
    return DepositRecord(
      id: _asString(json['id'], fallback: _fallbackId('deposit')),
      orderNumber: _asString(json['orderNumber']),
      totalAmount: _asDouble(json['totalAmount']),
      creditDeposit: _asDouble(json['creditDeposit']),
      cash: _asDouble(json['cash']),
      giftCard: _asDouble(json['giftCard']),
      other: _asDouble(json['other']),
      transactionDate: _asDate(json['transactionDate']),
      isManual: json['isManual'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'totalAmount': totalAmount,
    'creditDeposit': creditDeposit,
    'cash': cash,
    'giftCard': giftCard,
    'other': other,
    'transactionDate': transactionDate.toIso8601String(),
    'isManual': isManual,
  };
}

class DepositBalanceSummary {
  final int year;
  final int month;
  final double beginningBalance;
  final double monthCredits;
  final double monthExpenses;

  const DepositBalanceSummary({
    required this.year,
    required this.month,
    required this.beginningBalance,
    required this.monthCredits,
    required this.monthExpenses,
  });

  double get endingBalance => beginningBalance + monthCredits - monthExpenses;
}

class ExpenseRecord {
  final String id;
  final String checkNumber;
  final double totalAmount;
  final DateTime transactionDate;
  final String category;
  final String payee;
  final bool isManual;
  final String recurringSeriesId;
  final int recurringIndex;
  final int recurringEndMonthKey;
  final String recurringFrequency;

  const ExpenseRecord({
    required this.id,
    required this.checkNumber,
    required this.totalAmount,
    required this.transactionDate,
    required this.category,
    required this.payee,
    required this.isManual,
    this.recurringSeriesId = '',
    this.recurringIndex = 0,
    this.recurringEndMonthKey = 0,
    this.recurringFrequency = '',
  });

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) {
    final seriesId = _asString(json['recurringSeriesId']);
    return ExpenseRecord(
      id: _asString(json['id'], fallback: _fallbackId('expense')),
      checkNumber: _asString(json['checkNumber']),
      totalAmount: _asDouble(json['totalAmount']),
      transactionDate: _asDate(json['transactionDate']),
      category: _asString(json['category'], fallback: 'Other'),
      payee: _asString(json['payee']),
      isManual: json['isManual'] == true,
      recurringSeriesId: seriesId,
      recurringIndex: _asInt(json['recurringIndex']),
      recurringEndMonthKey: _asInt(json['recurringEndMonthKey']),
      recurringFrequency: _asString(
        json['recurringFrequency'],
        fallback: seriesId.isEmpty ? '' : RecurrenceSchedule.monthly,
      ),
    );
  }

  bool get isRecurring => recurringSeriesId.isNotEmpty;

  String get normalizedRecurringFrequency {
    if (!isRecurring) return '';
    return RecurrenceSchedule.isRecurringFrequency(recurringFrequency)
        ? recurringFrequency
        : RecurrenceSchedule.monthly;
  }

  ExpenseRecord copyWith({
    double? totalAmount,
    int? recurringEndMonthKey,
    String? recurringFrequency,
  }) {
    return ExpenseRecord(
      id: id,
      checkNumber: checkNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      transactionDate: transactionDate,
      category: category,
      payee: payee,
      isManual: isManual,
      recurringSeriesId: recurringSeriesId,
      recurringIndex: recurringIndex,
      recurringEndMonthKey: recurringEndMonthKey ?? this.recurringEndMonthKey,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'checkNumber': checkNumber,
    'totalAmount': totalAmount,
    'transactionDate': transactionDate.toIso8601String(),
    'category': category,
    'payee': payee,
    'isManual': isManual,
    'recurringSeriesId': recurringSeriesId,
    'recurringIndex': recurringIndex,
    'recurringEndMonthKey': recurringEndMonthKey,
    'recurringFrequency': recurringFrequency,
  };
}

class LiabilityRecord {
  final String id;
  final LiabilityTab tab;
  final String name;
  final DateTime date;
  final double starting;
  final double minimum;
  final int percent;
  final String source;

  const LiabilityRecord({
    required this.id,
    required this.tab,
    required this.name,
    required this.date,
    required this.starting,
    required this.minimum,
    required this.percent,
    required this.source,
  });

  factory LiabilityRecord.fromJson(Map<String, dynamic> json) {
    return LiabilityRecord(
      id: _asString(json['id'], fallback: _fallbackId('liability')),
      tab: _asString(json['tab']) == 'debt'
          ? LiabilityTab.debt
          : LiabilityTab.loan,
      name: _asString(json['name'], fallback: 'Liability'),
      date: _asDate(json['date']),
      starting: _asDouble(json['starting']),
      minimum: _asDouble(json['minimum']),
      percent: _asInt(json['percent']),
      source: _asString(json['source'], fallback: 'manual'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tab': tab.name,
    'name': name,
    'date': date.toIso8601String(),
    'starting': starting,
    'minimum': minimum,
    'percent': percent,
    'source': source,
  };

  LiabilityEntry toEntry() {
    return LiabilityEntry(
      name: name,
      date:
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}',
      starting: starting,
      minimum: minimum,
      percent: percent,
    );
  }
}

class LiabilitySummary {
  final double totalOwed;
  final double percent;
  final double totalPayoff;
  final double balance;

  const LiabilitySummary({
    required this.totalOwed,
    required this.percent,
    required this.totalPayoff,
    required this.balance,
  });

  static const empty = LiabilitySummary(
    totalOwed: 0,
    percent: 0,
    totalPayoff: 0,
    balance: 0,
  );
}

int _fallbackIdCounter = 0;

String _fallbackId(String prefix) =>
    '$prefix-imported-${AppClock.now.microsecondsSinceEpoch}-${_fallbackIdCounter++}';

String _asString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _asDate(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? AppClock.now;
}
