import 'package:flutter/material.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/money_formatter.dart';
import 'scan_deposit_screen.dart';

class ScanDepositManualScreen extends StatefulWidget {
  const ScanDepositManualScreen({super.key});

  @override
  State<ScanDepositManualScreen> createState() =>
      _ScanDepositManualScreenState();
}

class _ScanDepositManualScreenState extends State<ScanDepositManualScreen> {
  bool _isSaving = false;

  late ScannedDepositData _data;
  late TextEditingController _orderNumberController;
  late TextEditingController _totalAmountController;
  late TextEditingController _creditDepositController;
  late TextEditingController _cashController;
  late TextEditingController _giftCardController;
  late TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    _data = ScannedDepositData(transactionDate: AppClock.now);
    _orderNumberController = TextEditingController(text: _data.orderNumber);
    _totalAmountController = TextEditingController();
    _creditDepositController = TextEditingController();
    _cashController = TextEditingController();
    _giftCardController = TextEditingController();
    _otherController = TextEditingController();
    _creditDepositController.addListener(_updateTotalAmount);
    _cashController.addListener(_updateTotalAmount);
    _giftCardController.addListener(_updateTotalAmount);
    _otherController.addListener(_updateTotalAmount);
  }

  @override
  void dispose() {
    _creditDepositController.removeListener(_updateTotalAmount);
    _cashController.removeListener(_updateTotalAmount);
    _giftCardController.removeListener(_updateTotalAmount);
    _otherController.removeListener(_updateTotalAmount);
    _orderNumberController.dispose();
    _totalAmountController.dispose();
    _creditDepositController.dispose();
    _cashController.dispose();
    _giftCardController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  double _parseAmount(TextEditingController c) => parseMoney(c.text);

  double get _paymentTotal =>
      _parseAmount(_creditDepositController) +
      _parseAmount(_cashController) +
      _parseAmount(_giftCardController) +
      _parseAmount(_otherController);

  void _updateTotalAmount() {
    final total = _paymentTotal;
    final nextText = total > 0 ? formatMoney(total, symbol: false) : '';
    if (_totalAmountController.text == nextText) return;
    _totalAmountController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const DepositDeleteConfirmDialog(),
    );
    if (confirmed == true && mounted) {
      final emptyData = ScannedDepositData(transactionDate: AppClock.now);
      setState(() => _data = emptyData);
      _syncControllers(emptyData);
    }
  }

  void _syncControllers(ScannedDepositData data) {
    _orderNumberController.text = data.orderNumber;
    _creditDepositController.text = data.creditDeposit > 0
        ? data.creditDeposit.toStringAsFixed(2)
        : '';
    _cashController.text = data.cash > 0 ? data.cash.toStringAsFixed(2) : '';
    _giftCardController.text = data.giftCard > 0
        ? data.giftCard.toStringAsFixed(2)
        : '';
    _otherController.text = data.other > 0 ? data.other.toStringAsFixed(2) : '';
    _updateTotalAmount();
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
      setState(() => _data = _data.copyWith(transactionDate: picked));
    }
  }

  // ── Confirm & Save ────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    final updatedData = _data.copyWith(
      orderNumber: _orderNumberController.text.trim(),
      totalAmount: _paymentTotal,
      creditDeposit: parseMoney(_creditDepositController.text),
      cash: parseMoney(_cashController.text),
      giftCard: parseMoney(_giftCardController.text),
      other: parseMoney(_otherController.text),
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => DepositReviewDialog(data: updatedData, isManual: true),
    );
    if (shouldSave != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await LiabilityService.saveDeposit(
        orderNumber: updatedData.orderNumber,
        totalAmount: updatedData.totalAmount,
        creditDeposit: updatedData.creditDeposit,
        cash: updatedData.cash,
        giftCard: updatedData.giftCard,
        other: updatedData.other,
        transactionDate: updatedData.transactionDate,
        isManual: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deposit saved ✓')));
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
          'Deposit',
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
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
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
                  DepositDataCard(
                    orderNumberController: _orderNumberController,
                    totalAmountController: _totalAmountController,
                    creditDepositController: _creditDepositController,
                    cashController: _cashController,
                    giftCardController: _giftCardController,
                    otherController: _otherController,
                    transactionDate: _data.transactionDate,
                    receiptImageBytes: null,
                    onDeleteTap: _confirmDelete,
                    onDateTap: _pickDate,
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
