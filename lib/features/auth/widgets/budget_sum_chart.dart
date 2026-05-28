import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/budget_data.dart';
import '../../../services/local_store.dart';
import '../../../services/money_formatter.dart';

class BudgetSumChart extends StatefulWidget {
  final BudgetData data;
  final String periodKey;

  const BudgetSumChart({super.key, required this.data, this.periodKey = ''});

  @override
  State<BudgetSumChart> createState() => _BudgetSumChartState();
}

class _BudgetSumChartState extends State<BudgetSumChart> {
  static const _targetStorageKey = 'biztrack_budget_target_percentages_v1';

  final Map<String, Map<String, double>> _targetPercentagesByPeriod = {};
  bool _isEditingTargets = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTargets());
  }

  String get _periodKey {
    final key = widget.periodKey.trim();
    final rawKey = key.isNotEmpty
        ? key
        : widget.data.period.trim().isEmpty
        ? 'Week'
        : widget.data.period;

    return rawKey == 'Year' ? 'Month' : rawKey;
  }

  void _updateTarget(String label, String value) {
    final target = double.tryParse(value.trim());
    final periodTargets = _targetPercentagesByPeriod.putIfAbsent(
      _periodKey,
      () => <String, double>{},
    );

    setState(() {
      if (target == null) {
        periodTargets.remove(label);
      } else {
        periodTargets[label] = target.clamp(0, 100).toDouble();
      }
    });

    unawaited(_saveTargets());
  }

  Future<void> _loadTargets() async {
    final raw = await LocalStore.read(_targetStorageKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      final targets = <String, Map<String, double>>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        targets[entry.key.toString()] = {
          for (final targetEntry in value.entries)
            targetEntry.key.toString(): (targetEntry.value is num)
                ? (targetEntry.value as num).toDouble()
                : double.tryParse(targetEntry.value.toString()) ?? 0,
        };
      }
      targets.putIfAbsent('Month', () => targets['Year'] ?? <String, double>{});

      if (!mounted) return;
      setState(() {
        _targetPercentagesByPeriod
          ..clear()
          ..addAll(targets);
      });
    } catch (_) {
      return;
    }
  }

  Future<void> _saveTargets() async {
    await LocalStore.write(
      _targetStorageKey,
      jsonEncode(_targetPercentagesByPeriod),
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = _budgetSegments(widget.data);
    final targetPercentages =
        _targetPercentagesByPeriod[_periodKey] ?? const <String, double>{};

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
            _BudgetMetrics(data: widget.data),
            const SizedBox(height: 16),
            _StackedBudgetBar(segments: segments),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${widget.data.utilizationPercent}% used',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  'Surplus ${widget.data.surplusPercent}%',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Breakdown',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _isEditingTargets = !_isEditingTargets),
                  icon: Icon(
                    _isEditingTargets
                        ? Icons.check_circle_outline
                        : Icons.edit_outlined,
                    size: 18,
                  ),
                  label: Text(_isEditingTargets ? 'Done' : 'Edit target'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const _BreakdownHeader(),
            ...segments.map(
              (segment) => _BreakdownRow(
                segment: segment,
                targetPercentage:
                    targetPercentages[segment.label] ?? segment.percentage,
                periodKey: _periodKey,
                isEditingTarget: _isEditingTargets,
                onTargetChanged: (value) => _updateTarget(segment.label, value),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  List<_BudgetSegment> _budgetSegments(BudgetData data) {
    if (data.spent <= 0) {
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
          percentage: 100,
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
            percentage: category.percentage,
            color: category.color,
          ),
        );
      }
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

class _BreakdownHeader extends StatelessWidget {
  const _BreakdownHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(width: 20),
          Expanded(child: Text('Category', style: _headerStyle)),
          SizedBox(width: 6),
          SizedBox(
            width: 44,
            child: Text(
              'Actual',
              textAlign: TextAlign.right,
              style: _headerStyle,
            ),
          ),
          SizedBox(width: 6),
          SizedBox(
            width: 58,
            child: Text(
              'Target',
              textAlign: TextAlign.right,
              style: _headerStyle,
            ),
          ),
          SizedBox(width: 6),
          SizedBox(
            width: 76,
            child: Text(
              'Amount',
              textAlign: TextAlign.right,
              style: _headerStyle,
            ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    color: Color(0xFF9CA3AF),
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
  );
}

class _BreakdownRow extends StatelessWidget {
  final _BudgetSegment segment;
  final double targetPercentage;
  final String periodKey;
  final bool isEditingTarget;
  final ValueChanged<String> onTargetChanged;

  const _BreakdownRow({
    required this.segment,
    required this.targetPercentage,
    required this.periodKey,
    required this.isEditingTarget,
    required this.onTargetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOverTarget = segment.percentage > targetPercentage;
    final alertColor = isOverTarget
        ? const Color(0xFFDC2626)
        : const Color(0xFF111827);
    final mutedColor = isOverTarget
        ? const Color(0xFFDC2626)
        : const Color(0xFF6B7280);

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
              style: TextStyle(
                color: alertColor,
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
              style: TextStyle(
                color: mutedColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 58,
            height: 32,
            child: isEditingTarget
                ? TextFormField(
                    key: ValueKey('$periodKey-${segment.label}'),
                    initialValue: _fmtPercent(targetPercentage),
                    enabled: segment.amount > 0,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,3}\.?\d?'),
                      ),
                    ],
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: '%',
                      suffixStyle: TextStyle(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: mutedColor),
                      ),
                    ),
                    onChanged: onTargetChanged,
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_fmtPercent(targetPercentage)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 76,
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

String _fmtPercent(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}
