import 'dart:convert';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/data/repositories/transaction_repository.dart';

class LocalTransactionRepository implements TransactionRepository {
  static const _storageKey = 'savetep_local_data_v1';

  const LocalTransactionRepository();

  @override
  Future<TransactionSnapshot?> loadSnapshot() async {
    final raw = await LocalStore.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return TransactionSnapshot(
        deposits: _mapListFrom(decoded['deposits']),
        expenses: _mapListFrom(decoded['expenses']),
        liabilities: _mapListFrom(decoded['liabilities']),
        defaultBudgetSeedVersion: _asInt(decoded['defaultBudgetSeedVersion']),
        defaultBudgetSeedMonth: _asInt(decoded['defaultBudgetSeedMonthKey']),
      );
    } catch (_) {
      return TransactionSnapshot.empty();
    }
  }

  @override
  Future<void> saveSnapshot(TransactionSnapshot snapshot) {
    return LocalStore.write(_storageKey, jsonEncode(snapshot.toJson()));
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
