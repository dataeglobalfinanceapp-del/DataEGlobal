import 'package:savetep/features/auth/models/budget_data.dart';
import 'package:savetep/features/auth/screens/home_screen/budget_donut_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BudgetDonutChart renders synchronized budget details', (
    WidgetTester tester,
  ) async {
    const data = BudgetData(
      deposit: 1000,
      expense: 400,
      total: 1000,
      surplusPercent: 60,
      utilizationPercent: 40,
      categories: [
        BudgetCategory(
          label: 'Payroll',
          percentage: 60,
          color: Color(0xFF006B5F),
        ),
        BudgetCategory(label: 'Rent', percentage: 40, color: Color(0xFF10B981)),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 390, child: BudgetDonutChart(data: data)),
          ),
        ),
      ),
    );

    expect(find.text('OVERVIEW'), findsOneWidget);
    expect(find.text('TOTAL EXPENSE'), findsOneWidget);
    expect(find.text('TOTAL DEPOSIT'), findsOneWidget);
    expect(find.text('Payroll'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text(r'$1,000.00'), findsWidgets);
    expect(find.text(r'$900.00'), findsNothing);
    expect(find.text(r'$400.00'), findsOneWidget);
    expect(find.text(r'$600.00'), findsWidgets);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('40% utilized'), findsOneWidget);
    expect(find.text('Deposits'), findsNothing);
    expect(find.text('Expenses'), findsNothing);
  });

  testWidgets('BudgetDonutChart fits a compact mobile width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const data = BudgetData(
      deposit: 100000,
      expense: 13000,
      total: 100000,
      surplusPercent: 87,
      utilizationPercent: 13,
      categories: [
        BudgetCategory(
          label: 'Utilities',
          percentage: 76.9,
          color: Color(0xFF64748B),
        ),
        BudgetCategory(
          label: 'Insurance',
          percentage: 23.1,
          color: Color(0xFF1464F4),
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 320, child: BudgetDonutChart(data: data)),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('OVERVIEW'), findsOneWidget);
    expect(find.text(r'$100,000.00'), findsWidgets);
    expect(find.text(r'$90,000.00'), findsNothing);
    expect(find.text(r'$87,000.00'), findsWidgets);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('13% utilized'), findsOneWidget);
  });
}
