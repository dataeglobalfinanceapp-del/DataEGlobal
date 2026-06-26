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
