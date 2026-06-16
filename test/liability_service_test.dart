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
    LiabilityService.resetForTesting(disablePersistence: false);
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

  test('recurring expense sync preserves the original day of month', () async {
    await LiabilityService.saveExpense(
      checkNumber: '104',
      totalAmount: 3000,
      transactionDate: DateTime(2026, 1, 2),
      category: 'Insurance',
      payee: 'Insurance',
      isManual: true,
      isRecurringMonthly: true,
    );

    final expenses = await LiabilityService.loadExpenses();

    expect(_months(expenses), [1, 2, 3, 4, 5, 6]);
    expect(expenses.map((record) => record.transactionDate.day).toSet(), {2});
  });

  test('budget data includes transaction count for selected range', () async {
    await LiabilityService.saveDeposit(
      orderNumber: 'd1',
      totalAmount: 100,
      creditDebt: 100,
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 12),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'e1',
      totalAmount: 40,
      transactionDate: DateTime(2026, 6, 13),
      category: 'Fuel',
      payee: 'Fuel',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'e2',
      totalAmount: 80,
      transactionDate: DateTime(2026, 5, 1),
      category: 'Rent',
      payee: 'Rent',
      isManual: true,
    );

    final data = await LiabilityService.loadBudgetData(
      startDate: DateTime(2026, 6, 9),
      endDate: DateTime(2026, 6, 15),
      period: 'Week',
    );

    expect(data.transactionCount, 2);
  });

  test('default budget seed uses the created month', () async {
    LiabilityService.resetForTesting(seedDefaultBudgetData: true);

    final deposits = await LiabilityService.loadDeposits();
    final expenses = await LiabilityService.loadExpenses();

    expect(deposits, hasLength(2));
    expect(expenses, hasLength(15));
    expect(deposits.map((record) => record.transactionDate.month).toSet(), {6});
    expect(expenses.map((record) => record.transactionDate.month).toSet(), {6});

    final cash = deposits.singleWhere((record) => record.cash == 100000);
    expect(cash.transactionDate.day, 1);
    expect(cash.totalAmount, 100000);

    final credit = deposits.singleWhere((record) => record.creditDebt == 20000);
    expect(credit.transactionDate.day, 15);
    expect(credit.totalAmount, 20000);

    final insurance = expenses.singleWhere(
      (record) => record.category == 'Insurance',
    );
    expect(insurance.transactionDate.day, 2);
    expect(insurance.isRecurring, isTrue);

    final rent = expenses.singleWhere((record) => record.category == 'Rent');
    expect(rent.transactionDate.day, 1);
    expect(rent.isRecurring, isTrue);

    expect(await LiabilityService.loadDeposits(), hasLength(2));
    expect(await LiabilityService.loadExpenses(), hasLength(15));
  });

  test(
    'default budget seed aggregates through the created date range',
    () async {
      LiabilityService.resetForTesting(seedDefaultBudgetData: true);

      final data = await LiabilityService.loadBudgetData(
        startDate: DateTime(2026, 6),
        endDate: DateTime(2026, 6, 15),
        period: 'Created month',
      );

      expect(data.deposit, 120000);
      expect(data.expense, closeTo(53542.44, 0.001));
      expect(data.transactionCount, 10);
      expect(data.recurringExpenses.map((item) => item.category).toSet(), {
        'Insurance',
        'Rent',
      });
    },
  );
}

List<int> _months(List<ExpenseRecord> expenses) {
  return expenses.map((record) => record.transactionDate.month).toList()
    ..sort();
}
