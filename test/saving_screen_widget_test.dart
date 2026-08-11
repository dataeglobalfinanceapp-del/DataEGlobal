import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/saving_screen/saving_screen.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 1, 1));
    LiabilityService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
  });

  testWidgets('Saving plan shows default rate and reduces remaining amount', (
    WidgetTester tester,
  ) async {
    await _saveDeposit(amount: 120000, date: DateTime(2026, 1, 1));
    await _saveExpense(amount: 20000, date: DateTime(2026, 1, 2));

    await tester.pumpWidget(const MaterialApp(home: SavingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Saving Plan'), findsOneWidget);
    expect(find.text('TOTAL DEPOSIT'), findsOneWidget);
    expect(find.text('TOTAL BALANCE'), findsNothing);
    expect(find.text(r'$120,000.00'), findsOneWidget);
    expect(find.text('Total Saving'), findsOneWidget);
    expect(find.text(r'$0.00'), findsOneWidget);
    expect(find.text('Saving rate 10%'), findsOneWidget);
    expect(find.text(r'$12,000.00'), findsOneWidget);
    expect(find.text(r'$1,000.00'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, '500');
    await tester.pump();

    expect(find.text(r'$0.00'), findsOneWidget);
    expect(find.text(r'$1,000.00'), findsWidgets);

    await tester.tap(find.byTooltip('Confirm saving amount').first);
    await tester.pump();

    expect(find.text(r'$500.00'), findsNWidgets(2));
  });

  testWidgets('Saving plan splits targets by day, week, and edited rate', (
    WidgetTester tester,
  ) async {
    await _saveDeposit(amount: 120000, date: DateTime(2026, 1, 1));

    await tester.pumpWidget(const MaterialApp(home: SavingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(find.text('PER DAY'), findsOneWidget);
    expect(find.text('January 1'), findsOneWidget);
    expect(find.text(r'$32.88'), findsWidgets);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.text('PER WEEK'), findsOneWidget);
    expect(find.text('January 1-7'), findsOneWidget);
    expect(find.text(r'$226.42'), findsWidgets);

    await tester.tap(find.byTooltip('Edit saving rate'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '20',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Saving rate 20%'), findsOneWidget);
    expect(find.text(r'$24,000.00'), findsOneWidget);
  });

  testWidgets('monthly saving distributes to week and day views', (
    WidgetTester tester,
  ) async {
    await _saveDeposit(amount: 120000, date: DateTime(2026, 1, 1));

    await tester.pumpWidget(const MaterialApp(home: SavingScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '1000');
    await tester.tap(find.byTooltip('Confirm saving amount').first);
    await tester.pump();

    expect(find.text(r'$1,000.00'), findsWidgets);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(_firstSavingInputText(tester), '225.81');
    expect(find.text(r'$1,000.00'), findsWidgets);

    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(_firstSavingInputText(tester), '32.26');
    expect(find.text(r'$1,000.00'), findsWidgets);
  });

  testWidgets('week and day saving roll up to related periods', (
    WidgetTester tester,
  ) async {
    await _saveDeposit(amount: 120000, date: DateTime(2026, 1, 1));

    await tester.pumpWidget(const MaterialApp(home: SavingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '700');
    await tester.tap(find.byTooltip('Confirm saving amount').first);
    await tester.pump();

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(_firstSavingInputText(tester), '700.00');

    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(_firstSavingInputText(tester), '100.00');

    await tester.enterText(find.byType(TextField).first, '200');
    await tester.tap(find.byTooltip('Confirm saving amount').first);
    await tester.pump();

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(_firstSavingInputText(tester), '800.00');

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(_firstSavingInputText(tester), '800.00');
  });

  testWidgets('day view collapses past dates without deleting saved amounts', (
    WidgetTester tester,
  ) async {
    AppClock.set(DateTime(2026, 1, 10));
    await _saveDeposit(amount: 120000, date: DateTime(2026, 1, 1));

    await tester.pumpWidget(const MaterialApp(home: SavingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(find.text('Past dates (9)'), findsOneWidget);
    expect(find.text('Show all'), findsOneWidget);
    expect(find.text('January 1'), findsNothing);
    expect(find.text('January 10'), findsOneWidget);

    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();

    expect(find.text('Show less'), findsOneWidget);
    expect(find.text('January 1'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '31');
    await tester.tap(find.byTooltip('Confirm saving amount').first);
    await tester.pump();

    expect(find.text(r'$31.00'), findsOneWidget);

    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();

    expect(find.text('January 1'), findsNothing);
    expect(find.text(r'$31.00'), findsOneWidget);
  });

  testWidgets('week view collapses past weeks and preserves saved totals', (
    WidgetTester tester,
  ) async {
    AppClock.set(DateTime(2026, 1, 10));
    await _saveDeposit(amount: 120000, date: DateTime(2026, 1, 1));

    await tester.pumpWidget(const MaterialApp(home: SavingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.text('Past weeks (1)'), findsOneWidget);
    expect(find.text('Show all'), findsOneWidget);
    expect(find.text('January 1-7'), findsNothing);
    expect(find.text('January 8-14'), findsOneWidget);

    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();

    expect(find.text('Show less'), findsOneWidget);
    expect(find.text('January 1-7'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '700');
    await tester.tap(find.byTooltip('Confirm saving amount').first);
    await tester.pump();

    expect(find.text(r'$700.00'), findsOneWidget);

    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();

    expect(find.text('January 1-7'), findsNothing);
    expect(find.text(r'$700.00'), findsOneWidget);
  });

  testWidgets('month view collapses past months and preserves saved totals', (
    WidgetTester tester,
  ) async {
    AppClock.set(DateTime(2026, 4, 10));
    await _saveDeposit(amount: 120000, date: DateTime(2026, 1, 1));

    await tester.pumpWidget(const MaterialApp(home: SavingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Past months (3)'), findsOneWidget);
    expect(find.text('Show all'), findsOneWidget);
    expect(find.text('January'), findsNothing);
    expect(find.text('April'), findsOneWidget);

    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();

    expect(find.text('Show less'), findsOneWidget);
    expect(find.text('January'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '1000');
    await tester.tap(find.byTooltip('Confirm saving amount').first);
    await tester.pump();

    expect(find.text(r'$1,000.00'), findsWidgets);

    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();

    expect(find.text('January'), findsNothing);
    expect(find.text(r'$1,000.00'), findsWidgets);
  });

  testWidgets('remaining amount below one dollar displays as met target', (
    WidgetTester tester,
  ) async {
    await _saveDeposit(amount: 120000, date: DateTime(2026, 1, 1));

    await tester.pumpWidget(const MaterialApp(home: SavingScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '999.50');
    await tester.tap(find.byTooltip('Confirm saving amount').first);
    await tester.pump();

    final zeroTexts = tester.widgetList<Text>(find.text(r'$0.00'));
    expect(
      zeroTexts.any((text) => text.style?.color == const Color(0xFF16A34A)),
      isTrue,
    );
  });

  testWidgets('daily shortfall rolls forward and reacts to past edits', (
    WidgetTester tester,
  ) async {
    AppClock.set(DateTime(2026, 1, 3));
    await _saveDeposit(amount: 365000, date: DateTime(2026, 1, 1));

    await tester.pumpWidget(const MaterialApp(home: SavingScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '100');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), '60');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text(r'$140.00'), findsWidgets);
    expect(find.text(r'$36,500.00'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text(r'$140.00'), findsNothing);
    expect(find.text(r'$100.00'), findsWidgets);
  });
}

String _firstSavingInputText(WidgetTester tester) {
  final field = tester.widget<TextField>(find.byType(TextField).first);
  return field.controller?.text ?? '';
}

Future<void> _saveDeposit({required double amount, required DateTime date}) {
  return LiabilityService.saveDeposit(
    orderNumber: 'saving-deposit',
    totalAmount: amount,
    creditDeposit: amount,
    cash: 0,
    giftCard: 0,
    other: 0,
    transactionDate: date,
    isManual: true,
  );
}

Future<void> _saveExpense({required double amount, required DateTime date}) {
  return LiabilityService.saveExpense(
    checkNumber: 'saving-expense',
    totalAmount: amount,
    transactionDate: date,
    category: 'Other',
    payee: 'Saving test expense',
    isManual: true,
  );
}
