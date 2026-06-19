import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biztrack/features/auth/screens/scan_screen/deposit_screen/deposit_account_balance_summary_screen.dart';
import 'package:biztrack/features/auth/screens/scan_screen/deposit_screen/scan_deposit_choice.dart';
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

  test('deposit balance summary carries prior month balance forward', () async {
    await _saveDeposit(amount: 100, date: DateTime(2026, 5, 30));
    await _saveDeposit(amount: 75, date: DateTime(2026, 6, 10));
    await _saveDeposit(amount: 50, date: DateTime(2026, 7, 1));

    final DepositBalanceSummary summary =
        await LiabilityService.loadDepositBalanceSummary(year: 2026, month: 6);

    expect(summary.beginningBalance, 100);
    expect(summary.monthCredits, 75);
    expect(summary.endingBalance, 175);

    final budget = await LiabilityService.loadBudgetData(
      startDate: DateTime(2026, 6),
      endDate: DateTime(2026, 6, 30),
      period: 'June',
    );
    expect(budget.deposit, 75);
    expect(budget.saving, 7.5);
    expect(budget.income, 67.5);
  });

  testWidgets('Deposit account balance summary renders monthly balances', (
    WidgetTester tester,
  ) async {
    await _saveDeposit(amount: 100, date: DateTime(2026, 5, 30));
    await _saveDeposit(amount: 75, date: DateTime(2026, 6, 10));

    await tester.pumpWidget(
      const MaterialApp(home: DepositAccountBalanceSummaryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deposit account balance summary'), findsWidgets);
    expect(find.text('June 2026'), findsOneWidget);
    expect(find.text('Beginning balance from previous month'), findsOneWidget);
    expect(
      find.text('Deposits and other credits for selected month'),
      findsOneWidget,
    );
    expect(find.text('Ending deposit balance'), findsOneWidget);
    expect(find.text(r'$100.00'), findsOneWidget);
    expect(find.text(r'$75.00'), findsOneWidget);
    expect(find.text(r'$175.00'), findsOneWidget);
  });

  testWidgets('Deposit tab exposes account balance summary option', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScanDepositScreen()));

    expect(find.text('Deposit account balance summary'), findsOneWidget);
    expect(
      find.text('Review beginning balance, credits, and ending balance'),
      findsOneWidget,
    );
  });
}

Future<void> _saveDeposit({required double amount, required DateTime date}) {
  return LiabilityService.saveDeposit(
    orderNumber: 'D-${date.month}-${date.day}',
    totalAmount: amount,
    creditDeposit: amount,
    cash: 0,
    giftCard: 0,
    other: 0,
    transactionDate: date,
    isManual: true,
  );
}
