import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biztrack/features/auth/screens/reminder_screen/reminder_screen.dart';
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

  testWidgets('ReminderScreen shows reminder details inline on the card', (
    WidgetTester tester,
  ) async {
    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: DateTime(2026, 6, 10),
        category: 'Utilities',
        amount: 120,
        reminderCount: 'Just one',
        payee: 'Utilities',
      ),
    ]);

    await tester.pumpWidget(const MaterialApp(home: ReminderScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Utilities'), findsWidgets);
    expect(find.text('Just one'), findsOneWidget);
    expect(find.text('06/10/2026'), findsOneWidget);
    expect(find.text(r'$120.00'), findsOneWidget);
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
    expect(find.text(r'$100.00'), findsOneWidget);
    expect(find.text('Remaining balance this year'), findsOneWidget);
    expect(find.text(r'$700.00'), findsOneWidget);
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

    expect(find.text(r'$240.00'), findsOneWidget);

    await tester.tap(find.byTooltip('Completed'));
    await tester.pumpAndSettle();

    expect(find.text(r'$240.00'), findsNothing);
    expect(find.text('Tap a date to create a reminder.'), findsOneWidget);
    expect(find.text('Reminder marked as finished.'), findsOneWidget);
  });

  testWidgets('CreateReminderScreen renders required form fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateReminderScreen(initialDate: DateTime(2026, 6, 15)),
      ),
    );

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
}
