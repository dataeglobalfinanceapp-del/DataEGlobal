import 'package:flutter/material.dart';

import 'package:biztrack/services/app_clock.dart';
import 'package:biztrack/services/liability_service.dart';
import 'package:biztrack/services/money_formatter.dart';

enum _ReservePeriod { monthly, quarterly, yearly }

class ReservesScreen extends StatefulWidget {
  const ReservesScreen({super.key});

  @override
  State<ReservesScreen> createState() => _ReservesScreenState();
}

class _ReservesScreenState extends State<ReservesScreen> {
  _ReservePeriod _period = _ReservePeriod.monthly;
  int _year = AppClock.now.year;
  bool _isLoading = true;
  List<DepositRecord> _deposits = [];
  List<ExpenseRecord> _expenses = [];
  final Set<String> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final deposits = await LiabilityService.loadDeposits();
    final expenses = await LiabilityService.loadExpenses();
    if (!mounted) return;
    setState(() {
      _deposits = deposits;
      _expenses = expenses;
      _isLoading = false;
    });
  }

  double get _yearSaving => _deposits
      .where((record) => record.transactionDate.year == _year)
      .fold<double>(0, (sum, record) => sum + record.saving);

  double get _yearIncome => _deposits
      .where((record) => record.transactionDate.year == _year)
      .fold<double>(0, (sum, record) => sum + record.income);

  double get _yearExpenses => _expenses
      .where((record) => record.transactionDate.year == _year)
      .fold<double>(0, (sum, record) => sum + record.totalAmount);

  double get _availableIncome => _yearIncome - _yearExpenses;

  List<_ReserveGroup> get _groups {
    return switch (_period) {
      _ReservePeriod.monthly => List.generate(12, (index) {
        final month = index + 1;
        return _buildGroup(
          key: 'm-$month',
          title: _monthNames[month],
          start: DateTime(_year, month),
          end: DateTime(_year, month + 1, 0),
        );
      }),
      _ReservePeriod.quarterly => List.generate(4, (index) {
        final startMonth = index * 3 + 1;
        final endMonth = startMonth + 2;
        return _buildGroup(
          key: 'q-${index + 1}',
          title: '${_monthNames[startMonth]} - ${_monthNames[endMonth]}',
          start: DateTime(_year, startMonth),
          end: DateTime(_year, endMonth + 1, 0),
        );
      }),
      _ReservePeriod.yearly => [
        _buildGroup(
          key: 'y-$_year',
          title: 'January - December',
          start: DateTime(_year),
          end: DateTime(_year, 12, 31),
        ),
      ],
    };
  }

  _ReserveGroup _buildGroup({
    required String key,
    required String title,
    required DateTime start,
    required DateTime end,
  }) {
    final deposits = _deposits
        .where((record) => _isInRange(record.transactionDate, start, end))
        .toList();
    final expenses =
        _expenses
            .where((record) => _isInRange(record.transactionDate, start, end))
            .toList()
          ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
    final totalDeposits = deposits.fold<double>(
      0,
      (sum, record) => sum + record.totalAmount,
    );
    final totalSaving = deposits.fold<double>(
      0,
      (sum, record) => sum + record.saving,
    );
    final totalIncome = deposits.fold<double>(
      0,
      (sum, record) => sum + record.income,
    );
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, record) => sum + record.totalAmount,
    );

    return _ReserveGroup(
      key: key,
      title: title,
      totalDeposits: totalDeposits,
      totalSaving: totalSaving,
      totalIncome: totalIncome,
      expenses: expenses,
      totalExpenses: totalExpenses,
    );
  }

  bool _isInRange(DateTime value, DateTime start, DateTime end) {
    final date = DateTime(value.year, value.month, value.day);
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    return !date.isBefore(first) && !date.isAfter(last);
  }

  void _setPeriod(_ReservePeriod period) {
    setState(() {
      _period = period;
      _expandedGroups.clear();
    });
  }

  void _changeYear(int delta) {
    setState(() {
      _year += delta;
      _expandedGroups.clear();
    });
  }

  void _toggleGroup(String key) {
    setState(() {
      if (_expandedGroups.contains(key)) {
        _expandedGroups.remove(key);
      } else {
        _expandedGroups.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;

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
          'Income',
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
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                children: [
                  _ReserveSummary(
                    totalIncome: _yearIncome,
                    totalSaving: _yearSaving,
                    availableIncome: _availableIncome,
                  ),
                  const SizedBox(height: 10),
                  _ReservePeriodToggle(period: _period, onChanged: _setPeriod),
                  const SizedBox(height: 12),
                  _YearSelector(
                    year: _year,
                    onPrev: () => _changeYear(-1),
                    onNext: () => _changeYear(1),
                  ),
                  const SizedBox(height: 12),
                  ...groups.map(
                    (group) => _ReserveGroupTile(
                      group: group,
                      isExpanded: _expandedGroups.contains(group.key),
                      onToggle: () => _toggleGroup(group.key),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF171638),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.bar_chart, size: 18),
                      label: const Text(
                        'INVESTMENTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Color(0xFFFACC15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ReserveSummary extends StatelessWidget {
  final double totalIncome;
  final double totalSaving;
  final double availableIncome;

  const _ReserveSummary({
    required this.totalIncome,
    required this.totalSaving,
    required this.availableIncome,
  });

  @override
  Widget build(BuildContext context) {
    final availableColor = availableIncome > 0
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

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
                  'AVAILABLE INCOME',
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
                    formatMoney(availableIncome),
                    style: TextStyle(
                      color: availableColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ReserveSummaryMini(
                        label: 'INCOME',
                        amount: totalIncome,
                        color: const Color(0xFF93C5FD),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ReserveSummaryMini(
                        label: 'SAVING',
                        amount: totalSaving,
                        color: const Color(0xFFFACC15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: Color(0xFFFACC15),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReserveSummaryMini extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _ReserveSummaryMini({
    required this.label,
    required this.amount,
    required this.color,
  });

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
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReservePeriodToggle extends StatelessWidget {
  final _ReservePeriod period;
  final ValueChanged<_ReservePeriod> onChanged;

  const _ReservePeriodToggle({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = [
      (_ReservePeriod.monthly, 'Monthly'),
      (_ReservePeriod.quarterly, 'Quarter'),
      (_ReservePeriod.yearly, 'Yearly'),
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

class _ReserveGroupTile extends StatelessWidget {
  final _ReserveGroup group;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ReserveGroupTile({
    required this.group,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.chevron_right,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatMoney(group.availableIncome),
                    style: TextStyle(
                      color: group.availableIncome > 0
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 9, 14, 7),
              child: Row(
                children: [
                  Expanded(child: _ReserveHeaderText('TRANSACTION')),
                  SizedBox(
                    width: 96,
                    child: _ReserveHeaderText(
                      'AMOUNT',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            _ReserveRow(
              label: 'Total Deposit',
              amount: group.totalDeposits,
              color: const Color(0xFF16A34A),
              isBold: true,
            ),
            _ReserveRow(
              label: 'Saving',
              amount: group.totalSaving,
              color: const Color(0xFFCA8A04),
              isBold: true,
            ),
            _ReserveRow(
              label: 'Income',
              amount: group.totalIncome,
              color: const Color(0xFF2563EB),
              isBold: true,
            ),
            ...group.expenses.map(
              (expense) => _ReserveRow(
                label: expense.payee.isEmpty ? expense.category : expense.payee,
                amount: -expense.totalAmount,
                color: const Color(0xFF111827),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF7E6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AVAILABLE: ${formatMoney(group.availableIncome)}',
                    style: TextStyle(
                      color: group.availableIncome > 0
                          ? const Color(0xFF15803D)
                          : const Color(0xFFEF4444),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReserveHeaderText extends StatelessWidget {
  final String label;
  final TextAlign textAlign;

  const _ReserveHeaderText(this.label, {this.textAlign = TextAlign.left});

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

class _ReserveRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isBold;

  const _ReserveRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                formatMoney(amount),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReserveGroup {
  final String key;
  final String title;
  final double totalDeposits;
  final double totalSaving;
  final double totalIncome;
  final List<ExpenseRecord> expenses;
  final double totalExpenses;

  const _ReserveGroup({
    required this.key,
    required this.title,
    required this.totalDeposits,
    required this.totalSaving,
    required this.totalIncome,
    required this.expenses,
    required this.totalExpenses,
  });

  double get availableIncome => totalIncome - totalExpenses;
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
