import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/home_screen/home_screen.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/theme/dark_contrast.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
  });

  testWidgets('HomeScreen uses a responsive iPhone action layout', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('SaveTep'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Profit &\nLoss'), findsOneWidget);
    expect(find.text('Investments'), findsOneWidget);
    expect(find.text('TRANSACTION'), findsNothing);
    expect(_actionGridDelegate(tester).crossAxisCount, 4);
    _expectBudgetCardsAlignedWithDateRange(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('HomeScreen shows estimated tax at year end in balance summary', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await LiabilityService.saveDeposit(
      orderNumber: 'A100',
      totalAmount: 125,
      creditDeposit: 100,
      cash: 25,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 12),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'E200',
      totalAmount: 45,
      transactionDate: DateTime(2026, 6, 13),
      category: 'Fuel',
      payee: 'Fuel Stop',
      isManual: true,
    );

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('TOTAL BALANCE'), findsOneWidget);
    expect(find.text('ESTIMATED TAX AT YEAR END'), findsOneWidget);
    expect(find.text(r'$80.00'), findsOneWidget);
    expect(find.text(r'$8.00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('HomeScreen action grid follows responsive breakpoints', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const cases = <_GridBreakpointCase>[
      _GridBreakpointCase(Size(350, 780), 3),
      _GridBreakpointCase(Size(768, 1024), 5),
      _GridBreakpointCase(Size(920, 1024), 6),
    ];

    for (final testCase in cases) {
      tester.view.physicalSize = testCase.size;
      await _pumpHomeScreen(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '${testCase.size}');
      expect(_actionGridDelegate(tester).crossAxisCount, testCase.columns);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

Future<void> _pumpHomeScreen(WidgetTester tester) async {
  final controller = DarkContrastController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    DarkContrastScope(
      controller: controller,
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
}

class _GridBreakpointCase {
  final Size size;
  final int columns;

  const _GridBreakpointCase(this.size, this.columns);
}

SliverGridDelegateWithFixedCrossAxisCount _actionGridDelegate(
  WidgetTester tester,
) {
  final GridView grid = tester.widget<GridView>(find.byType(GridView));
  return grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
}

void _expectBudgetCardsAlignedWithDateRange(WidgetTester tester) {
  final dateRangeRect = tester.getRect(
    find.byKey(const ValueKey('home.dateRangeCard')),
  );
  final totalBalanceRect = tester.getRect(
    find.byKey(const ValueKey('home.totalBalanceCard')),
  );
  final overviewRect = tester.getRect(
    find.byKey(const ValueKey('home.overviewCard')),
  );

  for (final cardRect in <Rect>[totalBalanceRect, overviewRect]) {
    expect(cardRect.left, moreOrLessEquals(dateRangeRect.left));
    expect(cardRect.right, moreOrLessEquals(dateRangeRect.right));
    expect(cardRect.width, moreOrLessEquals(dateRangeRect.width));
  }
}
