import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/recurring_expense_reminder_service.dart';
import 'package:savetep/services/reminder_service.dart';

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

      final List<ReminderRecord> updatedReminders =
          await ReminderService.loadReminders();
      expect(
        _reminderAmountForDate(updatedReminders, DateTime(2026, 6, 10)),
        225,
      );
      expect(
        _reminderAmountForDate(updatedReminders, DateTime(2026, 7, 10)),
        225,
      );

      AppClock.set(DateTime(2026, 7, 10));
      expenses = await LiabilityService.loadExpenses();
      expect(_amountFor(expenses, DateTime(2026, 7, 10)), 225);
    },
  );

  test(
    'editing a future recurring reminder updates future reminders and expenses',
    () async {
      await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
        checkNumber: '208',
        totalAmount: 100,
        transactionDate: DateTime(2026, 1, 10),
        startDate: DateTime(2026, 1, 10),
        category: 'Rent',
        payee: 'Landlord',
        isManual: true,
        frequency: 'Monthly',
      );

      expect(_dateKeys(await LiabilityService.loadExpenses()), <String>[
        '2026-01-10',
        '2026-02-10',
        '2026-03-10',
        '2026-04-10',
        '2026-05-10',
        '2026-06-10',
      ]);

      final ReminderRecord octoberReminder =
          (await ReminderService.loadReminders()).singleWhere(
            (ReminderRecord record) => _dateKey(record.date) == '2026-10-10',
          );

      final bool updated =
          await RecurringExpenseReminderService.updateReminderAmount(
            reminderId: octoberReminder.id,
            amount: 175,
            scope: ReminderEditScope.single,
          );

      expect(updated, isTrue);

      final List<ReminderRecord> reminders =
          await ReminderService.loadReminders();
      expect(_reminderAmountForDate(reminders, DateTime(2026, 9, 10)), 100);
      expect(_reminderAmountForDate(reminders, DateTime(2026, 10, 10)), 175);
      expect(_reminderAmountForDate(reminders, DateTime(2026, 12, 10)), 175);

      var expenses = await LiabilityService.loadExpenses();
      expect(_amountFor(expenses, DateTime(2026, 6, 10)), 100);
      expect(_amountFor(expenses, DateTime(2026, 10, 10)), 175);
      expect(
        expenses
            .where(
              (ExpenseRecord record) =>
                  record.recurringSeriesId ==
                      octoberReminder.recurringSeriesId &&
                  _dateKey(record.transactionDate) == '2026-10-10',
            )
            .length,
        1,
      );
      expect(
        expenses
            .where(
              (ExpenseRecord record) =>
                  record.recurringSeriesId == octoberReminder.recurringSeriesId,
            )
            .map((ExpenseRecord record) => record.recurringSeriesId)
            .toSet(),
        <String>{octoberReminder.recurringSeriesId},
      );

      AppClock.set(DateTime(2026, 11, 10));
      expenses = await LiabilityService.loadExpenses();

      expect(_amountFor(expenses, DateTime(2026, 9, 10)), 100);
      expect(_amountFor(expenses, DateTime(2026, 10, 10)), 175);
      expect(_amountFor(expenses, DateTime(2026, 11, 10)), 175);
      expect(
        expenses
            .where(
              (ExpenseRecord record) =>
                  record.recurringSeriesId ==
                      octoberReminder.recurringSeriesId &&
                  _dateKey(record.transactionDate) == '2026-10-10',
            )
            .length,
        1,
      );
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
    'editing recurring reminder updates linked expenses date-forward',
    () async {
      AppClock.set(DateTime(2026, 6, 29));
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

      var expenses = await LiabilityService.loadExpenses();
      expect(_amountFor(expenses, DateTime(2026, 6, 1)), 80);
      expect(_amountFor(expenses, DateTime(2026, 6, 15)), 95);
      expect(_amountFor(expenses, DateTime(2026, 6, 29)), 95);

      final List<ReminderRecord> reminders =
          await ReminderService.loadReminders();
      expect(_reminderAmountForDate(reminders, DateTime(2026, 6, 1)), 80);
      expect(_reminderAmountForDate(reminders, DateTime(2026, 6, 15)), 95);
      expect(_reminderAmountForDate(reminders, DateTime(2026, 6, 29)), 95);

      AppClock.set(DateTime(2026, 7, 13));
      expenses = await LiabilityService.loadExpenses();
      expect(_amountFor(expenses, DateTime(2026, 7, 13)), 95);
    },
  );

  test(
    'editing recurring reminder fails without changing reminder when expense is missing',
    () async {
      AppClock.set(DateTime(2026, 6, 15));
      await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
        checkNumber: '207',
        totalAmount: 80,
        transactionDate: DateTime(2026, 6, 1),
        startDate: DateTime(2026, 6, 1),
        category: 'Utilities',
        payee: 'Power Co',
        isManual: true,
        frequency: 'Biweekly',
      );

      await LiabilityService.loadExpenses();
      final ReminderRecord reminder = (await ReminderService.loadReminders())
          .singleWhere(
            (ReminderRecord record) => _dateKey(record.date) == '2026-06-15',
          );
      await LiabilityService.deleteFutureRecurringExpenses(
        recurringSeriesId: reminder.recurringSeriesId,
        fromDate: reminder.date,
      );

      final bool updated =
          await RecurringExpenseReminderService.updateReminderAmount(
            reminderId: reminder.id,
            amount: 95,
            scope: ReminderEditScope.single,
          );

      expect(updated, isFalse);
      expect(
        _reminderAmountFor(await ReminderService.loadReminders(), reminder.id),
        80,
      );
      expect(_dateKeys(await LiabilityService.loadExpenses()), <String>[
        '2026-06-01',
      ]);
    },
  );

  test(
    'deleting one recurring reminder occurrence keeps the schedule active',
    () async {
      AppClock.set(DateTime(2026, 6, 29));
      await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
        checkNumber: '206',
        totalAmount: 90,
        transactionDate: DateTime(2026, 6, 1),
        startDate: DateTime(2026, 6, 1),
        category: 'Payroll',
        payee: 'Team payroll',
        isManual: true,
        frequency: 'Biweekly',
      );

      final ReminderRecord reminderToDelete =
          (await ReminderService.loadReminders()).singleWhere(
            (ReminderRecord record) => _dateKey(record.date) == '2026-06-15',
          );

      final bool deleted = await RecurringExpenseReminderService.deleteReminder(
        reminderId: reminderToDelete.id,
        scope: ReminderDeleteScope.single,
      );

      expect(deleted, isTrue);
      expect(
        _juneReminderDateKeys(await ReminderService.loadReminders()),
        <String>['2026-06-01', '2026-06-29'],
      );

      AppClock.set(DateTime(2026, 7, 13));
      final List<ExpenseRecord> expenses =
          await LiabilityService.loadExpenses();
      expect(_dateKeys(expenses), <String>[
        '2026-06-01',
        '2026-06-15',
        '2026-06-29',
        '2026-07-13',
      ]);
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

double _reminderAmountFor(List<ReminderRecord> reminders, String reminderId) {
  return reminders
      .singleWhere((ReminderRecord record) => record.id == reminderId)
      .amount;
}

double _reminderAmountForDate(List<ReminderRecord> reminders, DateTime date) {
  return reminders
      .singleWhere(
        (ReminderRecord record) =>
            record.date.year == date.year &&
            record.date.month == date.month &&
            record.date.day == date.day,
      )
      .amount;
}

List<String> _dateKeys(List<ExpenseRecord> expenses) {
  return expenses
      .map((ExpenseRecord record) => _dateKey(record.transactionDate))
      .toList(growable: false)
    ..sort();
}

List<String> _juneReminderDateKeys(List<ReminderRecord> reminders) {
  return reminders
      .where((ReminderRecord record) => record.date.month == 6)
      .map((ReminderRecord record) => _dateKey(record.date))
      .toList(growable: false)
    ..sort();
}

String _dateKey(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
