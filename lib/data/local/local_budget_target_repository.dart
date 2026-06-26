import 'dart:convert';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/data/repositories/budget_target_repository.dart';

class LocalBudgetTargetRepository implements BudgetTargetRepository {
  static const _storageKey = 'SaveTep_budget_target_percentages_v1';

  const LocalBudgetTargetRepository();

  @override
  Future<Map<String, Map<String, double>>> loadTargetPercentages() async {
    final raw = await LocalStore.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final targets = <String, Map<String, double>>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        targets[entry.key.toString()] = {
          for (final targetEntry in value.entries)
            targetEntry.key.toString(): _asDouble(targetEntry.value),
        };
      }
      return targets;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveTargetPercentages(
    Map<String, Map<String, double>> percentagesByPeriod,
  ) {
    return LocalStore.write(_storageKey, jsonEncode(percentagesByPeriod));
  }
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
