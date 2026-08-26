enum SavingPeriod { day, week, month }

class SavingDeposit {
  final double amount;
  final DateTime date;

  const SavingDeposit({required this.amount, required this.date});
}

class SavingRateInput {
  const SavingRateInput._();

  static double? parse(String input) {
    final value = double.tryParse(input.replaceAll('%', '').trim());
    return isValid(value) ? value : null;
  }

  static bool isValid(double? value) => value != null && value >= 0;
}

class SavingPeriodRow {
  final String key;
  final DateTime start;
  final DateTime end;
  final double requiredAmount;

  const SavingPeriodRow({
    required this.key,
    required this.start,
    required this.end,
    required this.requiredAmount,
  });

  SavingPeriodRow copyWith({double? requiredAmount}) {
    return SavingPeriodRow(
      key: key,
      start: start,
      end: end,
      requiredAmount: requiredAmount ?? this.requiredAmount,
    );
  }
}
