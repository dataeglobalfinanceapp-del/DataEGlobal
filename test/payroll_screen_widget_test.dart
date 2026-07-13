import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/data/dto/save_employee_request.dart';
import 'package:savetep/domain/models/temporary_employee_document.dart';
import 'package:savetep/domain/services/employee_document_capture_service.dart';
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

  testWidgets('PayrollScreen starts with no employees after local cleanup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Jack Nicholson'), findsNothing);
    expect(find.text('Waylon Dalton'), findsNothing);
    expect(
      find.text('6 employees still need to confirm payroll.'),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('payroll.tab.employees')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Employee List'), findsOneWidget);
    expect(find.text('No employees found.'), findsOneWidget);
    expect(find.text('Showing 0 employees'), findsOneWidget);
    expect(find.text('Add New Employee'), findsOneWidget);
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

      await _seedDefaultEmployees();
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Payroll'), findsWidgets);
      expect(find.text('Employees'), findsWidgets);
      expect(find.text('Setting payroll'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.text('BALANCE'), findsOneWidget);
      expect(find.text('PAY DATE'), findsNothing);
      expect(find.text('PROCESS PAYROLL DATE'), findsNothing);
      expect(find.text('PAY PERIOD'), findsNothing);
      expect(find.text('Jack Nicholson'), findsOneWidget);
      expect(
        find.text('6 employees still need to confirm payroll.'),
        findsOneWidget,
      );
      expect(find.text(r'$5,000.00'), findsWidgets);
      expect(find.text('Total Deposit'), findsNothing);
      expect(find.text('Total Expense'), findsNothing);
      expect(find.byType(SingleChildScrollView), findsNothing);

      await tester.tap(find.text('6 employees still need to confirm payroll.'));
      await tester.pumpAndSettle();

      expect(find.text('Payroll Settings'), findsOneWidget);
      expect(find.text('PROCESS PAYROLL DATE'), findsNothing);
      expect(find.text('PAY DATE'), findsNothing);
      expect(find.text('PAYROLL SCHEDULE'), findsNothing);
      expect(find.text('PAY PERIOD'), findsNothing);
      expect(find.text('6 employees not have payroll setup.'), findsOneWidget);
      expect(find.text('Jack Nicholson'), findsOneWidget);
      expect(find.text('None'), findsWidgets);

      await tester.tap(find.text('6 employees not have payroll setup.'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('Payroll schedule'), findsOneWidget);
      expect(find.text('Paid after X days after period end'), findsOneWidget);
      expect(find.text('Remind X days after period end'), findsOneWidget);
      expect(find.text('Rate'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeSetup.save')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Choose a payroll schedule'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeSetup.schedule')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Biweekly').last);
      await tester.pumpAndSettle();
      expect(find.text('Weekday'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeSetup.weekday')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Friday').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(
          const ValueKey<String>('payroll.employeeSetup.paidAfterDays'),
        ),
        '21',
      );
      await tester.enterText(
        find.byKey(
          const ValueKey<String>('payroll.employeeSetup.remindAfterDays'),
        ),
        '8',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeSetup.save')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enter 0-20'), findsOneWidget);
      expect(find.text('Enter 0-7'), findsOneWidget);
      await tester.enterText(
        find.byKey(
          const ValueKey<String>('payroll.employeeSetup.paidAfterDays'),
        ),
        '3',
      );
      await tester.enterText(
        find.byKey(
          const ValueKey<String>('payroll.employeeSetup.remindAfterDays'),
        ),
        '2',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.employeeSetup.rate')),
        '21.25',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.employeeSetup.save')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Biweekly'), findsOneWidget);
      expect(find.text('5 employees not have payroll setup.'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Biweekly'), findsOneWidget);
      expect(find.text('PAYROLL PERIOD'), findsOneWidget);
      expect(find.text('05/31/26 - 06/13/26'), findsOneWidget);

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
        findsNothing,
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
      expect(find.text('Send Email'), findsOneWidget);
      expect(find.text('Create next'), findsOneWidget);
      expect(find.text('Create Next Employee'), findsNothing);
      expect(find.byIcon(Icons.mail_outline), findsNothing);

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
      expect(find.text('Showing 1 employee'), findsOneWidget);

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

      await _enterRequiredAddEmployeeFields(tester, fullName: 'Taylor Reed');
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
      expect(service.requests.single.employeeDetails.address, '100 Pine St');
      expect(service.requests.single.employeeDetails.rate, 24.5);
      expect(
        service.requests.single.linkW4,
        'https://example.com/taylor-w4.pdf',
      );
      expect(find.text('Email draft opened'), findsOneWidget);
      expect(find.text('Add New Employee'), findsWidgets);
    },
  );

  testWidgets('W4 camera photo sends with email and clears after success', (
    WidgetTester tester,
  ) async {
    final service = _RecordingEmployeeDocumentEmailService();
    final captureService = _FakeEmployeeDocumentCaptureService(
      document: _temporaryW4Document(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PayrollScreen(
          employeeDocumentEmailService: service,
          employeeDocumentCaptureService: captureService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('payroll.tab.employees')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add New Employee'));
    await tester.pumpAndSettle();

    await _enterRequiredAddEmployeeFields(tester, fullName: 'Taylor Reed');
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('payroll.addEmployee.ssn')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('payroll.addEmployee.ssn')),
      '123456789',
    );

    await _pressW4CameraButton(tester);

    expect(captureService.captureCount, 1);
    expect(
      find.byKey(
        const ValueKey<String>('payroll.addEmployee.linkW4.photoStatus'),
      ),
      findsOneWidget,
    );
    expect(find.text('W4 photo ready to email'), findsOneWidget);

    final Finder sendEmailButton = find.byKey(
      const ValueKey<String>('payroll.addEmployee.linkW4.sendEmail'),
    );
    await tester.ensureVisible(sendEmailButton);
    await tester.pumpAndSettle();
    await tester.tap(sendEmailButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('payroll.w4Email.recipient')),
      'manager@example.com',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('payroll.w4Email.send')),
    );
    await tester.pumpAndSettle();

    expect(service.requests, hasLength(1));
    expect(service.requests.single.temporaryDocument, isNotNull);
    expect(service.requests.single.temporaryDocument!.fileName, 'w4.jpg');
    expect(service.requests.single.socialSecurityNumber, '123-45-6789');
    expect(
      find.byKey(
        const ValueKey<String>('payroll.addEmployee.linkW4.photoStatus'),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey<String>('payroll.addEmployee.ssn')),
          )
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Email draft opened'), findsOneWidget);
  });

  testWidgets(
    'W4 photo stays after email cancel or failure and can be deleted',
    (WidgetTester tester) async {
      final service = _RecordingEmployeeDocumentEmailService();
      final captureService = _FakeEmployeeDocumentCaptureService(
        document: _temporaryW4Document(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PayrollScreen(
            employeeDocumentEmailService: service,
            employeeDocumentCaptureService: captureService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.tab.employees')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add New Employee'));
      await tester.pumpAndSettle();

      await _enterRequiredAddEmployeeFields(tester, fullName: 'Taylor Reed');
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('payroll.addEmployee.ssn')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.addEmployee.ssn')),
        '987654321',
      );
      await _pressW4CameraButton(tester);

      final Finder status = find.byKey(
        const ValueKey<String>('payroll.addEmployee.linkW4.photoStatus'),
      );
      expect(status, findsOneWidget);

      final Finder sendEmailButton = find.byKey(
        const ValueKey<String>('payroll.addEmployee.linkW4.sendEmail'),
      );
      await tester.ensureVisible(sendEmailButton);
      await tester.pumpAndSettle();
      await tester.tap(sendEmailButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.w4Email.cancel')),
      );
      await tester.pumpAndSettle();

      expect(service.requests, isEmpty);
      expect(status, findsOneWidget);
      expect(_ssnFieldText(tester), '987-65-4321');

      service.shouldFail = true;
      await tester.ensureVisible(sendEmailButton);
      await tester.pumpAndSettle();
      await tester.tap(sendEmailButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('payroll.w4Email.recipient')),
        'manager@example.com',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('payroll.w4Email.send')),
      );
      await tester.pumpAndSettle();

      expect(service.requests, isEmpty);
      expect(status, findsOneWidget);
      expect(_ssnFieldText(tester), '987-65-4321');
      expect(find.text('Unable to send W4 email'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('payroll.addEmployee.linkW4.deletePhoto'),
        ),
      );
      await tester.pumpAndSettle();

      expect(status, findsNothing);
      expect(find.text('W4 photo removed'), findsOneWidget);
    },
  );

  testWidgets('Create Next Employee saves and resets temporary fields', (
    WidgetTester tester,
  ) async {
    final captureService = _FakeEmployeeDocumentCaptureService(
      document: _temporaryW4Document(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PayrollScreen(employeeDocumentCaptureService: captureService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('payroll.tab.employees')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add New Employee'));
    await tester.pumpAndSettle();

    await _enterRequiredAddEmployeeFields(tester, fullName: 'First Draft');
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('payroll.addEmployee.ssn')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('payroll.addEmployee.ssn')),
      '111223333',
    );
    await _pressW4CameraButton(tester);
    expect(
      find.byKey(
        const ValueKey<String>('payroll.addEmployee.linkW4.photoStatus'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('payroll.addEmployee.createNext')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Employee saved. Ready for next employee.'),
      findsOneWidget,
    );
    expect(_fieldText(tester, 'payroll.addEmployee.fullName'), isEmpty);
    expect(_ssnFieldText(tester), isEmpty);
    expect(
      find.byKey(
        const ValueKey<String>('payroll.addEmployee.linkW4.photoStatus'),
      ),
      findsNothing,
    );
    expect(find.text('Add New Employee'), findsWidgets);

    await _enterRequiredAddEmployeeFields(tester, fullName: 'Second Draft');
    await tester.tap(
      find.byKey(const ValueKey<String>('payroll.addEmployee.done')),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Draft'), findsOneWidget);
    expect(find.text('Second Draft'), findsOneWidget);
    expect(find.text('111-22-3333'), findsNothing);
  });

  testWidgets('W4 camera errors are shown without storing a photo', (
    WidgetTester tester,
  ) async {
    final captureService = _FakeEmployeeDocumentCaptureService(
      exception: const EmployeeDocumentCaptureException(
        'Camera permission is required to capture W4 photos.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PayrollScreen(
          employeeDocumentEmailService:
              _RecordingEmployeeDocumentEmailService(),
          employeeDocumentCaptureService: captureService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('payroll.tab.employees')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add New Employee'));
    await tester.pumpAndSettle();

    await _pressW4CameraButton(tester);

    expect(captureService.captureCount, 1);
    expect(
      find.text('Camera permission is required to capture W4 photos.'),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('payroll.addEmployee.linkW4.photoStatus'),
      ),
      findsNothing,
    );
  });
}

Finder _richTextWithPlainText(String text) {
  return find.byWidgetPredicate(
    (Widget widget) => widget is RichText && widget.text.toPlainText() == text,
  );
}

Future<void> _seedDefaultEmployees() async {
  final EmployeeService service = EmployeeService();
  for (final SaveEmployeeRequest request in _defaultEmployeeRequests) {
    await service.saveEmployee(request);
  }
}

const List<SaveEmployeeRequest> _defaultEmployeeRequests =
    <SaveEmployeeRequest>[
      SaveEmployeeRequest(
        id: 'employee-jack-nicholson',
        fullName: 'Jack Nicholson',
        birthday: '04/22/1988',
        phone: '555-2601',
        address: '195 Spruce Ave, #202, Bayshore, CA 94326',
        dateHire: '',
        jobType: 'Hourly',
        rate: 0,
      ),
      SaveEmployeeRequest(
        id: 'employee-waylon-dalton',
        fullName: 'Waylon Dalton',
        birthday: '11/08/1991',
        phone: '555-7194',
        address: '84 Market Street, San Mateo, CA 94401',
        dateHire: '',
        jobType: 'Hourly',
        rate: 0,
      ),
      SaveEmployeeRequest(
        id: 'employee-abdullah-lang',
        fullName: 'Abdullah Lang',
        birthday: '02/14/1986',
        phone: '555-4188',
        address: '410 Oak Lane, Daly City, CA 94015',
        dateHire: '',
        jobType: 'Hourly',
        rate: 0,
      ),
      SaveEmployeeRequest(
        id: 'employee-justine-henderson',
        fullName: 'Justine Henderson',
        birthday: '07/30/1994',
        phone: '555-8320',
        address: '72 Lincoln Drive, South City, CA 94080',
        dateHire: '',
        jobType: 'Hourly',
        rate: 0,
      ),
      SaveEmployeeRequest(
        id: 'employee-joanna-shaffer',
        fullName: 'Joanna Shaffer',
        birthday: '09/18/1989',
        phone: '555-0137',
        address: '33 Garden Court, Burlingame, CA 94010',
        dateHire: '',
        jobType: 'Hourly',
        rate: 0,
      ),
      SaveEmployeeRequest(
        id: 'employee-mathias-little',
        fullName: 'Mathias Little',
        birthday: '12/03/1990',
        phone: '555-4412',
        address: '925 Pine Road, San Bruno, CA 94066',
        dateHire: '',
        jobType: 'Hourly',
        rate: 0,
      ),
    ];

Future<void> _enterRequiredAddEmployeeFields(
  WidgetTester tester, {
  required String fullName,
  String rate = '24.50',
  String address = '100 Pine St',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('payroll.addEmployee.fullName')),
    fullName,
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('payroll.addEmployee.rate')),
    rate,
  );
  await tester.ensureVisible(
    find.byKey(const ValueKey<String>('payroll.addEmployee.address')),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey<String>('payroll.addEmployee.address')),
    address,
  );
}

String _fieldText(WidgetTester tester, String key) {
  return tester
      .widget<TextFormField>(find.byKey(ValueKey<String>(key)))
      .controller!
      .text;
}

String _ssnFieldText(WidgetTester tester) {
  return _fieldText(tester, 'payroll.addEmployee.ssn');
}

Future<void> _pressW4CameraButton(WidgetTester tester) async {
  final Finder cameraButton = find.byKey(
    const ValueKey<String>('payroll.addEmployee.linkW4.camera'),
  );
  await tester.ensureVisible(cameraButton);
  await tester.pumpAndSettle();

  final VoidCallback? onPressed = tester
      .widget<OutlinedButton>(cameraButton)
      .onPressed;
  expect(onPressed, isNotNull);
  onPressed!();
  await tester.pumpAndSettle();
}

TemporaryEmployeeDocument _temporaryW4Document() {
  return TemporaryEmployeeDocument(
    bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
    fileName: 'w4.jpg',
    mimeType: 'image/jpeg',
    createdAt: DateTime(2026, 6, 15, 10, 30),
  );
}

class _RecordingEmployeeDocumentEmailService
    implements EmployeeDocumentEmailService {
  final List<W4EmailRequest> requests = <W4EmailRequest>[];
  bool shouldFail = false;

  @override
  Future<void> sendW4Email(W4EmailRequest request) async {
    if (shouldFail) {
      throw const EmployeeDocumentEmailException('Unable to send W4 email');
    }

    requests.add(request);
  }
}

class _FakeEmployeeDocumentCaptureService
    implements EmployeeDocumentCaptureService {
  final TemporaryEmployeeDocument? document;
  final EmployeeDocumentCaptureException? exception;
  int captureCount = 0;

  _FakeEmployeeDocumentCaptureService({this.document, this.exception});

  @override
  Future<TemporaryEmployeeDocument?> captureW4Photo() async {
    captureCount += 1;
    final EmployeeDocumentCaptureException? captureException = exception;
    if (captureException != null) throw captureException;
    return document;
  }
}
