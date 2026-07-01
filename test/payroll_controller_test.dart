import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/domain/services/employee_service.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_controller.dart';
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

  test('pay period total pay follows the selected payroll date', () async {
    await LiabilityService.saveExpense(
      checkNumber: 'PAY-1',
      totalAmount: 100,
      transactionDate: DateTime(2026, 6, 15),
      category: 'Payroll',
      payee: 'Payroll',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'PAY-2',
      totalAmount: 200,
      transactionDate: DateTime(2026, 6, 29),
      category: 'Payroll',
      payee: 'Payroll',
      isManual: true,
    );

    final PayrollController controller = PayrollController();
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state.payPeriodTotalPay, 100);

    controller.setPayDate(DateTime(2026, 6, 29));
    expect(controller.state.payPeriodTotalPay, 200);
  });

  test(
    'confirming employee payroll syncs expense and persists values',
    () async {
      final PayrollController controller = PayrollController();
      addTearDown(controller.dispose);

      await controller.load();
      final firstEmployee = controller.state.payroll.employees.first;

      await controller.updateEmployee(
        firstEmployee.id,
        rate: 20,
        regularHours: 40,
        overtimeHours: 10,
        commission: 5,
        tips: 2,
      );

      var payrollExpenses = (await LiabilityService.loadExpenses())
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(payrollExpenses, hasLength(1));
      expect(payrollExpenses.single.totalAmount, 1107);
      expect(payrollExpenses.single.transactionDate, DateTime(2026, 6, 15));

      await controller.updateEmployee(
        firstEmployee.id,
        rate: 20,
        regularHours: 40,
        overtimeHours: 10,
        commission: 5,
        tips: 3,
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
    },
  );
}
