import 'package:flutter/material.dart';

class BudgetCategory {
  final String label;
  final double percentage;
  final Color color;

  const BudgetCategory({
    required this.label,
    required this.percentage,
    required this.color,
  });
}

class BudgetData {
  final double available;
  final double spent;
  final double total;
  final String period;
  final int surplusPercent;
  final int utilizationPercent;
  final List<BudgetCategory> categories;

  const BudgetData({
    this.available = 101.00,
    this.spent = 1249.00,
    this.total = 1500.00,
    this.period = '02/01 - 02/07, 2026',
    this.surplusPercent = 10,
    this.utilizationPercent = 96,
    this.categories = const [
      BudgetCategory(label: 'Payroll',             percentage: 60, color: Color(0xFF2563EB)),
      BudgetCategory(label: 'Rent',                percentage: 8,  color: Color(0xFF3B82F6)),
      BudgetCategory(label: 'Insurance',           percentage: 3,  color: Color(0xFF60A5FA)),
      BudgetCategory(label: 'Consumable\nSupplies',percentage: 3,  color: Color(0xFF93C5FD)),
      BudgetCategory(label: 'Utilities',           percentage: 3,  color: Color(0xFFBFDBFE)),
      BudgetCategory(label: 'Fuel',                percentage: 5,  color: Color(0xFFEF4444)),
      BudgetCategory(label: 'COGS',                percentage: 4,  color: Color(0xFF1E3A5F)),
      BudgetCategory(label: 'Other',               percentage: 1,  color: Color(0xFF374151)),
      BudgetCategory(label: 'Loan\nObligations',   percentage: 7,  color: Color(0xFFDC2626)),
      BudgetCategory(label: 'Equipment',           percentage: 2,  color: Color(0xFF1D4ED8)),
    ],
  });
}
