class SavingRolloverPeriod {
  final DateTime end;
  final double requiredAmount;
  final double savedAmount;

  const SavingRolloverPeriod({
    required this.end,
    required this.requiredAmount,
    required this.savedAmount,
  });
}

/// Returns each period's required amount after moving any unpaid balance from
/// completed periods to the first period that has not ended yet.
///
/// The running balance lets a later payment satisfy an earlier shortfall while
/// preventing an overpayment from reducing a future period's normal target.
List<double> calculateSavingRequiredAmounts({
  required List<SavingRolloverPeriod> periods,
  required DateTime today,
}) {
  final requiredAmounts = [for (final period in periods) period.requiredAmount];
  final currentDate = DateTime(today.year, today.month, today.day);
  final dueIndex = periods.indexWhere(
    (period) => !_dateOnly(period.end).isBefore(currentDate),
  );

  if (dueIndex == -1) return requiredAmounts;

  var overdueAmount = 0.0;
  for (var index = 0; index < dueIndex; index++) {
    final period = periods[index];
    overdueAmount += period.requiredAmount - period.savedAmount;
    if (overdueAmount < 0) overdueAmount = 0;
  }

  requiredAmounts[dueIndex] += overdueAmount;
  return requiredAmounts;
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
