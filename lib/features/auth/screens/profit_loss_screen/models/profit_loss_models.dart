import 'package:savetep/features/auth/models/expense_category.dart';
import 'package:savetep/services/liability_service.dart';

class ProfitLossData {
  final List<DepositRecord> deposits;
  final List<ExpenseRecord> expenses;
  final List<ExpenseCategory> selectedExpenseCategories;

  const ProfitLossData({
    this.deposits = const <DepositRecord>[],
    this.expenses = const <ExpenseRecord>[],
    this.selectedExpenseCategories = const <ExpenseCategory>[],
  });
}

class ProfitLossReport {
  final int year;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String businessName;
  final double grossIncome;
  final List<ProfitLossExpenseLine> fixedExpenseLines;
  final List<ProfitLossExpenseLine> variableExpenseLines;
  final double fixedExpenseSubtotal;
  final double variableExpenseSubtotal;
  final double totalExpenses;
  final double netIncomeBeforeTaxes;
  final double estimatedTaxPercentage;
  final double estimatedTaxAmount;
  final double netIncomeAfterTaxes;

  const ProfitLossReport({
    required this.year,
    required this.periodStart,
    required this.periodEnd,
    required this.businessName,
    required this.grossIncome,
    required this.fixedExpenseLines,
    required this.variableExpenseLines,
    required this.fixedExpenseSubtotal,
    required this.variableExpenseSubtotal,
    required this.totalExpenses,
    required this.netIncomeBeforeTaxes,
    required this.estimatedTaxPercentage,
    required this.estimatedTaxAmount,
    required this.netIncomeAfterTaxes,
  });

  List<ProfitLossExpenseLine> get expenseLines =>
      List<ProfitLossExpenseLine>.unmodifiable(<ProfitLossExpenseLine>[
        ...fixedExpenseLines,
        ...variableExpenseLines,
      ]);
}

class ProfitLossExpenseLine {
  final ExpenseCategory category;
  final double amount;
  final DateTime periodStart;
  final DateTime periodEnd;

  const ProfitLossExpenseLine({
    required this.category,
    required this.amount,
    required this.periodStart,
    required this.periodEnd,
  });

  String get categoryId => category.id;

  String get label => category.name;

  String get reportCategory => category.name;

  bool get trackedInApp => true;
}
