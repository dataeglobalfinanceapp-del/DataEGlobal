import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

enum ExpenseCategory {
  utilities('Utilities', Icons.lightbulb_outline),
  loanObligation('Loan Obligation', Icons.account_balance_outlined),
  payroll('Payroll', Icons.people_outline),
  equipment('Equipment', Icons.precision_manufacturing_outlined),
  cogs('COGS', Icons.inventory_2_outlined),
  insurance('Insurance', Icons.shield_outlined),
  consumableSupplies('Consumable Supplies', Icons.shopping_bag_outlined),
  fuel('Fuel', Icons.local_gas_station_outlined),
  rent('Rent', Icons.home_outlined);

  const ExpenseCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ScannedExpenseData {
  final String checkNumber;
  final double totalAmount;
  final DateTime transactionDate;
  final ExpenseCategory category;
  final String payee;
  // Changed: XFile instead of File — works on both mobile and web
  final XFile? receiptImage;

  const ScannedExpenseData({
    this.checkNumber = '',
    this.totalAmount = 0,
    required this.transactionDate,
    this.category = ExpenseCategory.utilities,
    this.payee = '',
    this.receiptImage,
  });

  ScannedExpenseData copyWith({
    String? checkNumber,
    double? totalAmount,
    DateTime? transactionDate,
    ExpenseCategory? category,
    String? payee,
    XFile? receiptImage,
  }) {
    return ScannedExpenseData(
      checkNumber: checkNumber ?? this.checkNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      category: category ?? this.category,
      payee: payee ?? this.payee,
      receiptImage: receiptImage ?? this.receiptImage,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Scan Expense Screen
// ─────────────────────────────────────────────────────────────────────────────

class ScanExpenseScreen extends StatefulWidget {
  const ScanExpenseScreen({super.key});

  @override
  State<ScanExpenseScreen> createState() => _ScanExpenseScreenState();
}

class _ScanExpenseScreenState extends State<ScanExpenseScreen> {
  XFile? _scannedImage;
  Uint8List? _scannedImageBytes; // Used for Image.memory — works on web + mobile
  bool _isScanning = false;
  bool _dataExtracted = false;

  ScannedExpenseData _data = ScannedExpenseData(
    transactionDate: DateTime.now(),
  );

  late TextEditingController _checkNumberController;
  late TextEditingController _totalAmountController;
  late TextEditingController _payeeController;

  @override
  void initState() {
    super.initState();
    _checkNumberController = TextEditingController(text: _data.checkNumber);
    _totalAmountController = TextEditingController(
        text: _data.totalAmount > 0 ? _data.totalAmount.toStringAsFixed(2) : '');
    _payeeController = TextEditingController(text: _data.payee);
  }

  @override
  void dispose() {
    _checkNumberController.dispose();
    _totalAmountController.dispose();
    _payeeController.dispose();
    super.dispose();
  }

  // ── Camera permission dialog ──────────────────────────────────────────────

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

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // Mock extracted data — replace with real OCR/ML Kit
      setState(() {
        _scannedImage = picked;
        _scannedImageBytes = bytes;
        _isScanning = false;
        _dataExtracted = true;
        _data = ScannedExpenseData(
          checkNumber: '5306',
          totalAmount: 120.00,
          transactionDate: DateTime(2026, 2, 25),
          category: ExpenseCategory.utilities,
          payee: 'Dulce Estilo Shop',
          receiptImage: picked,
        );
        _checkNumberController.text = _data.checkNumber;
        _totalAmountController.text = _data.totalAmount.toStringAsFixed(2);
        _payeeController.text = _data.payee;
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
        _data = ScannedExpenseData(transactionDate: DateTime.now());
        _checkNumberController.text = '';
        _totalAmountController.text = '';
        _payeeController.text = '';
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
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A2340)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _data = _data.copyWith(transactionDate: picked));
    }
  }

  // ── Category picker ───────────────────────────────────────────────────────

  Future<void> _showCategoryPicker() async {
    final selected = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CategoryPickerSheet(selected: _data.category),
    );
    if (selected != null && mounted) {
      setState(() => _data = _data.copyWith(category: selected));
    }
  }

  // ── Confirm ───────────────────────────────────────────────────────────────

  void _confirm() {
    final updatedData = _data.copyWith(
      checkNumber: _checkNumberController.text.trim(),
      totalAmount: double.tryParse(_totalAmountController.text) ?? 0,
      payee: _payeeController.text.trim(),
    );
    Navigator.pop(context, updatedData);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_outlined, color: Colors.black87),
            onPressed: _showCameraPermissionDialog,
            tooltip: 'Scan check',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Check info bar (shown after scan) ────────────────────
            if (_dataExtracted) ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Text(
                  'Check number: ${_data.checkNumber}  |  Amount: \$${_data.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
            ],

            // ── Scanned check image ───────────────────────────────────
            _ScannerArea(
              imageBytes: _scannedImageBytes,
              isScanning: _isScanning,
              onTap: _showCameraPermissionDialog,
            ),

            const SizedBox(height: 16),

            if (_dataExtracted) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2340),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle,
                                  color: Colors.white, size: 14),
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
                          // CHECK NUMBER row
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
                              const Icon(Icons.receipt_long_outlined,
                                  size: 20, color: Color(0xFF888888)),
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
                                        horizontal: 4, vertical: 6),
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
                                  child: const Icon(Icons.delete_outline,
                                      size: 18, color: Color(0xFFEF4444)),
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
                                        color: const Color(0xFFD0D0D0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 6, 12, 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d{0,2}')),
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
                              if (_scannedImageBytes != null) ...[
                                const SizedBox(width: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  // Image.memory instead of Image.file — cross-platform safe
                                  child: Image.memory(
                                    _scannedImageBytes!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 12),

                          // TRANSACTION DATE
                          _InfoRow(
                            label: 'TRANSACTION:',
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined,
                                      size: 20, color: Color(0xFF4A90D9)),
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
                          _InfoRow(
                            label: 'CATEGORY:',
                            child: GestureDetector(
                              onTap: _showCategoryPicker,
                              child: Row(
                                children: [
                                  Icon(_data.category.icon,
                                      size: 20, color: const Color(0xFF4A90D9)),
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
                                  const Icon(Icons.keyboard_arrow_down,
                                      size: 18, color: Color(0xFF888888)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 12),

                          // PAYEE
                          _InfoRow(
                            label: 'PAYEE:',
                            child: Row(
                              children: [
                                const Icon(Icons.storefront_outlined,
                                    size: 20, color: Color(0xFF4A90D9)),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),

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
                          fontSize: 16, fontWeight: FontWeight.w500),
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
// Info Row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _InfoRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF555555),
          ),
        ),
        const Spacer(),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner Area
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
      height: 180,
      color: Colors.white,
      child: isScanning
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1A2340)),
                  SizedBox(height: 12),
                  Text('Scanning check...',
                      style:
                          TextStyle(color: Colors.black54, fontSize: 14)),
                ],
              ),
            )
          : imageBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image.memory instead of Image.file — cross-platform safe
                    Image.memory(imageBytes!, fit: BoxFit.cover),
                    Container(color: Colors.black.withOpacity(0.08)),
                  ],
                )
              : GestureDetector(
                  onTap: onTap,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.document_scanner_outlined,
                          size: 32,
                          color: Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tap to scan check',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Picker Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPickerSheet extends StatefulWidget {
  final ExpenseCategory selected;
  const _CategoryPickerSheet({required this.selected});

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late ExpenseCategory _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ...ExpenseCategory.values.map((cat) {
            final isSelected = _selected == cat;
            return ListTile(
              leading: Icon(cat.icon,
                  size: 22,
                  color: isSelected
                      ? const Color(0xFF1A2340)
                      : const Color(0xFF888888)),
              title: Text(
                cat.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF1A2340)
                      : Colors.black87,
                ),
              ),
              trailing: isSelected
                  ? Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A2340),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 14),
                    )
                  : Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCCCCCC)),
                      ),
                    ),
              onTap: () {
                setState(() => _selected = cat);
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (context.mounted) Navigator.pop(context, cat);
                });
              },
            );
          }),
          const SizedBox(height: 16),
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
                style: TextStyle(
                    fontSize: 14, color: Colors.black87, height: 1.5),
                children: [
                  TextSpan(text: 'Allow '),
                  TextSpan(
                    text: 'Saving Teps',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' to take picture and record video'),
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