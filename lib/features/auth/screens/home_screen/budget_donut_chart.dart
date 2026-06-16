import 'package:flutter/material.dart';

import '../../models/budget_data.dart';
import 'budget_sum_chart.dart';

class BudgetDonutChart extends StatelessWidget {
  final BudgetData data;
  final String periodKey;

  const BudgetDonutChart({super.key, required this.data, this.periodKey = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BudgetTotalsCard(data: data),
        const SizedBox(height: 12),
        BudgetSumChart(data: data, periodKey: periodKey),
      ],
    );
  }
}
