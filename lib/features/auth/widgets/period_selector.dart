import 'package:flutter/material.dart';

import 'package:savetep/services/app_clock.dart';

enum BudgetPeriod {
  week('Week'),
  month('Month'),
  year('Year');

  const BudgetPeriod(this.label);

  final String label;
}

class PeriodSelector extends StatefulWidget {
  const PeriodSelector({
    super.key,
    this.initialPeriod = BudgetPeriod.week,
    this.onPeriodChanged,
    this.onRangeChanged,
  });

  final BudgetPeriod initialPeriod;
  final ValueChanged<BudgetPeriod>? onPeriodChanged;
  final ValueChanged<DateTimeRange>? onRangeChanged;

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  late BudgetPeriod _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
  }

  @override
  void didUpdateWidget(covariant PeriodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialPeriod != widget.initialPeriod) {
      _selectedPeriod = widget.initialPeriod;
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _rangeFor(_selectedPeriod);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 20,
              color: Color(0xFF1E40AF),
            ),
            const SizedBox(width: 8),
            Text(
              '${_formatDate(range.start)} - ${_formatDate(range.end)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            for (final period in BudgetPeriod.values) ...[
              Expanded(
                child: _PeriodButton(
                  label: period.label,
                  isSelected: _selectedPeriod == period,
                  onPressed: () => _selectPeriod(period),
                ),
              ),
              if (period != BudgetPeriod.values.last) const SizedBox(width: 12),
            ],
          ],
        ),
      ],
    );
  }

  void _selectPeriod(BudgetPeriod period) {
    if (_selectedPeriod == period) {
      return;
    }

    setState(() {
      _selectedPeriod = period;
    });

    widget.onPeriodChanged?.call(period);
    widget.onRangeChanged?.call(_rangeFor(period));
  }

  DateTimeRange _rangeFor(BudgetPeriod period) {
    final now = AppClock.now;

    return switch (period) {
      BudgetPeriod.week => DateTimeRange(
        start: now.subtract(const Duration(days: 6)),
        end: now,
      ),
      BudgetPeriod.month => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: now,
      ),
      BudgetPeriod.year => DateTimeRange(start: DateTime(now.year), end: now),
    };
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF1F2937) : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        elevation: 0,
        side: isSelected
            ? BorderSide.none
            : const BorderSide(color: Colors.grey, width: 1),
      ),
      child: Text(label),
    );
  }
}
