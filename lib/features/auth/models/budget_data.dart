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

class RecurringExpenseBudgetItem {
  final String id;
  final String label;
  final String category;
  final double amount;
  final DateTime transactionDate;

  const RecurringExpenseBudgetItem({
    required this.id,
    required this.label,
    required this.category,
    required this.amount,
    required this.transactionDate,
  });
}

class BudgetData {
  final double deposit;
  final double expense;
  final double total;
  final String period;
  final int surplusPercent;
  final int utilizationPercent;
  final int transactionCount;
  final List<BudgetCategory> categories;
  final List<RecurringExpenseBudgetItem> recurringExpenses;

  const BudgetData({
    this.deposit = 0,
    this.expense = 0,
    this.total = 0,
    this.period = '',
    this.surplusPercent = 0,
    this.utilizationPercent = 0,
    this.transactionCount = 0,
    this.categories = const [],
    this.recurringExpenses = const [],
  });

  double get reserve => deposit - expense;

  bool get hasActivity => total > 0 || expense > 0 || deposit != 0;
}
