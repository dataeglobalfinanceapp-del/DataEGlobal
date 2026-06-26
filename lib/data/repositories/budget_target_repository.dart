abstract class BudgetTargetRepository {
  Future<Map<String, Map<String, double>>> loadTargetPercentages();

  Future<void> saveTargetPercentages(
    Map<String, Map<String, double>> percentagesByPeriod,
  );
}
