import 'package:flutter/material.dart';

import 'package:savetep/features/auth/models/balance_summary_data.dart';
import 'package:savetep/features/auth/models/budget_data.dart';
import 'package:savetep/features/auth/screens/home_screen/domain/home_budget_data_mapper.dart';
import 'package:savetep/features/auth/screens/home_screen/models/home_budget_chart_models.dart';
import 'package:savetep/features/auth/widgets/balance_summary_card.dart';

import 'budget_sum_chart.dart';

class BudgetDonutChart extends StatelessWidget {
  final BudgetData? data;
  final HomeBudgetData? homeData;
  final String periodKey;

  const BudgetDonutChart({
    super.key,
    this.data,
    this.homeData,
    this.periodKey = '',
  }) : assert(data != null || homeData != null);

  @override
  Widget build(BuildContext context) {
    final budgetData = homeData ?? mapHomeBudgetData(data!);
    final mediaSize = MediaQuery.sizeOf(context);
    final double heightScale = (mediaSize.height / 844)
        .clamp(0.78, 1.15)
        .toDouble();
    final double cardGap = ((mediaSize.width >= 600 ? 18 : 14) * heightScale)
        .clamp(mediaSize.width >= 600 ? 14.0 : 8.0, 20.0)
        .toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BalanceSummaryCard(
          cardKey: const ValueKey('home.totalBalanceCard'),
          data: BalanceSummaryData(
            totalBalance: budgetData.available,
            estimatedTaxAtYearEnd: budgetData.estimatedTaxAtYearEnd,
            totalExpense: budgetData.expense,
            totalDeposit: budgetData.deposit,
          ),
        ),
        SizedBox(height: cardGap),
        BudgetSumChart(data: budgetData, periodKey: periodKey),
      ],
    );
  }
}
