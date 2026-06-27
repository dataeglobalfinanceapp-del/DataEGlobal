import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/reminder_service.dart';

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

  test('biweekly recurring reminders repeat every 14 days', () async {
    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: DateTime(2026, 6, 1),
        category: 'Payroll',
        amount: 800,
        reminderCount: 'Biweekly',
        payee: 'Team payroll',
      ),
    ]);

    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();
    final List<String> juneDates = reminders
        .where((ReminderRecord record) => record.date.month == 6)
        .map((ReminderRecord record) => _dateKey(record.date))
        .toList(growable: false);

    expect(juneDates, <String>['2026-06-01', '2026-06-15', '2026-06-29']);
    expect(
      reminders.map((ReminderRecord record) => record.reminderCount).toSet(),
      <String>{'Biweekly'},
    );
  });

  test(
    'semi-monthly recurring reminders use the selected start date pair',
    () async {
      await ReminderService.saveReminders(<ReminderDraft>[
        ReminderDraft(
          date: DateTime(2026, 6, 20),
          category: 'Rent',
          amount: 600,
          reminderCount: 'Semi-monthly',
          payee: 'Studio rent',
        ),
      ]);

      final List<ReminderRecord> reminders =
          await ReminderService.loadReminders();
      final List<String> firstDates = reminders
          .take(5)
          .map((ReminderRecord record) => _dateKey(record.date))
          .toList(growable: false);

      expect(firstDates, <String>[
        '2026-06-20',
        '2026-07-05',
        '2026-07-20',
        '2026-08-05',
        '2026-08-20',
      ]);
      expect(
        reminders.every((ReminderRecord record) => record.isRecurring),
        true,
      );
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

  test(
    'series amount edit updates recurring occurrences date-forward',
    () async {
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
      final ReminderRecord september = reminders.singleWhere(
        (ReminderRecord record) => record.date.month == 9,
      );

      await ReminderService.updateAmount(
        september.id,
        500,
        scope: ReminderEditScope.series,
      );

      final List<ReminderRecord> updated =
          await ReminderService.loadReminders();
      expect(
        updated
            .where((ReminderRecord record) => record.date.month < 9)
            .map((ReminderRecord record) => record.amount)
            .toSet(),
        <double>{450},
      );
      expect(
        updated
            .where((ReminderRecord record) => record.date.month >= 9)
            .map((ReminderRecord record) => record.amount)
            .toSet(),
        <double>{500},
      );
    },
  );

  test(
    'remaining balance uses recurring occurrences in the selected year',
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

      expect(
        ReminderService.remainingBalanceThisYear(june, year: 2026),
        closeTo(630, 0.001),
      );

      AppClock.set(DateTime(2027, 1, 1));
      reminders = await ReminderService.loadReminders();
      final ReminderRecord january = reminders.singleWhere(
        (ReminderRecord record) =>
            record.date.year == 2027 && record.date.month == 1,
      );

      expect(
        ReminderService.remainingBalanceThisYear(january, year: 2027),
        closeTo(1080, 0.001),
      );
    },
  );

  test(
    'remaining balance excludes completed recurring occurrences once',
    () async {
      await ReminderService.saveReminders(<ReminderDraft>[
        ReminderDraft(
          date: DateTime(2026, 6, 10),
          category: 'Rent',
          amount: 100,
          reminderCount: 'Monthly',
          payee: 'Studio Rent',
        ),
      ]);

      List<ReminderRecord> reminders = await ReminderService.loadReminders();
      final ReminderRecord june = reminders.singleWhere(
        (ReminderRecord record) => record.date.month == 6,
      );

      expect(
        ReminderService.remainingBalanceThisYear(june, year: 2026),
        closeTo(700, 0.001),
      );
      expect(await ReminderService.markFinished(june.id), true);

      reminders = await ReminderService.loadReminders();
      final ReminderRecord july = reminders.singleWhere(
        (ReminderRecord record) => record.date.month == 7,
      );

      expect(
        ReminderService.remainingBalanceThisYear(july, year: 2026),
        closeTo(600, 0.001),
      );

      AppClock.set(DateTime(2026, 7, 1));
      reminders = await ReminderService.loadReminders();
      final ReminderRecord currentJuly = reminders.singleWhere(
        (ReminderRecord record) => record.date.month == 7,
      );

      expect(
        ReminderService.remainingBalanceThisYear(currentJuly, year: 2026),
        closeTo(600, 0.001),
      );
      expect(await ReminderService.markFinished(currentJuly.id), true);

      reminders = await ReminderService.loadReminders();
      final ReminderRecord august = reminders.singleWhere(
        (ReminderRecord record) => record.date.month == 8,
      );

      expect(
        ReminderService.remainingBalanceThisYear(august, year: 2026),
        closeTo(500, 0.001),
      );
    },
  );
}

List<int> _months(List<ReminderRecord> reminders) {
  return reminders.map((ReminderRecord record) => record.date.month).toList()
    ..sort();
}

String _dateKey(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
