import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/models/expense_category.dart';
import 'package:savetep/features/auth/screens/reminder_screen/reminder_screen.dart';
import 'package:savetep/providers/expense_category_provider.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/reminder_service.dart';

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

  testWidgets('ReminderScreen renders empty reminder calendar state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReminderScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Reminder'), findsOneWidget);
    expect(find.text('PAYMENT OBLIGATIONS'), findsOneWidget);
    expect(find.text('View all'), findsNothing);
    expect(find.text('Tap a date to create a reminder.'), findsOneWidget);
  });

  testWidgets('ReminderScreen weekly view keeps Month tab available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReminderScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('13'), findsNothing);
    expect(find.text('21'), findsNothing);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(find.text('Spent this month'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
  });

  testWidgets('ReminderScreen shows reminder details inline on the card', (
    WidgetTester tester,
  ) async {
    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: DateTime(2026, 6, 10),
        category: 'electric',
        amount: 120,
        reminderCount: 'Just one',
        payee: 'electric',
      ),
    ]);

    await tester.pumpWidget(const MaterialApp(home: ReminderScreen()));
    await tester.pumpAndSettle();

    expect(find.text('electric'), findsWidgets);
    expect(find.text('Just one'), findsOneWidget);
    expect(find.text('06/10/2026'), findsOneWidget);
    expect(find.text(r'$120.00'), findsWidgets);
    expect(find.byTooltip('Completed'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('ReminderScreen shows recurring remaining balance this year', (
    WidgetTester tester,
  ) async {
    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: DateTime(2026, 6, 10),
        category: 'Rent',
        amount: 100,
        reminderCount: 'Monthly',
        payee: 'Studio Rent',
      ),
    ]);

    await tester.pumpWidget(const MaterialApp(home: ReminderScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Rent'), findsWidgets);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text(r'$100.00'), findsWidgets);
    expect(find.text('Balance left: \$700.00'), findsOneWidget);
  });

  testWidgets('ReminderScreen toggles month and week reminder summaries', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveDeposit(
      orderNumber: 'DEP-1',
      totalAmount: 1000,
      creditDeposit: 1000,
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 10),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'EXP-1',
      totalAmount: 200,
      transactionDate: DateTime(2026, 6, 16),
      category: 'electric',
      payee: 'electric',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'EXP-2',
      totalAmount: 50,
      transactionDate: DateTime(2026, 6, 25),
      category: 'gas',
      payee: 'gas',
      isManual: true,
    );
    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: DateTime(2026, 6, 16),
        category: 'electric',
        amount: 100,
        reminderCount: 'Just one',
        payee: 'This Week Bill',
      ),
      ReminderDraft(
        date: DateTime(2026, 6, 25),
        category: 'gas',
        amount: 80,
        reminderCount: 'Just one',
        payee: 'Later Bill',
      ),
      ReminderDraft(
        date: DateTime(2026, 6, 18),
        category: 'Insurance',
        amount: 40,
        reminderCount: 'Monthly',
        payee: 'Recurring Bill',
      ),
    ]);

    await tester.pumpWidget(const MaterialApp(home: ReminderScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Spent this month'), findsOneWidget);
    expect(find.text(r'$750.00'), findsOneWidget);
    expect(find.text(r'$220.00'), findsOneWidget);
    expect(find.text('This Week Bill'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Later Bill'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Later Bill'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.text('Spent this week'), findsOneWidget);
    expect(find.text(r'$140.00'), findsOneWidget);
    expect(find.text('This Week Bill'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recurring Bill'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Recurring Bill'), findsOneWidget);
    expect(find.text('Later Bill'), findsNothing);
  });

  testWidgets('Completed removes the selected payment obligation card', (
    WidgetTester tester,
  ) async {
    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: DateTime(2026, 6, 20),
        category: 'Insurance',
        amount: 240,
        reminderCount: 'Just one',
        payee: 'Carrier',
      ),
    ]);

    await tester.pumpWidget(const MaterialApp(home: ReminderScreen()));
    await tester.pumpAndSettle();

    expect(find.text(r'$240.00'), findsWidgets);

    await tester.tap(find.byTooltip('Completed'));
    await tester.pumpAndSettle();

    expect(find.text(r'$240.00'), findsNothing);
    expect(find.text('Tap a date to create a reminder.'), findsOneWidget);
    expect(find.text('Reminder marked as finished.'), findsOneWidget);
  });

  testWidgets(
    'Completed recurring payment lowers balance for later reminders',
    (WidgetTester tester) async {
      await ReminderService.saveReminders(<ReminderDraft>[
        ReminderDraft(
          date: DateTime(2026, 6, 10),
          category: 'Rent',
          amount: 100,
          reminderCount: 'Monthly',
          payee: 'Studio Rent',
        ),
      ]);

      await tester.pumpWidget(const MaterialApp(home: ReminderScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Balance left: \$700.00'), findsOneWidget);

      await tester.tap(find.byTooltip('Completed'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsOneWidget);
      expect(find.text('Balance left: \$600.00'), findsOneWidget);
    },
  );

  testWidgets('Edit amount dialog delays text field focus', (
    WidgetTester tester,
  ) async {
    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: DateTime(2026, 6, 10),
        category: 'electric',
        amount: 120,
        reminderCount: 'Just one',
        payee: 'electric',
      ),
    ]);

    await tester.pumpWidget(const MaterialApp(home: ReminderScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    final TextField amountField = tester.widget(find.byType(TextField));
    final EditableText editableText = tester.widget(find.byType(EditableText));

    expect(amountField.autofocus, false);
    expect(editableText.focusNode.hasFocus, true);
  });

  testWidgets('CreateReminderScreen renders required form fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeExpenseCategoriesProvider.overrideWith(
            (ref) async => ExpenseCategory.values,
          ),
        ],
        child: MaterialApp(
          home: CreateReminderScreen(initialDate: DateTime(2026, 6, 15)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Reminder'), findsOneWidget);
    expect(find.textContaining('DATE', findRichText: true), findsOneWidget);
    expect(find.textContaining('CATEGORY', findRichText: true), findsOneWidget);
    expect(find.textContaining('AMOUNT', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('REMINDER COUNT', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Add more reminder'), findsOneWidget);
  });

  testWidgets('CreateReminderScreen uses active business categories', (
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
        child: MaterialApp(
          home: CreateReminderScreen(initialDate: DateTime(2026, 6, 15)),
        ),
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
  });
}
