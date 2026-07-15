import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_expense_service.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_models.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 7, 20));
    LiabilityService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
  });

  test(
    'confirmed future payroll expense activates on the expense date',
    () async {
      final PayrollEmployee employee = PayrollEmployee(
        id: 'employee-maya',
        name: 'Maya Rodriguez',
        rate: 20,
        regularHours: 40,
        isPayrollConfirmed: true,
        dateHire: '07/13/26',
        payrollSetting: EmployeePayrollSetting(
          schedule: EmployeePayrollSchedule.biWeekly,
          endingDay: EmployeePayrollEndingDay.sunday,
          firstPeriodEndDate: DateTime(2026, 7, 26),
        ),
      );

      await PayrollExpenseService.syncConfirmedEmployee(employee);

      expect(await LiabilityService.loadExpenses(), isEmpty);

      await PayrollExpenseService.syncConfirmedEmployee(
        employee.copyWith(tips: 50),
      );
      AppClock.set(DateTime(2026, 7, 26));

      final List<ExpenseRecord> expenses =
          await LiabilityService.loadExpenses();

      expect(expenses, hasLength(1));
      expect(expenses.single.id, _expectedExpenseId);
      expect(expenses.single.checkNumber, _expectedExpenseId);
      expect(expenses.single.category, 'Payroll');
      expect(expenses.single.payee, 'Payroll - Maya Rodriguez');
      expect(expenses.single.totalAmount, 850);
      expect(expenses.single.transactionDate, DateTime(2026, 7, 26));

      final budget = await LiabilityService.loadBudgetData(
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        period: 'July',
      );
      expect(budget.expense, 850);
      expect(budget.categories.single.label, 'Payroll');

      await PayrollExpenseService.syncConfirmedEmployee(
        employee.copyWith(tips: 75),
      );
      final List<ExpenseRecord> updatedExpenses =
          await LiabilityService.loadExpenses();

      expect(updatedExpenses, hasLength(1));
      expect(updatedExpenses.single.id, _expectedExpenseId);
      expect(updatedExpenses.single.totalAmount, 875);
    },
  );
}

const String _expectedExpenseId =
    'payroll-expense-employee-maya-20260713-20260726';
