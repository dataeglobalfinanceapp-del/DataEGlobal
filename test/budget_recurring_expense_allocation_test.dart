import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
  });

  test(
    'budget data shows daily portions for recurring monthly expenses',
    () async {
      await LiabilityService.saveExpense(
        checkNumber: 'R-1',
        totalAmount: 300,
        transactionDate: DateTime(2026, 6, 1),
        category: 'Rent',
        payee: 'Rent',
        isManual: true,
        isRecurringMonthly: true,
      );

      final dayData = await LiabilityService.loadBudgetData(
        startDate: DateTime(2026, 6, 10),
        endDate: DateTime(2026, 6, 10),
        period: 'Day',
      );
      expect(dayData.expense, closeTo(10, 0.001));

      final weekData = await LiabilityService.loadBudgetData(
        startDate: DateTime(2026, 6, 9),
        endDate: DateTime(2026, 6, 15),
        period: 'Week',
      );
      expect(weekData.expense, closeTo(70, 0.001));

      final monthData = await LiabilityService.loadBudgetData(
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 30),
        period: 'Month',
      );
      expect(monthData.expense, closeTo(300, 0.001));
      expect(monthData.categories.single.label, 'Rent');
      expect(monthData.categories.single.percentage, closeTo(100, 0.001));
    },
  );
}
