import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/scan_screen/deposit_screen/deposit_account_balance_summary_screen.dart';
import 'package:savetep/features/auth/screens/scan_screen/deposit_screen/scan_deposit_choice.dart';
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

  test('deposit balance summary carries prior month balance forward', () async {
    await _saveDeposit(amount: 100, date: DateTime(2026, 5, 30));
    await _saveDeposit(amount: 75, date: DateTime(2026, 6, 10));
    await _saveDeposit(amount: 50, date: DateTime(2026, 7, 1));
    await _saveExpense(amount: 40, date: DateTime(2026, 6, 12));

    final DepositBalanceSummary summary =
        await LiabilityService.loadDepositBalanceSummary(year: 2026, month: 6);

    expect(summary.beginningBalance, 100);
    expect(summary.monthCredits, 75);
    expect(summary.monthExpenses, 40);
    expect(summary.monthlySurplusRatio, closeTo(0.466, 0.001));
    expect(summary.endingBalance, 135);

    final List<DepositBalanceSummary> summaries =
        await LiabilityService.loadDepositBalanceSummariesForYear(year: 2026);
    expect(summaries[4].monthlySurplusRatio, 1);
    expect(summaries[6].beginningBalance, 135);
    expect(summaries[6].monthCredits, 50);
    expect(summaries[6].endingBalance, 185);

    final budget = await LiabilityService.loadBudgetData(
      startDate: DateTime(2026, 6),
      endDate: DateTime(2026, 6, 30),
      period: 'June',
    );
    expect(budget.deposit, 75);
    expect(budget.expense, 40);
    expect(budget.available, 35);
  });

  testWidgets('Deposit account balance summary expands monthly balances', (
    WidgetTester tester,
  ) async {
    await _saveDeposit(amount: 100, date: DateTime(2026, 5, 30));
    await _saveDeposit(amount: 75, date: DateTime(2026, 6, 10));
    await _saveDeposit(amount: 50, date: DateTime(2026, 7, 1));
    await _saveExpense(amount: 40, date: DateTime(2026, 6, 12));

    await tester.pumpWidget(
      const MaterialApp(home: DepositAccountBalanceSummaryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deposit account balance summary'), findsWidgets);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('January'), findsOneWidget);
    expect(find.text('June'), findsOneWidget);
    expect(find.text('July'), findsNothing);
    expect(find.text(r'$0.00'), findsWidgets);
    expect(find.text(r'$135.00'), findsWidgets);
    expect(find.text(r'$185.00'), findsNothing);

    await tester.tap(find.text('June'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Beginning deposit balance from the previous month ending balance',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Deposits added during the selected month'),
      findsOneWidget,
    );
    expect(
      find.text('Total expenses during the selected month'),
      findsOneWidget,
    );
    expect(
      find.text('Ending deposit balance for the selected month'),
      findsOneWidget,
    );
    expect(find.text(r'$100.00'), findsWidgets);
    expect(find.text(r'$75.00'), findsOneWidget);
    expect(find.text(r'$40.00'), findsOneWidget);
    expect(find.text(r'$135.00'), findsWidgets);
  });

  testWidgets('Deposit account balance summary shows completed month ratios', (
    WidgetTester tester,
  ) async {
    AppClock.set(DateTime(2026, 7, 15));

    await _saveDeposit(amount: 50, date: DateTime(2026, 5, 8));
    await _saveExpense(amount: 100, date: DateTime(2026, 5, 9));
    await _saveDeposit(amount: 75, date: DateTime(2026, 6, 10));
    await _saveExpense(amount: 40, date: DateTime(2026, 6, 12));
    await _saveDeposit(amount: 200, date: DateTime(2026, 7, 1));
    await _saveExpense(amount: 100, date: DateTime(2026, 7, 2));

    await tester.pumpWidget(
      const MaterialApp(home: DepositAccountBalanceSummaryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('May'), findsOneWidget);
    expect(find.text('June'), findsOneWidget);
    expect(find.text('July'), findsOneWidget);
    expect(find.text('-100%'), findsOneWidget);
    expect(find.text('46.7%'), findsOneWidget);
    expect(find.text('50%'), findsNothing);

    final Text lowRatioText = tester.widget<Text>(find.text('46.7%'));
    expect(lowRatioText.style?.color, const Color(0xFFDC2626));
    expect(
      monthlySurplusRatioColor(
        const DepositBalanceSummary(
          year: 2026,
          month: 6,
          beginningBalance: 0,
          monthCredits: 0,
          monthExpenses: 0,
          monthlySurplusRatio: 1.1,
        ),
      ),
      const Color(0xFF111827),
    );
  });

  testWidgets('Deposit tab exposes account balance summary option', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScanDepositScreen()));

    expect(find.text('Enter Manually'), findsNothing);
    expect(find.text('Extract Automatically'), findsOneWidget);
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

Future<void> _saveExpense({required double amount, required DateTime date}) {
  return LiabilityService.saveExpense(
    checkNumber: 'E-${date.month}-${date.day}',
    totalAmount: amount,
    transactionDate: date,
    category: 'Fuel',
    payee: 'Fuel',
    isManual: true,
  );
}
