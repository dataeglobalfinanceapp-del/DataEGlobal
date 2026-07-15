import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';

import 'payroll_models.dart';
import 'payroll_period_calculator.dart';

class PayrollExpenseService {
  const PayrollExpenseService._();

  static Future<void> syncConfirmedEmployee(PayrollEmployee employee) async {
    if (!employee.isPayrollConfirmed || employee.totalPay <= 0) return;

    final EmployeePayrollSetting? setting = employee.payrollSetting;
    if (setting == null || setting.schedule == EmployeePayrollSchedule.none) {
      return;
    }

    final PayrollPayPeriod? period =
        PayrollPeriodCalculator.currentPeriodForEmployee(
          employee,
          asOf: AppClock.now,
        );
    if (period == null) return;

    final int paidAfterPeriodEndDays = setting.paidAfterPeriodEndDays < 0
        ? 0
        : setting.paidAfterPeriodEndDays;
    final DateTime expenseDate = PayrollPeriodCalculator.addCalendarDays(
      period.end,
      paidAfterPeriodEndDays,
    );

    await LiabilityService.syncEmployeePayrollExpense(
      expenseId: expenseIdFor(
        employeeId: employee.id,
        periodStart: period.start,
        periodEnd: period.end,
      ),
      totalAmount: employee.totalPay,
      transactionDate: expenseDate,
      payee: 'Payroll - ${employee.name}',
    );
  }

  static String expenseIdFor({
    required String employeeId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    return 'payroll-expense-${_stableToken(employeeId)}-'
        '${_dateKey(periodStart)}-${_dateKey(periodEnd)}';
  }

  static String _stableToken(String value) {
    final String token = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return token.isEmpty ? 'employee' : token;
  }

  static String _dateKey(DateTime date) {
    final DateTime value = PayrollPeriodCalculator.dateOnly(date);
    return '${value.year}'
        '${value.month.toString().padLeft(2, '0')}'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
