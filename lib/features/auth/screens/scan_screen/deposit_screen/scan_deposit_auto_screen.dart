import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:savetep/features/auth/screens/scan_screen/mindee/mindee_analysis_models.dart';
import 'package:savetep/features/auth/screens/scan_screen/mindee/mindee_mapping.dart';
import 'package:savetep/features/auth/screens/scan_screen/mindee/mindee_providers.dart';
import 'package:savetep/services/card_last_four.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/money_formatter.dart';
import 'deposit_form_validator.dart';
import 'scan_deposit_screen.dart';

class ScanDepositAutoScreen extends StatefulWidget {
  const ScanDepositAutoScreen({super.key});

  @override
  State<ScanDepositAutoScreen> createState() => _ScanDepositAutoScreenState();
}

class _ScanDepositAutoScreenState extends State<ScanDepositAutoScreen> {
  static const DepositFormValidator _validator = DepositFormValidator();

  Uint8List? _scannedImageBytes;
  bool _isScanning = false;
  bool _hasExtractedData = false;
  bool _hasPaymentTotalMismatch = false;
  bool _isSaving = false;
  CancellationToken? _activeCancellationToken;

  late ScannedDepositData _data;
  late TextEditingController _orderNumberController;
  late TextEditingController _totalAmountController;
  late TextEditingController _creditDepositController;
  late TextEditingController _cardLastFourController;
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
    _cardLastFourController = TextEditingController();
    _cashController = TextEditingController();
    _giftCardController = TextEditingController();
    _otherController = TextEditingController();
    _totalAmountController.addListener(_updateTotalAmount);
    _creditDepositController.addListener(_updateTotalAmount);
    _cashController.addListener(_updateTotalAmount);
    _giftCardController.addListener(_updateTotalAmount);
    _otherController.addListener(_updateTotalAmount);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startAutomaticExtraction());
    });
  }

  @override
  void dispose() {
    _activeCancellationToken?.cancel();
    _totalAmountController.removeListener(_updateTotalAmount);
    _creditDepositController.removeListener(_updateTotalAmount);
    _cashController.removeListener(_updateTotalAmount);
    _giftCardController.removeListener(_updateTotalAmount);
    _otherController.removeListener(_updateTotalAmount);
    _orderNumberController.dispose();
    _totalAmountController.dispose();
    _creditDepositController.dispose();
    _cardLastFourController.dispose();
    _cashController.dispose();
    _giftCardController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  Future<void> _startAutomaticExtraction() async {
    _activeCancellationToken?.cancel();
    final emptyData = ScannedDepositData(transactionDate: AppClock.now);
    setState(() {
      _scannedImageBytes = null;
      _isScanning = false;
      _hasExtractedData = false;
      _hasPaymentTotalMismatch = false;
      _data = emptyData;
    });
    _syncControllers(emptyData);
    await _showCameraPermissionDialog();
  }

  // ── Camera picker ─────────────────────────────────────────────────────────

  Future<void> _showCameraPermissionDialog() async {
    final choice = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const DepositCameraPermissionDialog(),
    );
    if (!mounted) return;
    debugPrint('[ScanDeposit] Camera permission rationale choice: $choice.');
    if (choice == 'while' || choice == 'once') {
      await _pickImage(ImageSource.camera);
    } else {
      debugPrint(
        '[ScanDeposit] Camera capture was not started because permission was declined.',
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isScanning) return;
    debugPrint('[ScanDeposit] Starting camera capture.');
    setState(() => _isScanning = true);
    CancellationToken? requestToken;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) {
        debugPrint('[ScanDeposit] Camera capture was cancelled.');
        if (mounted) setState(() => _isScanning = false);
        return;
      }
      debugPrint('[ScanDeposit] Image captured; reading image data.');
      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      _activeCancellationToken?.cancel();
      requestToken = CancellationToken();
      _activeCancellationToken = requestToken;
      final currentOrderNumber = _orderNumberController.text.trim();
      final pendingData = ScannedDepositData(
        orderNumber: currentOrderNumber,
        transactionDate: AppClock.now,
        receiptImage: picked,
      );
      setState(() {
        _scannedImageBytes = bytes;
        _hasExtractedData = false;
        _hasPaymentTotalMismatch = false;
        _data = pendingData;
      });
      _syncControllers(pendingData);

      final extractedData = await _extractDepositData(
        picked,
        cancellationToken: requestToken,
        currentAutomaticOrderNumber: currentOrderNumber,
      );
      requestToken.throwIfCancelled();
      if (!mounted || !identical(_activeCancellationToken, requestToken)) {
        return;
      }
      setState(() {
        _isScanning = false;
        _hasExtractedData = true;
        _data = extractedData;
      });
      _syncControllers(extractedData);
      debugPrint('[ScanDeposit] Scan extraction completed successfully.');
    } on MindeeRequestCancelledException {
      return;
    } catch (error, stackTrace) {
      debugPrint('[ScanDeposit] Mindee analysis failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted &&
          (requestToken == null ||
              identical(_activeCancellationToken, requestToken))) {
        setState(() {
          _isScanning = false;
          _hasExtractedData = false;
          _hasPaymentTotalMismatch = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to analyze this image. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (requestToken != null &&
          identical(_activeCancellationToken, requestToken)) {
        _activeCancellationToken = null;
      }
    }
  }

  Future<ScannedDepositData> _extractDepositData(
    XFile picked, {
    required CancellationToken cancellationToken,
    required String currentAutomaticOrderNumber,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await container
        .read(documentAnalysisServiceProvider)
        .analyze(
          image: picked,
          type: ScanTransactionType.deposit,
          cancellationToken: cancellationToken,
        );
    cancellationToken.throwIfCancelled();
    return container
        .read(depositMindeeMapperProvider)
        .map(
          result: result,
          image: picked,
          fallbackDate: AppClock.now,
          currentAutomaticOrderNumber: currentAutomaticOrderNumber,
        );
  }

  void _syncControllers(ScannedDepositData data) {
    _orderNumberController.text = data.orderNumber;
    _creditDepositController.text = data.creditDeposit > 0
        ? data.creditDeposit.toStringAsFixed(2)
        : '';
    _cardLastFourController.text = data.cardLastFour;
    _cashController.text = data.cash > 0 ? data.cash.toStringAsFixed(2) : '';
    _giftCardController.text = data.giftCard > 0
        ? data.giftCard.toStringAsFixed(2)
        : '';
    _otherController.text = data.other > 0 ? data.other.toStringAsFixed(2) : '';
    final total = data.totalAmount > 0 ? data.totalAmount : _paymentTotal;
    _totalAmountController.text = total > 0 ? total.toStringAsFixed(2) : '';
    _updateTotalAmount();
  }

  double _parseAmount(TextEditingController c) => parseMoney(c.text);

  double get _paymentTotal =>
      _parseAmount(_creditDepositController) +
      _parseAmount(_cashController) +
      _parseAmount(_giftCardController) +
      _parseAmount(_otherController);

  void _updateTotalAmount() {
    if (!_hasExtractedData) {
      final total = _paymentTotal;
      final nextText = total > 0 ? formatMoney(total, symbol: false) : '';
      if (_totalAmountController.text != nextText) {
        _totalAmountController.value = TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(offset: nextText.length),
        );
      }
    }

    final totalAmount = parseMoney(_totalAmountController.text);
    final mismatch =
        _hasExtractedData &&
        totalAmount > 0 &&
        !depositPaymentBreakdownMatches(
          totalAmount: totalAmount,
          creditDeposit: _parseAmount(_creditDepositController),
          cash: _parseAmount(_cashController),
          giftCard: _parseAmount(_giftCardController),
          other: _parseAmount(_otherController),
        );
    if (mounted && mismatch != _hasPaymentTotalMismatch) {
      setState(() => _hasPaymentTotalMismatch = mismatch);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const DepositDeleteConfirmDialog(),
    );
    if (confirmed == true && mounted) {
      _activeCancellationToken?.cancel();
      _activeCancellationToken = null;
      final emptyData = ScannedDepositData(transactionDate: AppClock.now);
      setState(() {
        _scannedImageBytes = null;
        _isScanning = false;
        _hasExtractedData = false;
        _hasPaymentTotalMismatch = false;
        _data = emptyData;
      });
      _syncControllers(emptyData);
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
      setState(() => _data = _data.copyWith(transactionDate: picked));
    }
  }

  // ── Confirm & Save ────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    if (_hasPaymentTotalMismatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment methods must match the extracted deposit total before saving.',
          ),
        ),
      );
      return;
    }
    final bool isManualEntry = !_hasExtractedData;
    final double creditDebitAmount = parseMoney(_creditDepositController.text);
    final String cardLastFour = creditDebitAmount > 0
        ? normalizeCardLastFour(_cardLastFourController.text)
        : '';
    final validationMessage = _validator.validateCardLastFour(
      creditDebitAmount: creditDebitAmount,
      cardLastFour: cardLastFour,
    );
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }
    _cardLastFourController.text = cardLastFour;

    final updatedData = _data.copyWith(
      orderNumber: _orderNumberController.text.trim(),
      totalAmount: parseMoney(_totalAmountController.text),
      creditDeposit: creditDebitAmount,
      cardLastFour: cardLastFour,
      cash: parseMoney(_cashController.text),
      giftCard: parseMoney(_giftCardController.text),
      other: parseMoney(_otherController.text),
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) =>
          DepositReviewDialog(data: updatedData, isManual: isManualEntry),
    );
    if (shouldSave != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await LiabilityService.saveDeposit(
        orderNumber: updatedData.orderNumber,
        totalAmount: updatedData.totalAmount,
        creditDeposit: updatedData.creditDeposit,
        cardLastFour: updatedData.cardLastFour,
        cash: updatedData.cash,
        giftCard: updatedData.giftCard,
        other: updatedData.other,
        transactionDate: updatedData.transactionDate,
        isManual: isManualEntry,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deposit saved')));
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
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_outlined, color: Colors.black87),
            onPressed: _isScanning ? null : _showCameraPermissionDialog,
            tooltip: 'Scan receipt',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ScannerArea(
              imageBytes: _scannedImageBytes,
              isScanning: _isScanning,
              onTap: _showCameraPermissionDialog,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _AutoEntryHeader(hasExtractedData: _hasExtractedData),
                  if (_hasPaymentTotalMismatch) ...[
                    const SizedBox(height: 10),
                    const DepositAmountReviewWarning(),
                  ],
                  const SizedBox(height: 16),
                  DepositDataCard(
                    orderNumberController: _orderNumberController,
                    totalAmountController: _totalAmountController,
                    creditDepositController: _creditDepositController,
                    cardLastFourController: _cardLastFourController,
                    cashController: _cashController,
                    giftCardController: _giftCardController,
                    otherController: _otherController,
                    transactionDate: _data.transactionDate,
                    receiptImageBytes: _scannedImageBytes,
                    allowTotalEditing: _hasExtractedData,
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
              onPressed: _isSaving || _isScanning ? null : _confirm,
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

// ─────────────────────────────────────────────────────────────────────────────
// Auto-mode widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AutoEntryHeader extends StatelessWidget {
  final bool hasExtractedData;

  const _AutoEntryHeader({required this.hasExtractedData});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          hasExtractedData ? 'EXTRACTED DATA' : 'DEPOSIT DATA',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF555555),
          ),
        ),
        const Spacer(),
        _AutoEntryStatusBadge(hasExtractedData: hasExtractedData),
      ],
    );
  }
}

class _AutoEntryStatusBadge extends StatelessWidget {
  final bool hasExtractedData;

  const _AutoEntryStatusBadge({required this.hasExtractedData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: hasExtractedData
            ? const Color(0xFF1A2340)
            : const Color(0xFF059669),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasExtractedData ? Icons.check_circle : Icons.edit_outlined,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            hasExtractedData ? 'AUTO EXTRACT' : 'EDITABLE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerArea extends StatelessWidget {
  final Uint8List? imageBytes;
  final bool isScanning;
  final VoidCallback? onTap;

  const _ScannerArea({
    required this.imageBytes,
    required this.isScanning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: ColoredBox(
        color: Colors.white,
        child: imageBytes != null
            ? SizedBox(
                width: double.infinity,
                height: 220,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(imageBytes!, fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    if (isScanning)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x66000000),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 12),
                                Text(
                                  'Extracting data...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : isScanning
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF1A2340)),
                    SizedBox(height: 12),
                    Text(
                      'Extracting data...',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              )
            : GestureDetector(
                onTap: onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.document_scanner_outlined,
                        size: 36,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap to scan receipt',
                      style: TextStyle(fontSize: 15, color: Color(0xFF888888)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Or use the quick action above',
                      style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
