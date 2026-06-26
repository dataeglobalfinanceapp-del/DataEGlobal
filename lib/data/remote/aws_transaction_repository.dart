import 'dart:convert';

import 'package:savetep/core/api/aws_api_client.dart';
import 'package:savetep/data/repositories/transaction_repository.dart';

class AwsTransactionRepository implements TransactionRepository {
  static const _storageKey = 'transactions';

  final AwsApiClient client;

  const AwsTransactionRepository(this.client);

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
