import 'package:flutter/material.dart' show DateTimeRange;
import 'package:savetep/services/liability_service.dart'
    show DepositRecord, ExpenseRecord;

enum TransactionKind { deposit, expense }

final class TransactionPage<T> {
  final List<T> items;
  final String? nextCursor;
  final int? totalCount;

  TransactionPage({required List<T> items, this.nextCursor, this.totalCount})
    : items = List<T>.unmodifiable(items);
}

final class TransactionQuery {
  final TransactionKind kind;
  final DateTime startDate;
  final DateTime endDate;
  final String? category;
  final int limit;
  final String? cursor;

  const TransactionQuery({
    required this.kind,
    required this.startDate,
    required this.endDate,
    this.category,
    this.limit = 50,
    this.cursor,
  }) : assert(limit > 0);
}

final class TransactionAggregates {
  final double totalDeposits;
  final double totalExpenses;
  final double estimatedTaxAtYearEnd;
  final List<String> expenseCategories;
  final double selectedCategoryTotal;

  TransactionAggregates({
    required this.totalDeposits,
    required this.totalExpenses,
    required this.estimatedTaxAtYearEnd,
    required List<String> expenseCategories,
    required this.selectedCategoryTotal,
  }) : expenseCategories = List<String>.unmodifiable(expenseCategories);

  TransactionAggregates.empty()
    : totalDeposits = 0,
      totalExpenses = 0,
      estimatedTaxAtYearEnd = 0,
      expenseCategories = const <String>[],
      selectedCategoryTotal = 0;
}

abstract class TransactionQueryRepository {
  Future<TransactionPage<DepositRecord>> queryDeposits(TransactionQuery query);

  Future<TransactionPage<ExpenseRecord>> queryExpenses(TransactionQuery query);

  Future<TransactionAggregates> fetchAggregates({
    required int year,
    required DateTimeRange expenseDateRange,
    String? category,
  });

  Future<List<DepositRecord>> fetchDepositsForExport(DateTimeRange range);

  Future<List<ExpenseRecord>> fetchExpensesForExport({
    required DateTimeRange range,
    String? category,
  });
}
