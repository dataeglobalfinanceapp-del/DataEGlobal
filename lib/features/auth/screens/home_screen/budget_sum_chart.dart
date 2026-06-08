import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
            const SizedBox(height: 14),
            _StackedBudgetBar(segments: segments),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${widget.data.utilizationPercent}% used',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  'Surplus ${widget.data.surplusPercent}%',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
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
            if (widget.data.recurringExpenses.isNotEmpty) ...[
              const SizedBox(height: 4),
              const Divider(height: 16, color: Color(0xFFE5E7EB)),
              const Row(
                children: [
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
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  List<_BudgetSegment> _budgetSegments(BudgetData data) {
    if (data.expense <= 0) {
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

    if (categories.isEmpty && data.expense > 0) {
      segments.add(
        _BudgetSegment(
          label: 'Expenses',
          amount: data.expense,
          percentage: 100,
          color: const Color(0xFF2563EB),
        ),
      );
    } else {
      for (final category in categories) {
        final amount = data.expense * category.percentage / 100;
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
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetricBlock(
          label: 'Deposits',
          value: _fmtMoney(data.deposit),
          color: const Color(0xFF16A34A),
        ),
        _MetricBlock(
          label: 'Expenses',
          value: _fmtMoney(data.expense),
          color: const Color(0xFFFF1744),
        ),
        _MetricBlock(
          label: 'Reserves',
          value: _fmtMoney(data.reserve),
          color: data.reserve > 0
              ? const Color(0xFF16A34A)
              : const Color(0xFFFF1744),
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
              fontSize: 12,
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
                fontSize: 18,
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

class _RecurringExpenseRow extends StatelessWidget {
  final RecurringExpenseBudgetItem item;
  final VoidCallback onEditTap;

  const _RecurringExpenseRow({required this.item, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final item = this.item;

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

String _fmtMonth(DateTime date) => '${_monthNames[date.month]} ${date.year}';

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
