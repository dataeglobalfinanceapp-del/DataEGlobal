import 'package:flutter/material.dart' show DateTimeRange;
import 'package:savetep/core/api/aws_api_client.dart';
import 'package:savetep/data/repositories/transaction_query_repository.dart';
import 'package:savetep/services/liability_service.dart'
    show DepositRecord, ExpenseRecord;

final class AwsTransactionQueryRepository
    implements TransactionQueryRepository {
  final AwsApiClient client;

  const AwsTransactionQueryRepository(this.client);

  @override
  Future<TransactionPage<DepositRecord>> queryDeposits(
    TransactionQuery query,
  ) async {
    throw UnsupportedError(
      'Remote deposits require the documented GET '
      '/businesses/{businessId}/income list response schema.',
    );
  }

  @override
  Future<TransactionPage<ExpenseRecord>> queryExpenses(
    TransactionQuery query,
  ) async {
    throw UnsupportedError(
      'Remote expenses require the documented GET '
      '/businesses/{businessId}/expenses list response schema.',
    );
  }

  @override
  Future<TransactionAggregates> fetchAggregates({
    required int year,
    required DateTimeRange expenseDateRange,
    String? category,
  }) async {
    throw UnsupportedError(
      'Remote transaction aggregates must be mapped to the verified '
      'profit-loss or dashboard contract; /transactions/aggregates does not '
      'exist.',
    );
  }

  @override
  Future<List<DepositRecord>> fetchDepositsForExport(
    DateTimeRange range,
  ) async {
    throw UnsupportedError(
      'Remote deposit export requires paging the verified income endpoint '
      'after its list response schema is documented.',
    );
  }

  @override
  Future<List<ExpenseRecord>> fetchExpensesForExport({
    required DateTimeRange range,
    String? category,
  }) async {
    throw UnsupportedError(
      'Remote expense export requires paging the verified expenses endpoint '
      'after its list response schema is documented.',
    );
  }
}
