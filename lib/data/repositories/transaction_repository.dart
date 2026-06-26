import 'package:savetep/data/dto/save_deposit_request.dart';
import 'package:savetep/data/dto/save_expense_request.dart';
import 'package:savetep/data/dto/save_liability_request.dart';
import 'package:savetep/services/liability_service.dart';

class TransactionSnapshot {
  final List<Map<String, dynamic>> deposits;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> liabilities;
  final int defaultBudgetSeedVersion;
  final int defaultBudgetSeedMonth;

  TransactionSnapshot({
    required Iterable<Map<String, dynamic>> deposits,
    required Iterable<Map<String, dynamic>> expenses,
    required Iterable<Map<String, dynamic>> liabilities,
    required this.defaultBudgetSeedVersion,
    required this.defaultBudgetSeedMonth,
  }) : deposits = _immutableMapList(deposits),
       expenses = _immutableMapList(expenses),
       liabilities = _immutableMapList(liabilities);

  TransactionSnapshot.empty()
    : deposits = const [],
      expenses = const [],
      liabilities = const [],
      defaultBudgetSeedVersion = 0,
      defaultBudgetSeedMonth = 0;

  Map<String, dynamic> toJson() {
    return {
      'deposits': deposits,
      'expenses': expenses,
      'liabilities': liabilities,
      'defaultBudgetSeedVersion': defaultBudgetSeedVersion,
      'defaultBudgetSeedMonthKey': defaultBudgetSeedMonth,
    };
  }
}

abstract class TransactionRepository {
  Future<List<DepositRecord>> loadDeposits();

  Future<List<ExpenseRecord>> loadExpenses();

  Future<List<LiabilityRecord>> loadLiabilities();

  Future<DepositRecord> saveDeposit(SaveDepositRequest request);

  Future<ExpenseRecord> saveExpense(SaveExpenseRequest request);

  Future<LiabilityRecord> saveLiability(SaveLiabilityRequest request);

  Future<ExpenseRecord> updateExpense(ExpenseRecord expense);

  Future<LiabilityRecord> updateLiability(LiabilityRecord liability);

  Future<bool> deleteDeposit(String id);

  Future<bool> deleteExpense(String id);

  Future<bool> deleteLiability(String id);

  Future<TransactionSnapshot?> loadSnapshot();

  Future<void> saveSnapshot(TransactionSnapshot snapshot);
}

List<Map<String, dynamic>> _immutableMapList(
  Iterable<Map<String, dynamic>> values,
) {
  return List.unmodifiable(
    values.map<Map<String, dynamic>>(
      (value) => Map<String, dynamic>.unmodifiable(value),
    ),
  );
}
