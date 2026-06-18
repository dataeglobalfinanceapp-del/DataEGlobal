import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biztrack/features/auth/screens/scan_screen/expense_screen/scan_expense_manual_screen.dart';
import 'package:biztrack/services/app_clock.dart';
import 'package:biztrack/services/liability_service.dart';
import 'package:biztrack/services/reminder_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
    ReminderService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
    ReminderService.resetForTesting(disablePersistence: false);
  });

  testWidgets('manual expense can add a recurring reminder schedule', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScanExpenseManualScreen()));

    await tester.enterText(find.byType(TextField).at(1), '150.00');
    await tester.enterText(find.byType(TextField).at(2), 'Power Co');

    await tester.ensureVisible(find.text('ADD TO REMINDERS'));
    await tester.tap(find.text('ADD TO REMINDERS'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Monthly'));
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biweekly').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();
    final List<String> firstReminderDates = reminders
        .take(3)
        .map((ReminderRecord record) => _dateKey(record.date))
        .toList(growable: false);

    expect(firstReminderDates, <String>[
      '2026-06-15',
      '2026-06-29',
      '2026-07-13',
    ]);
    expect(
      reminders.map((ReminderRecord record) => record.reminderCount).toSet(),
      <String>{'Biweekly'},
    );
    expect(reminders.first.payee, 'Power Co');
  });

  testWidgets('manual expense can add a recurring expense schedule', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScanExpenseManualScreen()));

    await tester.enterText(find.byType(TextField).at(1), '150.00');
    await tester.enterText(find.byType(TextField).at(2), 'Power Co');

    await tester.ensureVisible(find.text('RECURRING EXPENSE'));
    await tester.tap(find.text('RECURRING EXPENSE'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Monthly'));
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biweekly').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    var expenses = await LiabilityService.loadExpenses();

    expect(_expenseDateKeys(expenses), <String>['2026-06-15']);
    expect(
      expenses
          .map((ExpenseRecord record) => record.normalizedRecurringFrequency)
          .toList(growable: false),
      <String>['Biweekly'],
    );

    AppClock.set(DateTime(2026, 6, 29));
    expenses = await LiabilityService.loadExpenses();

    expect(_expenseDateKeys(expenses), <String>['2026-06-15', '2026-06-29']);
  });
}

String _dateKey(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

List<String> _expenseDateKeys(List<ExpenseRecord> expenses) {
  return expenses
      .map((ExpenseRecord record) => _dateKey(record.transactionDate))
      .toList(growable: false);
}
