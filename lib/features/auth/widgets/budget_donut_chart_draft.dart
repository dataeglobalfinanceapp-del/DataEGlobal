import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/budget_data.dart';
import '../../../services/money_formatter.dart';

class BudgetDonutChart extends StatelessWidget {
  final BudgetData data;
  const BudgetDonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final categories = _visibleCategories(data);
    final hasCategories = categories.isNotEmpty;
    final sections = hasCategories
        ? categories
        : const [
            BudgetCategory(
              label: 'No activity',
              percentage: 1,
              color: Color(0xFFE5E7EB),
            ),
          ];

    return SizedBox(
      height: 330,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(constraints.maxWidth, 350.0);
          final chartSize = math.min(size * 0.64, 280.0);
          final centerRadius = chartSize * 0.5;
          final sectionRadius = chartSize * 0.08;

          return Center(
            child: SizedBox(
              width: size,
              height: 330,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 42,
                    child: SizedBox(
                      width: chartSize,
                      height: chartSize,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 1,
                          centerSpaceRadius: centerRadius,
                          startDegreeOffset: -90,
                          sections: sections.map((cat) {
                            return PieChartSectionData(
                              value: cat.percentage,
                              color: cat.color,
                              radius: sectionRadius,
                              showTitle: false,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 42 + (chartSize - 112) / 2,
                    child: _CenterBudgetText(data: data),
                  ),
                  if (hasCategories)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CategoryLabelPainter(categories: categories),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data.period,
                          style: const TextStyle(
                            color: Color(0xFF1A2340),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<BudgetCategory> _visibleCategories(BudgetData data) {
    final categories =
        data.categories.where((category) => category.percentage > 0).toList()
          ..sort((a, b) => b.percentage.compareTo(a.percentage));

    if (categories.length <= 10) return categories;

    final visible = categories.take(9).toList();
    final otherTotal = categories
        .skip(9)
        .fold<double>(0, (total, category) => total + category.percentage);
    visible.add(
      BudgetCategory(
        label: 'Other',
        percentage: otherTotal,
        color: const Color(0xFF374151),
      ),
    );
    return visible;
  }
}

class _CenterBudgetText extends StatelessWidget {
  final BudgetData data;

  const _CenterBudgetText({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 112,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${formatMoney(data.available)} available',
              style: TextStyle(
                color: data.available >= 0
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFFF1744),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'SURPLUS ${data.surplusPercent}%',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatMoney(data.spent)} /',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatMoney(data.total),
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          Text(
            '${data.utilizationPercent}% Utilization',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _CategoryLabelPainter extends CustomPainter {
  final List<BudgetCategory> categories;

  const _CategoryLabelPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty) return;

    final center = Offset(
      size.width / 2,
      42 + math.min(size.width * 0.64, 220.0) / 2,
    );
    final labelRadius = math.min(size.width * 0.43, 146.0);
    var startAngle = -math.pi / 2;

    for (final category in categories) {
      final sweep = category.percentage / 100 * math.pi * 2;
      final angle = startAngle + sweep / 2;
      final position = Offset(
        center.dx + math.cos(angle) * labelRadius,
        center.dy + math.sin(angle) * labelRadius,
      );
      _paintLabel(canvas, position, angle, category);
      startAngle += sweep;
    }
  }

  void _paintLabel(
    Canvas canvas,
    Offset position,
    double angle,
    BudgetCategory category,
  ) {
    final percent = '${category.percentage.round()}%';
    final label = category.label.replaceAll('\n', ' ');
    final align = math.cos(angle) < -0.2
        ? TextAlign.right
        : math.cos(angle) > 0.2
        ? TextAlign.left
        : TextAlign.center;

    final maxWidth = label.length > 13 ? 86.0 : 74.0;
    final painter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$percent ',
            style: TextStyle(
              color: category.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: maxWidth);

    final dx = switch (align) {
      TextAlign.right => position.dx - painter.width,
      TextAlign.center => position.dx - painter.width / 2,
      _ => position.dx,
    };
    final dy = position.dy - painter.height / 2;

    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _CategoryLabelPainter oldDelegate) {
    return oldDelegate.categories != categories;
  }
}
