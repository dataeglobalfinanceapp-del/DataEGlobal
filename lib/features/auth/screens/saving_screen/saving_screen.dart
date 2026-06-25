import 'package:flutter/material.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/money_formatter.dart';

enum _SavingPeriod { day, week, month }

class SavingScreen extends StatefulWidget {
  const SavingScreen({super.key});

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  static const double _defaultSavingRate = 10;

  _SavingPeriod _period = _SavingPeriod.month;
  int _year = AppClock.now.year;
  double _savingRate = _defaultSavingRate;
  bool _isLoading = true;
  List<DepositRecord> _deposits = [];
  final Map<String, TextEditingController> _savedControllers = {};
  final Map<String, double> _savedAmounts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final controller in _savedControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final deposits = await LiabilityService.loadDeposits();
    if (!mounted) return;
    setState(() {
      _deposits = deposits;
      _isLoading = false;
    });
  }

  double get _yearDeposits => _deposits
      .where((record) => record.transactionDate.year == _year)
      .fold<double>(0, (sum, record) => sum + record.totalAmount);

  double get _totalSavingTarget => _yearDeposits * (_savingRate / 100);

  double get _totalSaving =>
      _savedAmounts.values.fold<double>(0, (sum, amount) => sum + amount);

  List<_SavingPeriodRow> get _savingRows {
    final totalTarget = _totalSavingTarget;

    return switch (_period) {
      _SavingPeriod.day => _buildDailyRows(totalTarget),
      _SavingPeriod.week => _buildWeeklyRows(totalTarget),
      _SavingPeriod.month => _buildMonthlyRows(totalTarget),
    };
  }

  List<_SavingPeriodRow> _buildDailyRows(double totalTarget) {
    final start = DateTime(_year);
    final days = _daysInYear(_year);
    final requiredAmount = days == 0 ? 0.0 : totalTarget / days;

    return List.generate(days, (index) {
      final date = start.add(Duration(days: index));
      return _SavingPeriodRow(
        key: '$_year-day-$index',
        label: _formatDate(date),
        requiredAmount: requiredAmount,
      );
    });
  }

  List<_SavingPeriodRow> _buildWeeklyRows(double totalTarget) {
    final spans = _weekSpansForYear(_year);
    final requiredAmount = spans.isEmpty ? 0.0 : totalTarget / spans.length;

    return List.generate(spans.length, (index) {
      final span = spans[index];
      return _SavingPeriodRow(
        key: '$_year-week-$index',
        label: _formatDateRange(span.start, span.end),
        requiredAmount: requiredAmount,
      );
    });
  }

  List<_SavingPeriodRow> _buildMonthlyRows(double totalTarget) {
    const months = 12;
    final requiredAmount = totalTarget / months;

    return List.generate(months, (index) {
      final month = index + 1;
      return _SavingPeriodRow(
        key: '$_year-month-$month',
        label: _monthNames[month],
        requiredAmount: requiredAmount,
      );
    });
  }

  void _setPeriod(_SavingPeriod period) {
    setState(() => _period = period);
  }

  void _changeYear(int delta) {
    setState(() => _year += delta);
  }

  void _confirmSavedAmount(String key) {
    final controller = _controllerFor(key);
    final amount = parseMoney(controller.text);
    final displayAmount = amount == 0 ? '' : formatMoney(amount, symbol: false);

    setState(() {
      _savedAmounts[key] = amount;
    });

    controller.value = TextEditingValue(
      text: displayAmount,
      selection: TextSelection.collapsed(offset: displayAmount.length),
    );
    FocusManager.instance.primaryFocus?.unfocus();
  }

  TextEditingController _controllerFor(String key) {
    final existing = _savedControllers[key];
    if (existing != null) return existing;

    final amount = _savedAmounts[key] ?? 0;
    final controller = TextEditingController(
      text: amount == 0 ? '' : formatMoney(amount, symbol: false),
    );
    _savedControllers[key] = controller;
    return controller;
  }

  Future<void> _editSavingRate() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _SavingRateDialog(initialRate: _savingRate),
    );

    if (result == null || !mounted) return;

    setState(() => _savingRate = result);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _savingRows;
    final periodTarget = rows.isEmpty ? 0.0 : rows.first.requiredAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saving Plan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    sliver: SliverList.list(
                      children: [
                        _SavingSummary(
                          totalDeposits: _yearDeposits,
                          totalSaving: _totalSaving,
                          savingRate: _savingRate,
                          totalSavingTarget: _totalSavingTarget,
                          periodLabel: _period.label,
                          periodTarget: periodTarget,
                          onEditRate: _editSavingRate,
                        ),
                        const SizedBox(height: 10),
                        _SavingPeriodToggle(
                          period: _period,
                          onChanged: _setPeriod,
                        ),
                        const SizedBox(height: 12),
                        _YearSelector(
                          year: _year,
                          onPrev: () => _changeYear(-1),
                          onNext: () => _changeYear(1),
                        ),
                        const SizedBox(height: 12),
                        const _SavingRowsHeader(),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    sliver: SliverList.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return _SavingPlanRow(
                          key: ValueKey(row.key),
                          label: row.label,
                          controller: _controllerFor(row.key),
                          requiredAmount: row.requiredAmount,
                          savedAmount: _savedAmounts[row.key] ?? 0,
                          onConfirm: () => _confirmSavedAmount(row.key),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
      ),
    );
  }
}

class _SavingSummary extends StatelessWidget {
  final double totalDeposits;
  final double totalSaving;
  final double savingRate;
  final double totalSavingTarget;
  final String periodLabel;
  final double periodTarget;
  final VoidCallback onEditRate;

  const _SavingSummary({
    required this.totalDeposits,
    required this.totalSaving,
    required this.savingRate,
    required this.totalSavingTarget,
    required this.periodLabel,
    required this.periodTarget,
    required this.onEditRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171638),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL DEPOSIT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMoney(totalDeposits),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Saving rate ${_formatRate(savingRate)}%',
                      style: const TextStyle(
                        color: Color(0xFFFACC15),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      tooltip: 'Edit saving rate',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFFFACC15),
                        size: 18,
                      ),
                      onPressed: onEditRate,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SavingSummaryMini(
                        label: 'TOTAL TARGET',
                        amount: totalSavingTarget,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SavingSummaryMini(
                        label: 'PER ${periodLabel.toUpperCase()}',
                        amount: periodTarget,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 120,
            margin: const EdgeInsets.only(left: 14),
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Saving',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMoney(totalSaving),
                    style: const TextStyle(
                      color: Color(0xFFFACC15),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
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

class _SavingRateDialog extends StatefulWidget {
  final double initialRate;

  const _SavingRateDialog({required this.initialRate});

  @override
  State<_SavingRateDialog> createState() => _SavingRateDialogState();
}

class _SavingRateDialogState extends State<_SavingRateDialog> {
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
    final value = double.tryParse(_controller.text.replaceAll('%', '').trim());
    if (value == null || value < 0) {
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

  const _SavingSummaryMini({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatMoney(amount),
            style: const TextStyle(
              color: Color(0xFF93C5FD),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SavingPeriodToggle extends StatelessWidget {
  final _SavingPeriod period;
  final ValueChanged<_SavingPeriod> onChanged;

  const _SavingPeriodToggle({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = [
      (_SavingPeriod.day, 'Day'),
      (_SavingPeriod.week, 'Week'),
      (_SavingPeriod.month, 'Month'),
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

class _YearSelector extends StatelessWidget {
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _YearSelector({
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

class _SavingRowsHeader extends StatelessWidget {
  const _SavingRowsHeader();

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

class _SavingPlanRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double requiredAmount;
  final double savedAmount;
  final VoidCallback onConfirm;

  const _SavingPlanRow({
    super.key,
    required this.label,
    required this.controller,
    required this.requiredAmount,
    required this.savedAmount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final remainingAmount = requiredAmount - savedAmount;
    final remainingColor = remainingAmount > 0
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

class _SavingPeriodRow {
  final String key;
  final String label;
  final double requiredAmount;

  const _SavingPeriodRow({
    required this.key,
    required this.label,
    required this.requiredAmount,
  });
}

class _DateSpan {
  final DateTime start;
  final DateTime end;

  const _DateSpan({required this.start, required this.end});
}

extension on _SavingPeriod {
  String get label {
    return switch (this) {
      _SavingPeriod.day => 'day',
      _SavingPeriod.week => 'week',
      _SavingPeriod.month => 'month',
    };
  }
}

List<_DateSpan> _weekSpansForYear(int year) {
  final firstDay = DateTime(year);
  final lastDay = DateTime(year, 12, 31);
  final weeks = <_DateSpan>[];

  var start = firstDay;
  while (!start.isAfter(lastDay)) {
    final end = start.add(const Duration(days: 6));
    weeks.add(
      _DateSpan(start: start, end: end.isAfter(lastDay) ? lastDay : end),
    );
    start = start.add(const Duration(days: 7));
  }

  return weeks;
}

int _daysInYear(int year) {
  return DateTime(year + 1).difference(DateTime(year)).inDays;
}

String _formatDate(DateTime date) {
  return '${_monthNames[date.month]} ${date.day}';
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
