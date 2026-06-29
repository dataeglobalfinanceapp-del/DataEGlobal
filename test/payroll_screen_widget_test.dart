import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/payroll_screen/payroll_screen.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_service.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/reminder_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
    ReminderService.resetForTesting();
    PayrollService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
    ReminderService.resetForTesting(disablePersistence: false);
    PayrollService.resetForTesting(disablePersistence: false);
  });

  testWidgets(
    'PayrollScreen calculates employee total and saves payroll expense',
    (WidgetTester tester) async {
      await LiabilityService.saveDeposit(
        orderNumber: 'DEP-1',
        totalAmount: 5000,
        creditDeposit: 5000,
        cash: 0,
        giftCard: 0,
        other: 0,
        transactionDate: DateTime(2026, 6, 1),
        isManual: true,
      );

      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Payroll'), findsOneWidget);
      expect(find.text('BALANCE'), findsOneWidget);
      expect(find.text('PAY DATE'), findsOneWidget);
      expect(find.text('Jack Nicholson'), findsOneWidget);
      expect(find.text(r'$5,000.00'), findsWidgets);

      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.employee.0.rate')),
        '20',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.employee.0.regularHours')),
        '40',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.employee.0.overtimeHours')),
        '10',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.employee.0.commission')),
        '5',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.employee.0.tips')),
        '2',
      );
      await tester.pumpAndSettle();

      expect(find.text(r'$1,107.00'), findsWidgets);

      await tester.dragUntilVisible(
        find.text('Save payroll'),
        find.byType(ListView).first,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save payroll'));
      await tester.pumpAndSettle();

      expect(
        find.text('Payroll saved to expenses and reminders.'),
        findsOneWidget,
      );

      final expenses = await LiabilityService.loadExpenses();
      final payrollExpenses = expenses
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(payrollExpenses, hasLength(1));
      expect(payrollExpenses.single.totalAmount, 1107);
    },
  );
}
