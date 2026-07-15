import 'dart:convert';

import 'package:savetep/data/dto/save_deposit_request.dart';
import 'package:savetep/data/dto/save_expense_request.dart';
import 'package:savetep/data/dto/save_liability_request.dart';
import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/data/repositories/transaction_repository.dart';
import 'package:savetep/services/liability_service.dart';

class LocalTransactionRepository implements TransactionRepository {
  static const _storageKey = 'savetep_local_data_v1';

  final bool disablePersistenceForTesting;
  final List<DepositRecord> _deposits = [];
  final List<ExpenseRecord> _expenses = [];
  final List<ExpenseRecord> _scheduledPayrollExpenses = [];
  final List<LiabilityRecord> _liabilities = [];

  int _defaultBudgetSeedVersion = 0;
  int _defaultBudgetSeedMonth = 0;
  int _idCounter = 0;
  bool _loaded;

  LocalTransactionRepository({this.disablePersistenceForTesting = false})
    : _loaded = disablePersistenceForTesting;

  @override
  Future<List<DepositRecord>> loadDeposits() async {
    await _ensureLoaded();
    return List.unmodifiable(_deposits);
  }

  @override
  Future<List<ExpenseRecord>> loadExpenses() async {
    await _ensureLoaded();
    return List.unmodifiable(_expenses);
  }

  @override
  Future<List<LiabilityRecord>> loadLiabilities() async {
    await _ensureLoaded();
    return List.unmodifiable(_liabilities);
  }

  @override
  Future<DepositRecord> saveDeposit(SaveDepositRequest request) async {
    await _ensureLoaded();
    final record = DepositRecord(
      id: _newId('deposit'),
      orderNumber: request.orderNumber,
      totalAmount: request.totalAmount,
      creditDeposit: request.creditDeposit,
      cardLastFour: request.cardLastFour,
      cash: request.cash,
      giftCard: request.giftCard,
      other: request.other,
      transactionDate: request.transactionDate,
      isManual: request.isManual,
    );
    _deposits.add(record);
    await _persist();
    return record;
  }

  @override
  Future<ExpenseRecord> saveExpense(SaveExpenseRequest request) async {
    await _ensureLoaded();
    final record = ExpenseRecord(
      id: _newId('expense'),
      checkNumber: request.checkNumber,
      totalAmount: request.totalAmount,
      transactionDate: request.transactionDate,
      category: request.category,
      payee: request.payee,
      isManual: request.isManual,
      recurringSeriesId: request.recurringSeriesId,
      recurringIndex: request.recurringIndex,
      recurringEndMonthKey: request.recurringEndMonthKey,
      recurringFrequency: request.recurringFrequency,
    );
    _expenses.add(record);
    await _persist();
    return record;
  }

  @override
  Future<LiabilityRecord> saveLiability(SaveLiabilityRequest request) async {
    await _ensureLoaded();
    final record = LiabilityRecord(
      id: _newId('liability'),
      tab: request.tab,
      name: request.name,
      date: request.date,
      starting: request.starting,
      minimum: request.minimum,
      percent: request.percent,
      source: request.source,
    );
    _liabilities.add(record);
    await _persist();
    return record;
  }

  @override
  Future<ExpenseRecord> updateExpense(ExpenseRecord expense) async {
    await _ensureLoaded();
    final index = _expenses.indexWhere((record) => record.id == expense.id);
    if (index == -1) {
      _expenses.add(expense);
    } else {
      _expenses[index] = expense;
    }
    await _persist();
    return expense;
  }

  @override
  Future<LiabilityRecord> updateLiability(LiabilityRecord liability) async {
    await _ensureLoaded();
    final index = _liabilities.indexWhere(
      (record) => record.id == liability.id,
    );
    if (index == -1) {
      _liabilities.add(liability);
    } else {
      _liabilities[index] = liability;
    }
    await _persist();
    return liability;
  }

  @override
  Future<bool> deleteDeposit(String id) async {
    await _ensureLoaded();
    final before = _deposits.length;
    _deposits.removeWhere((record) => record.id == id);
    final removed = _deposits.length != before;
    if (removed) await _persist();
    return removed;
  }

  @override
  Future<bool> deleteExpense(String id) async {
    await _ensureLoaded();
    final before = _expenses.length;
    _expenses.removeWhere((record) => record.id == id);
    final removed = _expenses.length != before;
    if (removed) await _persist();
    return removed;
  }

  @override
  Future<bool> deleteLiability(String id) async {
    await _ensureLoaded();
    final before = _liabilities.length;
    _liabilities.removeWhere((record) => record.id == id);
    final removed = _liabilities.length != before;
    if (removed) await _persist();
    return removed;
  }

  @override
  Future<TransactionSnapshot?> loadSnapshot() async {
    await _ensureLoaded();
    return TransactionSnapshot(
      deposits: _deposits.map((record) => record.toJson()),
      expenses: _expenses.map((record) => record.toJson()),
      scheduledPayrollExpenses: _scheduledPayrollExpenses.map(
        (record) => record.toJson(),
      ),
      liabilities: _liabilities.map((record) => record.toJson()),
      defaultBudgetSeedVersion: _defaultBudgetSeedVersion,
      defaultBudgetSeedMonth: _defaultBudgetSeedMonth,
    );
  }

  @override
  Future<void> saveSnapshot(TransactionSnapshot snapshot) async {
    _loadFromSnapshot(snapshot);
    _loaded = true;
    await _persist();
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    final raw = await LocalStore.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _loaded = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _loaded = true;
        return;
      }
      _loadFromSnapshot(
        TransactionSnapshot(
          deposits: _mapListFrom(decoded['deposits']),
          expenses: _mapListFrom(decoded['expenses']),
          scheduledPayrollExpenses: _mapListFrom(
            decoded['scheduledPayrollExpenses'],
          ),
          liabilities: _mapListFrom(decoded['liabilities']),
          defaultBudgetSeedVersion: _asInt(decoded['defaultBudgetSeedVersion']),
          defaultBudgetSeedMonth: _asInt(decoded['defaultBudgetSeedMonthKey']),
        ),
      );
    } catch (_) {
      _loadFromSnapshot(TransactionSnapshot.empty());
    }

    _loaded = true;
  }

  void _loadFromSnapshot(TransactionSnapshot snapshot) {
    _deposits
      ..clear()
      ..addAll(snapshot.deposits.map(DepositRecord.fromJson));
    _expenses
      ..clear()
      ..addAll(snapshot.expenses.map(ExpenseRecord.fromJson));
    _scheduledPayrollExpenses
      ..clear()
      ..addAll(snapshot.scheduledPayrollExpenses.map(ExpenseRecord.fromJson));
    _liabilities
      ..clear()
      ..addAll(snapshot.liabilities.map(LiabilityRecord.fromJson));
    _defaultBudgetSeedVersion = snapshot.defaultBudgetSeedVersion;
    _defaultBudgetSeedMonth = snapshot.defaultBudgetSeedMonth;
  }

  Future<void> _persist() async {
    if (disablePersistenceForTesting) return;

    await LocalStore.write(
      _storageKey,
      jsonEncode(
        TransactionSnapshot(
          deposits: _deposits.map((record) => record.toJson()),
          expenses: _expenses.map((record) => record.toJson()),
          scheduledPayrollExpenses: _scheduledPayrollExpenses.map(
            (record) => record.toJson(),
          ),
          liabilities: _liabilities.map((record) => record.toJson()),
          defaultBudgetSeedVersion: _defaultBudgetSeedVersion,
          defaultBudgetSeedMonth: _defaultBudgetSeedMonth,
        ).toJson(),
      ),
    );
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
  }
}

List<Map<String, dynamic>> _mapListFrom(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList(growable: false);
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
