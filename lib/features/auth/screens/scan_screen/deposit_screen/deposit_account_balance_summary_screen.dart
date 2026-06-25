import 'package:flutter/material.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/money_formatter.dart';

class DepositAccountBalanceSummaryScreen extends StatefulWidget {
  const DepositAccountBalanceSummaryScreen({super.key});

  @override
  State<DepositAccountBalanceSummaryScreen> createState() =>
      _DepositAccountBalanceSummaryScreenState();
}

class _DepositAccountBalanceSummaryScreenState
    extends State<DepositAccountBalanceSummaryScreen> {
  late int _selectedYear;
  late Future<List<DepositBalanceSummary>> _summaryFuture;
  final Set<int> _expandedMonths = <int>{};

  @override
  void initState() {
    super.initState();
    _selectedYear = AppClock.now.year;
    _summaryFuture = _loadSummaries();
  }

  Future<List<DepositBalanceSummary>> _loadSummaries() {
    return LiabilityService.loadDepositBalanceSummariesForYear(
      year: _selectedYear,
    );
  }

  void _changeYear(int delta) {
    final int currentYear = AppClock.now.year;
    final int nextYear = _selectedYear + delta;
    if (nextYear > currentYear) {
      return;
    }

    setState(() {
      _selectedYear = nextYear;
      _expandedMonths.clear();
      _summaryFuture = _loadSummaries();
    });
  }

  void _toggleMonth(int month) {
    setState(() {
      if (!_expandedMonths.add(month)) {
        _expandedMonths.remove(month);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = AppClock.now;
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
          setState(() => _summaryFuture = _loadSummaries());
          await _summaryFuture;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
          children: <Widget>[
            _YearSelector(
              year: _selectedYear,
              onPrevious: () => _changeYear(-1),
              onNext: _selectedYear < now.year ? () => _changeYear(1) : null,
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<DepositBalanceSummary>>(
              future: _summaryFuture,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<DepositBalanceSummary>> snapshot,
                  ) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        height: 260,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final List<DepositBalanceSummary> summaries =
                        snapshot.data ?? const <DepositBalanceSummary>[];
                    final List<DepositBalanceSummary> visibleSummaries =
                        summaries
                            .where(
                              (DepositBalanceSummary summary) =>
                                  _selectedYear < now.year ||
                                  summary.month <= now.month,
                            )
                            .toList(growable: false);
                    return Column(
                      children: <Widget>[
                        for (final DepositBalanceSummary summary
                            in visibleSummaries)
                          _MonthSummaryTile(
                            summary: summary,
                            isExpanded: _expandedMonths.contains(summary.month),
                            onTap: () => _toggleMonth(summary.month),
                          ),
                      ],
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const _YearSelector({
    required this.year,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, size: 22),
          ),
          Expanded(
            child: Text(
              '$year',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
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
}

class _MonthSummaryTile extends StatelessWidget {
  final DepositBalanceSummary summary;
  final bool isExpanded;
  final VoidCallback onTap;

  const _MonthSummaryTile({
    required this.summary,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              child: Row(
                children: <Widget>[
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: const Color(0xFF111827),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _monthNames[summary.month],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatMoney(summary.endingBalance),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...<Widget>[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: <Widget>[
                  _SummaryAmountRow(
                    label:
                        'Beginning deposit balance from the previous month ending balance',
                    amount: summary.beginningBalance,
                  ),
                  const SizedBox(height: 10),
                  _SummaryAmountRow(
                    label: 'Deposits added during the selected month',
                    amount: summary.monthCredits,
                  ),
                  const SizedBox(height: 10),
                  _SummaryAmountRow(
                    label: 'Total expenses during the selected month',
                    amount: summary.monthExpenses,
                  ),
                  const SizedBox(height: 10),
                  _SummaryAmountRow(
                    label: 'Ending deposit balance for the selected month',
                    amount: summary.endingBalance,
                    isEmphasis: true,
                  ),
                ],
              ),
            ),
          ],
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
                  : const Color(0xFF4B5563),
              fontSize: isEmphasis ? 13 : 12,
              fontWeight: isEmphasis ? FontWeight.w800 : FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatMoney(amount),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: isEmphasis ? 15 : 13,
            fontWeight: isEmphasis ? FontWeight.w900 : FontWeight.w700,
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
