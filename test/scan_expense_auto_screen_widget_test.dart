import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/models/expense_category.dart';
import 'package:savetep/features/auth/screens/scan_screen/expense_screen/scan_expense_auto_screen.dart';
import 'package:savetep/providers/expense_category_provider.dart';
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
    expect(find.text('CHECK NUMBER:'), findsNothing);
    expect(find.text('TOTAL AMOUNT'), findsOneWidget);
    expect(find.text('TIPS & GRATUITY'), findsOneWidget);
    expect(find.text('TRANSACTION:'), findsOneWidget);
    expect(find.text('TIME:'), findsNothing);
    expect(find.text('CATEGORY:'), findsOneWidget);
    expect(find.text('PAYEE:'), findsOneWidget);
    expect(find.text('CARD LAST 4:'), findsOneWidget);
    expect(find.text('RECURRING EXPENSE'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('ADD TO REMINDERS'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('expense.totalAmount')),
      '150.25',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('expense.tipsGratuity')),
      '5.25',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('expense.payee')),
      'Power Co',
    );
    final Finder cardLast4Field = find.byKey(
      const ValueKey<String>('expense.cardLast4'),
    );
    await tester.enterText(cardLast4Field, '12345');
    expect(tester.widget<TextField>(cardLast4Field).controller?.text, '1234');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Review Expense'), findsOneWidget);
    expect(find.text('TIPS & GRATUITY'), findsWidgets);
    expect(find.text(r'$5.25'), findsOneWidget);
    expect(find.text('CHECK NUMBER'), findsNothing);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();
    expect(expenses, hasLength(1));
    expect(expenses.single.checkNumber, isEmpty);
    expect(expenses.single.totalAmount, 150.25);
    expect(expenses.single.tipsGratuity, 5.25);
    expect(expenses.single.transactionDate, DateTime(2026, 7, 8));
    expect(expenses.single.category, 'Energy');
    expect(expenses.single.payee, 'Power Co');
    expect(expenses.single.isManual, isFalse);

    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();
    expect(reminders, isEmpty);
  });

  testWidgets('category picker uses only the active business categories', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeExpenseCategoriesProvider.overrideWith(
            (ref) async => const <ExpenseCategory>[
              ExpenseCategory.rents,
              ExpenseCategory.travel,
            ],
          ),
        ],
        child: const MaterialApp(home: ScanExpenseAutoScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ExpenseCategory.rents.name), findsOneWidget);
    expect(find.text(ExpenseCategory.energy.name), findsNothing);

    await tester.ensureVisible(find.text(ExpenseCategory.rents.name));
    await tester.tap(find.text(ExpenseCategory.rents.name));
    await tester.pumpAndSettle();

    expect(find.text(ExpenseCategory.travel.name), findsOneWidget);
    expect(find.text(ExpenseCategory.energy.name), findsNothing);

    await tester.tap(find.text(ExpenseCategory.travel.name));
    await tester.pumpAndSettle();

    expect(find.text(ExpenseCategory.travel.name), findsOneWidget);
    expect(find.text(ExpenseCategory.rents.name), findsNothing);
  });

  testWidgets('camera permission is requested only from the camera action', (
    WidgetTester tester,
  ) async {
    const MethodChannel imagePickerChannel = MethodChannel(
      'plugins.flutter.io/image_picker',
    );
    var cameraRequests = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      imagePickerChannel,
      (MethodCall call) async {
        cameraRequests++;
        throw PlatformException(code: 'camera_access_denied');
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        imagePickerChannel,
        null,
      ),
    );

    await _pumpAutoExpenseScreen(tester);
    expect(cameraRequests, 0);
    expect(find.text('While using this app'), findsNothing);
    expect(find.text('Only this time'), findsNothing);
    expect(find.text("Don't allow"), findsNothing);
    expect(find.byTooltip('Scan receipt'), findsOneWidget);

    await tester.tap(find.byTooltip('Scan receipt'));
    await tester.pumpAndSettle();
    expect(cameraRequests, 1);
    expect(find.textContaining('Settings'), findsNothing);

    await tester.tap(find.byTooltip('Scan receipt'));
    await tester.pump();
    expect(cameraRequests, 1);
    expect(find.textContaining('Settings'), findsOneWidget);
  });

  testWidgets('auto recurring expense automatically adds reminders', (
    WidgetTester tester,
  ) async {
    AppClock.set(DateTime(2026, 6, 15));
    await _pumpAutoExpenseScreen(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('expense.totalAmount')),
      '150.00',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('expense.tipsGratuity')),
      '4.00',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('expense.payee')),
      'Power Co',
    );

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
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
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
    expect(expenses.single.tipsGratuity, 4);

    AppClock.set(DateTime(2026, 6, 29));
    expenses = await LiabilityService.loadExpenses();

    expect(_expenseDateKeys(expenses), <String>['2026-06-15', '2026-06-29']);
    expect(
      expenses.map((ExpenseRecord record) => record.tipsGratuity).toSet(),
      <double>{4},
    );
  });

  test('recurring expense reminder uses selected future start date', () async {
    AppClock.set(DateTime(2026, 6, 15));

    await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
      checkNumber: '',
      totalAmount: 150,
      transactionDate: AppClock.now,
      startDate: DateTime(2026, 7, 1),
      category: 'electric',
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
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeExpenseCategoriesProvider.overrideWith(
          (ref) async => ExpenseCategory.values,
        ),
      ],
      child: const MaterialApp(home: ScanExpenseAutoScreen()),
    ),
  );
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
