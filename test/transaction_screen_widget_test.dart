import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/transaction_screen/transaction_screen.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
  });

  testWidgets('TransactionScreen opens on expense monthly view and exports', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveDeposit(
      orderNumber: 'A100',
      totalAmount: 125,
      creditDeposit: 100,
      cardLastFour: '1234',
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
      category: 'gas',
      payee: 'Gas Stop',
      isManual: true,
    );

    await tester.pumpWidget(const MaterialApp(home: TransactionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Transaction'), findsOneWidget);
    expect(find.text('TOTAL BALANCE'), findsOneWidget);
    expect(find.text('AVAILABLE FUNDS'), findsNothing);
    expect(find.text(r'$80.00'), findsOneWidget);
    expect(find.text(r'$125.00'), findsOneWidget);
    expect(find.text('TOTAL DEPOSIT'), findsOneWidget);
    expect(find.text('ESTIMATED TAX RATE'), findsNothing);
    expect(find.text('10%'), findsNothing);
    expect(find.text(r'ESTIMATED TAX AT YEAR END'), findsOneWidget);
    expect(find.text(r'$8.00'), findsOneWidget);
    expect(find.text(r'$45.00'), findsWidgets);

    await tester.dragUntilVisible(
      find.text('PDF'),
      find.byType(ListView),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();

    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
    expect(find.text('Excel'), findsOneWidget);
  });

  testWidgets('Estimated tax at year end label opens profit and loss', (
    WidgetTester tester,
  ) async {
    await _pumpTransactionScreenWithProfitAndLossRoute(tester);

    await tester.tap(find.text('ESTIMATED TAX AT YEAR END'));
    await tester.pumpAndSettle();

    expect(find.text('Profit and Loss'), findsOneWidget);
  });

  testWidgets('Estimated tax at year end value opens profit and loss', (
    WidgetTester tester,
  ) async {
    await _pumpTransactionScreenWithProfitAndLossRoute(tester);

    await tester.tap(find.text(r'$12.50'));
    await tester.pumpAndSettle();

    expect(find.text('Profit and Loss'), findsOneWidget);
  });

  testWidgets('TransactionScreen expands and deletes a deposit group', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveDeposit(
      orderNumber: 'A100',
      totalAmount: 125,
      creditDeposit: 100,
      cardLastFour: '1234',
      cash: 25,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 12),
      isManual: true,
    );

    await tester.pumpWidget(const MaterialApp(home: TransactionScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deposit'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('June'),
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('June'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Credit/Debit'),
      find.byType(ListView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();

    expect(find.text('Credit/Debit'), findsOneWidget);
    expect(find.text('LAST 4'), findsOneWidget);
    expect(find.text('1234'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete deposit?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No deposit history for this view.'), findsOneWidget);
  });

  testWidgets('TransactionScreen hides invalid deposit card last four', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveDeposit(
      orderNumber: 'A101',
      totalAmount: 100,
      creditDeposit: 100,
      cardLastFour: '987',
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 12),
      isManual: true,
    );

    await tester.pumpWidget(const MaterialApp(home: TransactionScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deposit'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('June'),
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('June'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Credit/Debit'),
      find.byType(ListView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();

    expect(find.text('LAST 4'), findsOneWidget);
    expect(find.text('987'), findsNothing);
  });

  testWidgets('TransactionScreen filters expenses from a category tap', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveExpense(
      checkNumber: 'E200',
      totalAmount: 45,
      transactionDate: DateTime(2026, 6, 10),
      category: 'gas',
      payee: 'Gas Stop',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'E201',
      totalAmount: 100,
      transactionDate: DateTime(2026, 6, 11),
      category: 'Rent',
      payee: 'Studio Rent',
      isManual: true,
    );

    await tester.pumpWidget(const MaterialApp(home: TransactionScreen()));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('June'),
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();

    await tester.tap(find.text('June'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Gas Stop'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gas Stop'), findsOneWidget);
    expect(find.text('Studio Rent'), findsOneWidget);

    await tester.tap(find.text('gas'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('gas total'),
      find.byType(ListView),
      const Offset(0, 180),
    );
    await tester.pumpAndSettle();

    expect(find.text('gas total'), findsOneWidget);
    expect(find.text(r'$45.00'), findsWidgets);
    expect(find.text('Gas Stop'), findsOneWidget);
    expect(find.text('Studio Rent'), findsNothing);
  });

  testWidgets('TransactionScreen range selector keeps grouping selectable', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveExpense(
      checkNumber: 'E200',
      totalAmount: 45,
      transactionDate: DateTime(2026, 6, 12),
      category: 'gas',
      payee: 'Gas Stop',
      isManual: true,
    );

    await tester.pumpWidget(const MaterialApp(home: TransactionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Quarterly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Week 24'),
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week 24'), findsOneWidget);
  });

  testWidgets('TransactionScreen filters expense tab by date range', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveDeposit(
      orderNumber: 'inside-range',
      totalAmount: 200,
      creditDeposit: 200,
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 10),
      isManual: true,
    );
    await LiabilityService.saveDeposit(
      orderNumber: 'outside-range',
      totalAmount: 1000,
      creditDeposit: 1000,
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 20),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'E200',
      totalAmount: 45,
      transactionDate: DateTime(2026, 6, 12),
      category: 'gas',
      payee: 'Gas Stop',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'E201',
      totalAmount: 100,
      transactionDate: DateTime(2026, 6, 20),
      category: 'Office',
      payee: 'Office Supply',
      isManual: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionScreen(
          initialExpenseDateRange: DateTimeRange(
            start: DateTime(2026, 6, 10),
            end: DateTime(2026, 6, 15),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('06/10/2026 - 06/15/2026'), findsOneWidget);
    expect(find.text(r'$155.00'), findsOneWidget);
    expect(find.text(r'$200.00'), findsOneWidget);
    expect(find.text(r'$45.00'), findsWidgets);
    expect(find.text(r'$100.00'), findsNothing);
    expect(find.text(r'$1,000.00'), findsNothing);

    await tester.dragUntilVisible(
      find.text('June'),
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('June'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Gas Stop'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gas Stop'), findsOneWidget);
    expect(find.text('Office Supply'), findsNothing);
  });
}

Future<void> _pumpTransactionScreenWithProfitAndLossRoute(
  WidgetTester tester,
) async {
  await LiabilityService.saveDeposit(
    orderNumber: 'A100',
    totalAmount: 125,
    creditDeposit: 100,
    cash: 25,
    giftCard: 0,
    other: 0,
    transactionDate: DateTime(2026, 6, 12),
    isManual: true,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: const TransactionScreen(),
      routes: <String, WidgetBuilder>{
        '/profit-loss': (_) => const Scaffold(body: Text('Profit and Loss')),
      },
    ),
  );
  await tester.pumpAndSettle();
}
