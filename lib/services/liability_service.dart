import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:biztrack/features/auth/models/budget_data.dart';
import 'package:biztrack/features/auth/models/liability_model.dart';
import 'package:biztrack/services/local_store_test/local_store.dart';

import 'app_clock.dart';
import 'recurrence_schedule.dart';

part 'save_future_expense.dart';

class LiabilityService {
  static const _storageKey = 'biztrack_local_data_v1';
  static const _defaultBudgetSeedVersionKey = 'defaultBudgetSeedVersion';
  static const _defaultBudgetSeedMonthKey = 'defaultBudgetSeedMonthKey';

  static final List<DepositRecord> _deposits = [];
  static final List<ExpenseRecord> _expenses = [];
  static final List<LiabilityRecord> _liabilities = [];

  static int _idCounter = 0;
  static int _defaultBudgetSeedVersion = 0;
  static int _defaultBudgetSeedMonth = 0;
  static bool _loaded = false;
  static bool _disablePersistenceForTesting = false;
  static final ValueNotifier<int> _dataVersion = ValueNotifier<int>(0);

  static ValueListenable<int> get dataVersion => _dataVersion;

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
    await _ensureLoaded();
    _deposits.add(
      DepositRecord(
        id: _newId('deposit'),
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
    await _persist();
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
    await _ensureLoaded();

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
      _addExpense(expense);
    }

    await _persist();
    _notifyDataChanged();
  }

  static void _addExpense(ExpenseRecord expense) {
    _expenses.add(expense);
    _addExpenseLiability(expense);
  }

  static void _addExpenseLiability(ExpenseRecord expense) {
    if (expense.category == 'Loan Obligation') {
      _liabilities.add(_liabilityFromExpense(expense));
    }
  }

  static Future<bool> deleteDeposit(String id) async {
    await _ensureLoaded();
    final before = _deposits.length;
    _deposits.removeWhere((record) => record.id == id);
    final removed = _deposits.length != before;
    if (removed) {
      await _persist();
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

    await _ensureLoaded();
    final DateTime? occurrence = occurrenceDate == null
        ? null
        : RecurrenceSchedule.dateOnly(occurrenceDate);
    final DateTime cutoff = RecurrenceSchedule.dateOnly(
      fromDate ?? AppClock.now,
    );
    final List<ExpenseRecord> expensesToUpdate = _expenses
        .where(
          (record) =>
              record.recurringSeriesId == recurringSeriesId &&
              (occurrence == null
                  ? !RecurrenceSchedule.dateOnly(
                      record.transactionDate,
                    ).isBefore(cutoff)
                  : RecurrenceSchedule.isSameDate(
                      record.transactionDate,
                      occurrence,
                    )),
        )
        .toList(growable: false);
    if (expensesToUpdate.isEmpty) return false;

    final Set<String> expenseIds = expensesToUpdate
        .map((record) => record.id)
        .toSet();
    _removeExpenseLiabilities(expensesToUpdate);

    for (var index = 0; index < _expenses.length; index++) {
      final ExpenseRecord record = _expenses[index];
      if (!expenseIds.contains(record.id)) continue;
      _expenses[index] = record.copyWith(totalAmount: amount);
      _addExpenseLiability(_expenses[index]);
    }

    await _persist();
    _notifyDataChanged();
    return true;
  }

  static Future<bool> deleteExpense(String id) async {
    await _ensureLoaded();
    final matching = _expenses.where((record) => record.id == id).toList();
    if (matching.isEmpty) return false;

    final expense = matching.first;
    if (expense.isRecurring) {
      return _stopRecurringExpenseFromMonth(expense, AppClock.now);
    }

    final expensesToDelete = matching;
    final expenseIds = expensesToDelete.map((record) => record.id).toSet();

    _expenses.removeWhere((record) => expenseIds.contains(record.id));
    _removeExpenseLiabilities(expensesToDelete);
    await _persist();
    _notifyDataChanged();
    return true;
  }

  static Future<bool> deleteFutureRecurringExpenses({
    required String recurringSeriesId,
    DateTime? fromDate,
  }) async {
    if (recurringSeriesId.isEmpty) return false;

    await _ensureLoaded();
    final DateTime cutoff = RecurrenceSchedule.dateOnly(
      fromDate ?? AppClock.now,
    );
    final int cutoffMonthKey = SaveFutureExpense._monthKey(cutoff);
    final List<ExpenseRecord> expensesToDelete = _expenses
        .where(
          (record) =>
              record.recurringSeriesId == recurringSeriesId &&
              !RecurrenceSchedule.dateOnly(
                record.transactionDate,
              ).isBefore(cutoff),
        )
        .toList(growable: false);
    final List<ExpenseRecord> retainedExpenses = _expenses
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
    _expenses.removeWhere((record) => expenseIdsToDelete.contains(record.id));
    _removeExpenseLiabilities(expensesToDelete);

    final Set<String> retainedExpenseIds = retainedExpenses
        .map((record) => record.id)
        .toSet();
    for (var index = 0; index < _expenses.length; index++) {
      final ExpenseRecord record = _expenses[index];
      if (!retainedExpenseIds.contains(record.id)) continue;
      _expenses[index] = record.copyWith(
        recurringEndMonthKey: _earlierRecurringEndMonthKey(
          record.recurringEndMonthKey,
          cutoffMonthKey,
        ),
      );
    }

    await _persist();
    _notifyDataChanged();
    return true;
  }

  static Future<bool> _stopRecurringExpenseFromMonth(
    ExpenseRecord expense,
    DateTime month,
  ) async {
    final deleteMonthKey = SaveFutureExpense._monthKey(month);
    final seriesRecords = _expenses
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
    _expenses.removeWhere((record) => expenseIdsToDelete.contains(record.id));
    _removeExpenseLiabilities(expensesToDelete);

    for (var index = 0; index < _expenses.length; index++) {
      final record = _expenses[index];
      if (!retainedExpenseIds.contains(record.id)) continue;
      _expenses[index] = record.copyWith(
        recurringEndMonthKey: _earlierRecurringEndMonthKey(
          record.recurringEndMonthKey,
          deleteMonthKey,
        ),
      );
    }

    await _persist();
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
    await _ensureLoaded();
    _liabilities.add(
      LiabilityRecord(
        id: _newId('liability'),
        tab: tab,
        name: name,
        date: date,
        starting: starting,
        minimum: minimum,
        percent: percent,
        source: 'manual',
      ),
    );
    await _persist();
    _notifyDataChanged();
  }

  static Future<List<DepositRecord>> loadDeposits() async {
    await _ensureLoaded();
    return List.unmodifiable(_deposits);
  }

  static Future<DepositBalanceSummary> loadDepositBalanceSummary({
    required int year,
    required int month,
  }) async {
    await _ensureLoaded();
    final DateTime monthStart = DateTime(year, month);
    final List<DepositBalanceSummary> summaries =
        _depositBalanceSummariesForYear(monthStart.year);
    return summaries[monthStart.month - 1];
  }

  static Future<List<DepositBalanceSummary>>
  loadDepositBalanceSummariesForYear({required int year}) async {
    await _ensureLoaded();
    return _depositBalanceSummariesForYear(year);
  }

  static Future<List<ExpenseRecord>> loadExpenses() async {
    await _ensureLoaded();
    return List.unmodifiable(_expenses);
  }

  static Future<List<LiabilityRecord>> loadLiabilities() async {
    await _ensureLoaded();
    return List.unmodifiable(_liabilities);
  }

  static Future<BudgetData> loadBudgetData({
    required DateTime startDate,
    required DateTime endDate,
    required String period,
  }) async {
    await _ensureLoaded();

    final deposits = _deposits
        .where(
          (record) => _isInRange(record.transactionDate, startDate, endDate),
        )
        .toList();
    final expenses = _expenses
        .where(
          (record) => _isInRange(record.transactionDate, startDate, endDate),
        )
        .toList();
    final budgetExpenses = _budgetExpenseAmountsForRange(startDate, endDate);

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
    await _ensureLoaded();

    final monthEntries = <int, List<LiabilityEntry>>{
      for (var month = 1; month <= 12; month++) month: <LiabilityEntry>[],
    };

    for (final record in _liabilities.where(
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
    await _ensureLoaded();

    final records = _liabilities.where((record) => record.tab == tab);
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
    _deposits.clear();
    _expenses.clear();
    _liabilities.clear();
    _idCounter = 0;
    _defaultBudgetSeedVersion = 0;
    _defaultBudgetSeedMonth = 0;
    _loaded = true;
    _disablePersistenceForTesting = disablePersistence;
    if (seedDefaultBudgetData) {
      _seedDefaultBudgetDataIfNeeded(AppClock.now, force: true);
    }
    _notifyDataChanged();
  }

  static Future<void> _ensureLoaded() async {
    if (_loaded) {
      final changed = _prepareLoadedData(AppClock.now);
      if (changed) await _persist();
      return;
    }

    final raw = await LocalStore.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _loaded = true;
      final changed = _prepareLoadedData(AppClock.now);
      if (changed) await _persist();
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _deposits
        ..clear()
        ..addAll(
          _listFromJson(decoded['deposits']).map(DepositRecord.fromJson),
        );
      _expenses
        ..clear()
        ..addAll(
          _listFromJson(decoded['expenses']).map(ExpenseRecord.fromJson),
        );
      _liabilities
        ..clear()
        ..addAll(
          _listFromJson(decoded['liabilities']).map(LiabilityRecord.fromJson),
        );
      _defaultBudgetSeedVersion = _asInt(decoded[_defaultBudgetSeedVersionKey]);
      _defaultBudgetSeedMonth = _asInt(decoded[_defaultBudgetSeedMonthKey]);
    } catch (_) {
      _deposits.clear();
      _expenses.clear();
      _liabilities.clear();
      _defaultBudgetSeedVersion = 0;
      _defaultBudgetSeedMonth = 0;
    }

    _loaded = true;
    final changed = _prepareLoadedData(AppClock.now);
    if (changed) await _persist();
  }

  static bool _prepareLoadedData(DateTime createdAt) {
    final seeded = _seedDefaultBudgetDataIfNeeded(createdAt);
    final synced = SaveFutureExpense.syncDueRecurringExpenses(createdAt);
    return seeded || synced;
  }

  static bool _seedDefaultBudgetDataIfNeeded(
    DateTime createdAt, {
    bool force = false,
  }) {
    if (_disablePersistenceForTesting && !force) return false;
    if (_defaultBudgetSeedVersion >= DefaultBudgetSeedData.version) {
      return false;
    }
    if (_deposits.isNotEmpty ||
        _expenses.isNotEmpty ||
        _liabilities.isNotEmpty) {
      return false;
    }

    var changed = false;
    for (final seed in DefaultBudgetSeedData.deposits) {
      final transactionDate = _seedDate(createdAt, seed.dayOfMonth);
      if (transactionDate == null) continue;

      _deposits.add(
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
        );
        for (final expense in expenses) {
          _addExpense(expense);
        }
        changed = changed || expenses.isNotEmpty;
        continue;
      }

      _addExpense(
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

    _defaultBudgetSeedVersion = DefaultBudgetSeedData.version;
    _defaultBudgetSeedMonth = SaveFutureExpense._monthKey(createdAt);
    return changed;
  }

  static Future<void> _persist() async {
    if (_disablePersistenceForTesting) return;

    final payload = jsonEncode({
      'deposits': _deposits.map((record) => record.toJson()).toList(),
      'expenses': _expenses.map((record) => record.toJson()).toList(),
      'liabilities': _liabilities.map((record) => record.toJson()).toList(),
      _defaultBudgetSeedVersionKey: _defaultBudgetSeedVersion,
      _defaultBudgetSeedMonthKey: _defaultBudgetSeedMonth,
    });

    await LocalStore.write(_storageKey, payload);
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

  static List<Map<String, dynamic>> _listFromJson(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  static bool _isInRange(DateTime value, DateTime start, DateTime end) {
    final date = DateTime(value.year, value.month, value.day);
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    return !date.isBefore(first) && !date.isAfter(last);
  }

  static List<_BudgetExpenseAmount> _budgetExpenseAmountsForRange(
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
    for (final expense in _expenses) {
      final amount = expense.isRecurring
          ? _recurringExpenseAmountForRange(
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
    ExpenseRecord expense,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
  ) {
    final periodStart = RecurrenceSchedule.dateOnly(expense.transactionDate);
    final periodEndExclusive = _recurringExpensePeriodEndExclusive(expense);
    final periodDays = periodEndExclusive.difference(periodStart).inDays;
    if (periodDays <= 0) return 0;

    final overlapStart = _laterDate(periodStart, rangeStart);
    final overlapEnd = _earlierDate(periodEndExclusive, rangeEndExclusive);
    final overlapDays = overlapEnd.difference(overlapStart).inDays;
    if (overlapDays <= 0) return 0;

    return expense.totalAmount / periodDays * overlapDays;
  }

  static DateTime _recurringExpensePeriodEndExclusive(ExpenseRecord expense) {
    final occurrenceDate = RecurrenceSchedule.dateOnly(expense.transactionDate);
    final frequency = expense.normalizedRecurringFrequency;

    final seriesStartDate = _recurringSeriesStartDate(expense);
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

  static DateTime _recurringSeriesStartDate(ExpenseRecord expense) {
    var startDate = RecurrenceSchedule.dateOnly(expense.transactionDate);
    for (final record in _expenses) {
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

  static List<DepositBalanceSummary> _depositBalanceSummariesForYear(int year) {
    double runningBalance =
        _sumDepositsBefore(DateTime(year)) - _sumExpensesBefore(DateTime(year));
    final List<DepositBalanceSummary> summaries = <DepositBalanceSummary>[];

    for (int month = 1; month <= 12; month += 1) {
      final DateTime monthStart = DateTime(year, month);
      final DateTime nextMonthStart = DateTime(year, month + 1);
      final double monthCredits = _sumDepositsInRange(
        monthStart,
        nextMonthStart,
      );
      final double monthExpenses = _sumExpensesInRange(
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

  static double _sumDepositsBefore(DateTime cutoff) {
    return _deposits
        .where(
          (DepositRecord record) => record.transactionDate.isBefore(cutoff),
        )
        .fold<double>(
          0,
          (double total, DepositRecord record) => total + record.totalAmount,
        );
  }

  static double _sumExpensesBefore(DateTime cutoff) {
    return _expenses
        .where(
          (ExpenseRecord record) => record.transactionDate.isBefore(cutoff),
        )
        .fold<double>(
          0,
          (double total, ExpenseRecord record) => total + record.totalAmount,
        );
  }

  static double _sumDepositsInRange(DateTime start, DateTime end) {
    return _deposits
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

  static double _sumExpensesInRange(DateTime start, DateTime end) {
    return _expenses
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

  static void _removeExpenseLiabilities(Iterable<ExpenseRecord> expenses) {
    final expenseList = expenses.toList();
    final expenseIds = expenseList.map((record) => record.id).toSet();

    _liabilities.removeWhere(
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
