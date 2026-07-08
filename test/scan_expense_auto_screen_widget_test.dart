import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/scan_screen/expense_screen/scan_expense_auto_screen.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
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
    await tester.pumpWidget(const MaterialApp(home: ScanExpenseAutoScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Don't allow"));
    await tester.pumpAndSettle();

    expect(find.text('EXPENSE DATA'), findsOneWidget);
    expect(find.text('EDITABLE'), findsOneWidget);
    expect(find.text('CHECK NUMBER:'), findsOneWidget);
    expect(find.text('TOTAL AMOUNT'), findsOneWidget);
    expect(find.text('TRANSACTION:'), findsOneWidget);
    expect(find.text('CATEGORY:'), findsOneWidget);
    expect(find.text('PAYEE:'), findsOneWidget);
    expect(find.text('RECURRING EXPENSE'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

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
  });
}
