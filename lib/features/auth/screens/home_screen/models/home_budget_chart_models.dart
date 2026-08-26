class HomeBudgetData {
  final double deposit;
  final double expense;
  final double total;
  final String period;
  final int surplusPercent;
  final int utilizationPercent;
  final double estimatedTaxAtYearEnd;
  final int transactionCount;
  final List<HomeBudgetCategory> categories;

  const HomeBudgetData({
    this.deposit = 0,
    this.expense = 0,
    this.total = 0,
    this.period = '',
    this.surplusPercent = 0,
    this.utilizationPercent = 0,
    this.estimatedTaxAtYearEnd = 0,
    this.transactionCount = 0,
    this.categories = const [],
  });

  double get available => deposit - expense;
}

class HomeBudgetCategory {
  final String label;
  final double percentage;

  const HomeBudgetCategory({required this.label, required this.percentage});
}

class HomeBudgetSegment {
  final String label;
  final double amount;
  final double percentage;
  final bool isPlaceholder;

  const HomeBudgetSegment({
    required this.label,
    required this.amount,
    required this.percentage,
    this.isPlaceholder = false,
  });

  bool isOverTarget(double targetPercentage) {
    return percentage > 0 && percentage > targetPercentage;
  }
}
