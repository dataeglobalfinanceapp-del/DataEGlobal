import 'package:savetep/domain/services/budget_target_service.dart';

abstract interface class HomeBudgetTargetRepository {
  Future<Map<String, Map<String, double>>> loadTargetPercentages();

  Future<void> saveTargetPercentages(
    Map<String, Map<String, double>> percentagesByPeriod,
  );
}

class ServiceHomeBudgetTargetRepository implements HomeBudgetTargetRepository {
  const ServiceHomeBudgetTargetRepository();

  @override
  Future<Map<String, Map<String, double>>> loadTargetPercentages() {
    return BudgetTargetService.loadTargetPercentages();
  }

  @override
  Future<void> saveTargetPercentages(
    Map<String, Map<String, double>> percentagesByPeriod,
  ) {
    return BudgetTargetService.saveTargetPercentages(percentagesByPeriod);
  }
}
