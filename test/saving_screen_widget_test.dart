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

    await tester.pumpWidget(const MaterialApp(home: SavingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Saving Plan'), findsOneWidget);
    expect(find.text('TOTAL DEPOSIT'), findsOneWidget);
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
