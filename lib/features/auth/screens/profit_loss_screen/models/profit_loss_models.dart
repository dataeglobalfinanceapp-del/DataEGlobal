import 'package:savetep/services/liability_service.dart';

class ProfitLossData {
  final List<DepositRecord> deposits;
  final List<ExpenseRecord> expenses;

  const ProfitLossData({
    this.deposits = const <DepositRecord>[],
    this.expenses = const <ExpenseRecord>[],
  });
}

class ProfitLossReport {
  final int year;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String businessName;
  final double grossIncome;
  final List<ProfitLossExpenseLine> expenseLines;
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
    required this.expenseLines,
    required this.totalExpenses,
    required this.netIncomeBeforeTaxes,
    required this.estimatedTaxPercentage,
    required this.estimatedTaxAmount,
    required this.netIncomeAfterTaxes,
  });
}

class ProfitLossExpenseLine {
  final String label;
  final double amount;
  final bool trackedInApp;
  final String? reportCategory;
  final DateTime periodStart;
  final DateTime periodEnd;

  const ProfitLossExpenseLine({
    required this.label,
    required this.amount,
    required this.trackedInApp,
    required this.reportCategory,
    required this.periodStart,
    required this.periodEnd,
  });
}
