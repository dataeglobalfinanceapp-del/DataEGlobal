import 'package:flutter/material.dart';

import '../../models/budget_data.dart';
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
        BudgetTotalsCard(data: data),
        SizedBox(height: cardGap),
        BudgetSumChart(data: data, periodKey: periodKey),
      ],
    );
  }
}
