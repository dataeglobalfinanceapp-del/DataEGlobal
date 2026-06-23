import 'package:flutter_test/flutter_test.dart';

import 'package:biztrack/features/auth/screens/tax_screen/tax_estimator.dart';

void main() {
  test(
    'projects annual reserve from accumulated reserve and current month',
    () {
      expect(
        TaxEstimator.projectAnnualReserve(totalReserve: 1200, currentMonth: 3),
        closeTo(4800, 0.001),
      );
      expect(
        TaxEstimator.projectAnnualReserve(totalReserve: 1200, currentMonth: 4),
        closeTo(3600, 0.001),
      );
      expect(
        TaxEstimator.projectAnnualReserve(totalReserve: 1200, currentMonth: 6),
        closeTo(2400, 0.001),
      );
      expect(
        TaxEstimator.projectAnnualReserve(totalReserve: 1200, currentMonth: 8),
        closeTo(1800, 0.001),
      );
      expect(
        TaxEstimator.projectAnnualReserve(totalReserve: 1200, currentMonth: 9),
        closeTo(1600, 0.001),
      );
      expect(
        TaxEstimator.projectAnnualReserve(totalReserve: 1200, currentMonth: 10),
        closeTo(1440, 0.001),
      );
      expect(
        TaxEstimator.projectAnnualReserve(totalReserve: 1200, currentMonth: 12),
        closeTo(1200, 0.001),
      );
    },
  );

  test('uses projected annual reserve when choosing tax percentage', () {
    final estimate = TaxEstimator.calculate(
      totalReserve: 45000,
      currentMonth: 6,
    );

    expect(estimate.projectedAnnualReserve, closeTo(90000, 0.001));
    expect(estimate.bracket.rate, 22);
    expect(estimate.taxDue, closeTo(9900, 0.001));
    expect(estimate.remaining, closeTo(35100, 0.001));
  });
}
