import 'app_clock.dart';
import 'tax_estimator.dart';

class TaxEstimateService {
  const TaxEstimateService._();

  static TaxEstimate calculateYearEndEstimate<TDeposit, TExpense>({
    required Iterable<TDeposit> deposits,
    required Iterable<TExpense> expenses,
    required int year,
    required DateTime Function(TDeposit record) depositDate,
    required double Function(TDeposit record) depositAmount,
    required DateTime Function(TExpense record) expenseDate,
    required double Function(TExpense record) expenseAmount,
  }) {
    final projectionMonth = projectionMonthForYear(year);
    final reserve = reserveThroughMonth<TDeposit, TExpense>(
      deposits: deposits,
      expenses: expenses,
      year: year,
      month: projectionMonth,
      depositDate: depositDate,
      depositAmount: depositAmount,
      expenseDate: expenseDate,
      expenseAmount: expenseAmount,
    );

    return TaxEstimator.calculate(
      totalReserve: reserve,
      currentMonth: projectionMonth,
    );
  }

  static int projectionMonthForYear(int year) {
    final now = AppClock.now;
    return year == now.year ? now.month : 12;
  }

  static double reserveThroughMonth<TDeposit, TExpense>({
    required Iterable<TDeposit> deposits,
    required Iterable<TExpense> expenses,
    required int year,
    required int month,
    required DateTime Function(TDeposit record) depositDate,
    required double Function(TDeposit record) depositAmount,
    required DateTime Function(TExpense record) expenseDate,
    required double Function(TExpense record) expenseAmount,
  }) {
    final projectionMonth = month.clamp(1, 12).toInt();
    final deposit = deposits
        .where((record) {
          final date = depositDate(record);
          return date.year == year && date.month <= projectionMonth;
        })
        .fold<double>(0, (total, record) => total + depositAmount(record));
    final expense = expenses
        .where((record) {
          final date = expenseDate(record);
          return date.year == year && date.month <= projectionMonth;
        })
        .fold<double>(0, (total, record) => total + expenseAmount(record));

    return deposit - expense;
  }
}
