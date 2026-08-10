import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/features/auth/models/budget_data.dart';
import 'package:savetep/features/auth/screens/scan_screen/expense_screen/scan_expense_screen.dart';
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
      tipsGratuity: 5,
      transactionDate: DateTime(2026, 6, 15, 14, 35),
      category: 'electric',
      payee: 'Power Co',
      isManual: true,
      isRecurringMonthly: true,
      recurringStartDate: DateTime(2026, 7, 1),
      recurringFrequency: 'Monthly',
    );

    var expenses = await LiabilityService.loadExpenses();

    expect(_dateKeys(expenses), ['2026-07-01']);
    expect(expenses.single.transactionDate, DateTime(2026, 7, 1, 14, 35));
    expect(expenses.single.tipsGratuity, 5);

    final juneBudget = await LiabilityService.loadBudgetData(
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30),
      period: 'June',
    );
    expect(juneBudget.expense, 0);

    AppClock.set(DateTime(2026, 8, 1));
    expenses = await LiabilityService.loadExpenses();

    expect(_dateKeys(expenses), ['2026-07-01', '2026-08-01']);
    expect(
      expenses.map((ExpenseRecord record) => record.transactionDate.hour),
      everyElement(14),
    );
    expect(
      expenses.map((ExpenseRecord record) => record.tipsGratuity),
      everyElement(5),
    );
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
      creditDeposit: 100,
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
      category: 'gas',
      payee: 'gas',
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
    expect(data.expense, 40);
    expect(data.available, 60);
    expect(data.total, 100);
    expect(data.surplusPercent, 60);
    expect(data.utilizationPercent, 40);
  });

  test('deposit card last four is normalized before storage', () async {
    await LiabilityService.saveDeposit(
      orderNumber: 'd-card',
      totalAmount: 42,
      creditDeposit: 42,
      cardLastFour: '4111 1111 1111 9876',
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 14),
      isManual: true,
    );

    final deposits = await LiabilityService.loadDeposits();

    expect(deposits.single.cardLastFour, '9876');
    expect(deposits.single.toJson()['cardLastFour'], '9876');
  });

  test('expense tips and combined timestamp survive persistence', () async {
    final transactionDate = DateTime(2026, 8, 6, 14, 35);

    await LiabilityService.saveExpense(
      checkNumber: '',
      totalAmount: 125.75,
      tipsGratuity: 5,
      transactionDate: transactionDate,
      category: 'gas',
      payee: 'City Gas',
      isManual: false,
    );

    final expense = (await LiabilityService.loadExpenses()).single;

    expect(expense.totalAmount, 125.75);
    expect(expense.tipsGratuity, 5);
    expect(expense.transactionDate, transactionDate);
    expect(expense.toJson()['tipsGratuity'], 5);
    expect(expense.toJson()['transactionDate'], '2026-08-06T14:35:00.000');
  });

  test('legacy date-only expenses load at midnight with zero tips', () {
    final expense = ExpenseRecord.fromJson(<String, dynamic>{
      'id': 'legacy-expense',
      'checkNumber': '101',
      'totalAmount': 42,
      'transactionDate': '2026-08-06',
      'category': 'electric',
      'payee': 'Power Co',
      'isManual': true,
    });

    expect(expense.transactionDate, DateTime(2026, 8, 6));
    expect(expense.tipsGratuity, 0);
  });

  test('default budget seed covers every valid expense category', () {
    final seeds = DefaultBudgetSeedData.expenses;
    final expectedCategories = ExpenseCategory.values
        .map((ExpenseCategory category) => category.label)
        .toSet();

    expect(
      seeds.map((BudgetSeedExpense seed) => seed.category).toSet(),
      expectedCategories,
    );
    expect(seeds, hasLength(expectedCategories.length));
    for (final seed in seeds) {
      expect(seed.payee.trim(), isNotEmpty);
      expect(seed.total, greaterThan(0));
      expect(seed.date, isA<DateTime>());
      expect(seed.last4CreditCard, matches(RegExp(r'^\d{4}$')));
    }
  });

  test('default budget seed uses the created month', () async {
    LiabilityService.resetForTesting(seedDefaultBudgetData: true);

    final deposits = await LiabilityService.loadDeposits();
    final expenses = await LiabilityService.loadExpenses();

    expect(deposits, hasLength(2));
    expect(expenses, hasLength(21));
    expect(deposits.map((record) => record.transactionDate.month).toSet(), {6});
    expect(expenses.map((record) => record.transactionDate.month).toSet(), {6});
    expect(
      expenses.every(
        (ExpenseRecord record) =>
            RegExp(r'^\d{4}$').hasMatch(record.last4CreditCard),
      ),
      isTrue,
    );

    final cash = deposits.singleWhere((record) => record.cash == 100000);
    expect(cash.transactionDate.day, 1);
    expect(cash.totalAmount, 100000);

    final credit = deposits.singleWhere(
      (record) => record.creditDeposit == 20000,
    );
    expect(credit.transactionDate.day, 15);
    expect(credit.totalAmount, 20000);

    expect(await LiabilityService.loadDeposits(), hasLength(2));
    expect(await LiabilityService.loadExpenses(), hasLength(21));
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
      expect(data.available, closeTo(105897.03, 0.001));
      expect(data.total, 120000);
      expect(data.expense, closeTo(14102.97, 0.001));
      expect(data.surplusPercent, 88);
      expect(data.utilizationPercent, 12);
      expect(data.transactionCount, 16);
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
