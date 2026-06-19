import 'package:flutter/material.dart';

import '../../../services/deposit_allocation.dart';

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

class BudgetSeedDeposit {
  final int dayOfMonth;
  final String label;
  final double creditDeposit;
  final double cash;
  final double giftCard;
  final double other;

  const BudgetSeedDeposit({
    required this.dayOfMonth,
    required this.label,
    this.creditDeposit = 0,
    this.cash = 0,
    this.giftCard = 0,
    this.other = 0,
  });

  double get totalAmount => creditDeposit + cash + giftCard + other;
}

class BudgetSeedExpense {
  final int dayOfMonth;
  final String category;
  final double amount;
  final String payee;
  final bool isRecurringMonthly;

  const BudgetSeedExpense({
    required this.dayOfMonth,
    required this.category,
    required this.amount,
    this.payee = '',
    this.isRecurringMonthly = false,
  });
}

class DefaultBudgetSeedData {
  static const int version = 1;

  static const List<BudgetSeedDeposit> deposits = [
    BudgetSeedDeposit(dayOfMonth: 1, label: 'Cash', cash: 100000),
    BudgetSeedDeposit(dayOfMonth: 15, label: 'Credit', creditDeposit: 20000),
  ];

  static const List<BudgetSeedExpense> expenses = [
    BudgetSeedExpense(dayOfMonth: 5, category: 'Payroll', amount: 20000),
    BudgetSeedExpense(dayOfMonth: 17, category: 'Payroll', amount: 22000),
    BudgetSeedExpense(dayOfMonth: 10, category: 'Utilities', amount: 1200),
    BudgetSeedExpense(dayOfMonth: 16, category: 'Equipment', amount: 800),
    BudgetSeedExpense(dayOfMonth: 9, category: 'COGS', amount: 3000),
    BudgetSeedExpense(
      dayOfMonth: 2,
      category: 'Insurance',
      amount: 3000,
      isRecurringMonthly: true,
    ),
    BudgetSeedExpense(
      dayOfMonth: 2,
      category: 'Consumable Supplies',
      amount: 3185.82,
    ),
    BudgetSeedExpense(
      dayOfMonth: 10,
      category: 'Consumable Supplies',
      amount: 3000.27,
    ),
    BudgetSeedExpense(
      dayOfMonth: 17,
      category: 'Consumable Supplies',
      amount: 4000.56,
    ),
    BudgetSeedExpense(
      dayOfMonth: 22,
      category: 'Consumable Supplies',
      amount: 3500.30,
    ),
    BudgetSeedExpense(
      dayOfMonth: 30,
      category: 'Consumable Supplies',
      amount: 1254.20,
    ),
    BudgetSeedExpense(dayOfMonth: 8, category: 'Fuel', amount: 156.35),
    BudgetSeedExpense(dayOfMonth: 17, category: 'Fuel', amount: 256.57),
    BudgetSeedExpense(dayOfMonth: 23, category: 'Fuel', amount: 189.22),
    BudgetSeedExpense(
      dayOfMonth: 1,
      category: 'Rent',
      amount: 20000,
      isRecurringMonthly: true,
    ),
  ];
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

  const BudgetData({
    this.deposit = 0,
    this.expense = 0,
    this.total = 0,
    this.period = '',
    this.surplusPercent = 0,
    this.utilizationPercent = 0,
    this.transactionCount = 0,
    this.categories = const [],
  });

  double get saving => DepositAllocation.savingFor(deposit);

  double get income => DepositAllocation.incomeFor(deposit);

  double get reserves => income;

  double get available => income - expense;

  double get reserve => available;

  bool get hasActivity => total > 0 || expense > 0 || deposit != 0;
}
