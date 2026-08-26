import 'package:flutter/material.dart';

import 'package:savetep/features/auth/screens/saving_screen/saving_screen_models.dart';
import 'package:savetep/features/auth/widgets/summary_card_shell.dart';
import 'package:savetep/services/money_formatter.dart';

class SavingSummary extends StatelessWidget {
  final double totalDeposit;
  final double totalSaving;
  final double savingRate;
  final double totalSavingTarget;
  final String periodLabel;
  final double periodTarget;
  final VoidCallback onEditRate;

  const SavingSummary({
    super.key,
    required this.totalDeposit,
    required this.totalSaving,
    required this.savingRate,
    required this.totalSavingTarget,
    required this.periodLabel,
    required this.periodTarget,
    required this.onEditRate,
  });

  @override
  Widget build(BuildContext context) {
    return SummaryCardShell(
      builder: (BuildContext context, SummaryCardMetrics metrics) {
        final totalSavingWidth = (metrics.width * 0.34)
            .clamp(104.0, metrics.isTablet ? 170.0 : 136.0)
            .toDouble();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _SavingSummaryDetails(
                totalDeposit: totalDeposit,
                savingRate: savingRate,
                totalSavingTarget: totalSavingTarget,
                periodLabel: periodLabel,
                periodTarget: periodTarget,
                onEditRate: onEditRate,
                metrics: metrics,
              ),
            ),
            SummaryCardColumnDivider(
              height: metrics.tallColumnDividerHeight,
              horizontalMargin: metrics.columnDividerMargin,
            ),
            SizedBox(
              width: totalSavingWidth,
              child: _SavingTotalMetric(
                totalSaving: totalSaving,
                metrics: metrics,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SavingSummaryDetails extends StatelessWidget {
  final double totalDeposit;
  final double savingRate;
  final double totalSavingTarget;
  final String periodLabel;
  final double periodTarget;
  final VoidCallback onEditRate;
  final SummaryCardMetrics metrics;

  const _SavingSummaryDetails({
    required this.totalDeposit,
    required this.savingRate,
    required this.totalSavingTarget,
    required this.periodLabel,
    required this.periodTarget,
    required this.onEditRate,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final rateFontSize =
        ((metrics.isTablet ? 14.0 : 13.0) * metrics.heightScale)
            .clamp(11.0, metrics.isTablet ? 15.0 : 13.0)
            .toDouble();
    final totalDepositFontSize =
        ((metrics.isTablet ? 30.0 : 28.0) * metrics.heightScale)
            .clamp(22.0, metrics.isTablet ? 34.0 : 28.0)
            .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'TOTAL DEPOSIT',
          style: TextStyle(
            color: SummaryCardTokens.label,
            fontSize: metrics.primaryLabelFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: metrics.primaryVerticalGap + 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatMoney(totalDeposit),
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontSize: totalDepositFontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Saving rate ${_formatRate(savingRate)}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SummaryCardTokens.balanceAmount,
                  fontSize: rateFontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 2),
            IconButton(
              tooltip: 'Edit saving rate',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.edit_outlined,
                color: SummaryCardTokens.balanceAmount,
                size: metrics.isTablet ? 19 : 18,
              ),
              onPressed: onEditRate,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _SavingSummaryMini(
                label: 'TOTAL TARGET',
                amount: totalSavingTarget,
                metrics: metrics,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SavingSummaryMini(
                label: 'PER ${periodLabel.toUpperCase()}',
                amount: periodTarget,
                metrics: metrics,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SavingTotalMetric extends StatelessWidget {
  final double totalSaving;
  final SummaryCardMetrics metrics;

  const _SavingTotalMetric({required this.totalSaving, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final labelFontSize =
        ((metrics.isTablet ? 14.0 : 13.0) * metrics.heightScale)
            .clamp(11.0, metrics.isTablet ? 15.0 : 13.0)
            .toDouble();
    final amountFontSize =
        ((metrics.isTablet ? 26.0 : 24.0) * metrics.heightScale)
            .clamp(20.0, metrics.isTablet ? 30.0 : 24.0)
            .toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Saving',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: SummaryCardTokens.secondaryLabel,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatMoney(totalSaving),
            maxLines: 1,
            style: TextStyle(
              color: SummaryCardTokens.balanceAmount,
              fontSize: amountFontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class SavingRateDialog extends StatefulWidget {
  final double initialRate;

  const SavingRateDialog({super.key, required this.initialRate});

  @override
  State<SavingRateDialog> createState() => _SavingRateDialogState();
}

class _SavingRateDialogState extends State<SavingRateDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatRate(widget.initialRate));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = SavingRateInput.parse(_controller.text);
    if (value == null) {
      setState(() => _errorText = 'Enter a rate of 0 or higher');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit saving rate'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Saving rate',
          suffixText: '%',
          errorText: _errorText,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _SavingSummaryMini extends StatelessWidget {
  final String label;
  final double amount;
  final SummaryCardMetrics metrics;

  const _SavingSummaryMini({
    required this.label,
    required this.amount,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final labelFontSize =
        ((metrics.isTablet ? 11.0 : 10.0) * metrics.heightScale)
            .clamp(8.5, metrics.isTablet ? 12.0 : 10.0)
            .toDouble();
    final amountFontSize =
        ((metrics.isTablet ? 15.0 : 14.0) * metrics.heightScale)
            .clamp(12.0, metrics.isTablet ? 17.0 : 14.0)
            .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: SummaryCardTokens.label,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatMoney(amount),
            style: TextStyle(
              color: SummaryCardTokens.supportingAmount,
              fontSize: amountFontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class SavingPeriodToggle extends StatelessWidget {
  final SavingPeriod period;
  final ValueChanged<SavingPeriod> onChanged;

  const SavingPeriodToggle({
    super.key,
    required this.period,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (SavingPeriod.day, 'Day'),
      (SavingPeriod.week, 'Week'),
      (SavingPeriod.month, 'Month'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: items.map((item) {
          final isActive = period == item.$1;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(item.$1),
              borderRadius: BorderRadius.circular(3),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF171638) : Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class YearSelector extends StatelessWidget {
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const YearSelector({
    super.key,
    required this.year,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, size: 20),
        ),
        Text(
          '$year',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}

class PastPeriodsToggle extends StatelessWidget {
  final String label;
  final bool showAll;
  final int count;
  final VoidCallback onToggle;

  const PastPeriodsToggle({
    super.key,
    required this.label,
    required this.showAll,
    required this.count,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label ($count)',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: onToggle,
            child: Text(showAll ? 'Show less' : 'Show all'),
          ),
        ],
      ),
    );
  }
}

class SavingRowsHeader extends StatelessWidget {
  const SavingRowsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: _SavingHeaderText('DATE')),
          SizedBox(width: 10),
          SizedBox(
            width: 148,
            child: _SavingHeaderText('SAVED', textAlign: TextAlign.right),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: _SavingHeaderText('REMAINING', textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class SavingPlanRow extends StatelessWidget {
  final SavingPeriodRow row;
  final SavingPeriod period;
  final TextEditingController controller;
  final double remainingAmount;
  final VoidCallback onConfirm;

  const SavingPlanRow({
    super.key,
    required this.row,
    required this.period,
    required this.controller,
    required this.remainingAmount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final remainingColor = remainingAmount == 0
        ? const Color(0xFF16A34A)
        : remainingAmount > 0
        ? const Color(0xFFDC2626)
        : const Color(0xFF111827);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              _formatRowLabel(period, row),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 148,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '0.00',
                      prefixText: r'$ ',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                    ),
                    onSubmitted: (_) => onConfirm(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Confirm saving amount',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                  onPressed: onConfirm,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                formatMoney(remainingAmount),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: remainingColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingHeaderText extends StatelessWidget {
  final String label;
  final TextAlign textAlign;

  const _SavingHeaderText(this.label, {this.textAlign = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: textAlign,
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}

extension SavingPeriodPresentation on SavingPeriod {
  String get label {
    return switch (this) {
      SavingPeriod.day => 'day',
      SavingPeriod.week => 'week',
      SavingPeriod.month => 'month',
    };
  }

  String get pastLabel {
    return switch (this) {
      SavingPeriod.day => 'Past dates',
      SavingPeriod.week => 'Past weeks',
      SavingPeriod.month => 'Past months',
    };
  }
}

String _formatRowLabel(SavingPeriod period, SavingPeriodRow row) {
  return switch (period) {
    SavingPeriod.day => '${_monthNames[row.start.month]} ${row.start.day}',
    SavingPeriod.week => _formatDateRange(row.start, row.end),
    SavingPeriod.month => _monthNames[row.start.month],
  };
}

String _formatDateRange(DateTime start, DateTime end) {
  if (start.month == end.month) {
    return '${_monthNames[start.month]} ${start.day}-${end.day}';
  }
  return '${_monthNames[start.month]} ${start.day} - '
      '${_monthNames[end.month]} ${end.day}';
}

String _formatRate(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

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
