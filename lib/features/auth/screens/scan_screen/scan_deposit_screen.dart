import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class ScannedDepositData {
  final String orderNumber;
  final double totalAmount;
  final double creditDebt;
  final double cash;
  final double giftCard;
  final double other;
  final DateTime transactionDate;
  // Changed: XFile instead of File — works on both mobile and web
  final XFile? receiptImage;

  const ScannedDepositData({
    this.orderNumber = '01',
    this.totalAmount = 0,
    this.creditDebt = 0,
    this.cash = 0,
    this.giftCard = 0,
    this.other = 0,
    required this.transactionDate,
    this.receiptImage,
  });

  ScannedDepositData copyWith({
    String? orderNumber,
    double? totalAmount,
    double? creditDebt,
    double? cash,
    double? giftCard,
    double? other,
    DateTime? transactionDate,
    XFile? receiptImage,
  }) {
    return ScannedDepositData(
      orderNumber: orderNumber ?? this.orderNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      creditDebt: creditDebt ?? this.creditDebt,
      cash: cash ?? this.cash,
      giftCard: giftCard ?? this.giftCard,
      other: other ?? this.other,
      transactionDate: transactionDate ?? this.transactionDate,
      receiptImage: receiptImage ?? this.receiptImage,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Scan Deposit Screen
// ─────────────────────────────────────────────────────────────────────────────

class ScanDepositScreen extends StatefulWidget {
  const ScanDepositScreen({super.key});

  @override
  State<ScanDepositScreen> createState() => _ScanDepositScreenState();
}

class _ScanDepositScreenState extends State<ScanDepositScreen> {
  XFile? _scannedImage;
  Uint8List? _scannedImageBytes; // Used for Image.memory — works on web + mobile
  bool _isScanning = false;
  bool _dataExtracted = false;
  bool _duplicateWarning = false;

  ScannedDepositData _data = ScannedDepositData(
    transactionDate: DateTime.now(),
  );

  // Field controllers
  late TextEditingController _orderNumberController;
  late TextEditingController _totalAmountController;
  late TextEditingController _creditDebtController;
  late TextEditingController _cashController;
  late TextEditingController _giftCardController;
  late TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    _orderNumberController = TextEditingController(text: _data.orderNumber);
    _totalAmountController = TextEditingController(
        text: _data.totalAmount > 0 ? _data.totalAmount.toStringAsFixed(2) : '');
    _creditDebtController = TextEditingController(
        text: _data.creditDebt > 0 ? _data.creditDebt.toStringAsFixed(2) : '');
    _cashController = TextEditingController(
        text: _data.cash > 0 ? _data.cash.toStringAsFixed(2) : '');
    _giftCardController = TextEditingController(
        text: _data.giftCard > 0 ? _data.giftCard.toStringAsFixed(2) : '');
    _otherController = TextEditingController(
        text: _data.other > 0 ? _data.other.toStringAsFixed(2) : '');
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _totalAmountController.dispose();
    _creditDebtController.dispose();
    _cashController.dispose();
    _giftCardController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  // ── Camera / Gallery picker ───────────────────────────────────────────────

  Future<void> _showCameraPermissionDialog() async {
    final choice = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _CameraPermissionDialog(),
    );

    if (!mounted) return;
    if (choice == 'while' || choice == 'once') {
      _pickImage(ImageSource.camera);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isScanning = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) {
        if (mounted) setState(() => _isScanning = false);
        return;
      }

      // Read bytes — works on both web and mobile (no dart:io needed)
      final bytes = await picked.readAsBytes();

      // Simulate OCR extraction delay
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // Mock extracted data — replace with real OCR/ML Kit result
      setState(() {
        _scannedImage = picked;
        _scannedImageBytes = bytes;
        _isScanning = false;
        _dataExtracted = true;
        _duplicateWarning = true; // simulate duplicate detection
        _data = ScannedDepositData(
          orderNumber: '01',
          totalAmount: 1072.00,
          creditDebt: 558.00,
          cash: 514.00,
          giftCard: 0,
          other: 0,
          transactionDate: DateTime(2026, 2, 25),
          receiptImage: picked,
        );
        _orderNumberController.text = _data.orderNumber;
        _totalAmountController.text = _data.totalAmount.toStringAsFixed(2);
        _creditDebtController.text = _data.creditDebt.toStringAsFixed(2);
        _cashController.text = _data.cash.toStringAsFixed(2);
        _giftCardController.text = _data.giftCard.toStringAsFixed(2);
        _otherController.text = _data.other.toStringAsFixed(2);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _DeleteConfirmDialog(),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _scannedImage = null;
        _scannedImageBytes = null;
        _dataExtracted = false;
        _duplicateWarning = false;
        _data = ScannedDepositData(transactionDate: DateTime.now());
        _orderNumberController.text = _data.orderNumber;
        _totalAmountController.text = '';
        _creditDebtController.text = '';
        _cashController.text = '';
        _giftCardController.text = '';
        _otherController.text = '';
      });
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data.transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A2340),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _data = _data.copyWith(transactionDate: picked));
    }
  }

  // ── Confirm ───────────────────────────────────────────────────────────────

  void _confirm() {
    final updatedData = _data.copyWith(
      orderNumber: _orderNumberController.text.trim(),
      totalAmount: double.tryParse(_totalAmountController.text) ?? 0,
      creditDebt: double.tryParse(_creditDebtController.text) ?? 0,
      cash: double.tryParse(_cashController.text) ?? 0,
      giftCard: double.tryParse(_giftCardController.text) ?? 0,
      other: double.tryParse(_otherController.text) ?? 0,
    );
    // TODO: pass updatedData to your backend/repository
    Navigator.pop(context, updatedData);
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
            onPressed: _showCameraPermissionDialog,
            tooltip: 'Scan receipt',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Scanner area ─────────────────────────────────────────────
            _ScannerArea(
              imageBytes: _scannedImageBytes,
              isScanning: _isScanning,
              onTap: _showCameraPermissionDialog,
            ),

            const SizedBox(height: 16),

            // ── Detected data section ────────────────────────────────────
            if (_dataExtracted) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Header row
                    _DetectedDataHeader(isDuplicate: _duplicateWarning),

                    if (_duplicateWarning) ...[
                      const SizedBox(height: 10),
                      const _DuplicateWarning(),
                    ],

                    const SizedBox(height: 16),

                    // Data card
                    _DataCard(
                      orderNumberController: _orderNumberController,
                      totalAmountController: _totalAmountController,
                      creditDebtController: _creditDebtController,
                      cashController: _cashController,
                      giftCardController: _giftCardController,
                      otherController: _otherController,
                      transactionDate: _data.transactionDate,
                      receiptImageBytes: _scannedImageBytes,
                      onDeleteTap: _confirmDelete,
                      onDateTap: _pickDate,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ── Confirm button ─────────────────────────────────────────────────
      bottomNavigationBar: _dataExtracted
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2340),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner Area Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ScannerArea extends StatelessWidget {
  final Uint8List? imageBytes;
  final bool isScanning;
  final VoidCallback onTap;

  const _ScannerArea({
    required this.imageBytes,
    required this.isScanning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      color: Colors.white,
      child: isScanning
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
          : imageBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image.memory works on web + mobile; Image.file does not work on web
                    Image.memory(imageBytes!, fit: BoxFit.cover),
                    Container(color: Colors.black.withOpacity(0.1)),
                  ],
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
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Or use the ⚡ icon above',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFAAAAAA),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detected Data Header
// ─────────────────────────────────────────────────────────────────────────────

class _DetectedDataHeader extends StatelessWidget {
  final bool isDuplicate;
  const _DetectedDataHeader({required this.isDuplicate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'DETECTED DATA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF555555),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2340),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text(
                'LIVE EXTRACTION',
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Duplicate Warning
// ─────────────────────────────────────────────────────────────────────────────

class _DuplicateWarning extends StatelessWidget {
  const _DuplicateWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: const Text(
        'This data already exists in the system (created at 13:00 on 03/20/2026). Do you want to add it again?',
        style: TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Card
// ─────────────────────────────────────────────────────────────────────────────

class _DataCard extends StatelessWidget {
  final TextEditingController orderNumberController;
  final TextEditingController totalAmountController;
  final TextEditingController creditDebtController;
  final TextEditingController cashController;
  final TextEditingController giftCardController;
  final TextEditingController otherController;
  final DateTime transactionDate;
  final Uint8List? receiptImageBytes;
  final VoidCallback onDeleteTap;
  final VoidCallback onDateTap;

  const _DataCard({
    required this.orderNumberController,
    required this.totalAmountController,
    required this.creditDebtController,
    required this.cashController,
    required this.giftCardController,
    required this.otherController,
    required this.transactionDate,
    required this.receiptImageBytes,
    required this.onDeleteTap,
    required this.onDateTap,
  });

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Order number row ──────────────────────────────────────────
          Row(
            children: [
              const Text(
                'ORDER NUMBER:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF555555),
                ),
              ),
              const Spacer(),
              const Icon(Icons.receipt_long_outlined,
                  size: 20, color: Color(0xFF888888)),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: TextField(
                  controller: orderNumberController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 4, vertical: 6),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDeleteTap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),

          // ── Total amount ──────────────────────────────────────────────
          _AmountFieldRow(
            label: 'TOTAL AMOUNT',
            controller: totalAmountController,
            thumbnailBytes: receiptImageBytes,
          ),

          const SizedBox(height: 12),

          // ── Credit/Debt + Cash ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SmallAmountField(
                  label: 'CREDIT/DEBT',
                  controller: creditDebtController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallAmountField(
                  label: 'CASH',
                  controller: cashController,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Gift card + Other ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SmallAmountField(
                  label: 'GIFT CARD',
                  controller: giftCardController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallAmountField(
                  label: 'OTHER',
                  controller: otherController,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),

          // ── Transaction date ──────────────────────────────────────────
          Row(
            children: [
              const Text(
                'TRANSACTION:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF555555),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDateTap,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined,
                        size: 20, color: Color(0xFF4A90D9)),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(transactionDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2340),
                      ),
                    ),
                  ],
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
// Amount Field Row (with optional thumbnail)
// ─────────────────────────────────────────────────────────────────────────────

class _AmountFieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Uint8List? thumbnailBytes;

  const _AmountFieldRow({
    required this.label,
    required this.controller,
    this.thumbnailBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD0D0D0)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
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
                    prefixText: '\$',
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
        if (thumbnailBytes != null) ...[
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            // Image.memory instead of Image.file — cross-platform safe
            child: Image.memory(
              thumbnailBytes!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small Amount Field (for 2-column grid)
// ─────────────────────────────────────────────────────────────────────────────

class _SmallAmountField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _SmallAmountField({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD0D0D0)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              prefixText: '\$',
              prefixStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Camera Permission Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _CameraPermissionDialog extends StatelessWidget {
  const _CameraPermissionDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Camera icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.videocam_outlined,
                  size: 28, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                children: [
                  TextSpan(text: 'Allow '),
                  TextSpan(
                    text: 'Saving Teps',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                      text:
                          ' to take picture and record video'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _PermissionOption(
              label: 'While using this app',
              onTap: () => Navigator.pop(context, 'while'),
            ),
            const SizedBox(height: 8),
            _PermissionOption(
              label: 'Only this time',
              onTap: () => Navigator.pop(context, 'once'),
            ),
            const SizedBox(height: 8),
            _PermissionOption(
              label: "Don't allow",
              onTap: () => Navigator.pop(context, 'deny'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PermissionOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFDEEBF7),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A5FAD),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete Confirm Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Red warning icon
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: Color(0xFFEF4444), size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'DELETE EXPENSE?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This action will permanently remove this transaction from the ledger and cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD0D0D0)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2340),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
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