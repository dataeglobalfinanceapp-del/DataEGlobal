import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/scan_screen/expense_screen/scan_expense_auto_screen.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/recurring_expense_reminder_service.dart';
import 'package:savetep/services/reminder_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 7, 8));
    LiabilityService.resetForTesting();
    ReminderService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
    ReminderService.resetForTesting(disablePersistence: false);
  });

  testWidgets('auto expense entry card is editable before scanning', (
    WidgetTester tester,
  ) async {
    await _pumpAutoExpenseScreen(tester);

    expect(find.text('EXPENSE DATA'), findsOneWidget);
    expect(find.text('EDITABLE'), findsOneWidget);
    expect(find.text('CHECK NUMBER:'), findsOneWidget);
    expect(find.text('TOTAL AMOUNT'), findsOneWidget);
    expect(find.text('TRANSACTION:'), findsOneWidget);
    expect(find.text('CATEGORY:'), findsOneWidget);
    expect(find.text('PAYEE:'), findsOneWidget);
    expect(find.text('RECURRING EXPENSE'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('ADD TO REMINDERS'), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), 'E-100');
    await tester.enterText(find.byType(TextField).at(1), '150.25');
    await tester.enterText(find.byType(TextField).at(2), 'Power Co');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();
    expect(expenses, hasLength(1));
    expect(expenses.single.checkNumber, 'E-100');
    expect(expenses.single.totalAmount, 150.25);
    expect(expenses.single.transactionDate, DateTime(2026, 7, 8));
    expect(expenses.single.category, 'Utilities');
    expect(expenses.single.payee, 'Power Co');
    expect(expenses.single.isManual, isFalse);

    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();
    expect(reminders, isEmpty);
  });

  testWidgets('auto recurring expense automatically adds reminders', (
    WidgetTester tester,
  ) async {
    AppClock.set(DateTime(2026, 6, 15));
    await _pumpAutoExpenseScreen(tester);

    await tester.enterText(find.byType(TextField).at(1), '150.00');
    await tester.enterText(find.byType(TextField).at(2), 'Power Co');

    expect(find.text('ADD TO REMINDERS'), findsNothing);

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

    var expenses = await LiabilityService.loadExpenses();

    expect(_expenseDateKeys(expenses), <String>['2026-06-15']);
    expect(
      expenses
          .map((ExpenseRecord record) => record.normalizedRecurringFrequency)
          .toList(growable: false),
      <String>['Biweekly'],
    );
    expect(expenses.single.isManual, isFalse);

    AppClock.set(DateTime(2026, 6, 29));
    expenses = await LiabilityService.loadExpenses();

    expect(_expenseDateKeys(expenses), <String>['2026-06-15', '2026-06-29']);
  });

  test('recurring expense reminder uses selected future start date', () async {
    AppClock.set(DateTime(2026, 6, 15));

    await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
      checkNumber: '',
      totalAmount: 150,
      transactionDate: AppClock.now,
      startDate: DateTime(2026, 7, 1),
      category: 'Utilities',
      payee: 'Power Co',
      isManual: true,
      frequency: 'Biweekly',
    );

    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();
    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();
    final List<String> firstReminderDates = reminders
        .take(3)
        .map((ReminderRecord record) => _dateKey(record.date))
        .toList(growable: false);

    expect(firstReminderDates, <String>[
      '2026-07-01',
      '2026-07-15',
      '2026-07-29',
    ]);
    expect(
      reminders.map((ReminderRecord record) => record.reminderCount).toSet(),
      <String>{'Biweekly'},
    );
    expect(_expenseDateKeys(expenses), <String>['2026-07-01']);
    expect(
      reminders.first.recurringSeriesId,
      expenses.single.recurringSeriesId,
    );
  });
}

Future<void> _pumpAutoExpenseScreen(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ScanExpenseAutoScreen()));
  await tester.pumpAndSettle();

  await tester.tap(find.text("Don't allow"));
  await tester.pumpAndSettle();
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
