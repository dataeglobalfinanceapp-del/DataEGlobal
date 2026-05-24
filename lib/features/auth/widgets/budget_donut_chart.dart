import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget_data.dart';

class BudgetDonutChart extends StatelessWidget {
  final BudgetData data;
  const BudgetDonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 80,
              sections: data.categories.map((cat) {
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
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'SURPLUS 10%',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${data.spent.toStringAsFixed(2)}M /',
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
              const Text(
                '96% Utilization',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          // Labels around chart (see Step 4b below)
        ],
      ),
    );
  }
}