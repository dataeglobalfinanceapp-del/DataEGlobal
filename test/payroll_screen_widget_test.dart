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
    'PayrollScreen fits phone width, tabs, and saves payroll expense',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      expect(tester.takeException(), isNull);
      expect(find.text('Payroll'), findsWidgets);
      expect(find.text('Employees'), findsWidgets);
      expect(find.text('BALANCE'), findsOneWidget);
      expect(find.text('PAY DATE'), findsOneWidget);
      expect(find.text('Jack Nicholson'), findsOneWidget);
      expect(find.text(r'$5,000.00'), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsNothing);

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

      expect(tester.takeException(), isNull);
      expect(find.text(r'$1,107.00'), findsWidgets);

      await tester.drag(find.byType(ListView).first, const Offset(0, 600));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.tab.employees')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Employee List'), findsOneWidget);
      expect(find.text('Employee Information'), findsOneWidget);
      expect(find.text('Add New Employee'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Birthday'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Job Type'), findsOneWidget);
      expect(find.text('Showing 6 employees'), findsOneWidget);
      expect(find.text('Manage and view your employees.'), findsNothing);
      expect(find.byIcon(Icons.call_outlined), findsNothing);
      expect(find.byType(SingleChildScrollView), findsNothing);

      await tester.tap(find.text('Add New Employee'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Employee'), findsWidgets);
      expect(find.text('Back'), findsNothing);
      expect(find.text('Next'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.addEmployee.done')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsWidgets);

      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.addEmployee.fullName')),
        'Taylor Reed',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.addEmployee.jobType')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hourly').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.addEmployee.birthday')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.addEmployee.rate')),
        '24.50',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.addEmployee.phone')),
        '555-3399',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('payroll.addEmployee.address')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.addEmployee.address')),
        '500 Market Street, San Francisco, CA 94105',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('payroll.addEmployee.dateHire')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.addEmployee.dateHire')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.addEmployee.done')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Taylor Reed'), findsOneWidget);
      expect(find.text('Showing 7 employees'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.employees.search')),
        'Waylon',
      );
      await tester.pumpAndSettle();
      expect(find.text('Waylon Dalton'), findsOneWidget);
      expect(find.text('Abdullah Lang'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.tab.payroll')),
      );
      await tester.pumpAndSettle();

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
