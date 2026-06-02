import 'package:flutter_test/flutter_test.dart';

import 'package:biztrack/services/app_clock.dart';
import 'package:biztrack/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting();
  });

  test(
    'deleting recurring expense keeps prior months and stops future sync',
    () async {
      await LiabilityService.saveExpense(
        checkNumber: '101',
        totalAmount: 1200,
        transactionDate: DateTime(2026, 1, 10),
        category: 'Rent',
        payee: 'Rent',
        isManual: true,
        isRecurringMonthly: true,
      );

      var expenses = await LiabilityService.loadExpenses();
      expect(_months(expenses), [1, 2, 3, 4, 5, 6]);

      final juneRent = expenses.singleWhere(
        (record) => record.transactionDate.month == 6,
      );
      final deleted = await LiabilityService.deleteExpense(juneRent.id);

      expect(deleted, isTrue);
      expenses = await LiabilityService.loadExpenses();
      expect(_months(expenses), [1, 2, 3, 4, 5]);
      expect(expenses.map((record) => record.recurringEndMonthKey).toSet(), {
        2026 * 12 + 6,
      });

      AppClock.set(DateTime(2026, 7, 1));
      expenses = await LiabilityService.loadExpenses();

      expect(_months(expenses), [1, 2, 3, 4, 5]);
    },
  );

  test(
    'deleting recurring expense from selected month keeps earlier months',
    () async {
      await LiabilityService.saveExpense(
        checkNumber: '103',
        totalAmount: 700,
        transactionDate: DateTime(2026, 1, 10),
        category: 'Utilities',
        payee: 'Utilities',
        isManual: true,
        isRecurringMonthly: true,
      );

      var expenses = await LiabilityService.loadExpenses();
      final marchUtilities = expenses.singleWhere(
        (record) => record.transactionDate.month == 3,
      );

      final deleted = await LiabilityService.deleteRecurringExpenseFromMonth(
        marchUtilities.id,
        marchUtilities.transactionDate,
      );

      expect(deleted, isTrue);
      expenses = await LiabilityService.loadExpenses();
      expect(_months(expenses), [1, 2]);

      AppClock.set(DateTime(2026, 7, 1));
      expenses = await LiabilityService.loadExpenses();
      expect(_months(expenses), [1, 2]);
    },
  );

  test(
    'editing recurring amount keeps past months and updates future sync',
    () async {
      await LiabilityService.saveExpense(
        checkNumber: '102',
        totalAmount: 900,
        transactionDate: DateTime(2026, 1, 10),
        category: 'Rent',
        payee: 'Rent',
        isManual: true,
        isRecurringMonthly: true,
      );

      var expenses = await LiabilityService.loadExpenses();
      final juneRent = expenses.singleWhere(
        (record) => record.transactionDate.month == 6,
      );

      final updated = await LiabilityService.updateRecurringExpenseAmount(
        juneRent.id,
        950,
      );

      expect(updated, isTrue);
      expenses = await LiabilityService.loadExpenses();
      expect(
        expenses
            .where((record) => record.transactionDate.month < 6)
            .map((record) => record.totalAmount)
            .toSet(),
        {900},
      );
      expect(
        expenses
            .singleWhere((record) => record.transactionDate.month == 6)
            .totalAmount,
        950,
      );

      AppClock.set(DateTime(2026, 7, 1));
      expenses = await LiabilityService.loadExpenses();

      expect(_months(expenses), [1, 2, 3, 4, 5, 6, 7]);
      expect(
        expenses
            .singleWhere((record) => record.transactionDate.month == 7)
            .totalAmount,
        950,
      );
    },
  );
}

List<int> _months(List<ExpenseRecord> expenses) {
  return expenses.map((record) => record.transactionDate.month).toList()
    ..sort();
}
