import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../features/auth/models/budget_data.dart';
import '../services/money_formatter.dart';

class BudgetDonutChart extends StatelessWidget {
  final BudgetData data;

  const BudgetDonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final segments = _budgetSegments(data);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'OVERVIEW',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 560;
                final legendWidth = isTablet
                    ? 220.0
                    : math.max(
                        104.0,
                        math.min(148.0, constraints.maxWidth * 0.38),
                      );
                final gap = isTablet ? 24.0 : 10.0;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: math.min(legendWidth, constraints.maxWidth * 0.46),
                      child: _CategoryLegend(segments: segments),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _BudgetDonutFigure(
                        data: data,
                        segments: segments,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<_BudgetDonutSegment> _budgetSegments(BudgetData data) {
    final categories = _visibleCategories(data);
    if (categories.isEmpty) {
      if (data.expense > 0) {
        return [
          _BudgetDonutSegment(
            label: 'Uncategorized',
            amount: data.expense,
            percentage: 100,
            color: const Color(0xFF0F766E),
          ),
        ];
      }

      return const [
        _BudgetDonutSegment(
          label: 'No activity',
          amount: 0,
          percentage: 100,
          color: Color(0xFFE5E7EB),
          isPlaceholder: true,
        ),
      ];
    }

    return [
      for (var index = 0; index < categories.length; index++)
        _BudgetDonutSegment(
          label: categories[index].label,
          amount: data.expense * categories[index].percentage / 100,
          percentage: categories[index].percentage,
          color: _categoryColor(categories[index].label, index),
        ),
    ];
  }

  List<BudgetCategory> _visibleCategories(BudgetData data) {
    final categories =
        data.categories.where((category) => category.percentage > 0).toList()
          ..sort((a, b) => b.percentage.compareTo(a.percentage));

    if (categories.length <= 8) return categories;

    final visible = categories.take(7).toList();
    final otherTotal = categories
        .skip(7)
        .fold<double>(0, (total, category) => total + category.percentage);
    visible.add(
      BudgetCategory(
        label: 'Others',
        percentage: otherTotal,
        color: _categoryColor('Others', visible.length),
      ),
    );
    return visible;
  }
}

class _CategoryLegend extends StatelessWidget {
  final List<_BudgetDonutSegment> segments;

  const _CategoryLegend({required this.segments});

  @override
  Widget build(BuildContext context) {
    final activeSegments = segments
        .where((segment) => !segment.isPlaceholder)
        .toList(growable: false);

    if (activeSegments.isEmpty) {
      return const _EmptyLegend();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final segment in activeSegments)
          _LegendRow(
            label: segment.label,
            percentage: segment.percentage,
            color: segment.color,
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _LegendRow({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4.5),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${_formatPercent(percentage)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLegend extends StatelessWidget {
  const _EmptyLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: Color(0xFF9CA3AF)),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'No budget activity for this range',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetDonutFigure extends StatelessWidget {
  final BudgetData data;
  final List<_BudgetDonutSegment> segments;
  final bool isTablet;

  const _BudgetDonutFigure({
    required this.data,
    required this.segments,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = math.min(
          constraints.maxWidth,
          isTablet ? 270.0 : 220.0,
        );
        final outerRadius = chartSize / 2;
        final ringWidth = math.max(22.0, math.min(34.0, chartSize * 0.15));
        final centerRadius = math.max(0.0, outerRadius - ringWidth);
        final centerTextWidth = math.max(78.0, centerRadius * 1.55);

        return Center(
          child: SizedBox.square(
            dimension: chartSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Semantics(
                  label: _chartSemanticsLabel(segments),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: segments.length > 1 ? 2 : 0,
                      centerSpaceRadius: centerRadius,
                      startDegreeOffset: -90,
                      sections: [
                        for (final segment in segments)
                          PieChartSectionData(
                            value: segment.percentage,
                            color: segment.color,
                            radius: outerRadius,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
                _CenterBudgetText(data: data, width: centerTextWidth),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CenterBudgetText extends StatelessWidget {
  final BudgetData data;
  final double width;

  const _CenterBudgetText({required this.data, required this.width});

  @override
  Widget build(BuildContext context) {
    final balanceColor = data.available >= 0
        ? const Color(0xFF0F766E)
        : const Color(0xFFDC2626);

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Total Budget',
            maxLines: 1,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatMoney(data.total),
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Available ${formatMoney(data.available)}',
              maxLines: 1,
              style: TextStyle(
                color: balanceColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${data.utilizationPercent}% utilized',
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetDonutSegment {
  final String label;
  final double amount;
  final double percentage;
  final Color color;
  final bool isPlaceholder;

  const _BudgetDonutSegment({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
    this.isPlaceholder = false,
  });
}

Color _categoryColor(String label, int index) {
  final normalizedLabel = label.trim().toLowerCase();
  final mappedColor = _categoryColors[normalizedLabel];
  if (mappedColor != null) return mappedColor;

  return _chartPalette[index % _chartPalette.length];
}

String _chartSemanticsLabel(List<_BudgetDonutSegment> segments) {
  final activeSegments = segments.where((segment) => !segment.isPlaceholder);
  if (activeSegments.isEmpty) return 'Budget chart with no activity';

  return activeSegments
      .map(
        (segment) =>
            '${segment.label} ${_formatPercent(segment.percentage)}%, '
            '${formatMoney(segment.amount)}',
      )
      .join(', ');
}

String _formatPercent(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.05) return rounded.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

const _categoryColors = <String, Color>{
  'payroll': Color(0xFF006B5F),
  'rent': Color(0xFF10B981),
  'loan obligation': Color(0xFFDC2626),
  'cogs': Color(0xFF0F766E),
  'fuel': Color(0xFFF59E0B),
  'utilities': Color(0xFF64748B),
  'insurance': Color(0xFF2563EB),
  'consumable supplies': Color(0xFF8B5CF6),
  'equipment': Color(0xFF0EA5E9),
  'others': Color(0xFF374151),
};

const _chartPalette = <Color>[
  Color(0xFF006B5F),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFDC2626),
  Color(0xFF2563EB),
  Color(0xFF8B5CF6),
  Color(0xFF0EA5E9),
  Color(0xFF64748B),
];
