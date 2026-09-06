import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/models/expense_category.dart';
import 'package:savetep/features/auth/screens/profit_loss_screen/models/profit_loss_models.dart';
import 'package:savetep/features/auth/screens/profit_loss_screen/services/profit_loss_report_service.dart';
import 'package:savetep/services/liability_service.dart';

void main() {
  const ProfitLossReportService service = ProfitLossReportService();

  test('saved expenses preserve their stable category ID', () async {
    LiabilityService.resetForTesting();
    addTearDown(
      () => LiabilityService.resetForTesting(disablePersistence: false),
    );

    await LiabilityService.saveExpense(
      checkNumber: 'stable-category',
      totalAmount: 25,
      transactionDate: DateTime(2026, 1, 1),
      categoryId: ExpenseCategory.office.id,
      category: 'Renamed office label',
      payee: 'Office',
      isManual: true,
    );

    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();
    expect(expenses.single.categoryId, ExpenseCategory.office.id);
  });

  test('groups only selected category IDs and combines both subtotals', () {
    final ProfitLossReport report = service.buildReport(
      data: ProfitLossData(
        deposits: <DepositRecord>[
          DepositRecord(
            id: 'deposit',
            orderNumber: '1',
            totalAmount: 10000,
            creditDeposit: 0,
            cash: 10000,
            giftCard: 0,
            other: 0,
            transactionDate: DateTime(2026, 1, 15),
            isManual: true,
          ),
        ],
        expenses: <ExpenseRecord>[
          _expense(ExpenseCategory.rents, 1200),
          _expense(ExpenseCategory.payrollWages, 3000),
          _expense(ExpenseCategory.gasForMileage, 400),
          _expense(ExpenseCategory.travel, 750),
          ExpenseRecord(
            id: 'wrong-office-id',
            checkNumber: '',
            totalAmount: 900,
            transactionDate: DateTime(2026, 1, 10),
            categoryId: ExpenseCategory.travel.id,
            category: ExpenseCategory.office.name,
            payee: 'Mismatched category',
            isManual: true,
          ),
        ],
        selectedExpenseCategories: const <ExpenseCategory>[
          ExpenseCategory.rents,
          ExpenseCategory.payrollWages,
          ExpenseCategory.gasForMileage,
          ExpenseCategory.office,
          ExpenseCategory.rents,
        ],
      ),
      year: 2026,
      periodStart: DateTime(2026),
      periodEnd: DateTime(2026, 12, 31),
      currentDate: DateTime(2026, 6, 15),
    );

    expect(
      report.fixedExpenseLines.map(
        (ProfitLossExpenseLine line) => line.categoryId,
      ),
      <String>[ExpenseCategory.rents.id, ExpenseCategory.payrollWages.id],
    );
    expect(
      report.variableExpenseLines.map(
        (ProfitLossExpenseLine line) => line.categoryId,
      ),
      <String>[ExpenseCategory.gasForMileage.id, ExpenseCategory.office.id],
    );
    expect(report.fixedExpenseSubtotal, 4200);
    expect(report.variableExpenseSubtotal, 400);
    expect(report.totalExpenses, 4600);
    expect(report.netIncomeBeforeTaxes, 5400);
    expect(report.variableExpenseLines.last.amount, 0);
  });

  test('uses selected category type when prorating a legacy record', () {
    final ProfitLossReport report = service.buildReport(
      data: ProfitLossData(
        expenses: <ExpenseRecord>[
          ExpenseRecord(
            id: 'legacy-payroll',
            checkNumber: '',
            totalAmount: 3000,
            transactionDate: DateTime(2026, 6, 1),
            category: ExpenseCategory.payrollWages.mindeeLabel,
            payee: 'Payroll',
            isManual: true,
          ),
        ],
        selectedExpenseCategories: const <ExpenseCategory>[
          ExpenseCategory.payrollWages,
        ],
      ),
      year: 2026,
      periodStart: DateTime(2026, 6, 1),
      periodEnd: DateTime(2026, 6, 15),
      currentDate: DateTime(2026, 6, 15),
    );

    expect(report.fixedExpenseSubtotal, 1500);
    expect(report.variableExpenseSubtotal, 0);
    expect(report.totalExpenses, 1500);
  });
}

ExpenseRecord _expense(ExpenseCategory category, double amount) {
  return ExpenseRecord(
    id: category.id,
    checkNumber: '',
    totalAmount: amount,
    transactionDate: DateTime(2026, 1, 1),
    categoryId: category.id,
    category: category.name,
    payee: category.name,
    isManual: true,
  );
}
