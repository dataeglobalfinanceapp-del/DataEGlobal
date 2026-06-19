import 'package:flutter/material.dart';

import 'package:biztrack/services/app_clock.dart';
import 'package:biztrack/services/liability_service.dart';
import 'package:biztrack/services/money_formatter.dart';

class DepositAccountBalanceSummaryScreen extends StatefulWidget {
  const DepositAccountBalanceSummaryScreen({super.key});

  @override
  State<DepositAccountBalanceSummaryScreen> createState() =>
      _DepositAccountBalanceSummaryScreenState();
}

class _DepositAccountBalanceSummaryScreenState
    extends State<DepositAccountBalanceSummaryScreen> {
  late DateTime _selectedMonth;
  late Future<DepositBalanceSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    final DateTime now = AppClock.now;
    _selectedMonth = DateTime(now.year, now.month);
    _summaryFuture = _loadSummary();
  }

  Future<DepositBalanceSummary> _loadSummary() {
    return LiabilityService.loadDepositBalanceSummary(
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
      _summaryFuture = _loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Deposit account balance summary',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _summaryFuture = _loadSummary());
          await _summaryFuture;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            _MonthSelector(
              selectedMonth: _selectedMonth,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 12),
            FutureBuilder<DepositBalanceSummary>(
              future: _summaryFuture,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<DepositBalanceSummary> snapshot,
                  ) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final DepositBalanceSummary summary =
                        snapshot.data ??
                        DepositBalanceSummary(
                          year: _selectedMonth.year,
                          month: _selectedMonth.month,
                          beginningBalance: 0,
                          monthCredits: 0,
                        );
                    return _DepositBalanceSummaryCard(summary: summary);
                  },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, size: 22),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  '${_monthNames[selectedMonth.month]} ${selectedMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _dateRangeLabel(selectedMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, size: 22),
          ),
        ],
      ),
    );
  }

  static String _dateRangeLabel(DateTime month) {
    final DateTime end = DateTime(month.year, month.month + 1, 0);
    return '${_shortDate(month)} - ${_shortDate(end)}';
  }

  static String _shortDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _DepositBalanceSummaryCard extends StatelessWidget {
  final DepositBalanceSummary summary;

  const _DepositBalanceSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFF1E40AF),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Deposit account balance summary',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryAmountRow(
            label: 'Beginning balance from previous month',
            amount: summary.beginningBalance,
          ),
          const Divider(height: 22, color: Color(0xFFE5E7EB)),
          _SummaryAmountRow(
            label: 'Deposits and other credits for selected month',
            amount: summary.monthCredits,
          ),
          const Divider(height: 22, color: Color(0xFFE5E7EB)),
          _SummaryAmountRow(
            label: 'Ending deposit balance',
            amount: summary.endingBalance,
            isEmphasis: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryAmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isEmphasis;

  const _SummaryAmountRow({
    required this.label,
    required this.amount,
    this.isEmphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isEmphasis
                  ? const Color(0xFF111827)
                  : const Color(0xFF6B7280),
              fontSize: isEmphasis ? 13 : 12,
              fontWeight: isEmphasis ? FontWeight.w800 : FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatMoney(amount),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: isEmphasis
                ? const Color(0xFF16A34A)
                : const Color(0xFF111827),
            fontSize: isEmphasis ? 18 : 14,
            fontWeight: isEmphasis ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

const List<String> _monthNames = <String>[
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
