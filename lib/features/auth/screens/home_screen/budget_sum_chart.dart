import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:biztrack/features/auth/models/budget_data.dart';
import 'package:biztrack/services/local_store_test/local_store.dart';
import 'package:biztrack/services/money_formatter.dart';

class BudgetSumChart extends StatefulWidget {
  final BudgetData data;
  final String periodKey;
  const BudgetSumChart({super.key, required this.data, this.periodKey = ''});
  @override
  State<BudgetSumChart> createState() => _BudgetSumChartState();
}

class _BudgetSumChartState extends State<BudgetSumChart> {
  static const _targetStorageKey = 'SaveTep_budget_target_percentages_v1';
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
    final allLegendSegments = _allLegendSegments(widget.data);
    final targetPercentages =
        _targetPercentagesByPeriod[_periodKey] ?? const <String, double>{};
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: LayoutBuilder(
        builder: (context, cardConstraints) {
          final isWideCard = cardConstraints.maxWidth >= 560;
          final horizontalPadding = isWideCard ? 24.0 : 14.0;
          final topPadding = isWideCard ? 18.0 : 14.0;
          final bottomPadding = isWideCard ? 18.0 : 16.0;
          return Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                // Header row
                Row(
                  children: [
                    const Text('OVERVIEW', style: _overviewTitleStyle),
                    const Spacer(),
                    if (widget.data.period.trim().isNotEmpty) ...[
                      _PeriodPill(period: widget.data.period),
                      const SizedBox(width: 4),
                    ],
                    SizedBox.square(
                      dimension: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: _isEditingTargets ? 'Done' : 'Edit targets',
                        icon: Icon(
                          _isEditingTargets
                              ? Icons.check_circle_outline
                              : Icons.edit_outlined,
                          size: 18,
                        ),
                        color: const Color(0xFF0F766E),
                        onPressed: () => setState(
                          () => _isEditingTargets = !_isEditingTargets,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isWideCard ? 20 : 12),
                // Legend + Divider + Donut
                LayoutBuilder(
                  builder: (context, constraints) {
                    final contentWidth = constraints.maxWidth;
                    final isWide = contentWidth >= 560;
                    final isTight = contentWidth < 280;
                    final gap = isWide
                        ? 24.0
                        : isTight
                        ? 8.0
                        : 12.0;
                    // Legend takes fixed portion, chart fills the rest
                    final legendWidth = isWide
                        ? math.min(220.0, contentWidth * 0.36)
                        : math.min(160.0, contentWidth * 0.44);
                    final activeSegmentCount = math.max(
                      1,
                      allLegendSegments.length,
                    );
                    final rowHeight = _isEditingTargets ? 34.0 : 27.0;
                    final minChartHeight = isWide ? 200.0 : 160.0;
                    final dividerHeight = math.max(
                      minChartHeight,
                      activeSegmentCount * rowHeight + 8,
                    );
                    final legend = _CategoryLegend(
                      segments: allLegendSegments,
                      targetPercentages: targetPercentages,
                      periodKey: _periodKey,
                      isEditingTargets: _isEditingTargets,
                      onTargetChanged: _updateTarget,
                    );
                    final figure = _BudgetDonutFigure(
                      data: widget.data,
                      segments: segments,
                    );
                    if (isTight) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          legend,
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 12),
                          figure,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Legend
                        SizedBox(width: legendWidth, child: legend),
                        SizedBox(width: gap),
                        // Vertical divider
                        Container(
                          width: 1,
                          height: dividerHeight,
                          color: const Color(0xFFE5E7EB),
                        ),
                        SizedBox(width: gap),
                        // Donut chart
                        Expanded(child: figure),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Segments used for the actual donut chart rendering (active only, no zeros)
  List<_BudgetSegment> _budgetSegments(BudgetData data) {
    final segments = <_BudgetSegment>[];
    final categories = _visibleCategories(data);
    if (categories.isEmpty) {
      if (data.expense > 0) {
        segments.add(
          _BudgetSegment(
            label: 'Expenses',
            amount: data.expense,
            percentage: 100,
            color: const Color(0xFF0F766E),
          ),
        );
      } else {
        segments.add(
          const _BudgetSegment(
            label: 'No activity',
            amount: 0,
            percentage: 100,
            color: Color(0xFFE5E7EB),
            isPlaceholder: true,
          ),
        );
      }
    } else {
      for (var index = 0; index < categories.length; index++) {
        final category = categories[index];
        final amount = data.expense * category.percentage / 100;
        if (amount <= 0) continue;
        segments.add(
          _BudgetSegment(
            label: category.label,
            amount: amount,
            percentage: category.percentage,
            color: _categoryColor(category.label, index),
          ),
        );
      }
    }
    return segments;
  }

  /// All categories including zeros — shown in legend
  List<_BudgetSegment> _allLegendSegments(BudgetData data) {
    final allCategories = data.categories.toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final result = <_BudgetSegment>[];
    for (var index = 0; index < allCategories.length && index < 8; index++) {
      final category = allCategories[index];
      final amount = data.expense * category.percentage / 100;
      result.add(
        _BudgetSegment(
          label: category.label,
          amount: amount,
          percentage: category.percentage,
          color: _categoryColor(category.label, index),
        ),
      );
    }
    if (result.isEmpty) {
      result.add(
        const _BudgetSegment(
          label: 'No activity',
          amount: 0,
          percentage: 0,
          color: Color(0xFFE5E7EB),
          isPlaceholder: true,
        ),
      );
    }
    return result;
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
        color: const Color(0xFF374151),
      ),
    );
    return visible;
  }
}

// ── Range Summary ────────────────────────────────────────────────────────────

class BudgetTotalsCard extends StatelessWidget {
  final BudgetData data;

  const BudgetTotalsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final availableColor = data.available >= 0
        ? const Color(0xFF76C95F)
        : const Color(0xFFFF5E63);
    final depositColor = data.deposit >= 0
        ? const Color(0xFF76C95F)
        : const Color(0xFFFF5E63);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064A42), Color(0xFF052D2E)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0xFFBCA052), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF052D2E).withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL BALANCE',
                        style: TextStyle(
                          color: Color(0xFFC6E2CE),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _fmtMoney(data.available),
                          maxLines: 1,
                          style: const TextStyle(
                            color: Color(0xFFFFC84D),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            data.available >= 0
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color: availableColor,
                            size: 18,
                          ),
                          Expanded(
                            child: Text(
                              '${data.surplusPercent}% available from deposit',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: availableColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFFD9B957),
                  size: 48,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: const Color(0xFFBCA052).withValues(alpha: 0.44),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: 'TOTAL EXPENSE',
                    amount: data.expense,
                    icon: Icons.south_west_rounded,
                    iconColor: const Color(0xFFFF5E63),
                    amountColor: const Color(0xFFFF5E63),
                  ),
                ),
                Container(
                  width: 1,
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: const Color(0xFFBCA052).withValues(alpha: 0.28),
                ),
                Expanded(
                  child: _SummaryMetric(
                    label: 'TOTAL DEPOSIT',
                    amount: data.deposit,
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: depositColor,
                    amountColor: depositColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color amountColor;

  const _SummaryMetric({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 1.2),
            color: iconColor.withValues(alpha: 0.08),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8F4DC),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _fmtMoney(amount),
                  maxLines: 1,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BudgetTopCards extends StatelessWidget {
  final double deposit;
  final double expense;

  const BudgetTopCards({
    super.key,
    required this.deposit,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return BudgetTotalsCard(
      data: BudgetData(deposit: deposit, expense: expense, total: deposit),
    );
  }
}

// ── Period Pill ───────────────────────────────────────────────────────────────

class _PeriodPill extends StatelessWidget {
  final String period;
  const _PeriodPill({required this.period});
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        period,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Category Legend ───────────────────────────────────────────────────────────

class _CategoryLegend extends StatelessWidget {
  final List<_BudgetSegment> segments;
  final Map<String, double> targetPercentages;
  final String periodKey;
  final bool isEditingTargets;
  final void Function(String label, String value) onTargetChanged;
  const _CategoryLegend({
    required this.segments,
    required this.targetPercentages,
    required this.periodKey,
    required this.isEditingTargets,
    required this.onTargetChanged,
  });
  @override
  Widget build(BuildContext context) {
    final visibleSegments = segments
        .where((s) => !s.isPlaceholder)
        .toList(growable: false);
    if (visibleSegments.isEmpty) {
      return const _EmptyLegend();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final segment in visibleSegments)
          _LegendRow(
            segment: segment,
            targetPercentage:
                targetPercentages[segment.label] ?? segment.percentage,
            periodKey: periodKey,
            isEditingTarget: isEditingTargets,
            onTargetChanged: (value) => onTargetChanged(segment.label, value),
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final _BudgetSegment segment;
  final double targetPercentage;
  final String periodKey;
  final bool isEditingTarget;
  final ValueChanged<String> onTargetChanged;
  const _LegendRow({
    required this.segment,
    required this.targetPercentage,
    required this.periodKey,
    required this.isEditingTarget,
    required this.onTargetChanged,
  });
  @override
  Widget build(BuildContext context) {
    final isOverTarget =
        segment.percentage > 0 && segment.percentage > targetPercentage;
    final textColor = isOverTarget
        ? const Color(0xFFDC2626)
        : const Color(0xFF111827);
    final percentColor = isOverTarget ? const Color(0xFFDC2626) : segment.color;
    final valueColor = isOverTarget
        ? const Color(0xFFDC2626)
        : const Color(0xFF334155);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: segment.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: segment.color.withValues(alpha: 0.18),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              segment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          isEditingTarget
              ? SizedBox(
                  width: 52,
                  height: 30,
                  child: TextFormField(
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
                      color: percentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: '%',
                      suffixStyle: TextStyle(
                        color: percentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 7,
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
                        borderSide: BorderSide(color: percentColor),
                      ),
                    ),
                    onChanged: onTargetChanged,
                  ),
                )
              : Text(
                  '${_fmtPercent(segment.percentage)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
            'No budget activity',
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

// ── Donut Figure ──────────────────────────────────────────────────────────────

class _BudgetDonutFigure extends StatelessWidget {
  final BudgetData data;
  final List<_BudgetSegment> segments;
  const _BudgetDonutFigure({required this.data, required this.segments});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 160.0;
        if (availableWidth <= 0) return const SizedBox.shrink();

        // Keep chart compact – max 220px even on wide screens
        final chartSize = math.min(availableWidth, 220.0);

        // Very thin ring: ~5% of diameter, clamped 6–14px
        final ringWidth = (chartSize * 0.05).clamp(6.0, 14.0);
        final outerRadius = chartSize / 2;
        final centerRadius = outerRadius - ringWidth;

        // Center text area fits inside the hole
        final centerTextWidth = centerRadius * 1.55;

        final activeSegmentCount = segments
            .where((s) => !s.isPlaceholder)
            .length;

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
                      sectionsSpace: activeSegmentCount > 1 ? 1.0 : 0,
                      centerSpaceRadius: centerRadius,
                      startDegreeOffset: -90,
                      sections: [
                        for (final segment in segments)
                          PieChartSectionData(
                            value: segment.percentage,
                            color: segment.color,
                            radius: ringWidth,
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
    final availableColor = data.available >= 0
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final scale = (width / 122).clamp(0.65, 1.0).toDouble();
    final surplusPercent = data.deposit > 0
        ? ((data.available / data.deposit) * 100).round()
        : 0;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Available',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _fmtMoney(data.available),
              maxLines: 1,
              style: TextStyle(
                color: availableColor,
                fontSize: 20 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 6 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'SURPLUS $surplusPercent%',
              maxLines: 1,
              style: TextStyle(
                color: availableColor,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 6 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_fmtMoney(data.expense)} / ${_fmtMoney(data.deposit)}',
              maxLines: 1,
              style: TextStyle(
                color: Colors.black,
                fontSize: 12 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            '${data.utilizationPercent}% utilized',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 11 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data Model ────────────────────────────────────────────────────────────────

class _BudgetSegment {
  final String label;
  final double amount;
  final double percentage;
  final Color color;
  final bool isPlaceholder;
  const _BudgetSegment({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
    this.isPlaceholder = false,
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _categoryColor(String label, int index) {
  final normalizedLabel = label.trim().toLowerCase();
  final mappedColor = _categoryColors[normalizedLabel];
  if (mappedColor != null) return mappedColor;
  return _chartPalette[index % _chartPalette.length];
}

String _chartSemanticsLabel(List<_BudgetSegment> segments) {
  final activeSegments = segments.where((segment) => !segment.isPlaceholder);
  if (activeSegments.isEmpty) return 'Budget chart with no activity';
  return activeSegments
      .map(
        (segment) =>
            '${segment.label} ${_fmtPercent(segment.percentage)}%, '
            '${_fmtMoney(segment.amount)}',
      )
      .join(', ');
}

String _fmtMoney(double value) => formatMoney(value);
String _fmtPercent(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

const _overviewTitleStyle = TextStyle(
  color: Color(0xFF111827),
  fontSize: 13,
  fontWeight: FontWeight.w900,
);

const _categoryColors = <String, Color>{
  'payroll': Color(0xFF006B5F),
  'rent': Color(0xFF1F9E78),
  'loan': Color(0xFFD9342B),
  'loan obligation': Color(0xFFD9342B),
  'cogs': Color(0xFFB5D7AA),
  'fuel': Color(0xFFFFB703),
  'food': Color(0xFFFFB703),
  'utilities': Color(0xFF64748B),
  'insurance': Color(0xFF1464F4),
  'shopping': Color(0xFF0E9F7A),
  'transport': Color(0xFF83C98C),
  'entertainment': Color(0xFF8E8E8E),
  'consumable supplies': Color(0xFF74BFA5),
  'equipment': Color(0xFF65B891),
  'other': Color(0xFF5F6368),
  'others': Color(0xFF5F6368),
};

const _chartPalette = <Color>[
  Color(0xFF64748B),
  Color(0xFF1464F4),
  Color(0xFF0E9F7A),
  Color(0xFFFFB703),
  Color(0xFF83C98C),
  Color(0xFF8E8E8E),
  Color(0xFF006B5F),
  Color(0xFFD9342B),
];
