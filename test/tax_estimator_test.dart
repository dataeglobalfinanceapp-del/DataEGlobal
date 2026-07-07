import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/tax_estimate_service.dart';
import 'package:savetep/features/auth/screens/tax_screen/tax_estimator.dart';

void main() {
  tearDown(() {
    AppClock.reset();
  });

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

  test(
    'calculates year-end estimate from records through projection month',
    () {
      AppClock.set(DateTime(2026, 6, 15));

      final deposits = [
        _TaxRecord(amount: 125, date: DateTime(2026, 6, 12)),
        _TaxRecord(amount: 999, date: DateTime(2026, 7, 1)),
      ];
      final expenses = [
        _TaxRecord(amount: 45, date: DateTime(2026, 6, 13)),
        _TaxRecord(amount: 999, date: DateTime(2025, 6, 13)),
      ];

      final estimate =
          TaxEstimateService.calculateYearEndEstimate<_TaxRecord, _TaxRecord>(
            deposits: deposits,
            expenses: expenses,
            year: 2026,
            depositDate: (record) => record.date,
            depositAmount: (record) => record.amount,
            expenseDate: (record) => record.date,
            expenseAmount: (record) => record.amount,
          );

      expect(estimate.taxDue, closeTo(8, 0.001));
    },
  );
}

class _TaxRecord {
  final double amount;
  final DateTime date;

  const _TaxRecord({required this.amount, required this.date});
}
