import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/saving_screen/saving_rollover_calculator.dart';

void main() {
  test('combines incomplete past periods into the nearest due period', () {
    final amounts = calculateSavingRequiredAmounts(
      periods: [
        _period(day: 1, required: 100, saved: 60),
        _period(day: 2, required: 100, saved: 70),
        _period(day: 3, required: 100),
        _period(day: 4, required: 100),
      ],
      today: DateTime(2026, 1, 3),
    );

    expect(amounts, [100, 100, 170, 100]);
  });

  test('later past savings fulfill rollover without crediting the future', () {
    final fulfilled = calculateSavingRequiredAmounts(
      periods: [
        _period(day: 1, required: 100, saved: 60),
        _period(day: 2, required: 100, saved: 140),
        _period(day: 3, required: 100),
      ],
      today: DateTime(2026, 1, 3),
    );
    final overpaid = calculateSavingRequiredAmounts(
      periods: [
        _period(day: 1, required: 100, saved: 120),
        _period(day: 2, required: 100),
      ],
      today: DateTime(2026, 1, 2),
    );

    expect(fulfilled, [100, 100, 100]);
    expect(overpaid, [100, 100]);
  });

  test('recalculation replaces rather than duplicates an overdue amount', () {
    final periods = [
      _period(day: 1, required: 100, saved: 60),
      _period(day: 2, required: 100),
    ];

    expect(
      calculateSavingRequiredAmounts(
        periods: periods,
        today: DateTime(2026, 1, 2),
      ),
      [100, 140],
    );
    expect(
      calculateSavingRequiredAmounts(
        periods: periods,
        today: DateTime(2026, 1, 2),
      ),
      [100, 140],
    );
  });

  test('uses period end dates for weekly and monthly rollover', () {
    final weekly = calculateSavingRequiredAmounts(
      periods: [
        _period(day: 7, required: 200, saved: 150),
        _period(day: 14, required: 200),
      ],
      today: DateTime(2026, 1, 10),
    );
    final monthly = calculateSavingRequiredAmounts(
      periods: [
        SavingRolloverPeriod(
          end: DateTime(2026, 1, 31),
          requiredAmount: 1000,
          savedAmount: 400,
        ),
        SavingRolloverPeriod(
          end: DateTime(2026, 2, 28),
          requiredAmount: 1000,
          savedAmount: 0,
        ),
      ],
      today: DateTime(2026, 2, 10),
    );

    expect(weekly, [200, 250]);
    expect(monthly, [1000, 1600]);
  });
}

SavingRolloverPeriod _period({
  required int day,
  required double required,
  double saved = 0,
}) {
  return SavingRolloverPeriod(
    end: DateTime(2026, 1, day),
    requiredAmount: required,
    savedAmount: saved,
  );
}
