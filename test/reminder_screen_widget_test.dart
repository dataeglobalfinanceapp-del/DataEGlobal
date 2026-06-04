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
    expect(find.text('Tap a date to create a reminder.'), findsOneWidget);
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
