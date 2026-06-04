import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biztrack/features/auth/screens/transaction_screen/transaction_screen.dart';
import 'package:biztrack/services/app_clock.dart';
import 'package:biztrack/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
  });

  testWidgets('TransactionScreen renders seeded yearly totals and exports', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveDeposit(
      orderNumber: 'A100',
      totalAmount: 125,
      creditDebt: 100,
      cash: 25,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 12),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'E200',
      totalAmount: 45,
      transactionDate: DateTime(2026, 6, 13),
      category: 'Fuel',
      payee: 'Fuel Stop',
      isManual: true,
    );

    await tester.pumpWidget(const MaterialApp(home: TransactionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Transaction'), findsOneWidget);
    expect(find.text('TOTAL RESERVES'), findsOneWidget);
    expect(find.text(r'$80.00'), findsOneWidget);
    expect(find.text(r'$125.00'), findsWidgets);
    expect(find.text(r'$45.00'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
    expect(find.text('Excel'), findsOneWidget);
  });

  testWidgets('TransactionScreen expands and deletes a deposit group', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveDeposit(
      orderNumber: 'A100',
      totalAmount: 125,
      creditDebt: 100,
      cash: 25,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 12),
      isManual: true,
    );

    await tester.pumpWidget(const MaterialApp(home: TransactionScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week 24'));
    await tester.pumpAndSettle();

    expect(find.text('Credit/Debit'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete deposit?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No deposit history for this view.'), findsOneWidget);
  });
}
