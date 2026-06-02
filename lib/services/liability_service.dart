import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/auth/models/budget_data.dart';
import '../features/auth/models/liability_model.dart';
import 'app_clock.dart';
import '../services/local_store_test/local_store.dart';

part 'save_future_expense.dart';

class LiabilityService {
  static const _storageKey = 'biztrack_local_data_v1';

  static final List<DepositRecord> _deposits = [];
  static final List<ExpenseRecord> _expenses = [];
  static final List<LiabilityRecord> _liabilities = [];

  static int _idCounter = 0;
  static bool _loaded = false;
  static bool _disablePersistenceForTesting = false;
  static final ValueNotifier<int> _dataVersion = ValueNotifier<int>(0);

  static ValueListenable<int> get dataVersion => _dataVersion;

  static Future<void> saveDeposit({
    required String orderNumber,
    required double totalAmount,
    required double creditDebt,
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
        creditDebt: creditDebt,
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
  }) async {
    await _ensureLoaded();

    final expenses = isRecurringMonthly
        ? SaveFutureExpense.createDueMonthlyExpenses(
            checkNumber: checkNumber,
            totalAmount: totalAmount,
            transactionDate: transactionDate,
            category: category,
            payee: payee,
            isManual: isManual,
            now: AppClock.now,
          )
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

  static Future<bool> deleteRecurringExpenseFromMonth(
    String id,
    DateTime month,
  ) async {
    await _ensureLoaded();
    final matching = _expenses.where((record) => record.id == id).toList();
    if (matching.isEmpty) return false;

    final expense = matching.first;
    if (!expense.isRecurring) return false;

    return _stopRecurringExpenseFromMonth(expense, month);
  }

  static Future<bool> updateRecurringExpenseAmount(
    String id,
    double amount,
  ) async {
    if (amount <= 0) return false;

    await _ensureLoaded();
    final matching = _expenses.where((record) => record.id == id).toList();
    if (matching.isEmpty) return false;

    final expense = matching.first;
    if (!expense.isRecurring) return false;

    final editMonthKey = SaveFutureExpense._monthKey(AppClock.now);
    final seriesRecords = _expenses
        .where(
          (record) => record.recurringSeriesId == expense.recurringSeriesId,
        )
        .toList();
    final endMonthKey = SaveFutureExpense._seriesEndMonthKey(seriesRecords);
    if (endMonthKey > 0 && editMonthKey >= endMonthKey) return false;

    final expensesToUpdate = seriesRecords
        .where(
          (record) =>
              SaveFutureExpense._monthKey(record.transactionDate) >=
                  editMonthKey &&
              (endMonthKey == 0 ||
                  SaveFutureExpense._monthKey(record.transactionDate) <
                      endMonthKey),
        )
        .toList();
    if (expensesToUpdate.isEmpty) return false;
    if (expensesToUpdate.every((record) => record.totalAmount == amount)) {
      return true;
    }

    final expenseIds = expensesToUpdate.map((record) => record.id).toSet();
    _removeExpenseLiabilities(expensesToUpdate);

    for (var index = 0; index < _expenses.length; index++) {
      final record = _expenses[index];
      if (!expenseIds.contains(record.id)) continue;
      final updated = record.copyWith(totalAmount: amount);
      _expenses[index] = updated;
      _addExpenseLiability(updated);
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

    final depositTotal = deposits.fold<double>(
      0,
      (total, record) => total + record.totalAmount,
    );
    final expenseTotal = expenses.fold<double>(
      0,
      (total, record) => total + record.totalAmount,
    );
    final balance = depositTotal - expenseTotal;
    final total = depositTotal > 0 ? depositTotal : expenseTotal;
    final utilization = depositTotal > 0
        ? (expenseTotal / depositTotal * 100).round()
        : 0;
    final surplus = depositTotal > 0
        ? (balance / depositTotal * 100).round()
        : 0;

    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.totalAmount,
        ifAbsent: () => expense.totalAmount,
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
      recurringExpenses: _recurringExpenseBudgetItems(expenses),
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
  static void resetForTesting({bool disablePersistence = true}) {
    _deposits.clear();
    _expenses.clear();
    _liabilities.clear();
    _idCounter = 0;
    _loaded = true;
    _disablePersistenceForTesting = disablePersistence;
    _notifyDataChanged();
  }

  static Future<void> _ensureLoaded() async {
    if (_loaded) {
      final changed = SaveFutureExpense.syncDueMonthlyExpenses(AppClock.now);
      if (changed) await _persist();
      return;
    }

    final raw = await LocalStore.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _loaded = true;
      final changed = SaveFutureExpense.syncDueMonthlyExpenses(AppClock.now);
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
    } catch (_) {
      _deposits.clear();
      _expenses.clear();
      _liabilities.clear();
    }

    _loaded = true;
    final changed = SaveFutureExpense.syncDueMonthlyExpenses(AppClock.now);
    if (changed) await _persist();
  }

  static Future<void> _persist() async {
    if (_disablePersistenceForTesting) return;

    final payload = jsonEncode({
      'deposits': _deposits.map((record) => record.toJson()).toList(),
      'expenses': _expenses.map((record) => record.toJson()).toList(),
      'liabilities': _liabilities.map((record) => record.toJson()).toList(),
    });

    await LocalStore.write(_storageKey, payload);
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

  static List<RecurringExpenseBudgetItem> _recurringExpenseBudgetItems(
    List<ExpenseRecord> expenses,
  ) {
    final currentMonthKey = SaveFutureExpense._monthKey(AppClock.now);
    final bySeries = <String, List<ExpenseRecord>>{};

    for (final expense in expenses) {
      if (!expense.isRecurring) continue;
      if (expense.recurringEndMonthKey > 0 &&
          currentMonthKey >= expense.recurringEndMonthKey) {
        continue;
      }
      bySeries
          .putIfAbsent(expense.recurringSeriesId, () => <ExpenseRecord>[])
          .add(expense);
    }

    final items = <RecurringExpenseBudgetItem>[];
    for (final records in bySeries.values) {
      records.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
      final latest = records.last;
      items.add(
        RecurringExpenseBudgetItem(
          id: latest.id,
          label: latest.payee.trim().isEmpty
              ? latest.category
              : latest.payee.trim(),
          category: latest.category,
          amount: latest.totalAmount,
          transactionDate: latest.transactionDate,
        ),
      );
    }

    items.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return items;
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

class DepositRecord {
  final String id;
  final String orderNumber;
  final double totalAmount;
  final double creditDebt;
  final double cash;
  final double giftCard;
  final double other;
  final DateTime transactionDate;
  final bool isManual;

  const DepositRecord({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.creditDebt,
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
      creditDebt: _asDouble(json['creditDebt']),
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
    'creditDebt': creditDebt,
    'cash': cash,
    'giftCard': giftCard,
    'other': other,
    'transactionDate': transactionDate.toIso8601String(),
    'isManual': isManual,
  };
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
  });

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) {
    return ExpenseRecord(
      id: _asString(json['id'], fallback: _fallbackId('expense')),
      checkNumber: _asString(json['checkNumber']),
      totalAmount: _asDouble(json['totalAmount']),
      transactionDate: _asDate(json['transactionDate']),
      category: _asString(json['category'], fallback: 'Other'),
      payee: _asString(json['payee']),
      isManual: json['isManual'] == true,
      recurringSeriesId: _asString(json['recurringSeriesId']),
      recurringIndex: _asInt(json['recurringIndex']),
      recurringEndMonthKey: _asInt(json['recurringEndMonthKey']),
    );
  }

  bool get isRecurring => recurringSeriesId.isNotEmpty;

  ExpenseRecord copyWith({double? totalAmount, int? recurringEndMonthKey}) {
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
