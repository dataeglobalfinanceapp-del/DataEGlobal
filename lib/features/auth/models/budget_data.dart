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
  final double deposit;
  final double expense;
  final double total;
  final String period;
  final int surplusPercent;
  final int utilizationPercent;
  final List<BudgetCategory> categories;

  const BudgetData({
    this.deposit = 0,
    this.expense = 0,
    this.total = 0,
    this.period = '',
    this.surplusPercent = 0,
    this.utilizationPercent = 0,
    this.categories = const [],
  });

  double get reserve => deposit - expense;

  bool get hasActivity => total > 0 || expense > 0 || deposit != 0;
}
