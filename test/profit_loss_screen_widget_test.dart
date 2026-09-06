import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/models/expense_category.dart';
import 'package:savetep/features/auth/screens/profit_loss_screen/profit_loss_screen.dart';
import 'package:savetep/features/auth/screens/transaction_screen/transaction_screen.dart';
import 'package:savetep/features/auth/services/expense_category_service.dart';
import 'package:savetep/providers/expense_category_provider.dart';
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

  testWidgets('ProfitLossScreen renders yearly profit and loss statement', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveDeposit(
      orderNumber: 'profit-loss-deposit',
      totalAmount: 50000,
      creditDeposit: 0,
      cash: 50000,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 1, 15),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'payroll',
      totalAmount: 10000,
      transactionDate: DateTime(2026, 2, 1),
      categoryId: ExpenseCategory.payrollWages.id,
      category: ExpenseCategory.payrollWages.name,
      payee: 'Payroll',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'gas',
      totalAmount: 500,
      transactionDate: DateTime(2026, 3, 1),
      categoryId: ExpenseCategory.gasForMileage.id,
      category: ExpenseCategory.gasForMileage.name,
      payee: 'Gas Stop',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'unselected-travel',
      totalAmount: 750,
      transactionDate: DateTime(2026, 4, 1),
      categoryId: ExpenseCategory.travel.id,
      category: ExpenseCategory.travel.name,
      payee: 'Unselected Travel',
      isManual: true,
    );

    await _pumpProfitLossScreen(
      tester,
      selectedCategoryIds: <String>{
        ExpenseCategory.rents.id,
        ExpenseCategory.payrollWages.id,
        ExpenseCategory.gasForMileage.id,
        ExpenseCategory.office.id,
      },
    );

    expect(find.text('Profit and Loss'), findsOneWidget);
    expect(find.text('Profit and Loss Statement 2026'), findsOneWidget);
    expect(find.text('Period Start'), findsOneWidget);
    expect(find.text('01/01/2026'), findsOneWidget);
    expect(find.text('Period End'), findsOneWidget);
    expect(find.text('12/31/2026'), findsOneWidget);
    expect(find.text('Business Name'), findsOneWidget);
    expect(find.text('Save Tep'), findsOneWidget);
    expect(find.text('Gross Income'), findsOneWidget);
    expect(find.text(r'$50,000.00'), findsNWidgets(2));
    expect(find.text('FIXED EXPENSE'), findsOneWidget);
    expect(find.text(ExpenseCategory.rents.name), findsOneWidget);
    expect(find.text(ExpenseCategory.payrollWages.name), findsOneWidget);
    expect(find.text('Fixed Expense Subtotal'), findsOneWidget);
    expect(find.text(r'$10,000.00'), findsNWidgets(2));
    expect(find.text('VARIABLE EXPENSE'), findsOneWidget);
    expect(find.text(ExpenseCategory.gasForMileage.name), findsOneWidget);
    expect(find.text(ExpenseCategory.office.name), findsOneWidget);
    expect(find.text('Variable Expense Subtotal'), findsOneWidget);
    expect(find.text(r'$500.00'), findsNWidgets(2));
    expect(find.text(r'$0.00'), findsNWidgets(2));
    expect(find.text(ExpenseCategory.travel.name), findsNothing);
    expect(find.text('Total Expenses'), findsOneWidget);
    expect(find.text(r'$10,500.00'), findsOneWidget);
    expect(find.text('Net Income Before Taxes'), findsOneWidget);
    expect(find.text(r'$39,500.00'), findsOneWidget);
    expect(find.text('Estimated Tax Percentage'), findsOneWidget);
    expect(find.text('22%'), findsWidgets);
    expect(find.text('Estimated Tax Amount'), findsOneWidget);
    expect(find.text(r'$8,690.00'), findsOneWidget);
    expect(find.text('Net Income After Taxes'), findsOneWidget);
    expect(find.text(r'$30,810.00'), findsOneWidget);

    final table = tester.widget<Table>(find.byType(Table));
    expect(table.children.every((row) => row.children.length == 2), isTrue);
  });

  testWidgets('ProfitLossScreen renders at a narrow mobile width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpProfitLossScreen(
      tester,
      selectedCategoryIds: <String>{ExpenseCategory.rents.id},
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Profit and Loss Statement 2026'), findsOneWidget);
    expect(find.text(ExpenseCategory.rents.name), findsOneWidget);
  });

  testWidgets(
    'ProfitLossScreen filters by date range and prorates fixed costs',
    (WidgetTester tester) async {
      await LiabilityService.saveDeposit(
        orderNumber: 'range-deposit',
        totalAmount: 15000,
        creditDeposit: 15000,
        cash: 0,
        giftCard: 0,
        other: 0,
        transactionDate: DateTime(2026, 6, 10),
        isManual: true,
      );
      await LiabilityService.saveDeposit(
        orderNumber: 'outside-deposit',
        totalAmount: 50000,
        creditDeposit: 50000,
        cash: 0,
        giftCard: 0,
        other: 0,
        transactionDate: DateTime(2026, 5, 31),
        isManual: true,
      );
      await LiabilityService.saveExpense(
        checkNumber: 'payroll',
        totalAmount: 3000,
        transactionDate: DateTime(2026, 6, 1),
        categoryId: ExpenseCategory.payrollWages.id,
        category: ExpenseCategory.payrollWages.name,
        payee: 'Payroll',
        isManual: true,
      );
      await LiabilityService.saveExpense(
        checkNumber: 'gas-in-range',
        totalAmount: 100,
        transactionDate: DateTime(2026, 6, 10),
        categoryId: ExpenseCategory.gasForMileage.id,
        category: ExpenseCategory.gasForMileage.name,
        payee: 'Gas Stop',
        isManual: true,
      );
      await LiabilityService.saveExpense(
        checkNumber: 'gas-outside-range',
        totalAmount: 600,
        transactionDate: DateTime(2026, 5, 31),
        categoryId: ExpenseCategory.gasForMileage.id,
        category: ExpenseCategory.gasForMileage.name,
        payee: 'Gas Stop',
        isManual: true,
      );

      await _pumpProfitLossScreen(
        tester,
        selectedCategoryIds: <String>{
          ExpenseCategory.payrollWages.id,
          ExpenseCategory.gasForMileage.id,
        },
        initialDateRange: DateTimeRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 15),
        ),
      );

      expect(find.text('06/01/2026 - 06/15/2026'), findsOneWidget);
      expect(find.text('06/01/2026'), findsOneWidget);
      expect(find.text('06/15/2026'), findsOneWidget);
      expect(find.text(r'$15,000.00'), findsNWidgets(2));
      expect(find.text(ExpenseCategory.payrollWages.name), findsOneWidget);
      expect(find.text(r'$1,500.00'), findsNWidgets(2));
      expect(find.text(ExpenseCategory.gasForMileage.name), findsOneWidget);
      expect(find.text(r'$100.00'), findsNWidgets(2));
      expect(find.text(r'$600.00'), findsNothing);
      expect(find.text(r'$50,000.00'), findsNothing);
      expect(find.text(r'$1,600.00'), findsOneWidget);
    },
  );

  testWidgets('ProfitLossScreen category link opens matching expense report', (
    WidgetTester tester,
  ) async {
    await LiabilityService.saveExpense(
      checkNumber: 'gas-in-range',
      totalAmount: 45,
      transactionDate: DateTime(2026, 6, 12),
      categoryId: ExpenseCategory.gasForMileage.id,
      category: ExpenseCategory.gasForMileage.name,
      payee: 'Gas Stop',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'gas-outside-range',
      totalAmount: 90,
      transactionDate: DateTime(2026, 6, 20),
      categoryId: ExpenseCategory.gasForMileage.id,
      category: ExpenseCategory.gasForMileage.name,
      payee: 'Gas Later',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'rent-in-range',
      totalAmount: 300,
      transactionDate: DateTime(2026, 6, 10),
      categoryId: ExpenseCategory.rents.id,
      category: ExpenseCategory.rents.name,
      payee: 'Studio Rent',
      isManual: true,
    );

    await _pumpProfitLossScreen(
      tester,
      selectedCategoryIds: <String>{
        ExpenseCategory.rents.id,
        ExpenseCategory.gasForMileage.id,
      },
      initialDateRange: DateTimeRange(
        start: DateTime(2026, 6, 10),
        end: DateTime(2026, 6, 15),
      ),
      routes: <String, WidgetBuilder>{
        '/transactions': (BuildContext context) {
          final arguments =
              ModalRoute.of(context)!.settings.arguments
                  as TransactionScreenArguments;
          return TransactionScreen(
            initialExpenseCategory: arguments.initialExpenseCategory,
            initialExpenseDateRange: arguments.initialExpenseDateRange,
          );
        },
      },
    );

    await tester.dragUntilVisible(
      find.text(ExpenseCategory.gasForMileage.name),
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    final gasLink = tester.widget<Text>(
      find.text(ExpenseCategory.gasForMileage.name),
    );
    expect(gasLink.style?.decoration, TextDecoration.underline);

    await tester.tap(find.text(ExpenseCategory.gasForMileage.name));
    await tester.pumpAndSettle();

    expect(find.text('Transaction'), findsOneWidget);
    expect(find.text('06/10/2026 - 06/15/2026'), findsOneWidget);
    expect(
      find.text('${ExpenseCategory.gasForMileage.name} total'),
      findsOneWidget,
    );
    expect(find.text(r'$45.00'), findsWidgets);

    await tester.dragUntilVisible(
      find.text('June'),
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('June'));
    await tester.pumpAndSettle();

    expect(find.text('Gas Stop'), findsOneWidget);
    expect(find.text('Gas Later'), findsNothing);
    expect(find.text('Studio Rent'), findsNothing);
  });

  testWidgets('ProfitLossScreen refreshes changed account categories', (
    WidgetTester tester,
  ) async {
    final _FakeExpenseCategoryRepository repository =
        _FakeExpenseCategoryRepository(<String>{ExpenseCategory.rents.id});
    await LiabilityService.saveExpense(
      checkNumber: 'rent',
      totalAmount: 100,
      transactionDate: DateTime(2026, 6, 1),
      categoryId: ExpenseCategory.rents.id,
      category: ExpenseCategory.rents.name,
      payee: 'Rent',
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'office',
      totalAmount: 200,
      transactionDate: DateTime(2026, 6, 1),
      categoryId: ExpenseCategory.office.id,
      category: ExpenseCategory.office.name,
      payee: 'Office',
      isManual: true,
    );

    await _pumpProfitLossScreen(tester, repository: repository);

    expect(find.text(ExpenseCategory.rents.name), findsOneWidget);
    expect(find.text(ExpenseCategory.office.name), findsNothing);

    repository.selectedCategoryIds = <String>{ExpenseCategory.office.id};
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text(ExpenseCategory.rents.name), findsNothing);
    expect(find.text(ExpenseCategory.office.name), findsOneWidget);
    expect(find.text(r'$200.00'), findsNWidgets(3));
  });
}

Future<void> _pumpProfitLossScreen(
  WidgetTester tester, {
  Set<String> selectedCategoryIds = const <String>{},
  ExpenseCategoryRepository? repository,
  DateTimeRange? initialDateRange,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseCategoryRepositoryProvider.overrideWithValue(
          repository ?? _FakeExpenseCategoryRepository(selectedCategoryIds),
        ),
      ],
      child: MaterialApp(
        home: ProfitLossScreen(initialDateRange: initialDateRange),
        routes: routes,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeExpenseCategoryRepository implements ExpenseCategoryRepository {
  Set<String> selectedCategoryIds;

  _FakeExpenseCategoryRepository(this.selectedCategoryIds);

  @override
  Future<List<ExpenseCategory>> loadActiveCategories() async {
    return ExpenseCategory.onboardingCategories
        .where(
          (ExpenseCategory category) =>
              selectedCategoryIds.contains(category.id),
        )
        .toList(growable: false);
  }

  @override
  Future<Set<String>?> loadSelectedCategoryIds() async {
    return Set<String>.of(selectedCategoryIds);
  }

  @override
  Future<void> saveSelectedCategoryIds(Set<String> selectedCategoryIds) async {
    this.selectedCategoryIds = Set<String>.of(selectedCategoryIds);
  }
}
