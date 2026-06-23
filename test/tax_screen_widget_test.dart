import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biztrack/features/auth/screens/tax_screen/tax_screen.dart';
import 'package:biztrack/services/app_clock.dart';
import 'package:biztrack/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
  });

  testWidgets('TaxScreen estimates tax rate from projected annual reserve', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveDeposit(
      orderNumber: 'tax-deposit',
      totalAmount: 50000,
      creditDeposit: 0,
      cash: 50000,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 1, 15),
      isManual: true,
    );

    await tester.pumpWidget(const MaterialApp(home: TaxScreen()));
    await tester.pumpAndSettle();

    expect(find.text(r'$45,000.00'), findsOneWidget);
    expect(find.text('Projected annual reserve \$90,000.00'), findsOneWidget);
    expect(find.text('22%'), findsWidgets);
    expect(find.text(r'$9,900.00'), findsOneWidget);
  });
}
