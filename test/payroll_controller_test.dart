import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/domain/services/employee_service.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_controller.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_models.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_service.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/reminder_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
    PayrollService.resetForTesting();
    EmployeeService.resetForTesting();
    ReminderService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
    PayrollService.resetForTesting(disablePersistence: false);
    EmployeeService.resetForTesting(disablePersistence: false);
    ReminderService.resetForTesting(disablePersistence: false);
  });

  test(
    'monthly pay period total pay follows the selected payroll date',
    () async {
      await LiabilityService.saveExpense(
        checkNumber: 'PAY-1',
        totalAmount: 100,
        transactionDate: DateTime(2026, 6, 16),
        category: 'Payroll',
        payee: 'Payroll',
        isManual: true,
      );
      await LiabilityService.saveExpense(
        checkNumber: 'PAY-2',
        totalAmount: 200,
        transactionDate: DateTime(2026, 7, 16),
        category: 'Payroll',
        payee: 'Payroll',
        isManual: true,
      );

      final PayrollController controller = PayrollController();
      addTearDown(controller.dispose);

      await controller.load();
      controller.setSchedule(PayrollSchedule.monthly);
      expect(controller.state.payPeriodTotalPay, 100);

      controller.setPayDate(DateTime(2026, 7, 16));
      expect(controller.state.payPeriodTotalPay, 200);
    },
  );

  test('biweekly pay period follows the selected period begin date', () async {
    final PayrollController controller = PayrollController();
    addTearDown(controller.dispose);

    await controller.load();

    expect(
      controller.state.payroll.biweeklyPeriodBeginDate,
      DateTime(2026, 6, 1),
    );
    expect(controller.state.payroll.payPeriodStart, DateTime(2026, 6, 1));
    expect(controller.state.payroll.payPeriodEnd, DateTime(2026, 6, 14));
    expect(controller.state.payroll.payDate, DateTime(2026, 6, 16));

    controller.setBiweeklyPeriodBeginDate(DateTime(2026, 6, 2));

    expect(
      controller.state.payroll.biweeklyPeriodBeginDate,
      DateTime(2026, 6, 2),
    );
    expect(controller.state.payroll.payPeriodStart, DateTime(2026, 6, 2));
    expect(controller.state.payroll.payPeriodEnd, DateTime(2026, 6, 15));
    expect(controller.state.payroll.payDate, DateTime(2026, 6, 16));
  });

  test('pay date updates normalize today and past dates to tomorrow', () async {
    final PayrollController controller = PayrollController();
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state.payroll.payDate, DateTime(2026, 6, 16));

    controller.setPayDate(DateTime(2026, 6, 15));
    expect(controller.state.payroll.payDate, DateTime(2026, 6, 16));

    controller.setPayDate(DateTime(2026, 6, 1));
    expect(controller.state.payroll.payDate, DateTime(2026, 6, 16));

    controller.setPayDate(DateTime(2026, 6, 17));
    expect(controller.state.payroll.payDate, DateTime(2026, 6, 17));
  });

  test(
    'confirming all employee payrolls syncs expense and persists values',
    () async {
      final PayrollController controller = PayrollController();
      addTearDown(controller.dispose);

      await controller.load();
      controller.setPayDate(DateTime(2026, 6, 29));
      final firstEmployee = controller.state.payroll.employees.first;

      await controller.updateEmployee(
        firstEmployee.id,
        rate: 20,
        regularHours: 40,
        overtimeHours: 10,
        commission: 5,
        tips: 2,
        confirmPayroll: true,
      );

      var payrollExpenses = (await LiabilityService.loadExpenses())
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(payrollExpenses, isEmpty);

      for (final employee in controller.state.payroll.employees.skip(1)) {
        await controller.updateEmployee(employee.id, confirmPayroll: true);
      }

      payrollExpenses = (await LiabilityService.loadExpenses())
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(payrollExpenses, hasLength(1));
      expect(payrollExpenses.single.totalAmount, 1107);
      expect(payrollExpenses.single.transactionDate, DateTime(2026, 6, 29));

      await controller.updateEmployee(
        firstEmployee.id,
        rate: 20,
        regularHours: 40,
        overtimeHours: 10,
        commission: 5,
        tips: 3,
        confirmPayroll: true,
      );

      payrollExpenses = (await LiabilityService.loadExpenses())
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(payrollExpenses, hasLength(1));
      expect(payrollExpenses.single.totalAmount, 1108);

      final PayrollController reloadedController = PayrollController();
      addTearDown(reloadedController.dispose);

      await reloadedController.load();
      final reloadedEmployee = reloadedController.state.payroll.employees.first;
      expect(reloadedEmployee.tips, 3);
      expect(reloadedEmployee.totalPay, 1108);
      expect(reloadedController.state.payroll.allEmployeesConfirmed, isTrue);
    },
  );

  test(
    'missed unconfirmed payroll rolls forward with zeroed payroll fields',
    () async {
      final PayrollController controller = PayrollController();
      addTearDown(controller.dispose);

      await controller.load();
      controller.setPayDate(DateTime(2026, 6, 29));
      final firstEmployee = controller.state.payroll.employees.first;

      await controller.updateEmployee(
        firstEmployee.id,
        rate: 20,
        regularHours: 40,
        overtimeHours: 10,
        commission: 5,
        tips: 2,
        confirmPayroll: true,
      );

      AppClock.set(DateTime(2026, 6, 23));
      final PayrollController reloadedController = PayrollController();
      addTearDown(reloadedController.dispose);

      await reloadedController.load();

      expect(reloadedController.state.payroll.payDate, DateTime(2026, 7, 13));
      expect(reloadedController.state.payroll.totalPay, 0);
      expect(
        reloadedController.state.payroll.employees.every(
          (employee) =>
              employee.rate == 0 &&
              employee.regularHours == 0 &&
              employee.overtimeHours == 0 &&
              employee.commission == 0 &&
              employee.tips == 0 &&
              !employee.isPayrollConfirmed,
        ),
        isTrue,
      );

      final payrollExpenses = (await LiabilityService.loadExpenses())
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(payrollExpenses, isEmpty);
    },
  );
}
