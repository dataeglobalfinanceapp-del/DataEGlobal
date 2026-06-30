import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/payroll_screen/payroll_controller.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_service.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
    PayrollService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
    PayrollService.resetForTesting(disablePersistence: false);
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
}
