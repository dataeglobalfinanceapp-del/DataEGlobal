import 'package:flutter/material.dart';

import '../../models/budget_data.dart';
import '../../models/balance_summary_data.dart';
import '../../widgets/balance_summary_card.dart';
import 'budget_sum_chart.dart';

class BudgetDonutChart extends StatelessWidget {
  final BudgetData data;
  final String periodKey;

  const BudgetDonutChart({super.key, required this.data, this.periodKey = ''});

  @override
  Widget build(BuildContext context) {
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
            totalBalance: data.available,
            estimatedTaxAtYearEnd: data.estimatedTaxAtYearEnd,
            totalExpense: data.expense,
            totalDeposit: data.deposit,
          ),
        ),
        SizedBox(height: cardGap),
        BudgetSumChart(data: data, periodKey: periodKey),
      ],
    );
  }
}
