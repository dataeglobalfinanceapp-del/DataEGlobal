import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/payroll_screen/payroll_models.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_pay_date_validator.dart';
import 'package:savetep/services/app_clock.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15, 14, 30));
  });

  tearDown(AppClock.reset);

  test('pay dates are selectable only after today', () {
    expect(
      PayrollPayDateValidator.firstSelectablePayDate(),
      DateTime(2026, 6, 16),
    );
    expect(
      PayrollPayDateValidator.isSelectablePayDate(DateTime(2026, 6, 15)),
      isFalse,
    );
    expect(
      PayrollPayDateValidator.isSelectablePayDate(DateTime(2026, 6, 14)),
      isFalse,
    );
    expect(
      PayrollPayDateValidator.isSelectablePayDate(DateTime(2026, 6, 16)),
      isTrue,
    );
  });

  test('normalizes invalid pay dates to tomorrow', () {
    expect(
      PayrollPayDateValidator.normalizePayDate(DateTime(2026, 6, 1)),
      DateTime(2026, 6, 16),
    );
    expect(
      PayrollPayDateValidator.normalizePayDate(DateTime(2026, 6, 15)),
      DateTime(2026, 6, 16),
    );
    expect(
      PayrollPayDateValidator.normalizePayDate(DateTime(2026, 6, 20)),
      DateTime(2026, 6, 20),
    );
  });

  test('payroll records normalize draft and loaded pay dates', () {
    final draft = PayrollRecord.draft(id: 'payroll-draft');
    final loaded = PayrollRecord.fromJson(const <String, Object?>{
      'id': 'payroll-loaded',
      'payDate': '2026-06-15T00:00:00.000',
      'employees': <Object?>[],
    });

    expect(draft.payDate, DateTime(2026, 6, 16));
    expect(loaded.payDate, DateTime(2026, 6, 16));
  });
}
