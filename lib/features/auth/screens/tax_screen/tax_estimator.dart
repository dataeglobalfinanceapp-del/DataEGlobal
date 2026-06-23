class TaxEstimator {
  const TaxEstimator._();

  static TaxEstimate calculate({
    required double totalReserve,
    required int currentMonth,
  }) {
    final taxableReserve = totalReserve > 0 ? totalReserve : 0.0;
    final projectedAnnualReserve = projectAnnualReserve(
      totalReserve: taxableReserve,
      currentMonth: currentMonth,
    );
    final bracket = TaxBracket.forAmount(projectedAnnualReserve);
    final taxDue = taxableReserve * bracket.rate / 100;

    return TaxEstimate(
      bracket: bracket,
      taxDue: taxDue,
      remaining: totalReserve - taxDue,
      projectedAnnualReserve: projectedAnnualReserve,
    );
  }

  static double projectAnnualReserve({
    required double totalReserve,
    required int currentMonth,
  }) {
    final projectionMonth = currentMonth.clamp(1, 12).toInt();
    if (projectionMonth == 12) return totalReserve;
    return totalReserve / projectionMonth * 12;
  }
}

class TaxEstimate {
  final TaxBracket bracket;
  final double taxDue;
  final double remaining;
  final double projectedAnnualReserve;

  const TaxEstimate({
    required this.bracket,
    required this.taxDue,
    required this.remaining,
    required this.projectedAnnualReserve,
  });
}

class TaxBracket {
  final double rate;
  final double min;
  final double? max;
  final String label;

  const TaxBracket({
    required this.rate,
    required this.min,
    required this.max,
    required this.label,
  });

  String get rateLabel => rate.toStringAsFixed(0);

  static const brackets = [
    TaxBracket(rate: 10, min: 0, max: 12400, label: r'$0 to $12,400'),
    TaxBracket(rate: 12, min: 12401, max: 50400, label: r'$12,401 to $50,400'),
    TaxBracket(
      rate: 22,
      min: 50401,
      max: 105700,
      label: r'$50,401 to $105,700',
    ),
    TaxBracket(
      rate: 24,
      min: 105701,
      max: 201775,
      label: r'$105,701 to $201,775',
    ),
    TaxBracket(
      rate: 32,
      min: 201776,
      max: 256225,
      label: r'$201,776 to $256,225',
    ),
    TaxBracket(
      rate: 35,
      min: 256226,
      max: 640600,
      label: r'$256,226 to $640,600',
    ),
    TaxBracket(rate: 37, min: 640601, max: null, label: r'Over $640,600'),
  ];

  static TaxBracket forAmount(double amount) {
    for (final bracket in brackets) {
      if (bracket.max == null || amount <= bracket.max!) {
        return bracket;
      }
    }
    return brackets.last;
  }
}
