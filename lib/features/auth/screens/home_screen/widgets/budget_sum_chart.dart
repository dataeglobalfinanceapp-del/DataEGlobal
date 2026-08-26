import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:savetep/features/auth/screens/home_screen/controllers/home_budget_chart_controller.dart';
import 'package:savetep/features/auth/screens/home_screen/domain/home_budget_chart_calculator.dart';
import 'package:savetep/features/auth/screens/home_screen/models/home_budget_chart_models.dart';
import 'package:savetep/services/money_formatter.dart';

class BudgetSumChart extends StatefulWidget {
  final HomeBudgetData data;
  final String periodKey;
  const BudgetSumChart({super.key, required this.data, this.periodKey = ''});
  @override
  State<BudgetSumChart> createState() => _BudgetSumChartState();
}

class _BudgetSumChartState extends State<BudgetSumChart> {
  late final HomeBudgetChartController _chartController;

  @override
  void initState() {
    super.initState();
    _chartController = HomeBudgetChartController()
      ..addListener(_onStateChanged)
      ..loadTargets();
  }

  @override
  void dispose() {
    _chartController
      ..removeListener(_onStateChanged)
      ..dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  String get _periodKey {
    return HomeBudgetChartCalculator.periodKey(
      selectedPeriod: widget.periodKey,
      dataPeriod: widget.data.period,
    );
  }

  void _updateTarget(String label, String value) {
    _chartController.updateTarget(
      periodKey: _periodKey,
      label: label,
      value: value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = _presentSegments(
      HomeBudgetChartCalculator.budgetSegments(widget.data),
    );
    final allLegendSegments = _presentSegments(
      HomeBudgetChartCalculator.legendSegments(widget.data),
    );
    final targetPercentages = _chartController.targetPercentagesFor(_periodKey);
    final mediaSize = MediaQuery.sizeOf(context);
    final heightScale = (mediaSize.height / 844).clamp(0.78, 1.15).toDouble();
    return ConstrainedBox(
      constraints: const BoxConstraints(),
      child: LayoutBuilder(
        builder: (context, cardConstraints) {
          final isWideCard = cardConstraints.maxWidth >= 560;
          final horizontalPadding = ((isWideCard ? 24.0 : 14.0) * heightScale)
              .clamp(isWideCard ? 20.0 : 10.0, isWideCard ? 28.0 : 14.0)
              .toDouble();
          final topPadding = ((isWideCard ? 18.0 : 14.0) * heightScale)
              .clamp(isWideCard ? 14.0 : 9.0, isWideCard ? 20.0 : 14.0)
              .toDouble();
          final bottomPadding = ((isWideCard ? 18.0 : 14.0) * heightScale)
              .clamp(isWideCard ? 14.0 : 9.0, isWideCard ? 20.0 : 14.0)
              .toDouble();
          final headerGap = ((isWideCard ? 20.0 : 10.0) * heightScale)
              .clamp(isWideCard ? 14.0 : 7.0, isWideCard ? 22.0 : 10.0)
              .toDouble();
          return Container(
            key: const ValueKey('home.overviewCard'),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                        tooltip: _chartController.isEditingTargets
                            ? 'Done'
                            : 'Edit targets',
                        icon: Icon(
                          _chartController.isEditingTargets
                              ? Icons.check_circle_outline
                              : Icons.edit_outlined,
                          size: 18,
                        ),
                        color: const Color(0xFF0F766E),
                        onPressed: _chartController.toggleEditingTargets,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: headerGap),
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
                        : 10.0;
                    // Legend takes fixed portion, chart fills the rest
                    final legendWidth = isWide
                        ? math.min(220.0, contentWidth * 0.36)
                        : math.min(150.0, contentWidth * 0.44);
                    final activeSegmentCount = math.max(
                      1,
                      allLegendSegments.length,
                    );
                    final rowHeight =
                        ((_chartController.isEditingTargets ? 32.0 : 22.0) *
                                heightScale)
                            .clamp(
                              _chartController.isEditingTargets ? 28.0 : 18.0,
                              34.0,
                            )
                            .toDouble();
                    final minChartHeight =
                        ((isWide ? 200.0 : 130.0) * heightScale)
                            .clamp(
                              isWide ? 160.0 : 96.0,
                              isWide ? 220.0 : 130.0,
                            )
                            .toDouble();
                    final dividerHeight = math.max(
                      minChartHeight,
                      activeSegmentCount * rowHeight + 8,
                    );
                    final legend = _CategoryLegend(
                      segments: allLegendSegments,
                      targetPercentages: targetPercentages,
                      periodKey: _periodKey,
                      isEditingTargets: _chartController.isEditingTargets,
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
  List<_BudgetSegment> _presentSegments(List<HomeBudgetSegment> segments) {
    return List<_BudgetSegment>.generate(segments.length, (index) {
      final segment = segments[index];
      final color = segment.isPlaceholder
          ? const Color(0xFFE5E7EB)
          : segment.label == 'Expenses'
          ? const Color(0xFF0F766E)
          : _categoryColor(segment.label, index);
      return _BudgetSegment(data: segment, color: color);
    }, growable: false);
  }

  /// All categories including zeros — shown in legend
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
    final isOverTarget = segment.isOverTarget(targetPercentage);
    final textColor = isOverTarget
        ? const Color(0xFFDC2626)
        : const Color(0xFF111827);
    final percentColor = isOverTarget ? const Color(0xFFDC2626) : segment.color;
    final valueColor = isOverTarget
        ? const Color(0xFFDC2626)
        : const Color(0xFF334155);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
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
                fontSize: 12,
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
              : SizedBox(
                  width: 38,
                  child: Text(
                    '${_fmtPercent(segment.percentage)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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
  final HomeBudgetData data;
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

        final screenSize = MediaQuery.sizeOf(context);
        final screenWidth = screenSize.width;
        final widthChartCap = screenWidth >= 800 ? 300.0 : 220.0;
        final heightChartCap =
            (screenSize.height * (screenWidth >= 800 ? 0.30 : 0.22))
                .clamp(screenWidth >= 800 ? 150.0 : 96.0, widthChartCap)
                .toDouble();
        final maxChartSize = math.min(widthChartCap, heightChartCap);

        // Keep the mobile donut compact while the card stays scan-friendly.
        final chartSize = math.min(availableWidth, maxChartSize);

        // Very thin ring: about 5% of diameter, clamped 6-14px.
        final ringWidth = (chartSize * 0.05).clamp(6.0, 14.0);
        final outerRadius = chartSize / 2;
        final centerRadius = outerRadius - ringWidth;

        // Center text area fits inside the hole
        final centerTextWidth = centerRadius * 1.8;

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
  final HomeBudgetData data;
  final double width;
  const _CenterBudgetText({required this.data, required this.width});
  @override
  Widget build(BuildContext context) {
    final availableColor = data.available >= 0
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final scale = (width / 108).clamp(0.82, 1.0).toDouble();
    final surplusPercent = HomeBudgetChartCalculator.surplusPercent(data);
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
              fontSize: 10 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _fmtMoney(data.available),
              maxLines: 1,
              style: TextStyle(
                color: availableColor,
                fontSize: 15 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 4 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'SURPLUS $surplusPercent%',
              maxLines: 1,
              style: TextStyle(
                color: availableColor,
                fontSize: 11 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 4 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_fmtMoney(data.expense)} / ${_fmtMoney(data.deposit)}',
              maxLines: 1,
              style: TextStyle(
                color: Colors.black,
                fontSize: 10 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            '${data.utilizationPercent}% utilized',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 9 * scale,
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
  final HomeBudgetSegment data;
  final Color color;

  const _BudgetSegment({required this.data, required this.color});

  String get label => data.label;
  double get amount => data.amount;
  double get percentage => data.percentage;
  bool get isPlaceholder => data.isPlaceholder;

  bool isOverTarget(double targetPercentage) {
    return data.isOverTarget(targetPercentage);
  }
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
  'food purchase': Color(0xFFFFB703),
  'insurance': Color(0xFF1464F4),
  'shopping': Color(0xFF0E9F7A),
  'transport': Color(0xFF83C98C),
  'entertainment': Color(0xFF8E8E8E),
  'merchant accounting fees': Color(0xFF74BFA5),
  'gas': Color(0xFFEF4444),
  'water': Color(0xFF0EA5E9),
  'electric': Color(0xFFFBBF24),
  'donation': Color(0xFFEC4899),
  'professional fees': Color(0xFF65B891),
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
