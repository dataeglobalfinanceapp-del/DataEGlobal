import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/tax_screen/tax_screen.dart';
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

  testWidgets('TaxScreen renders yearly profit and tax statement', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveDeposit(
      orderNumber: 'tax-deposit',
      totalAmount: 50000,
      creditDeposit: 0,
      cash: 50000,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 1, 15),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'payroll',
      totalAmount: 10000,
      transactionDate: DateTime(2026, 2, 1),
      category: 'Payroll',
      payee: 'Payroll',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'gas',
      totalAmount: 500,
      transactionDate: DateTime(2026, 3, 1),
      category: 'gas',
      payee: 'Gas Stop',
      isManual: true,
    );

    await tester.pumpWidget(const MaterialApp(home: TaxScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Profit and Tax'), findsOneWidget);
    expect(find.text('Profit and Loss Statement 2026'), findsOneWidget);
    expect(find.text('Period Start'), findsOneWidget);
    expect(find.text('01/01/2026'), findsOneWidget);
    expect(find.text('Period End'), findsOneWidget);
    expect(find.text('12/31/2026'), findsOneWidget);
    expect(find.text('Business Name'), findsOneWidget);
    expect(find.text('Save Tep'), findsOneWidget);
    expect(find.text('Gross Income'), findsOneWidget);
    expect(find.text(r'$50,000.00'), findsNWidgets(2));
    expect(find.text('Payroll'), findsOneWidget);
    expect(find.text(r'$10,000.00'), findsOneWidget);
    expect(find.text('gas'), findsOneWidget);
    expect(find.text(r'$500.00'), findsOneWidget);
    expect(find.text('Advertising'), findsOneWidget);
    expect(find.text('Not tracked in app'), findsNothing);
    expect(find.text('Total Expenses'), findsOneWidget);
    expect(find.text(r'$10,500.00'), findsOneWidget);
    expect(find.text('Net Income Before Taxes'), findsOneWidget);
    expect(find.text(r'$39,500.00'), findsOneWidget);
    expect(find.text('Estimated Tax Percentage'), findsOneWidget);
    expect(find.text('22%'), findsWidgets);
    expect(find.text('Estimated Tax Amount'), findsOneWidget);
    expect(find.text(r'$8,690.00'), findsOneWidget);
    expect(find.text('Net Income After Taxes'), findsOneWidget);
    expect(find.text(r'$30,810.00'), findsOneWidget);

    final table = tester.widget<Table>(find.byType(Table));
    expect(table.children.every((row) => row.children.length == 2), isTrue);

    final advertisingRow = table.children.singleWhere((row) {
      final labelCell = row.children.first as Container;
      final label = labelCell.child;
      return label is Text && label.data == 'Advertising';
    });
    final decoration = advertisingRow.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFFE0F2FE));
  });

  testWidgets('TaxScreen renders at a narrow mobile width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TaxScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Profit and Loss Statement 2026'), findsOneWidget);
    expect(find.text('Not tracked in app'), findsNothing);
  });

  testWidgets('TaxScreen filters by date range and prorates fixed costs', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveDeposit(
      orderNumber: 'range-deposit',
      totalAmount: 15000,
      creditDeposit: 15000,
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 10),
      isManual: true,
    );
    await LiabilityService.saveDeposit(
      orderNumber: 'outside-deposit',
      totalAmount: 50000,
      creditDeposit: 50000,
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 5, 31),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'payroll',
      totalAmount: 3000,
      transactionDate: DateTime(2026, 6, 1),
      category: 'Payroll',
      payee: 'Payroll',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'gas-in-range',
      totalAmount: 100,
      transactionDate: DateTime(2026, 6, 10),
      category: 'gas',
      payee: 'Gas Stop',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'gas-outside-range',
      totalAmount: 600,
      transactionDate: DateTime(2026, 5, 31),
      category: 'gas',
      payee: 'Gas Stop',
      isManual: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TaxScreen(
          initialDateRange: DateTimeRange(
            start: DateTime(2026, 6, 1),
            end: DateTime(2026, 6, 15),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('06/01/2026 - 06/15/2026'), findsOneWidget);
    expect(find.text('06/01/2026'), findsOneWidget);
    expect(find.text('06/15/2026'), findsOneWidget);
    expect(find.text(r'$15,000.00'), findsNWidgets(2));
    expect(find.text('Payroll'), findsOneWidget);
    expect(find.text(r'$1,500.00'), findsOneWidget);
    expect(find.text('gas'), findsOneWidget);
    expect(find.text(r'$100.00'), findsOneWidget);
    expect(find.text(r'$600.00'), findsNothing);
    expect(find.text(r'$50,000.00'), findsNothing);
    expect(find.text(r'$1,600.00'), findsOneWidget);
  });

  testWidgets('TaxScreen category link opens matching expense report', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveExpense(
      checkNumber: 'gas-in-range',
      totalAmount: 45,
      transactionDate: DateTime(2026, 6, 12),
      category: 'gas',
      payee: 'Gas Stop',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'gas-outside-range',
      totalAmount: 90,
      transactionDate: DateTime(2026, 6, 20),
      category: 'gas',
      payee: 'Gas Later',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'rent-in-range',
      totalAmount: 300,
      transactionDate: DateTime(2026, 6, 10),
      category: 'Rent',
      payee: 'Studio Rent',
      isManual: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TaxScreen(
          initialDateRange: DateTimeRange(
            start: DateTime(2026, 6, 10),
            end: DateTime(2026, 6, 15),
          ),
        ),
        routes: <String, WidgetBuilder>{
          '/transactions': (BuildContext context) {
            final arguments =
                ModalRoute.of(context)!.settings.arguments
                    as TransactionScreenArguments;
            return TransactionScreen(
              initialExpenseCategory: arguments.initialExpenseCategory,
              initialExpenseDateRange: arguments.initialExpenseDateRange,
            );
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('gas'),
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    final gasLink = tester.widget<Text>(find.text('gas'));
    expect(gasLink.style?.decoration, TextDecoration.underline);

    await tester.tap(find.text('gas'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction'), findsOneWidget);
    expect(find.text('06/10/2026 - 06/15/2026'), findsOneWidget);
    expect(find.text('gas total'), findsOneWidget);
    expect(find.text(r'$45.00'), findsWidgets);

    await tester.dragUntilVisible(
      find.text('June'),
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('June'));
    await tester.pumpAndSettle();

    expect(find.text('Gas Stop'), findsOneWidget);
    expect(find.text('Gas Later'), findsNothing);
    expect(find.text('Studio Rent'), findsNothing);
  });
}
