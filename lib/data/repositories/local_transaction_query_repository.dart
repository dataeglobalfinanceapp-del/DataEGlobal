import 'package:flutter/material.dart' show DateTimeRange;
import 'package:savetep/data/repositories/transaction_query_repository.dart';
import 'package:savetep/services/liability_service.dart'
    show DepositRecord, ExpenseRecord, LiabilityService;
import 'package:savetep/services/tax_estimate_service.dart';

final class LocalTransactionQueryRepository
    implements TransactionQueryRepository {
  const LocalTransactionQueryRepository();

  @override
  Future<TransactionPage<DepositRecord>> queryDeposits(
    TransactionQuery query,
  ) async {
    if (query.kind != TransactionKind.deposit) {
      return TransactionPage<DepositRecord>(
        items: const [],
        nextCursor: null,
        totalCount: 0,
      );
    }

    final List<DepositRecord> deposits = await LiabilityService.loadDeposits();
    final List<DepositRecord> records =
        deposits
            .where(
              (DepositRecord record) => _isInRange(
                record.transactionDate,
                query.startDate,
                query.endDate,
              ),
            )
            .toList(growable: false)
          ..sort(_compareDepositsDescending);

    return _page(records: records, limit: query.limit, cursor: query.cursor);
  }

  @override
  Future<TransactionPage<ExpenseRecord>> queryExpenses(
    TransactionQuery query,
  ) async {
    if (query.kind != TransactionKind.expense) {
      return TransactionPage<ExpenseRecord>(
        items: const [],
        nextCursor: null,
        totalCount: 0,
      );
    }

    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();
    final List<ExpenseRecord> records =
        expenses
            .where((ExpenseRecord record) {
              final bool matchesRange = _isInRange(
                record.transactionDate,
                query.startDate,
                query.endDate,
              );
              final bool matchesCategory =
                  query.category == null || record.category == query.category;
              return matchesRange && matchesCategory;
            })
            .toList(growable: false)
          ..sort(_compareExpensesDescending);

    return _page(records: records, limit: query.limit, cursor: query.cursor);
  }

  // NOTE(local-only): This method loads all deposits and expenses from
  // LiabilityService independently of queryDeposits/queryExpenses.
  // On local storage this is acceptable. The AWS implementation MUST
  // use a single aggregates endpoint instead of loading full lists.
  // See aws_transaction_query_repository.dart for the correct pattern.
  @override
  Future<TransactionAggregates> fetchAggregates({
    required int year,
    required DateTimeRange expenseDateRange,
    String? category,
  }) async {
    final List<DepositRecord> deposits = await LiabilityService.loadDeposits();
    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();

    final double totalDeposits = _totalDepositsInRange(
      deposits,
      expenseDateRange,
    );
    final double totalExpenses = _totalExpensesInRange(
      expenses,
      expenseDateRange,
    );
    final List<String> expenseCategories = _expenseCategories(
      expenses,
      dateRange: expenseDateRange,
    );
    final double selectedCategoryTotal = _selectedCategoryExpenseTotal(
      expenses: expenses,
      dateRange: expenseDateRange,
      category: category,
    );
    final taxEstimate =
        TaxEstimateService.calculateYearEndEstimate<
          DepositRecord,
          ExpenseRecord
        >(
          deposits: deposits,
          expenses: expenses,
          year: year,
          depositDate: (DepositRecord record) => record.transactionDate,
          depositAmount: (DepositRecord record) => record.totalAmount,
          expenseDate: (ExpenseRecord record) => record.transactionDate,
          expenseAmount: (ExpenseRecord record) => record.totalAmount,
        );

    return TransactionAggregates(
      totalDeposits: totalDeposits,
      totalExpenses: totalExpenses,
      estimatedTaxAtYearEnd: taxEstimate.taxDue,
      expenseCategories: expenseCategories,
      selectedCategoryTotal: selectedCategoryTotal,
    );
  }

  @override
  Future<List<DepositRecord>> fetchDepositsForExport(
    DateTimeRange range,
  ) async {
    final List<DepositRecord> deposits = await LiabilityService.loadDeposits();
    final List<DepositRecord> records =
        deposits
            .where(
              (DepositRecord record) =>
                  _isInDateRange(record.transactionDate, range),
            )
            .toList(growable: false)
          ..sort(_compareDepositsAscending);
    return List<DepositRecord>.unmodifiable(records);
  }

  @override
  Future<List<ExpenseRecord>> fetchExpensesForExport({
    required DateTimeRange range,
    String? category,
  }) async {
    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();
    final List<ExpenseRecord> records =
        expenses
            .where((ExpenseRecord record) {
              final bool matchesRange = _isInDateRange(
                record.transactionDate,
                range,
              );
              final bool matchesCategory =
                  category == null || record.category == category;
              return matchesRange && matchesCategory;
            })
            .toList(growable: false)
          ..sort(_compareExpensesAscending);
    return List<ExpenseRecord>.unmodifiable(records);
  }
}

TransactionPage<T> _page<T>({
  required List<T> records,
  required int limit,
  required String? cursor,
}) {
  final int startIndex = _cursorIndex(cursor, records.length);
  final int pageLimit = limit < 1 ? 1 : limit;
  final int endIndex = (startIndex + pageLimit)
      .clamp(0, records.length)
      .toInt();
  final String? nextCursor = endIndex < records.length ? '$endIndex' : null;

  return TransactionPage<T>(
    items: records.sublist(startIndex, endIndex),
    nextCursor: nextCursor,
    totalCount: records.length,
  );
}

int _cursorIndex(String? cursor, int recordCount) {
  if (cursor == null) return 0;
  final int parsed = int.tryParse(cursor) ?? 0;
  return parsed.clamp(0, recordCount).toInt();
}

double _totalDepositsInRange(
  List<DepositRecord> deposits,
  DateTimeRange dateRange,
) {
  return deposits
      .where(
        (DepositRecord record) =>
            _isInDateRange(record.transactionDate, dateRange),
      )
      .fold<double>(
        0,
        (double total, DepositRecord record) => total + record.totalAmount,
      );
}

double _totalExpensesInRange(
  List<ExpenseRecord> expenses,
  DateTimeRange dateRange,
) {
  return expenses
      .where(
        (ExpenseRecord record) =>
            _isInDateRange(record.transactionDate, dateRange),
      )
      .fold<double>(
        0,
        (double total, ExpenseRecord record) => total + record.totalAmount,
      );
}

List<String> _expenseCategories(
  List<ExpenseRecord> expenses, {
  required DateTimeRange dateRange,
}) {
  final List<String> categories = expenses
      .where(
        (ExpenseRecord record) =>
            _isInDateRange(record.transactionDate, dateRange),
      )
      .map<String>((ExpenseRecord record) => record.category)
      .where((String category) => category.trim().isNotEmpty)
      .toSet()
      .toList(growable: false);
  categories.sort();
  return List<String>.unmodifiable(categories);
}

double _selectedCategoryExpenseTotal({
  required List<ExpenseRecord> expenses,
  required DateTimeRange dateRange,
  required String? category,
}) {
  if (category == null) return 0;

  return expenses
      .where(
        (ExpenseRecord record) =>
            _isInDateRange(record.transactionDate, dateRange) &&
            record.category == category,
      )
      .fold<double>(
        0,
        (double total, ExpenseRecord record) => total + record.totalAmount,
      );
}

bool _isInRange(DateTime value, DateTime startDate, DateTime endDate) {
  final DateTimeRange range = _normalizedRange(
    DateTimeRange(start: startDate, end: endDate),
  );
  final DateTime date = _dateOnly(value);
  return !date.isBefore(range.start) && !date.isAfter(range.end);
}

bool _isInDateRange(DateTime value, DateTimeRange range) {
  final DateTimeRange normalized = _normalizedRange(range);
  final DateTime date = _dateOnly(value);
  return !date.isBefore(normalized.start) && !date.isAfter(normalized.end);
}

DateTimeRange _normalizedRange(DateTimeRange range) {
  final DateTime start = _dateOnly(range.start);
  final DateTime end = _dateOnly(range.end);
  if (end.isBefore(start)) {
    return DateTimeRange(start: end, end: start);
  }
  return DateTimeRange(start: start, end: end);
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

int _compareDepositsDescending(DepositRecord a, DepositRecord b) {
  return b.transactionDate.compareTo(a.transactionDate);
}

int _compareExpensesDescending(ExpenseRecord a, ExpenseRecord b) {
  return b.transactionDate.compareTo(a.transactionDate);
}

int _compareDepositsAscending(DepositRecord a, DepositRecord b) {
  return a.transactionDate.compareTo(b.transactionDate);
}

int _compareExpensesAscending(ExpenseRecord a, ExpenseRecord b) {
  return a.transactionDate.compareTo(b.transactionDate);
}
