import 'package:flutter/material.dart';

import 'package:savetep/features/auth/screens/transaction_screen/transaction_screen.dart';

import 'expense_category_link.dart';

class ExpenseCategoryReportLink extends StatelessWidget {
  final String category;
  final String? label;
  final DateTimeRange dateRange;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  const ExpenseCategoryReportLink({
    super.key,
    required this.category,
    this.label,
    required this.dateRange,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return ExpenseCategoryLink(
      category: label ?? category,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      onTap: () => Navigator.pushNamed(
        context,
        '/transactions',
        arguments: TransactionScreenArguments(
          initialExpenseCategory: category,
          initialExpenseDateRange: dateRange,
        ),
      ),
    );
  }
}
