import 'package:flutter_test/flutter_test.dart';

import 'package:biztrack/services/app_clock.dart';
import 'package:biztrack/services/reminder_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    ReminderService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    ReminderService.resetForTesting(disablePersistence: false);
  });

  test('monthly recurring reminders sync active-year occurrences', () async {
    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: DateTime(2026, 1, 10),
        category: 'Rent',
        amount: 1200,
        reminderCount: 'Monthly',
        payee: 'Landlord',
      ),
    ]);

    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();

    expect(_months(reminders), <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    expect(
      reminders.every((ReminderRecord record) => record.isRecurring),
      true,
    );
    expect(
      reminders.map((ReminderRecord record) => record.payee).toSet(),
      <String>{'Landlord'},
    );
  });

  test(
    'deleting one recurring occurrence keeps the rest of the series',
    () async {
      await ReminderService.saveReminders(<ReminderDraft>[
        ReminderDraft(
          date: DateTime(2026, 1, 10),
          category: 'Insurance',
          amount: 300,
          reminderCount: 'Monthly',
          payee: 'Carrier',
        ),
      ]);

      List<ReminderRecord> reminders = await ReminderService.loadReminders();
      final ReminderRecord march = reminders.singleWhere(
        (ReminderRecord record) => record.date.month == 3,
      );

      final bool deleted = await ReminderService.deleteReminder(march.id);

      expect(deleted, true);
      reminders = await ReminderService.loadReminders();
      expect(_months(reminders), <int>[1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    },
  );

  test('series amount edit updates every recurring occurrence', () async {
    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: DateTime(2026, 1, 10),
        category: 'Loan',
        amount: 450,
        reminderCount: 'Monthly',
        payee: 'Bank',
      ),
    ]);

    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();
    final ReminderRecord june = reminders.singleWhere(
      (ReminderRecord record) => record.date.month == 6,
    );

    await ReminderService.updateAmount(
      june.id,
      500,
      scope: ReminderEditScope.series,
    );

    final List<ReminderRecord> updated = await ReminderService.loadReminders();
    expect(
      updated.map((ReminderRecord record) => record.amount).toSet(),
      <double>{500},
    );
  });

  test(
    'postponing recurring reminder preserves series and moves only selected',
    () async {
      await ReminderService.saveReminders(<ReminderDraft>[
        ReminderDraft(
          date: DateTime(2026, 6, 10),
          category: 'Utilities',
          amount: 90,
          reminderCount: 'Monthly',
          payee: 'Power Co',
        ),
      ]);

      List<ReminderRecord> reminders = await ReminderService.loadReminders();
      final ReminderRecord june = reminders.singleWhere(
        (ReminderRecord record) => record.date.month == 6,
      );

      await ReminderService.postpone(june.id, days: 2);

      reminders = await ReminderService.loadReminders();
      final ReminderRecord postponed = reminders.singleWhere(
        (ReminderRecord record) => record.date.month == 6,
      );

      expect(_months(reminders), <int>[6, 7, 8, 9, 10, 11, 12]);
      expect(postponed.date, DateTime(2026, 6, 12));
      expect(postponed.isRecurring, true);
    },
  );
}

List<int> _months(List<ReminderRecord> reminders) {
  return reminders.map((ReminderRecord record) => record.date.month).toList()
    ..sort();
}
