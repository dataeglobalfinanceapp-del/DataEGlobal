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
  final String category;
  final String payee;
  final double total;
  final DateTime date;
  final String last4CreditCard;

  BudgetSeedExpense({
    required this.category,
    required this.payee,
    required this.total,
    required this.date,
    required this.last4CreditCard,
  }) : assert(total > 0),
       assert(last4CreditCard.length == 4),
       assert(
         last4CreditCard.codeUnits.every(
           (int digit) => digit >= 0x30 && digit <= 0x39,
         ),
       );
}

class DefaultBudgetSeedData {
  static const int version = 2;

  static const List<BudgetSeedDeposit> deposits = [
    BudgetSeedDeposit(dayOfMonth: 1, label: 'Cash', cash: 100000),
    BudgetSeedDeposit(dayOfMonth: 15, label: 'Credit', creditDeposit: 20000),
  ];

  static final List<BudgetSeedExpense> expenses = List.unmodifiable([
    BudgetSeedExpense(
      category: 'Energy',
      payee: 'Green Energy Co.',
      total: 185.40,
      date: DateTime(2026, 6, 2),
      last4CreditCard: '4821',
    ),
    BudgetSeedExpense(
      category: 'Loan Obligation',
      payee: 'Community Business Bank',
      total: 1250,
      date: DateTime(2026, 6, 3),
      last4CreditCard: '7742',
    ),
    BudgetSeedExpense(
      category: 'Payroll',
      payee: 'Save Tep Payroll',
      total: 4200,
      date: DateTime(2026, 6, 4),
      last4CreditCard: '1936',
    ),
    BudgetSeedExpense(
      category: 'Business licenses and permits',
      payee: 'City Business Licensing Office',
      total: 325,
      date: DateTime(2026, 6, 5),
      last4CreditCard: '6604',
    ),
    BudgetSeedExpense(
      category: 'Food Purchase',
      payee: 'Restaurant Depot',
      total: 1875.65,
      date: DateTime(2026, 6, 6),
      last4CreditCard: '2847',
    ),
    BudgetSeedExpense(
      category: 'Restaurant supplies',
      payee: 'WebstaurantStore',
      total: 642.30,
      date: DateTime(2026, 6, 7),
      last4CreditCard: '9153',
    ),
    BudgetSeedExpense(
      category: 'Advertising and promotion',
      payee: 'Meta Ads',
      total: 450,
      date: DateTime(2026, 6, 8),
      last4CreditCard: '4386',
    ),
    BudgetSeedExpense(
      category: 'software',
      payee: 'Microsoft 365',
      total: 129.99,
      date: DateTime(2026, 6, 9),
      last4CreditCard: '5274',
    ),
    BudgetSeedExpense(
      category: 'pest control',
      payee: 'EcoShield Pest Solutions',
      total: 165,
      date: DateTime(2026, 6, 10),
      last4CreditCard: '8026',
    ),
    BudgetSeedExpense(
      category: 'Internet',
      payee: 'Spectrum Business',
      total: 119.95,
      date: DateTime(2026, 6, 11),
      last4CreditCard: '3719',
    ),
    BudgetSeedExpense(
      category: 'Maintenance',
      payee: 'Reliable Repair Services',
      total: 285,
      date: DateTime(2026, 6, 12),
      last4CreditCard: '6048',
    ),
    BudgetSeedExpense(
      category: 'Insurance',
      payee: 'Statewide Business Insurance',
      total: 760,
      date: DateTime(2026, 6, 13),
      last4CreditCard: '2465',
    ),
    BudgetSeedExpense(
      category: 'Rent',
      payee: 'Downtown Properties',
      total: 3500,
      date: DateTime(2026, 6, 14),
      last4CreditCard: '7194',
    ),
    BudgetSeedExpense(
      category: 'Office Supplies',
      payee: 'Staples',
      total: 214.68,
      date: DateTime(2026, 6, 15),
      last4CreditCard: '5832',
    ),
    BudgetSeedExpense(
      category: 'Meal, entertainment',
      payee: 'Harbor Bistro',
      total: 148.25,
      date: DateTime(2026, 6, 16),
      last4CreditCard: '9317',
    ),
    BudgetSeedExpense(
      category: 'merchant accounting fees',
      payee: 'Stripe',
      total: 96.42,
      date: DateTime(2026, 6, 17),
      last4CreditCard: '4058',
    ),
    BudgetSeedExpense(
      category: 'gas',
      payee: 'Shell',
      total: 82.74,
      date: DateTime(2026, 6, 18),
      last4CreditCard: '1673',
    ),
    BudgetSeedExpense(
      category: 'water',
      payee: 'City Water Services',
      total: 143.20,
      date: DateTime(2026, 6, 19),
      last4CreditCard: '6529',
    ),
    BudgetSeedExpense(
      category: 'electric',
      payee: 'Pacific Electric',
      total: 428.63,
      date: DateTime(2026, 6, 20),
      last4CreditCard: '3107',
    ),
    BudgetSeedExpense(
      category: 'donation',
      payee: 'Community Food Bank',
      total: 250,
      date: DateTime(2026, 6, 21),
      last4CreditCard: '8461',
    ),
    BudgetSeedExpense(
      category: 'professional fees',
      payee: 'Martinez CPA Group',
      total: 900,
      date: DateTime(2026, 6, 22),
      last4CreditCard: '2784',
    ),
  ]);
}

class BudgetData {
  final double deposit;
  final double expense;
  final double total;
  final String period;
  final int surplusPercent;
  final int utilizationPercent;
  final double estimatedTaxAtYearEnd;
  final int transactionCount;
  final List<BudgetCategory> categories;

  const BudgetData({
    this.deposit = 0,
    this.expense = 0,
    this.total = 0,
    this.period = '',
    this.surplusPercent = 0,
    this.utilizationPercent = 0,
    this.estimatedTaxAtYearEnd = 0,
    this.transactionCount = 0,
    this.categories = const [],
  });

  double get available => deposit - expense;

  double get reserve => available;

  bool get hasActivity => total > 0 || expense > 0 || deposit != 0;
}
