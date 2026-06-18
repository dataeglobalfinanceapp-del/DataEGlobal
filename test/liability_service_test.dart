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


  test('future recurring expense starts on the selected date only', () async {
    await LiabilityService.saveExpense(
      checkNumber: '107',
      totalAmount: 240,
      transactionDate: DateTime(2026, 6, 15),
      category: 'Utilities',
      payee: 'Power Co',
      isManual: true,
      isRecurringMonthly: true,
      recurringStartDate: DateTime(2026, 7, 1),
      recurringFrequency: 'Monthly',
    );

    var expenses = await LiabilityService.loadExpenses();

    expect(_dateKeys(expenses), ['2026-07-01']);

    final juneBudget = await LiabilityService.loadBudgetData(
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30),
      period: 'June',
    );
    expect(juneBudget.expense, 0);

    AppClock.set(DateTime(2026, 8, 1));
    expenses = await LiabilityService.loadExpenses();

    expect(_dateKeys(expenses), ['2026-07-01', '2026-08-01']);
  });

  test(
    'semi-monthly recurring expenses use the selected start date pair',
    () async {
      AppClock.set(DateTime(2026, 8, 5));

      await LiabilityService.saveExpense(
        checkNumber: '106',
        totalAmount: 600,
        transactionDate: DateTime(2026, 6, 20),
        category: 'Rent',
        payee: 'Studio rent',
        isManual: true,
        isRecurringMonthly: true,
        recurringStartDate: DateTime(2026, 6, 20),
        recurringFrequency: 'Semi-monthly',
      );

      final expenses = await LiabilityService.loadExpenses();

      expect(_dateKeys(expenses), [
        '2026-06-20',
        '2026-07-05',
        '2026-07-20',
        '2026-08-05',
      ]);
      expect(expenses.every((record) => record.isRecurring), isTrue);
    },
  );

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
    expect(data.deposit, 100);
    expect(data.saving, 10);
    expect(data.income, 90);
    expect(data.expense, 40);
    expect(data.available, 50);
    expect(data.total, 90);
    expect(data.surplusPercent, 56);
    expect(data.utilizationPercent, 44);
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
    expect(cash.saving, 10000);
    expect(cash.income, 90000);

    final credit = deposits.singleWhere((record) => record.creditDebt == 20000);
    expect(credit.transactionDate.day, 15);
    expect(credit.totalAmount, 20000);
    expect(credit.saving, 2000);
    expect(credit.income, 18000);

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
      expect(data.saving, 12000);
      expect(data.income, 108000);
      expect(data.available, closeTo(54457.56, 0.001));
      expect(data.total, 108000);
      expect(data.expense, closeTo(53542.44, 0.001));
      expect(data.surplusPercent, 50);
      expect(data.utilizationPercent, 50);
      expect(data.transactionCount, 10);
    },
  );
}

List<int> _months(List<ExpenseRecord> expenses) {
  return expenses.map((record) => record.transactionDate.month).toList()
    ..sort();
}

List<String> _dateKeys(List<ExpenseRecord> expenses) {
  return expenses.map((record) => _dateKey(record.transactionDate)).toList()
    ..sort();
}

String _dateKey(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
