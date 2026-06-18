class DepositAllocation {
  const DepositAllocation._();

  static const double savingRate = 0.10;
  static const double incomeRate = 0.90;
  static const double reservesRate = incomeRate;

  static double savingFor(double deposit) => deposit * savingRate;

  static double incomeFor(double deposit) => deposit * incomeRate;

  static double reservesFor(double deposit) => incomeFor(deposit);

  static double availableFrom({
    required double deposit,
    required double expenses,
  }) {
    return incomeFor(deposit) - expenses;
  }
}
