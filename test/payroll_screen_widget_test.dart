import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/domain/services/employee_document_email_service.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_screen.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_service.dart';
import 'package:savetep/domain/services/employee_service.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/reminder_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
    ReminderService.resetForTesting();
    PayrollService.resetForTesting();
    EmployeeService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
    ReminderService.resetForTesting(disablePersistence: false);
    PayrollService.resetForTesting(disablePersistence: false);
    EmployeeService.resetForTesting(disablePersistence: false);
  });

  testWidgets(
    'PayrollScreen fits phone width, tabs, and requires payroll confirmations',
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
      expect(
        find.text('6 employees still need to confirm payroll.'),
        findsOneWidget,
      );
      expect(find.text(r'$5,000.00'), findsWidgets);
      expect(find.text('Total Deposit'), findsNothing);
      expect(find.text('Total Expense'), findsNothing);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.text('06/16/2026'), findsOneWidget);

      await tester.tap(find.text('06/16/2026'));
      await tester.pumpAndSettle();
      expect(find.text('Choose pay date'), findsOneWidget);
      await tester.tap(find.text('15').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('06/16/2026'), findsOneWidget);
      expect(find.text('Period begin date'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('payroll.biweeklyPeriodBeginDate')),
        findsOneWidget,
      );
      expect(find.text('06/01/2026'), findsOneWidget);
      expect(find.text('06/01/2026 - 06/14/2026'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.biweeklyPeriodBeginDate')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Choose period begin date'), findsOneWidget);
      await tester.tap(find.text('2').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('06/02/2026'), findsOneWidget);
      expect(find.text('06/02/2026 - 06/15/2026'), findsOneWidget);
      expect(find.text('06/16/2026'), findsOneWidget);

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
      expect(find.text(r'$1,107.00'), findsNothing);

      await tester.dragUntilVisible(
        find.byKey(const ValueKey<String>('payroll.employee.0.confirm')),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('payroll.employee.0.action.dropdown'),
        ),
        findsOneWidget,
      );
      await Scrollable.ensureVisible(
        tester.element(
          find.byKey(
            const ValueKey<String>('payroll.employee.0.action.dropdown'),
          ),
        ),
        alignment: 0.45,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey<String>('payroll.employee.0.action.dropdown'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('payroll.employee.0.action.same')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('payroll.employee.0.action.change')),
        findsWidgets,
      );
      expect(
        find.byKey(
          const ValueKey<String>('payroll.employee.0.action.vacation'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('payroll.employee.0.action.off')),
        findsOneWidget,
      );
      await tester.tap(find.text('Change').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employee.0.confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$1,107.00'), findsWidgets);
      expect(
        find.text('Please confirm payroll for this employee.'),
        findsOneWidget,
      );
      expect(
        find.text('5 employees still need to confirm payroll.'),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('payroll.employee.0.edit')),
        findsNothing,
      );
      await tester.dragUntilVisible(
        find.byKey(const ValueKey<String>('payroll.employee.0.tips')),
        find.byType(ListView).first,
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.employee.0.tips')),
        '3',
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$1,108.00'), findsNothing);
      expect(find.text(r'$1,107.00'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employee.0.confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$1,108.00'), findsWidgets);

      await tester.dragUntilVisible(
        find.byKey(const ValueKey<String>('payroll.tab.employees')),
        find.byType(ListView).first,
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.tab.employees')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Employee List'), findsOneWidget);
      expect(find.text('Add New Employee'), findsOneWidget);
      expect(find.text('Employee Information'), findsNothing);
      expect(find.text('Full Name'), findsNothing);
      expect(find.text('Showing 6 employees'), findsOneWidget);
      expect(find.text('Manage and view your employees.'), findsNothing);
      expect(find.byIcon(Icons.call_outlined), findsNothing);
      expect(find.byType(SingleChildScrollView), findsNothing);

      await tester.tap(find.text('Jack Nicholson'));
      await tester.pumpAndSettle();

      expect(find.text('Employee Information'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Birthday'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Date Hire'), findsOneWidget);
      expect(find.text('Job Type'), findsOneWidget);
      expect(find.byIcon(Icons.call_outlined), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeInfo.close')),
      );
      await tester.pumpAndSettle();

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
        find.byKey(const ValueKey<String>('payroll.addEmployee.linkW4')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.addEmployee.linkW4')),
        'https://example.com/taylor-w4.pdf',
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

      await tester.dragUntilVisible(
        find.text('Taylor Reed'),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Taylor Reed'));
      await tester.pumpAndSettle();

      expect(find.text('555-3399'), findsOneWidget);
      expect(
        find.text('500 Market Street, San Francisco, CA 94105'),
        findsOneWidget,
      );
      expect(find.text('https://example.com/taylor-w4.pdf'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeInfo.edit')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.employeeInfo.phone')),
        '555-4400',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeInfo.confirm')),
      );
      await tester.pumpAndSettle();

      expect(find.text('555-4400'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeInfo.edit')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeInfo.remove')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Are you sure you want to remove this employee?'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeInfo.cancelRemove')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Taylor Reed'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeInfo.remove')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey<String>('payroll.employeeInfo.confirmRemove'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Employee Information'), findsNothing);
      expect(find.text('Taylor Reed'), findsNothing);
      expect(find.text('Showing 6 employees'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.employees.search')),
        'Waylon',
      );
      await tester.pumpAndSettle();
      expect(find.text('Waylon Dalton'), findsOneWidget);
      expect(find.text('Abdullah Lang'), findsNothing);

      await tester.dragUntilVisible(
        find.byKey(const ValueKey<String>('payroll.tab.payroll')),
        find.byType(ListView).first,
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.tab.payroll')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save payroll'), findsNothing);

      final expenses = await LiabilityService.loadExpenses();
      final payrollExpenses = expenses
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(payrollExpenses, isEmpty);
    },
  );

  testWidgets(
    'Add employee saves when job type birthday phone and date hire are empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.tab.employees')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add New Employee'));
      await tester.pumpAndSettle();

      expect(_richTextWithPlainText('Job Type *'), findsNothing);
      expect(_richTextWithPlainText('Birthday *'), findsNothing);
      expect(_richTextWithPlainText('Phone *'), findsNothing);
      expect(_richTextWithPlainText('Date Hire *'), findsNothing);
      expect(_richTextWithPlainText('Job Type (optional)'), findsOneWidget);
      expect(_richTextWithPlainText('Birthday (optional)'), findsOneWidget);
      expect(_richTextWithPlainText('Phone (optional)'), findsOneWidget);
      expect(_richTextWithPlainText('Date Hire (optional)'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.addEmployee.fullName')),
        'Minimal Fields',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.addEmployee.rate')),
        '18',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.addEmployee.address')),
        '100 Pine Street',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('payroll.addEmployee.done')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.addEmployee.done')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minimal Fields'), findsOneWidget);
      expect(find.text('Showing 7 employees'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.employees.search')),
        'Minimal',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minimal Fields'));
      await tester.pumpAndSettle();

      expect(find.text('Employee Information'), findsOneWidget);
      expect(find.text('100 Pine Street'), findsOneWidget);
      expect(find.text('-'), findsNWidgets(4));
    },
  );

  testWidgets(
    'W4 email flow validates recipient and sends only after confirmation',
    (WidgetTester tester) async {
      final service = _RecordingEmployeeDocumentEmailService();

      await tester.pumpWidget(
        MaterialApp(home: PayrollScreen(employeeDocumentEmailService: service)),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.tab.employees')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add New Employee'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.addEmployee.fullName')),
        'Taylor Reed',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('payroll.addEmployee.linkW4')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.addEmployee.linkW4')),
        'https://example.com/taylor-w4.pdf',
      );

      final Finder sendEmailButton = find.byKey(
        const ValueKey<String>('payroll.addEmployee.linkW4.sendEmail'),
      );

      await tester.ensureVisible(sendEmailButton);
      await tester.pumpAndSettle();
      await tester.tap(sendEmailButton);
      await tester.pumpAndSettle();
      expect(find.text('Send W4 Email'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.w4Email.cancel')),
      );
      await tester.pumpAndSettle();
      expect(service.requests, isEmpty);
      expect(find.text('Add New Employee'), findsWidgets);

      await tester.ensureVisible(sendEmailButton);
      await tester.pumpAndSettle();
      await tester.tap(sendEmailButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.w4Email.recipient')),
        'not-an-email',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.w4Email.send')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(service.requests, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.w4Email.recipient')),
        'manager@example.com',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.w4Email.send')),
      );
      await tester.pumpAndSettle();

      expect(service.requests, hasLength(1));
      expect(service.requests.single.recipientEmail, 'manager@example.com');
      expect(service.requests.single.employeeName, 'Taylor Reed');
      expect(
        service.requests.single.linkW4,
        'https://example.com/taylor-w4.pdf',
      );
      expect(find.text('Email draft opened'), findsOneWidget);
      expect(find.text('Add New Employee'), findsWidgets);
    },
  );
}

Finder _richTextWithPlainText(String text) {
  return find.byWidgetPredicate(
    (Widget widget) => widget is RichText && widget.text.toPlainText() == text,
  );
}

class _RecordingEmployeeDocumentEmailService
    implements EmployeeDocumentEmailService {
  final List<W4EmailRequest> requests = <W4EmailRequest>[];

  @override
  Future<void> sendW4Email(W4EmailRequest request) async {
    requests.add(request);
  }
}
