import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/budget_data.dart';
import '../../../services/money_formatter.dart';

class BudgetSumChart extends StatelessWidget {
  final BudgetData data;

  const BudgetSumChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final segments = _budgetSegments(data);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
            _BudgetMetrics(data: data),
            const SizedBox(height: 16),
            _StackedBudgetBar(segments: segments),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${data.utilizationPercent}% used',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  'Surplus ${data.surplusPercent}%',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Breakdown',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...segments.map((segment) => _BreakdownRow(segment: segment)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  List<_BudgetSegment> _budgetSegments(BudgetData data) {
    final denominator = math.max(data.total, data.spent);
    if (denominator <= 0) {
      return const [
        _BudgetSegment(
          label: 'No activity',
          amount: 0,
          percentage: 100,
          color: Color(0xFFE5E7EB),
        ),
      ];
    }

    final segments = <_BudgetSegment>[];
    final categories = _visibleCategories(data);

    if (categories.isEmpty && data.spent > 0) {
      segments.add(
        _BudgetSegment(
          label: 'Expenses',
          amount: data.spent,
          percentage: data.spent / denominator * 100,
          color: const Color(0xFF2563EB),
        ),
      );
    } else {
      for (final category in categories) {
        final amount = data.spent * category.percentage / 100;
        if (amount <= 0) continue;
        segments.add(
          _BudgetSegment(
            label: category.label,
            amount: amount,
            percentage: amount / denominator * 100,
            color: category.color,
          ),
        );
      }
    }

    if (data.available > 0) {
      segments.add(
        _BudgetSegment(
          label: 'Available',
          amount: data.available,
          percentage: data.available / denominator * 100,
          color: const Color(0xFF16A34A),
        ),
      );
    }

    if (segments.isEmpty) {
      return const [
        _BudgetSegment(
          label: 'No activity',
          amount: 0,
          percentage: 100,
          color: Color(0xFFE5E7EB),
        ),
      ];
    }

    return segments;
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
        label: 'Other',
        percentage: otherTotal,
        color: const Color(0xFF374151),
      ),
    );
    return visible;
  }
}

class _BudgetMetrics extends StatelessWidget {
  final BudgetData data;

  const _BudgetMetrics({required this.data});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricBlock(
          label: 'Available',
          value: _fmtMoney(data.available),
          color: data.available >= 0
              ? const Color(0xFF16A34A)
              : const Color(0xFFFF1744),
        ),
        _MetricBlock(
          label: 'Spent',
          value: _fmtMoney(data.spent),
          color: const Color(0xFF111827),
        ),
        _MetricBlock(
          label: 'Budget',
          value: _fmtMoney(data.total),
          color: const Color(0xFF2563EB),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedBudgetBar extends StatelessWidget {
  final List<_BudgetSegment> segments;

  const _StackedBudgetBar({required this.segments});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 18,
        width: double.infinity,
        child: Row(
          children: segments.map((segment) {
            final flex = math.max(1, (segment.percentage * 10).round());
            return Expanded(
              flex: flex,
              child: ColoredBox(color: segment.color),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final _BudgetSegment segment;

  const _BreakdownRow({required this.segment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: segment.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              segment.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(
              '${segment.percentage.round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _fmtMoney(segment.amount),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSegment {
  final String label;
  final double amount;
  final double percentage;
  final Color color;

  const _BudgetSegment({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

String _fmtMoney(double value) => formatMoney(value);
