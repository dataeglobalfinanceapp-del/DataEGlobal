import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/payroll_screen/payroll_schedule_calculator.dart';
import 'package:savetep/services/app_clock.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15, 12));
  });

  tearDown(AppClock.reset);

  test('default biweekly period begin date is today minus two weeks', () {
    expect(
      PayrollScheduleCalculator.defaultBiweeklyPeriodBeginDate(),
      DateTime(2026, 6, 1),
    );
  });

  test(
    'biweekly period begin date is selectable in previous current and next month',
    () {
      expect(
        PayrollScheduleCalculator.earliestBiweeklyPeriodBeginDate(),
        DateTime(2026, 5),
      );
      expect(
        PayrollScheduleCalculator.latestBiweeklyPeriodBeginDate(),
        DateTime(2026, 7, 31),
      );
      expect(
        PayrollScheduleCalculator.isSelectableBiweeklyPeriodBeginDate(
          DateTime(2026, 4, 30),
        ),
        isFalse,
      );
      expect(
        PayrollScheduleCalculator.isSelectableBiweeklyPeriodBeginDate(
          DateTime(2026, 5, 1),
        ),
        isTrue,
      );
      expect(
        PayrollScheduleCalculator.isSelectableBiweeklyPeriodBeginDate(
          DateTime(2026, 7, 31),
        ),
        isTrue,
      );
      expect(
        PayrollScheduleCalculator.isSelectableBiweeklyPeriodBeginDate(
          DateTime(2026, 8, 1),
        ),
        isFalse,
      );
    },
  );

  test('biweekly pay period uses selected begin date for a 14 day range', () {
    final period = PayrollScheduleCalculator.calculateBiweeklyPayPeriod(
      beginDate: DateTime(2026, 6, 2),
    );

    expect(period.start, DateTime(2026, 6, 2));
    expect(period.end, DateTime(2026, 6, 15));
  });
}
