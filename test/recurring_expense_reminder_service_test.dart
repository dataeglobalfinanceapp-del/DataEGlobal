import 'package:flutter_test/flutter_test.dart';

import 'package:biztrack/services/app_clock.dart';
import 'package:biztrack/services/liability_service.dart';
import 'package:biztrack/services/recurring_expense_reminder_service.dart';
import 'package:biztrack/services/reminder_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 1));
    LiabilityService.resetForTesting();
    ReminderService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
    ReminderService.resetForTesting(disablePersistence: false);
  });

  test('linked recurring save uses one shared recurring id', () async {
    await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
      checkNumber: '201',
      totalAmount: 100,
      transactionDate: DateTime(2026, 6, 1),
      startDate: DateTime(2026, 6, 1),
      category: 'Utilities',
      payee: 'Power Co',
      isManual: true,
      frequency: 'Biweekly',
    );

    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();
    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();

    expect(reminders, isNotEmpty);
    expect(expenses, hasLength(1));
    expect(
      reminders.first.recurringSeriesId,
      expenses.single.recurringSeriesId,
    );
  });

  test(
    'editing recurring reminder amount updates linked future expenses',
    () async {
      await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
        checkNumber: '202',
        totalAmount: 100,
        transactionDate: DateTime(2026, 1, 10),
        startDate: DateTime(2026, 1, 10),
        category: 'Rent',
        payee: 'Landlord',
        isManual: true,
        frequency: 'Monthly',
      );

      var expenses = await LiabilityService.loadExpenses();
      expect(_amountFor(expenses, DateTime(2026, 5, 10)), 100);
      expect(_amountFor(expenses, DateTime(2026, 6, 10)), 100);

      final ReminderRecord juneReminder =
          (await ReminderService.loadReminders()).singleWhere(
            (ReminderRecord record) => record.date.month == 6,
          );

      await RecurringExpenseReminderService.updateReminderAmount(
        reminderId: juneReminder.id,
        amount: 225,
        scope: ReminderEditScope.series,
      );

      expenses = await LiabilityService.loadExpenses();
      expect(_amountFor(expenses, DateTime(2026, 5, 10)), 100);
      expect(_amountFor(expenses, DateTime(2026, 6, 10)), 225);

      AppClock.set(DateTime(2026, 7, 10));
      expenses = await LiabilityService.loadExpenses();
      expect(_amountFor(expenses, DateTime(2026, 7, 10)), 225);
    },
  );

  test(
    'editing a recurring reminder earlier in the month updates its transaction',
    () async {
      AppClock.set(DateTime(2026, 8, 15));

      await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
        checkNumber: '205',
        totalAmount: 5000,
        transactionDate: DateTime(2026, 8, 2),
        startDate: DateTime(2026, 8, 2),
        category: 'Rent',
        payee: 'Rent',
        isManual: true,
        frequency: 'Monthly',
      );

      final ReminderRecord augustReminder =
          (await ReminderService.loadReminders()).singleWhere(
            (ReminderRecord record) => _dateKey(record.date) == '2026-08-02',
          );

      await RecurringExpenseReminderService.updateReminderAmount(
        reminderId: augustReminder.id,
        amount: 6000,
        scope: ReminderEditScope.series,
      );

      var expenses = await LiabilityService.loadExpenses();
      expect(_amountFor(expenses, DateTime(2026, 8, 2)), 6000);

      AppClock.set(DateTime(2026, 9, 2));
      expenses = await LiabilityService.loadExpenses();
      expect(_amountFor(expenses, DateTime(2026, 9, 2)), 6000);
    },
  );

  test(
    'editing one recurring reminder updates the linked expense occurrence',
    () async {
      AppClock.set(DateTime(2026, 6, 15));
      await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
        checkNumber: '204',
        totalAmount: 80,
        transactionDate: DateTime(2026, 6, 1),
        startDate: DateTime(2026, 6, 1),
        category: 'Utilities',
        payee: 'Power Co',
        isManual: true,
        frequency: 'Biweekly',
      );

      final ReminderRecord reminder = (await ReminderService.loadReminders())
          .singleWhere(
            (ReminderRecord record) => _dateKey(record.date) == '2026-06-15',
          );

      await RecurringExpenseReminderService.updateReminderAmount(
        reminderId: reminder.id,
        amount: 95,
        scope: ReminderEditScope.single,
      );

      final List<ExpenseRecord> expenses =
          await LiabilityService.loadExpenses();
      expect(_amountFor(expenses, DateTime(2026, 6, 1)), 80);
      expect(_amountFor(expenses, DateTime(2026, 6, 15)), 95);
    },
  );

  test(
    'deleting recurring reminder keeps history and stops future expenses',
    () async {
      AppClock.set(DateTime(2026, 6, 29));
      await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
        checkNumber: '203',
        totalAmount: 90,
        transactionDate: DateTime(2026, 6, 1),
        startDate: DateTime(2026, 6, 1),
        category: 'Payroll',
        payee: 'Team payroll',
        isManual: true,
        frequency: 'Biweekly',
      );

      var expenses = await LiabilityService.loadExpenses();
      expect(_dateKeys(expenses), <String>[
        '2026-06-01',
        '2026-06-15',
        '2026-06-29',
      ]);

      final ReminderRecord reminderToDelete =
          (await ReminderService.loadReminders()).singleWhere(
            (ReminderRecord record) => _dateKey(record.date) == '2026-06-29',
          );

      final bool deleted = await RecurringExpenseReminderService.deleteReminder(
        reminderId: reminderToDelete.id,
        scope: ReminderDeleteScope.series,
      );

      expect(deleted, isTrue);
      expect(await ReminderService.loadReminders(), isEmpty);

      expenses = await LiabilityService.loadExpenses();
      expect(_dateKeys(expenses), <String>['2026-06-01', '2026-06-15']);

      AppClock.set(DateTime(2026, 7, 13));
      expenses = await LiabilityService.loadExpenses();
      expect(_dateKeys(expenses), <String>['2026-06-01', '2026-06-15']);
    },
  );
}

double _amountFor(List<ExpenseRecord> expenses, DateTime date) {
  return expenses
      .singleWhere(
        (ExpenseRecord record) =>
            record.transactionDate.year == date.year &&
            record.transactionDate.month == date.month &&
            record.transactionDate.day == date.day,
      )
      .totalAmount;
}

List<String> _dateKeys(List<ExpenseRecord> expenses) {
  return expenses
      .map((ExpenseRecord record) => _dateKey(record.transactionDate))
      .toList(growable: false)
    ..sort();
}

String _dateKey(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
