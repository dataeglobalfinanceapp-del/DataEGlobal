import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_period_calculator.dart';

void main() {
  test(
    'bi weekly periods start from date hire and advance by fourteen days',
    () {
      final setting = EmployeePayrollSetting(
        schedule: EmployeePayrollSchedule.biWeekly,
        endingDay: EmployeePayrollEndingDay.sunday,
        firstPeriodEndDate: DateTime(2026, 7, 19),
      );

      final firstPeriod = PayrollPeriodCalculator.currentPeriod(
        dateHire: '07/13/26',
        setting: setting,
        asOf: DateTime(2026, 7, 13),
      );
      final nextPeriod = PayrollPeriodCalculator.currentPeriod(
        dateHire: '07/13/26',
        setting: setting,
        asOf: DateTime(2026, 7, 20),
      );

      expect(firstPeriod?.displayText, '07/13/26 - 07/19/26');
      expect(nextPeriod?.displayText, '07/20/26 - 08/02/26');
    },
  );

  test('saved first period end date anchors bi weekly periods', () {
    final setting = EmployeePayrollSetting(
      schedule: EmployeePayrollSchedule.biWeekly,
      endingDay: EmployeePayrollEndingDay.sunday,
      firstPeriodEndDate: DateTime(2026, 7, 19),
    );

    final firstPeriod = PayrollPeriodCalculator.currentPeriod(
      dateHire: '07/06/26',
      setting: setting,
      asOf: DateTime(2026, 7, 15),
    );
    final nextPeriod = PayrollPeriodCalculator.currentPeriod(
      dateHire: '07/06/26',
      setting: setting,
      asOf: DateTime(2026, 7, 20),
    );

    expect(firstPeriod?.displayText, '07/06/26 - 07/19/26');
    expect(nextPeriod?.displayText, '07/20/26 - 08/02/26');
  });

  test('weekly periods advance by seven days on the selected ending day', () {
    final setting = EmployeePayrollSetting(
      schedule: EmployeePayrollSchedule.weekly,
      endingDay: EmployeePayrollEndingDay.friday,
      firstPeriodEndDate: DateTime(2026, 7, 17),
    );

    final period = PayrollPeriodCalculator.currentPeriod(
      dateHire: '07/13/2026',
      setting: setting,
      asOf: DateTime(2026, 7, 24),
    );

    expect(period?.displayText, '07/18/26 - 07/24/26');
    expect(period?.end.weekday, DateTime.friday);
  });

  test('monthly periods use the selected month ending day', () {
    final setting = EmployeePayrollSetting(
      schedule: EmployeePayrollSchedule.monthly,
      monthlyEndingDay: 25,
      firstPeriodEndDate: DateTime(2026, 7, 25),
    );

    final firstPeriod = PayrollPeriodCalculator.currentPeriod(
      dateHire: '07/13/2026',
      setting: setting,
      asOf: DateTime(2026, 7, 13),
    );
    final nextPeriod = PayrollPeriodCalculator.currentPeriod(
      dateHire: '07/13/2026',
      setting: setting,
      asOf: DateTime(2026, 7, 26),
    );

    expect(firstPeriod?.displayText, '07/13/26 - 07/25/26');
    expect(nextPeriod?.displayText, '07/26/26 - 08/25/26');
  });

  test('monthly first period moves to next month when ending day passed', () {
    final setting = EmployeePayrollSetting(
      schedule: EmployeePayrollSchedule.monthly,
      monthlyEndingDay: 25,
      firstPeriodEndDate: DateTime(2026, 8, 25),
    );

    final firstPeriod = PayrollPeriodCalculator.currentPeriod(
      dateHire: '07/26/2026',
      setting: setting,
      asOf: DateTime(2026, 7, 26),
    );

    expect(firstPeriod?.displayText, '07/26/26 - 08/25/26');
  });

  test('semi monthly periods advance to the next configured ending day', () {
    final setting = EmployeePayrollSetting(
      schedule: EmployeePayrollSchedule.semiMonthly,
      firstSemiMonthlyEndingDay: 15,
      secondSemiMonthlyEndingDay: 30,
      firstPeriodEndDate: DateTime(2026, 7, 15),
    );

    final firstPeriod = PayrollPeriodCalculator.currentPeriod(
      dateHire: '07/13/2026',
      setting: setting,
      asOf: DateTime(2026, 7, 13),
    );
    final nextPeriod = PayrollPeriodCalculator.currentPeriod(
      dateHire: '07/13/2026',
      setting: setting,
      asOf: DateTime(2026, 7, 16),
    );

    expect(firstPeriod?.displayText, '07/13/26 - 07/15/26');
    expect(nextPeriod?.displayText, '07/16/26 - 07/30/26');
  });

  test('monthly ending days clamp to the last day of short months', () {
    final firstPeriodEnd =
        PayrollPeriodCalculator.firstPeriodEndDateForMonthlyEndingDay(
          hireDate: DateTime(2026, 2, 1),
          endingDay: 31,
        );

    expect(firstPeriodEnd, DateTime(2026, 2, 28));
  });

  test('period end dates for year use configured payroll schedule', () {
    final setting = EmployeePayrollSetting(
      schedule: EmployeePayrollSchedule.semiMonthly,
      firstSemiMonthlyEndingDay: 10,
      secondSemiMonthlyEndingDay: 25,
      firstPeriodEndDate: DateTime(2026, 7, 25),
    );

    final dates = PayrollPeriodCalculator.periodEndDatesForYear(
      dateHire: '07/13/2026',
      setting: setting,
      year: 2026,
    );

    expect(dates.take(5).map(PayrollPeriodCalculator.formatShortDate), <String>[
      '07/25/26',
      '08/10/26',
      '08/25/26',
      '09/10/26',
      '09/25/26',
    ]);
  });
}
