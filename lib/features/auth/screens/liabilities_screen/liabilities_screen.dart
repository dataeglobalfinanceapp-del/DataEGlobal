import 'package:flutter/material.dart';

import 'package:biztrack/services/app_clock.dart';
import 'package:biztrack/services/liability_service.dart';
import 'package:biztrack/services/money_formatter.dart';
import '../../models/liability_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Navigate here from your MenuGrid LIABILITIES tile:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const LiabilitiesScreen()));
// ─────────────────────────────────────────────────────────────────────────────

class LiabilitiesScreen extends StatefulWidget {
  const LiabilitiesScreen({super.key});

  @override
  State<LiabilitiesScreen> createState() => _LiabilitiesScreenState();
}

class _LiabilitiesScreenState extends State<LiabilitiesScreen> {
  LiabilityTab _activeTab = LiabilityTab.loan;
  int _year = AppClock.now.year;

  List<MonthlyLiability> _months = [];
  LiabilitySummary _summary = LiabilitySummary.empty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final months = await LiabilityService.loadMonthlyLiabilities(
      tab: _activeTab,
      year: _year,
    );
    final summary = await LiabilityService.loadLiabilitySummary(_activeTab);

    if (!mounted) return;
    setState(() {
      _months = months;
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _switchTab(LiabilityTab tab) async {
    setState(() {
      _activeTab = tab;
    });
    await _loadData();
  }

  Future<void> _changeYear(int delta) async {
    setState(() {
      _year += delta;
    });
    await _loadData();
  }

  void _toggleMonth(int index) {
    setState(() => _months[index].isExpanded = !_months[index].isExpanded);
  }

  String _fmt(double v) => formatMoney(v);

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
          'Liabilities',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2563EB),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                onPressed: _showAddDialog,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary card ───────────────────────────────────────────────
          _SummaryCard(
            totalOwn: _summary.totalOwed,
            percent: _summary.percent,
            totalPayOff: _summary.totalPayoff,
            balance: _summary.balance,
            fmt: _fmt,
          ),

          // ── Loan / Debt tab bar ────────────────────────────────────────
          _TabBar(
            active: _activeTab,
            onLoanTap: () => _switchTab(LiabilityTab.loan),
            onDebtTap: () => _switchTab(LiabilityTab.debt),
          ),

          const SizedBox(height: 8),

          // ── Year selector ──────────────────────────────────────────────
          _YearSelector(
            year: _year,
            onPrev: () => _changeYear(-1),
            onNext: () => _changeYear(1),
          ),

          const SizedBox(height: 8),

          // ── Month accordion list ───────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _months.length,
                    itemBuilder: (_, i) => _MonthTile(
                      monthly: _months[i],
                      onToggle: () => _toggleMonth(i),
                      fmt: _fmt,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Add dialog ─────────────────────────────────────────────────────────────
  Future<void> _showAddDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AddLiabilityDialog(tab: _activeTab),
    );
    if (saved == true) await _loadData();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final double totalOwn;
  final double percent;
  final double totalPayOff;
  final double balance;
  final String Function(double) fmt;

  const _SummaryCard({
    required this.totalOwn,
    required this.percent,
    required this.totalPayOff,
    required this.balance,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2340),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: TOTAL OWN + value
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL OWN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                fmt(totalOwn),
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Row 2: PERCENT
          Row(
            children: [
              const Text(
                'PERCENT',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          // Row 3: TOTAL PAY OFF + BALANCE labels
          Row(
            children: const [
              Text(
                'TOTAL PAY OFF',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              Spacer(),
              Text(
                'BALANCE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 4: values
          Row(
            children: [
              Text(
                fmt(totalPayOff),
                style: const TextStyle(
                  color: Color(0xFF4ADE80),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                fmt(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loan / Debt tab bar
// ─────────────────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final LiabilityTab active;
  final VoidCallback onLoanTap;
  final VoidCallback onDebtTap;

  const _TabBar({
    required this.active,
    required this.onLoanTap,
    required this.onDebtTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _TabButton(
            label: 'Loan',
            isActive: active == LiabilityTab.loan,
            onTap: onLoanTap,
          ),
          _TabButton(
            label: 'Debt',
            isActive: active == LiabilityTab.debt,
            onTap: onDebtTap,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1A2340) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF888888),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Year selector
// ─────────────────────────────────────────────────────────────────────────────
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
          icon: const Icon(
            Icons.chevron_left,
            size: 22,
            color: Color(0xFF1A2340),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        Text(
          '$year',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A2340),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onNext,
          icon: const Icon(
            Icons.chevron_right,
            size: 22,
            color: Color(0xFF1A2340),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month accordion tile
// ─────────────────────────────────────────────────────────────────────────────
class _MonthTile extends StatelessWidget {
  final MonthlyLiability monthly;
  final VoidCallback onToggle;
  final String Function(double) fmt;

  const _MonthTile({
    required this.monthly,
    required this.onToggle,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          // ── Month header row ─────────────────────────────────────────
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    monthly.isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.chevron_right,
                    size: 20,
                    color: const Color(0xFF1A2340),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    monthly.monthName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    fmt(monthly.total),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ─────────────────────────────────────────
          if (monthly.isExpanded && monthly.entries.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            // Column headers
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text('TRANSACTION', style: _kColHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'STARTING',
                      textAlign: TextAlign.right,
                      style: _kColHeader,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'MINIMUM',
                      textAlign: TextAlign.right,
                      style: _kColHeader,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '%',
                      textAlign: TextAlign.right,
                      style: _kColHeader,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // Entry rows
            ...monthly.entries.map((e) => _EntryRow(entry: e, fmt: fmt)),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // TOTAL row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    fmt(monthly.total),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
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

const _kColHeader = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.5,
  color: Color(0xFF888888),
);

// ─────────────────────────────────────────────────────────────────────────────
// Entry row inside an expanded month
// ─────────────────────────────────────────────────────────────────────────────
class _EntryRow extends StatelessWidget {
  final LiabilityEntry entry;
  final String Function(double) fmt;

  const _EntryRow({required this.entry, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + date
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '(${entry.date})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          // Starting
          Expanded(
            flex: 2,
            child: Text(
              fmt(entry.starting),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          // Minimum
          Expanded(
            flex: 2,
            child: Text(
              fmt(entry.minimum),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          // Percent
          Expanded(
            flex: 1,
            child: Text(
              '${entry.percent}%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Liability Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _AddLiabilityDialog extends StatefulWidget {
  final LiabilityTab tab;
  const _AddLiabilityDialog({required this.tab});

  @override
  State<_AddLiabilityDialog> createState() => _AddLiabilityDialogState();
}

class _AddLiabilityDialogState extends State<_AddLiabilityDialog> {
  final _nameController = TextEditingController();
  final _startingController = TextEditingController();
  final _minimumController = TextEditingController();
  final _percentController = TextEditingController();
  DateTime _date = AppClock.now;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _startingController.dispose();
    _minimumController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A2340)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final starting = parseMoney(_startingController.text);
    final minimum = parseMoney(_minimumController.text);
    final percent = int.tryParse(_percentController.text.trim()) ?? 0;

    if (name.isEmpty || starting <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name and starting amount.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await LiabilityService.saveLiability(
        tab: widget.tab,
        name: name,
        date: _date,
        starting: starting,
        minimum: minimum,
        percent: percent,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.tab == LiabilityTab.loan ? 'Loan' : 'Debt';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add $label',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2340),
              ),
            ),
            const SizedBox(height: 16),

            _DialogField(
              label: 'Name',
              controller: _nameController,
              hint: 'e.g. Car Loan',
            ),
            const SizedBox(height: 12),

            _DialogField(
              label: 'Starting Amount',
              controller: _startingController,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefix: '\$',
            ),
            const SizedBox(height: 12),

            _DialogField(
              label: 'Minimum Payment',
              controller: _minimumController,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefix: '\$',
            ),
            const SizedBox(height: 12),

            _DialogField(
              label: 'Interest %',
              controller: _percentController,
              hint: '0',
              keyboardType: TextInputType.number,
              suffix: '%',
            ),
            const SizedBox(height: 12),

            // Date picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD0D0D0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: Color(0xFF4A90D9),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _fmtDate(_date),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A2340),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD0D0D0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2340),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? prefix;
  final String? suffix;

  const _DialogField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
            prefixText: prefix,
            suffixText: suffix,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF1A2340),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
