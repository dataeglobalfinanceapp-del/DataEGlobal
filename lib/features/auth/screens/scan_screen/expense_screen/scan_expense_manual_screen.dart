import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../services/app_clock.dart';
import '../../../../../services/liability_service.dart';
import '../../../../../services/money_formatter.dart';
import '../../../../../services/reminder_service.dart';
import 'scan_expense_screen.dart';

class ScanExpenseManualScreen extends StatefulWidget {
  const ScanExpenseManualScreen({super.key});

  @override
  State<ScanExpenseManualScreen> createState() =>
      _ScanExpenseManualScreenState();
}

class _ScanExpenseManualScreenState extends State<ScanExpenseManualScreen> {
  bool _isSaving = false;
  bool _isRecurringMonthly = false;
  bool _addToReminders = false;
  ExpenseReminderFrequency _reminderFrequency =
      ExpenseReminderFrequency.monthly;

  late ScannedExpenseData _data;
  late DateTime _reminderStartDate;
  late TextEditingController _checkNumberController;
  late TextEditingController _totalAmountController;
  late TextEditingController _payeeController;

  @override
  void initState() {
    super.initState();
    _data = ScannedExpenseData(transactionDate: AppClock.now);
    _reminderStartDate = _data.transactionDate;
    _checkNumberController = TextEditingController();
    _totalAmountController = TextEditingController();
    _payeeController = TextEditingController();
  }

  @override
  void dispose() {
    _checkNumberController.dispose();
    _totalAmountController.dispose();
    _payeeController.dispose();
    super.dispose();
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const DeleteConfirmDialog(),
    );
    if (confirmed == true && mounted) {
      final emptyData = ScannedExpenseData(transactionDate: AppClock.now);
      setState(() {
        _isRecurringMonthly = false;
        _addToReminders = false;
        _reminderStartDate = emptyData.transactionDate;
        _reminderFrequency = ExpenseReminderFrequency.monthly;
        _data = emptyData;
      });
      _checkNumberController.text = '';
      _totalAmountController.text = '';
      _payeeController.text = '';
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data.transactionDate,
      firstDate: DateTime(2020),
      lastDate: AppClock.now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A2340)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _data = _data.copyWith(transactionDate: picked);
        if (!_addToReminders) {
          _reminderStartDate = picked;
        }
      });
    }
  }

  Future<void> _pickReminderStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A2340)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _reminderStartDate = picked);
    }
  }

  // ── Category picker ───────────────────────────────────────────────────────

  Future<void> _showCategoryPicker() async {
    final selected = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CategoryPickerSheet(selected: _data.category),
    );
    if (selected != null && mounted) {
      setState(() => _data = _data.copyWith(category: selected));
    }
  }

  // ── Confirm & Save ────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    final updatedData = _data.copyWith(
      checkNumber: _checkNumberController.text.trim(),
      totalAmount: parseMoney(_totalAmountController.text),
      payee: _payeeController.text.trim(),
    );

    setState(() => _isSaving = true);
    try {
      await LiabilityService.saveExpense(
        checkNumber: updatedData.checkNumber,
        totalAmount: updatedData.totalAmount,
        transactionDate: updatedData.transactionDate,
        category: updatedData.category.label,
        payee: updatedData.payee,
        isManual: true,
        isRecurringMonthly: _isRecurringMonthly,
      );
      await _saveExpenseReminder(updatedData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_saveMessage()),
        ),
      );
      Navigator.pop(context, updatedData);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveExpenseReminder(ScannedExpenseData data) async {
    if (!_addToReminders) return;

    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: _reminderStartDate,
        category: data.category.label,
        amount: data.totalAmount,
        reminderCount: _reminderFrequency.label,
        payee: data.payee,
      ),
    ]);
  }

  String _saveMessage() {
    if (_addToReminders && _isRecurringMonthly) {
      return 'Recurring expense and reminder schedule saved.';
    }
    if (_addToReminders) {
      return 'Expense saved and reminder schedule added.';
    }
    if (_isRecurringMonthly) {
      return 'Recurring expense saved. Future months appear when they start.';
    }
    return 'Expense saved';
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  // ── Build ─────────────────────────────────────────────────────────────────

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
          'Expense',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Text(
                        'MANUAL ENTRY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'MANUAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Data card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8E8E8)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // CHECK NUMBER
                        Row(
                          children: [
                            const Text(
                              'CHECK NUMBER:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Color(0xFF555555),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 20,
                              color: Color(0xFF888888),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: _checkNumberController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _confirmDelete,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 14),
                        // TOTAL AMOUNT
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFD0D0D0),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  6,
                                  12,
                                  8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TOTAL AMOUNT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF888888),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    TextField(
                                      controller: _totalAmountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}'),
                                        ),
                                      ],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A2340),
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                        prefixText: r'$',
                                        prefixStyle: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A2340),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // TRANSACTION DATE
                        InfoRow(
                          label: 'TRANSACTION:',
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 20,
                                  color: Color(0xFF4A90D9),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(_data.transactionDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A2340),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 12),
                        // CATEGORY
                        InfoRow(
                          label: 'CATEGORY:',
                          child: GestureDetector(
                            onTap: _showCategoryPicker,
                            child: Row(
                              children: [
                                Icon(
                                  _data.category.icon,
                                  size: 20,
                                  color: const Color(0xFF4A90D9),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _data.category.label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A2340),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: Color(0xFF888888),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 12),
                        // PAYEE
                        InfoRow(
                          label: 'PAYEE:',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.storefront_outlined,
                                size: 20,
                                color: Color(0xFF4A90D9),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  controller: _payeeController,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A2340),
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 12),
                        RecurringMonthlyOption(
                          value: _isRecurringMonthly,
                          onChanged: (value) {
                            setState(() => _isRecurringMonthly = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 12),
                        ExpenseReminderOption(
                          value: _addToReminders,
                          startDate: _reminderStartDate,
                          frequency: _reminderFrequency,
                          onChanged: (value) {
                            setState(() {
                              _addToReminders = value;
                              if (value) {
                                _reminderStartDate = _data.transactionDate;
                              }
                            });
                          },
                          onPickStartDate: _pickReminderStartDate,
                          onFrequencyChanged: (value) {
                            setState(() => _reminderFrequency = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2340),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
