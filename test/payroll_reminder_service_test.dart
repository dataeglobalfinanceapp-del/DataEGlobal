import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_models.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_reminder_service.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/reminder_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 7, 15));
    ReminderService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    ReminderService.resetForTesting(disablePersistence: false);
  });

  test(
    'sync creates employee payroll reminders through the current year',
    () async {
      await PayrollReminderService.syncEmployee(
        PayrollEmployee(
          id: 'employee-maya',
          name: 'Maya Rodriguez',
          dateHire: '07/06/26',
          payrollSetting: EmployeePayrollSetting(
            schedule: EmployeePayrollSchedule.biWeekly,
            endingDay: EmployeePayrollEndingDay.sunday,
            firstPeriodEndDate: DateTime(2026, 7, 19),
          ),
        ),
      );

      final List<ReminderRecord> reminders =
          await ReminderService.loadReminders();

      expect(_dateKeys(reminders), <String>[
        '2026-07-19',
        '2026-08-02',
        '2026-08-16',
        '2026-08-30',
        '2026-09-13',
        '2026-09-27',
        '2026-10-11',
        '2026-10-25',
        '2026-11-08',
        '2026-11-22',
        '2026-12-06',
        '2026-12-20',
      ]);
      expect(
        reminders.map((ReminderRecord record) => record.payee).toSet(),
        <String>{'Do payroll for Maya Rodriguez'},
      );
      expect(
        reminders.map((ReminderRecord record) => record.category).toSet(),
        <String>{'Payroll'},
      );
      expect(
        reminders.map((ReminderRecord record) => record.reminderCount).toSet(),
        <String>{'Biweekly'},
      );
      expect(
        reminders.every((ReminderRecord record) => record.isPayrollReminder),
        true,
      );

      await PayrollReminderService.syncEmployee(
        PayrollEmployee(
          id: 'employee-maya',
          name: 'Maya Rodriguez',
          dateHire: '07/06/26',
          payrollSetting: EmployeePayrollSetting(
            schedule: EmployeePayrollSchedule.biWeekly,
            endingDay: EmployeePayrollEndingDay.sunday,
            firstPeriodEndDate: DateTime(2026, 7, 19),
          ),
        ),
      );

      expect(
        _dateKeys(await ReminderService.loadReminders()),
        _dateKeys(reminders),
      );
    },
  );

  test(
    'setup changes keep past payroll reminders and replace future ones',
    () async {
      final PayrollEmployee employee = PayrollEmployee(
        id: 'employee-maya',
        name: 'Maya Rodriguez',
        dateHire: '07/06/26',
        payrollSetting: EmployeePayrollSetting(
          schedule: EmployeePayrollSchedule.biWeekly,
          endingDay: EmployeePayrollEndingDay.sunday,
          firstPeriodEndDate: DateTime(2026, 7, 19),
        ),
      );

      await PayrollReminderService.syncEmployee(employee);

      AppClock.set(DateTime(2026, 8, 1));
      await PayrollReminderService.syncEmployee(
        employee.copyWith(
          payrollSetting: employee.payrollSetting?.copyWith(
            remindAfterPeriodEndDays: 2,
          ),
        ),
      );

      final List<String> dateKeys = _dateKeys(
        await ReminderService.loadReminders(),
      );
      expect(dateKeys, contains('2026-07-19'));
      expect(dateKeys, isNot(contains('2026-08-02')));
      expect(dateKeys, contains('2026-08-04'));
      expect(dateKeys, contains('2026-08-18'));
    },
  );

  test('new year sync adds reminders for the new current year', () async {
    final PayrollEmployee employee = PayrollEmployee(
      id: 'employee-maya',
      name: 'Maya Rodriguez',
      dateHire: '07/06/26',
      payrollSetting: EmployeePayrollSetting(
        schedule: EmployeePayrollSchedule.biWeekly,
        endingDay: EmployeePayrollEndingDay.sunday,
        firstPeriodEndDate: DateTime(2026, 7, 19),
      ),
    );

    await PayrollReminderService.syncEmployee(employee);

    AppClock.set(DateTime(2027, 1, 1));
    await PayrollReminderService.syncEmployee(employee);

    final List<String> dateKeys = _dateKeys(
      await ReminderService.loadReminders(),
    );
    expect(dateKeys, contains('2026-12-20'));
    expect(dateKeys, contains('2027-01-03'));
    expect(dateKeys, contains('2027-12-19'));
    expect(dateKeys, isNot(contains('2028-01-02')));
  });
}

List<String> _dateKeys(List<ReminderRecord> reminders) {
  return reminders
      .map((ReminderRecord record) => _dateKey(record.date))
      .toList();
}

String _dateKey(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
