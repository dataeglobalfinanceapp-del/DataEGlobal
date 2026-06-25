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

  testWidgets('TransactionScreen opens on expense monthly view and exports', (
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
    expect(find.text('AVAILABLE FUNDS'), findsOneWidget);
    expect(find.text(r'$80.00'), findsOneWidget);
    expect(find.text(r'$125.00'), findsOneWidget);
    expect(find.text('TOTAL DEPOSIT'), findsOneWidget);
    expect(find.text('ESTIMATED TAX RATE'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
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

  testWidgets('Estimated tax rate label opens profit and loss', (
    WidgetTester tester,
  ) async {
    await _pumpTransactionScreenWithProfitAndLossRoute(tester);

    await tester.tap(find.text('ESTIMATED TAX RATE'));
    await tester.pumpAndSettle();

    expect(find.text('Profit and Loss'), findsOneWidget);
  });

  testWidgets('Estimated tax rate value opens profit and loss', (
    WidgetTester tester,
  ) async {
    await _pumpTransactionScreenWithProfitAndLossRoute(tester);

    await tester.tap(find.text('10%'));
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
    expect(find.text('Cash'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete deposit?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No deposit history for this view.'), findsOneWidget);
  });

  testWidgets('TransactionScreen filters expenses from a category tap', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveExpense(
      checkNumber: 'E200',
      totalAmount: 45,
      transactionDate: DateTime(2026, 6, 10),
      category: 'Fuel',
      payee: 'Fuel Stop',
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
      find.text('Fuel Stop'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fuel Stop'), findsOneWidget);
    expect(find.text('Studio Rent'), findsOneWidget);

    await tester.tap(find.text('Fuel'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Fuel total'),
      find.byType(ListView),
      const Offset(0, 180),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fuel total'), findsOneWidget);
    expect(find.text(r'$45.00'), findsWidgets);
    expect(find.text('Fuel Stop'), findsOneWidget);
    expect(find.text('Studio Rent'), findsNothing);
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
        '/tax': (_) => const Scaffold(body: Text('Profit and Loss')),
      },
    ),
  );
  await tester.pumpAndSettle();
}
