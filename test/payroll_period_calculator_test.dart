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
}
