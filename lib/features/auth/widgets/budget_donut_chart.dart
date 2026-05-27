import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget_data.dart';

class BudgetDonutChart extends StatelessWidget {
  final BudgetData data;
  const BudgetDonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final positiveCategories = data.categories
        .where((category) => category.percentage > 0)
        .toList();
    final sections = positiveCategories.isEmpty
        ? const [
            BudgetCategory(
              label: 'No activity',
              percentage: 1,
              color: Color(0xFFE5E7EB),
            ),
          ]
        : positiveCategories;

    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 80,
              sections: sections.map((cat) {
                return PieChartSectionData(
                  value: cat.percentage,
                  color: cat.color,
                  radius: 45,
                  showTitle: false,
                );
              }).toList(),
            ),
          ),
          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${data.available.toStringAsFixed(2)} available',
                style: TextStyle(
                  color: data.available >= 0
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'SURPLUS ${data.surplusPercent}%',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${data.spent.toStringAsFixed(2)} /',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              Text(
                '\$${data.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                '${data.utilizationPercent}% Utilization',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          // Labels around chart (see Step 4b below)
        ],
      ),
    );
  }
}
