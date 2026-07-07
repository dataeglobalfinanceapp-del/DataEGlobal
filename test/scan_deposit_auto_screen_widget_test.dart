import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/scan_screen/deposit_screen/scan_deposit_auto_screen.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 7, 7));
    LiabilityService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
  });

  testWidgets('auto deposit entry card is editable before scanning', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScanDepositAutoScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Don't allow"));
    await tester.pumpAndSettle();

    expect(find.text('MANUAL ENTRY'), findsOneWidget);
    expect(find.text('EDITABLE'), findsOneWidget);
    expect(find.text('ORDER NUMBER:'), findsOneWidget);
    expect(find.text('TOTAL AMOUNT'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'M-100');
    await tester.enterText(find.byType(TextField).at(1), '120.50');
    await tester.enterText(find.byType(TextField).at(2), '10.00');
    await tester.pump();

    expect(find.text(r'$130.50'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Review Deposit'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    final List<DepositRecord> deposits = await LiabilityService.loadDeposits();
    expect(deposits, hasLength(1));
    expect(deposits.single.orderNumber, 'M-100');
    expect(deposits.single.totalAmount, 130.50);
    expect(deposits.single.creditDeposit, 120.50);
    expect(deposits.single.cash, 10.00);
    expect(deposits.single.isManual, isTrue);
    expect(deposits.single.transactionDate, DateTime(2026, 7, 7));
  });
}
