import 'package:flutter/material.dart';

import '../../../../services/app_clock.dart';
import '../../../../services/liability_service.dart';
import '../../../../services/money_formatter.dart';

class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key});

  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  int _year = AppClock.now.year;
  bool _isLoading = true;
  List<DepositRecord> _deposits = [];
  List<ExpenseRecord> _expenses = [];

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

  double get _yearIncome => _deposits
      .where((record) => record.transactionDate.year == _year)
      .fold<double>(0, (sum, record) => sum + record.income);

  double get _yearExpenses => _expenses
      .where((record) => record.transactionDate.year == _year)
      .fold<double>(0, (sum, record) => sum + record.totalAmount);

  double get _totalIncome => _yearIncome - _yearExpenses;

  _TaxEstimate get _estimate {
    final taxableIncome = _totalIncome > 0 ? _totalIncome : 0.0;
    final bracket = _TaxBracket.forAmount(taxableIncome);
    final taxDue = taxableIncome * bracket.rate / 100;
    return _TaxEstimate(
      bracket: bracket,
      taxDue: taxDue,
      remaining: _totalIncome - taxDue,
    );
  }

  void _changeYear(int delta) {
    setState(() => _year += delta);
  }

  @override
  Widget build(BuildContext context) {
    final estimate = _estimate;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tax',
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
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                children: [
                  _TaxSummaryCard(
                    year: _year,
                    totalIncome: _totalIncome,
                    estimate: estimate,
                  ),
                  const SizedBox(height: 12),
                  _YearSelector(
                    year: _year,
                    onPrev: () => _changeYear(-1),
                    onNext: () => _changeYear(1),
                  ),
                  const SizedBox(height: 12),
                  _TaxMetricCard(
                    icon: Icons.percent,
                    label: 'ESTIMATE TAX RATE',
                    value: '${estimate.bracket.rateLabel}%',
                    detail: ' ',
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 10),
                  _TaxMetricCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'ESTIMATE TAX TO PAY',
                    value: formatMoney(estimate.taxDue),
                    detail: 'Calculated from total income',
                    color: const Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 10),
                  _TaxMetricCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'LEFT AFTER TAX',
                    value: formatMoney(estimate.remaining),
                    detail: 'Income after estimated tax',
                    color: estimate.remaining >= 0
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TaxSummaryCard extends StatelessWidget {
  final int year;
  final double totalIncome;
  final _TaxEstimate estimate;

  const _TaxSummaryCard({
    required this.year,
    required this.totalIncome,
    required this.estimate,
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
                Text(
                  'TAX YEAR $year',
                  style: const TextStyle(
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
                    formatMoney(totalIncome),
                    style: TextStyle(
                      color: totalIncome >= 0
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Jan 1 - Dec 31 | ${estimate.bracket.rateLabel}% estimate',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
              Icons.request_quote_outlined,
              color: Color(0xFFFACC15),
              size: 27,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _TaxMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 22),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _TaxEstimate {
  final _TaxBracket bracket;
  final double taxDue;
  final double remaining;

  const _TaxEstimate({
    required this.bracket,
    required this.taxDue,
    required this.remaining,
  });
}

class _TaxBracket {
  final double rate;
  final double min;
  final double? max;
  final String label;

  const _TaxBracket({
    required this.rate,
    required this.min,
    required this.max,
    required this.label,
  });

  String get rateLabel => rate.toStringAsFixed(0);

  static const brackets = [
    _TaxBracket(rate: 10, min: 0, max: 12400, label: r'$0 to $12,400'),
    _TaxBracket(rate: 12, min: 12401, max: 50400, label: r'$12,401 to $50,400'),
    _TaxBracket(
      rate: 22,
      min: 50401,
      max: 105700,
      label: r'$50,401 to $105,700',
    ),
    _TaxBracket(
      rate: 24,
      min: 105701,
      max: 201775,
      label: r'$105,701 to $201,775',
    ),
    _TaxBracket(
      rate: 32,
      min: 201776,
      max: 256225,
      label: r'$201,776 to $256,225',
    ),
    _TaxBracket(
      rate: 35,
      min: 256226,
      max: 640600,
      label: r'$256,226 to $640,600',
    ),
    _TaxBracket(rate: 37, min: 640601, max: null, label: r'Over $640,600'),
  ];

  static _TaxBracket forAmount(double amount) {
    for (final bracket in brackets) {
      if (bracket.max == null || amount <= bracket.max!) {
        return bracket;
      }
    }
    return brackets.last;
  }
}
