import 'dart:convert';

import 'package:savetep/core/api/aws_api_client.dart';
import 'package:savetep/data/dto/save_deposit_request.dart';
import 'package:savetep/data/dto/save_expense_request.dart';
import 'package:savetep/data/dto/save_liability_request.dart';
import 'package:savetep/data/repositories/transaction_repository.dart';
import 'package:savetep/services/liability_service.dart';

class AwsTransactionRepository implements TransactionRepository {
  static const _storageKey = 'transactions';

  final AwsApiClient client;

  const AwsTransactionRepository(this.client);

  @override
  Future<List<DepositRecord>> loadDeposits() {
    throw UnimplementedError('AWS transaction repository is not wired yet.');
  }

  @override
  Future<List<ExpenseRecord>> loadExpenses() {
    throw UnimplementedError('AWS transaction repository is not wired yet.');
  }

  @override
  Future<List<LiabilityRecord>> loadLiabilities() {
    throw UnimplementedError('AWS transaction repository is not wired yet.');
  }

  @override
  Future<DepositRecord> saveDeposit(SaveDepositRequest request) {
    throw UnimplementedError('AWS transaction repository is not wired yet.');
  }

  @override
  Future<ExpenseRecord> saveExpense(SaveExpenseRequest request) {
    throw UnimplementedError('AWS transaction repository is not wired yet.');
  }

  @override
  Future<LiabilityRecord> saveLiability(SaveLiabilityRequest request) {
    throw UnimplementedError('AWS transaction repository is not wired yet.');
  }

  @override
  Future<ExpenseRecord> updateExpense(ExpenseRecord expense) {
    throw UnimplementedError('AWS transaction repository is not wired yet.');
  }

  @override
  Future<LiabilityRecord> updateLiability(LiabilityRecord liability) {
    throw UnimplementedError('AWS transaction repository is not wired yet.');
  }

  @override
  Future<bool> deleteDeposit(String id) {
    throw UnimplementedError('AWS transaction repository is not wired yet.');
  }

  @override
  Future<bool> deleteExpense(String id) {
    throw UnimplementedError('AWS transaction repository is not wired yet.');
  }

  @override
  Future<bool> deleteLiability(String id) {
    throw UnimplementedError('AWS transaction repository is not wired yet.');
  }

  @override
  Future<TransactionSnapshot?> loadSnapshot() async {
    final raw = await client.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return TransactionSnapshot(
      deposits: _mapListFrom(decoded['deposits']),
      expenses: _mapListFrom(decoded['expenses']),
      liabilities: _mapListFrom(decoded['liabilities']),
      defaultBudgetSeedVersion: _asInt(decoded['defaultBudgetSeedVersion']),
      defaultBudgetSeedMonth: _asInt(decoded['defaultBudgetSeedMonthKey']),
    );
  }

  @override
  Future<void> saveSnapshot(TransactionSnapshot snapshot) {
    return client.write(_storageKey, jsonEncode(snapshot.toJson()));
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
