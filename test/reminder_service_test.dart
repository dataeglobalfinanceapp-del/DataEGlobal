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

  test(
    'monthly recurring reminders sync current and future occurrences',
    () async {
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

      expect(_months(reminders), <int>[6, 7, 8, 9, 10, 11, 12]);
      expect(
        reminders.every((ReminderRecord record) => record.isRecurring),
        true,
      );
      expect(
        reminders.map((ReminderRecord record) => record.payee).toSet(),
        <String>{'Landlord'},
      );
    },
  );

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
      final ReminderRecord august = reminders.singleWhere(
        (ReminderRecord record) => record.date.month == 8,
      );

      final bool deleted = await ReminderService.deleteReminder(august.id);

      expect(deleted, true);
      reminders = await ReminderService.loadReminders();
      expect(_months(reminders), <int>[6, 7, 9, 10, 11, 12]);
    },
  );

  test('marking one-time reminder finished removes it', () async {
    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: DateTime(2026, 6, 20),
        category: 'Utilities',
        amount: 80,
        reminderCount: 'Just one',
        payee: 'Power Co',
      ),
    ]);

    final ReminderRecord reminder =
        (await ReminderService.loadReminders()).single;

    final bool finished = await ReminderService.markFinished(reminder.id);

    expect(finished, true);
    expect(await ReminderService.loadReminders(), isEmpty);
  });

  test(
    'marking recurring reminder finished removes only selected occurrence',
    () async {
      await ReminderService.saveReminders(<ReminderDraft>[
        ReminderDraft(
          date: DateTime(2026, 6, 10),
          category: 'Insurance',
          amount: 300,
          reminderCount: 'Monthly',
          payee: 'Carrier',
        ),
      ]);

      List<ReminderRecord> reminders = await ReminderService.loadReminders();
      final ReminderRecord june = reminders.singleWhere(
        (ReminderRecord record) => record.date.month == 6,
      );

      final bool finished = await ReminderService.markFinished(june.id);

      expect(finished, true);
      reminders = await ReminderService.loadReminders();
      expect(_months(reminders), <int>[7, 8, 9, 10, 11, 12]);
      expect(
        reminders.every((ReminderRecord record) => record.isRecurring),
        true,
      );
    },
  );

  test('month rollover deletes reminders from prior months', () async {
    AppClock.set(DateTime(2026, 5, 20));
    ReminderService.resetForTesting();

    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: DateTime(2026, 5, 25),
        category: 'Utilities',
        amount: 80,
        reminderCount: 'Just one',
        payee: 'Power Co',
      ),
      ReminderDraft(
        date: DateTime(2026, 6, 5),
        category: 'Insurance',
        amount: 200,
        reminderCount: 'Just one',
        payee: 'Carrier',
      ),
    ]);

    expect(_months(await ReminderService.loadReminders()), <int>[5, 6]);

    AppClock.set(DateTime(2026, 6, 1));

    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();

    expect(_months(reminders), <int>[6]);
    expect(reminders.single.payee, 'Carrier');
  });

  test(
    'month rollover does not recreate deleted recurring occurrences',
    () async {
      AppClock.set(DateTime(2026, 5, 20));
      ReminderService.resetForTesting();

      await ReminderService.saveReminders(<ReminderDraft>[
        ReminderDraft(
          date: DateTime(2026, 1, 10),
          category: 'Rent',
          amount: 1200,
          reminderCount: 'Monthly',
          payee: 'Landlord',
        ),
      ]);

      expect(_months(await ReminderService.loadReminders()), <int>[
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
      ]);

      AppClock.set(DateTime(2026, 6, 1));

      final List<ReminderRecord> reminders =
          await ReminderService.loadReminders();

      expect(_months(reminders), <int>[6, 7, 8, 9, 10, 11, 12]);
      expect(
        reminders.every((ReminderRecord record) => record.isRecurring),
        true,
      );
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
