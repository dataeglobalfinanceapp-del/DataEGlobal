import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/home_screen/home_screen.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';

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

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('SaveTep'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Profit &\nLoss'), findsOneWidget);
    expect(find.text('Investments'), findsOneWidget);
    expect(find.text('TRANSACTION'), findsNothing);
    expect(_actionGridDelegate(tester).crossAxisCount, 4);
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
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_actionGridDelegate(tester).crossAxisCount, testCase.columns);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
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
