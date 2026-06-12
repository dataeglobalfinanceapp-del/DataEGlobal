import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/budget_data.dart';
import '../../../../services/liability_service.dart';
import '../../../../services/local_store_test/local_store.dart';
import '../../../../services/money_formatter.dart';

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

  Future<bool> _updateRecurringExpenseAmount(
    RecurringExpenseBudgetItem item,
    double amount,
  ) async {
    final updated = await LiabilityService.updateRecurringExpenseAmount(
      item.id,
      amount,
    );
    if (!mounted) return updated;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated
              ? 'Recurring expense amount updated.'
              : 'Could not update that recurring expense.',
        ),
      ),
    );
    return updated;
  }

  Future<void> _showRecurringExpenseActions(
    RecurringExpenseBudgetItem item,
  ) async {
    final action = await showModalBottomSheet<_RecurringExpenseAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecurringExpenseActionSheet(item: item),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _RecurringExpenseAction.edit:
        await _editRecurringExpenseAmount(item);
        break;
      case _RecurringExpenseAction.delete:
        await _confirmDeleteRecurringExpense(item);
        break;
    }
  }

  Future<void> _editRecurringExpenseAmount(
    RecurringExpenseBudgetItem item,
  ) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _EditRecurringExpenseDialog(item: item),
    );
    if (amount == null) return;
    await _updateRecurringExpenseAmount(item, amount);
  }

  Future<void> _confirmDeleteRecurringExpense(
    RecurringExpenseBudgetItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recurring expense?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('${item.category} | ${_fmtMoney(item.amount)}'),
            const SizedBox(height: 10),
            Text(
              'This stops the recurring expense starting ${_fmtMonth(item.transactionDate)}. Previous months stay in budget history.',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await LiabilityService.deleteRecurringExpenseFromMonth(
      item.id,
      item.transactionDate,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Recurring expense stopped starting ${_fmtMonth(item.transactionDate)}.'
              : 'Could not find that recurring expense.',
        ),
      ),
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
                    final isTight = contentWidth < 340;
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
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Legend
                        SizedBox(
                          width: legendWidth,
                          child: _CategoryLegend(
                            segments: allLegendSegments,
                            targetPercentages: targetPercentages,
                            periodKey: _periodKey,
                            isEditingTargets: _isEditingTargets,
                            onTargetChanged: _updateTarget,
                          ),
                        ),
                        SizedBox(width: gap),
                        // Vertical divider
                        Container(
                          width: 1,
                          height: dividerHeight,
                          color: const Color(0xFFE5E7EB),
                        ),
                        SizedBox(width: gap),
                        // Donut chart
                        Expanded(
                          child: _BudgetDonutFigure(
                            data: widget.data,
                            segments: segments,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Recurring expenses
                if (widget.data.recurringExpenses.isNotEmpty) ...[
                  SizedBox(height: isWideCard ? 18 : 12),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.repeat, size: 15, color: Color(0xFF0F766E)),
                      SizedBox(width: 6),
                      Text(
                        'Recurring expenses',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...widget.data.recurringExpenses.map(
                    (item) => _RecurringExpenseRow(
                      item: item,
                      onEditTap: () => _showRecurringExpenseActions(item),
                    ),
                  ),
                ] else ...[
                  SizedBox(height: isWideCard ? 18 : 12),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  InkWell(
                    onTap: () {}, // hook up navigation if needed
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.repeat,
                            size: 18,
                            color: Color(0xFF0F766E),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Recurring expenses',
                              style: TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
    final allCategories =
        data.categories.toList()
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

// ── Deposit + Expense Summary Cards ──────────────────────────────────────────

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
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Deposit',
            amount: deposit,
            icon: Icons.download_rounded,
            iconBgColor: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            amountColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Expense',
            amount: expense,
            icon: Icons.upload_rounded,
            iconBgColor: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            amountColor: const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final Color amountColor;
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _fmtMoney(amount),
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final availableColor = data.reserve >= 0
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final scale = (width / 122).clamp(0.65, 1.0).toDouble();
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total Budget',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 11 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _fmtMoney(data.total),
              maxLines: 1,
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: 22 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 6 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Available ${_fmtMoney(data.reserve)}',
              maxLines: 1,
              style: TextStyle(
                color: availableColor,
                fontSize: 12 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: 3 * scale),
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

// ── Edit Recurring Expense Dialog ─────────────────────────────────────────────

class _EditRecurringExpenseDialog extends StatefulWidget {
  final RecurringExpenseBudgetItem item;
  const _EditRecurringExpenseDialog({required this.item});
  @override
  State<_EditRecurringExpenseDialog> createState() =>
      _EditRecurringExpenseDialogState();
}

class _EditRecurringExpenseDialogState
    extends State<_EditRecurringExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatMoney(widget.item.amount, symbol: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(context, parseMoney(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit recurring expense'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              widget.item.category,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: r'$',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = parseMoney(value ?? '');
                if (amount <= 0) return 'Enter an amount greater than 0';
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

// ── Recurring Expense Action Sheet ────────────────────────────────────────────

enum _RecurringExpenseAction { edit, delete }

class _RecurringExpenseActionSheet extends StatelessWidget {
  final RecurringExpenseBudgetItem item;
  const _RecurringExpenseActionSheet({required this.item});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.repeat,
                      color: Color(0xFF0F766E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.category} | ${_fmtMoney(item.amount)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF2563EB),
              ),
              title: const Text('Edit recurring expense'),
              subtitle: const Text('Update the amount'),
              onTap: () => Navigator.pop(context, _RecurringExpenseAction.edit),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(0xFFDC2626),
              ),
              title: const Text('Delete recurring expense'),
              subtitle: Text(
                'Stop starting ${_fmtMonth(item.transactionDate)}',
              ),
              onTap: () =>
                  Navigator.pop(context, _RecurringExpenseAction.delete),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Recurring Expense Row ─────────────────────────────────────────────────────

class _RecurringExpenseRow extends StatelessWidget {
  final RecurringExpenseBudgetItem item;
  final VoidCallback onEditTap;
  const _RecurringExpenseRow({required this.item, required this.onEditTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.repeat, size: 15, color: Color(0xFF0F766E)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _fmtMoney(item.amount),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox.square(
            dimension: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Edit recurring expense',
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              onPressed: onEditTap,
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

String _fmtMonth(DateTime date) => '${_monthNames[date.month]} ${date.year}';

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

const _monthNames = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];