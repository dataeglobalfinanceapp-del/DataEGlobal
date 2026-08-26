import 'package:savetep/features/auth/models/budget_data.dart';
import 'package:savetep/features/auth/screens/home_screen/models/home_budget_chart_models.dart';

HomeBudgetData mapHomeBudgetData(BudgetData data) {
  return HomeBudgetData(
    deposit: data.deposit,
    expense: data.expense,
    total: data.total,
    period: data.period,
    surplusPercent: data.surplusPercent,
    utilizationPercent: data.utilizationPercent,
    estimatedTaxAtYearEnd: data.estimatedTaxAtYearEnd,
    transactionCount: data.transactionCount,
    categories: [
      for (final category in data.categories)
        HomeBudgetCategory(
          label: category.label,
          percentage: category.percentage,
        ),
    ],
  );
}
