import 'package:flutter/material.dart' show DateTimeRange;
import 'package:savetep/core/api/aws_api_client.dart';
import 'package:savetep/data/repositories/transaction_query_repository.dart';
import 'package:savetep/services/liability_service.dart'
    show DepositRecord, ExpenseRecord;

final class AwsTransactionQueryRepository
    implements TransactionQueryRepository {
  // ignore: unused_field
  final AwsApiClient _client;

  const AwsTransactionQueryRepository(this._client);

  // TODO(aws-migration):
  //   Method: queryDeposits
  //   Endpoint: GET /transactions
  //   Query params: kind=deposit, startDate, endDate, limit, cursor
  //   Response shape: { items: [...], nextCursor: String?, totalCount: int }
  //   DynamoDB table: transactions
  //   GSI needed: businessId-transactionDate-index
  //   Auth: Cognito JWT in Authorization header via AwsApiClient
  @override
  Future<TransactionPage<DepositRecord>> queryDeposits(
    TransactionQuery query,
  ) async {
    return TransactionPage<DepositRecord>(
      items: const [],
      nextCursor: null,
      totalCount: 0,
    );
  }

  // TODO(aws-migration):
  //   Method: queryExpenses
  //   Endpoint: GET /transactions
  //   Query params: kind=expense, startDate, endDate, category, limit, cursor
  //   Response shape: { items: [...], nextCursor: String?, totalCount: int }
  //   DynamoDB table: transactions
  //   GSI needed: businessId-transactionDate-index
  //   Auth: Cognito JWT in Authorization header via AwsApiClient
  @override
  Future<TransactionPage<ExpenseRecord>> queryExpenses(
    TransactionQuery query,
  ) async {
    return TransactionPage<ExpenseRecord>(
      items: const [],
      nextCursor: null,
      totalCount: 0,
    );
  }

  // TODO(aws-migration):
  //   Method: fetchAggregates
  //   Endpoint: GET /transactions/aggregates
  //   Query params: year, expenseStartDate, expenseEndDate, category
  //   Response shape: {
  //     totalDeposits: double,
  //     totalExpenses: double,
  //     estimatedTaxAtYearEnd: double,
  //     expenseCategories: [...],
  //     selectedCategoryTotal: double
  //   }
  //   DynamoDB table: transactions
  //   GSI needed: businessId-transactionDate-index
  //   Auth: Cognito JWT in Authorization header via AwsApiClient
  //   NOTE: Do NOT load full lists — call a dedicated aggregates
  //   Lambda endpoint that computes totals/categories server-side.
  //   See local_transaction_query_repository.dart NOTE(local-only)
  //   comment for why this matters.
  @override
  Future<TransactionAggregates> fetchAggregates({
    required int year,
    required DateTimeRange expenseDateRange,
    String? category,
  }) async {
    return TransactionAggregates.empty();
  }

  // TODO(aws-migration):
  //   Method: fetchDepositsForExport
  //   Endpoint: GET /transactions/export
  //   Query params: kind=deposit, startDate, endDate
  //   Response shape: { items: [...] }
  //   DynamoDB table: transactions
  //   GSI needed: businessId-transactionDate-index
  //   Auth: Cognito JWT in Authorization header via AwsApiClient
  @override
  Future<List<DepositRecord>> fetchDepositsForExport(
    DateTimeRange range,
  ) async {
    return const <DepositRecord>[];
  }

  // TODO(aws-migration):
  //   Method: fetchExpensesForExport
  //   Endpoint: GET /transactions/export
  //   Query params: kind=expense, startDate, endDate, category
  //   Response shape: { items: [...] }
  //   DynamoDB table: transactions
  //   GSI needed: businessId-transactionDate-index
  //   Auth: Cognito JWT in Authorization header via AwsApiClient
  @override
  Future<List<ExpenseRecord>> fetchExpensesForExport({
    required DateTimeRange range,
    String? category,
  }) async {
    return const <ExpenseRecord>[];
  }
}
