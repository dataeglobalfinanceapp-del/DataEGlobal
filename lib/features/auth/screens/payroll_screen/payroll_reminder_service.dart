import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/recurrence_schedule.dart';
import 'package:savetep/services/reminder_service.dart';

import 'payroll_models.dart';
import 'payroll_period_calculator.dart';

class PayrollReminderService {
  const PayrollReminderService._();

  static Future<void> syncEmployees(Iterable<PayrollEmployee> employees) async {
    for (final PayrollEmployee employee in employees) {
      await syncEmployee(employee);
    }
  }

  static Future<void> syncEmployee(PayrollEmployee employee) async {
    final EmployeePayrollSetting? setting = employee.payrollSetting;
    if (setting == null || setting.schedule == EmployeePayrollSchedule.none) {
      return;
    }

    final int year = AppClock.now.year;
    final int reminderOffsetDays = setting.remindAfterPeriodEndDays < 0
        ? 0
        : setting.remindAfterPeriodEndDays;
    final DateTime yearEnd = DateTime(year, 12, 31);
    final List<DateTime> reminderDates =
        PayrollPeriodCalculator.periodEndDatesForYear(
              dateHire: employee.dateHire,
              setting: setting,
              year: year,
            )
            .map(
              (DateTime periodEnd) => PayrollPeriodCalculator.dateOnly(
                PayrollPeriodCalculator.addCalendarDays(
                  periodEnd,
                  reminderOffsetDays,
                ),
              ),
            )
            .where((DateTime reminderDate) => !reminderDate.isAfter(yearEnd))
            .toList(growable: false);

    await ReminderService.syncPayrollReminderSeries(
      seriesId: seriesIdForEmployee(employee.id),
      reminderDates: reminderDates,
      title: 'Do payroll for ${employee.name}',
      frequency: _frequencyForSchedule(setting.schedule),
      amount: employee.totalPay,
    );
  }

  static String seriesIdForEmployee(String employeeId) {
    return 'payroll-reminder-${employeeId.trim()}';
  }

  static String _frequencyForSchedule(EmployeePayrollSchedule schedule) {
    return switch (schedule) {
      EmployeePayrollSchedule.weekly => RecurrenceSchedule.weekly,
      EmployeePayrollSchedule.biWeekly => RecurrenceSchedule.biweekly,
      EmployeePayrollSchedule.monthly => RecurrenceSchedule.monthly,
      EmployeePayrollSchedule.semiMonthly => RecurrenceSchedule.semiMonthly,
      EmployeePayrollSchedule.none => 'None',
    };
  }
}
