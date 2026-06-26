import 'package:flutter/foundation.dart';

import 'package:savetep/data/local/local_budget_target_repository.dart';
import 'package:savetep/data/repositories/budget_target_repository.dart';

class BudgetTargetService {
  static BudgetTargetRepository _repository =
      const LocalBudgetTargetRepository();

  BudgetTargetService._();

  static Future<Map<String, Map<String, double>>>
  loadTargetPercentages() async {
    final targets = await _repository.loadTargetPercentages();
    return {
      ...targets,
      'Month': targets['Month'] ?? targets['Year'] ?? <String, double>{},
    };
  }

  static Future<void> saveTargetPercentages(
    Map<String, Map<String, double>> percentagesByPeriod,
  ) {
    return _repository.saveTargetPercentages(percentagesByPeriod);
  }

  @visibleForTesting
  static void setRepositoryForTesting(BudgetTargetRepository repository) {
    _repository = repository;
  }
}
