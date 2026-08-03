import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:savetep/core/config/dev_backend_config.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/money_formatter.dart';
import 'package:savetep/services/recurring_expense_reminder_service.dart';
import 'scan_expense_screen.dart';

class ScanExpenseAutoScreen extends StatefulWidget {
  const ScanExpenseAutoScreen({super.key});

  @override
  State<ScanExpenseAutoScreen> createState() => _ScanExpenseAutoScreenState();
}

class _ScanExpenseAutoScreenState extends State<ScanExpenseAutoScreen> {
  Uint8List? _scannedImageBytes;
  bool _isScanning = false;
  bool _hasExtractedData = false;
  bool _isSaving = false;
  bool _isRecurringExpense = false;
  ExpenseScheduleFrequency _recurringFrequency =
      ExpenseScheduleFrequency.monthly;

  late ScannedExpenseData _data;
  late DateTime _recurringStartDate;
  late TextEditingController _checkNumberController;
  late TextEditingController _totalAmountController;
  late TextEditingController _payeeController;
  late TextEditingController _cardLast4Controller;

  @override
  void initState() {
    super.initState();
    _data = ScannedExpenseData(transactionDate: AppClock.now);
    _recurringStartDate = _data.transactionDate;
    _checkNumberController = TextEditingController();
    _totalAmountController = TextEditingController();
    _payeeController = TextEditingController();
    _cardLast4Controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startAutomaticExtraction());
    });
  }

  @override
  void dispose() {
    _checkNumberController.dispose();
    _totalAmountController.dispose();
    _payeeController.dispose();
    _cardLast4Controller.dispose();
    super.dispose();
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  Future<void> _startAutomaticExtraction() async {
    final emptyData = ScannedExpenseData(transactionDate: AppClock.now);
    setState(() {
      _scannedImageBytes = null;
      _isScanning = false;
      _hasExtractedData = false;
      _isRecurringExpense = false;
      _recurringStartDate = emptyData.transactionDate;
      _recurringFrequency = ExpenseScheduleFrequency.monthly;
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
      builder: (_) => const CameraPermissionDialog(),
    );
    if (!mounted) return;
    debugPrint('[ScanExpense] Camera permission rationale choice: $choice.');
    if (choice == 'while' || choice == 'once') {
      await _pickImage(ImageSource.camera);
    } else {
      debugPrint(
        '[ScanExpense] Camera capture was not started because permission was declined.',
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    debugPrint('[ScanExpense] Starting camera capture.');
    setState(() => _isScanning = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) {
        debugPrint('[ScanExpense] Camera capture was cancelled.');
        if (mounted) setState(() => _isScanning = false);
        return;
      }
      debugPrint('[ScanExpense] Image captured; reading image data.');
      final bytes = await picked.readAsBytes();
      final extractedData = await _extractExpenseData(picked);
      if (!mounted) return;
      setState(() {
        _scannedImageBytes = bytes;
        _isScanning = false;
        _hasExtractedData = true;
        _data = extractedData;
        _recurringStartDate = extractedData.transactionDate;
      });
      _syncControllers(extractedData);
      debugPrint('[ScanExpense] Scan extraction completed successfully.');
    } catch (error, stackTrace) {
      debugPrint('[ScanExpense] Camera capture or extraction failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $error')),
        );
      }
    }
  }

  Future<ScannedExpenseData> _extractExpenseData(XFile picked) async {
    try {
      final bytes = await picked.readAsBytes();
      final baseUrl = devBackendBaseUrl.endsWith('/')
          ? devBackendBaseUrl.substring(0, devBackendBaseUrl.length - 1)
          : devBackendBaseUrl;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/textract/analyze'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: picked.name,
          contentType: _imageMediaType(picked),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Receipt analysis failed with status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      debugPrint('[ScanExpense] Raw Textract response: ${jsonEncode(decoded)}');
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Receipt analysis returned an invalid response.',
        );
      }

      final vendorName = _optionalResponseString(decoded, 'vendorName');
      final payee = _optionalResponseString(decoded, 'payee');
      final cardLast4 = _optionalResponseString(decoded, 'cardLast4');
      if (cardLast4 != null && !RegExp(r'^\d{4}$').hasMatch(cardLast4)) {
        throw const FormatException('Invalid card last-four value.');
      }

      return ScannedExpenseData(
        checkNumber:
            _optionalResponseString(decoded, 'checkNumber')?.trim() ?? '',
        totalAmount: _parseResponseAmount(decoded['total']),
        transactionDate: _parseResponseDate(
          _optionalResponseString(decoded, 'transactionDate'),
        ),
        category: ExpenseCategory.utilities,
        payee: (payee ?? vendorName ?? '').trim(),
        cardLast4: cardLast4,
        receiptImage: picked,
      );
    } catch (_) {
      rethrow;
    }
  }

  http.MediaType _imageMediaType(XFile picked) {
    final mimeType = picked.mimeType?.toLowerCase();
    if (mimeType == 'image/png' || picked.name.toLowerCase().endsWith('.png')) {
      return http.MediaType('image', 'png');
    }
    if (mimeType == null ||
        mimeType == 'image/jpeg' ||
        mimeType == 'image/jpg' ||
        picked.name.toLowerCase().endsWith('.jpg') ||
        picked.name.toLowerCase().endsWith('.jpeg')) {
      return http.MediaType('image', 'jpeg');
    }

    throw UnsupportedError('Only JPEG and PNG receipt images are supported.');
  }

  String? _optionalResponseString(Map<String, dynamic> response, String key) {
    final value = response[key];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Invalid $key value in receipt analysis response.');
  }

  double _parseResponseAmount(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is! String) {
      throw const FormatException(
        'Invalid total value in receipt analysis response.',
      );
    }

    final normalized = value
        .replaceAll(RegExp(r'[^0-9,.\-]'), '')
        .replaceAll(',', '');
    final amount = double.tryParse(normalized);
    if (amount == null) {
      throw FormatException('Unable to parse receipt total: $value');
    }
    return amount;
  }

  DateTime _parseResponseDate(String? value) {
    if (value == null || value.trim().isEmpty) return AppClock.now;

    final trimmed = value.trim();
    final isoDate = DateTime.tryParse(trimmed);
    if (isoDate != null) {
      return DateTime(isoDate.year, isoDate.month, isoDate.day);
    }

    final match = RegExp(
      r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2}|\d{4})$',
    ).firstMatch(trimmed);
    if (match == null) {
      throw FormatException('Unable to parse receipt date: $value');
    }

    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);
    var year = int.parse(match.group(3)!);
    if (year < 100) year += 2000;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw FormatException('Unable to parse receipt date: $value');
    }
    return parsed;
  }

  void _syncControllers(ScannedExpenseData data) {
    _checkNumberController.text = data.checkNumber;
    _totalAmountController.text = data.totalAmount > 0
        ? data.totalAmount.toStringAsFixed(2)
        : '';
    _payeeController.text = data.payee;
    _cardLast4Controller.text = data.cardLast4 ?? '';
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
        _scannedImageBytes = null;
        _isScanning = false;
        _hasExtractedData = false;
        _data = emptyData;
        _isRecurringExpense = false;
        _recurringStartDate = emptyData.transactionDate;
        _recurringFrequency = ExpenseScheduleFrequency.monthly;
      });
      _syncControllers(emptyData);
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await pickExpenseScheduleDate(
      context,
      initialDate: _data.transactionDate,
      firstDate: DateTime(2020),
      lastDate: AppClock.now,
    );
    if (picked != null && mounted) {
      setState(() {
        _data = _data.copyWith(transactionDate: picked);
        if (!_isRecurringExpense) {
          _recurringStartDate = picked;
        }
      });
    }
  }

  Future<void> _pickRecurringStartDate() async {
    final picked = await pickExpenseScheduleDate(
      context,
      initialDate: _recurringStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _recurringStartDate = picked);
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
    final cardLast4 = _cardLast4Controller.text.trim();
    final updatedData = ScannedExpenseData(
      checkNumber: _checkNumberController.text.trim(),
      totalAmount: parseMoney(_totalAmountController.text),
      transactionDate: _data.transactionDate,
      category: _data.category,
      payee: _payeeController.text.trim(),
      cardLast4: cardLast4.isEmpty ? null : cardLast4,
      receiptImage: _data.receiptImage,
    );

    setState(() => _isSaving = true);
    try {
      if (_isRecurringExpense) {
        await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
          checkNumber: updatedData.checkNumber,
          totalAmount: updatedData.totalAmount,
          transactionDate: updatedData.transactionDate,
          startDate: _recurringStartDate,
          category: updatedData.category.label,
          payee: updatedData.payee,
          isManual: false,
          frequency: _recurringFrequency.label,
        );
      } else {
        await LiabilityService.saveExpense(
          checkNumber: updatedData.checkNumber,
          totalAmount: updatedData.totalAmount,
          transactionDate: updatedData.transactionDate,
          category: updatedData.category.label,
          payee: updatedData.payee,
          isManual: false,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_saveMessage())));
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

  String _saveMessage() {
    if (_isRecurringExpense) {
      return 'Recurring expense and reminder schedule saved.';
    }
    return 'Expense saved';
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
            if (_hasExtractedData)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  'Check: ${_data.checkNumber}  |  Amount: ${formatMoney(_data.totalAmount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
            _ScannerArea(
              imageBytes: _scannedImageBytes,
              isScanning: _isScanning,
              onTap: _showCameraPermissionDialog,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AutoEntryHeader(hasExtractedData: _hasExtractedData),
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
                            if (_scannedImageBytes != null) ...[
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
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
                                  formatExpenseDate(_data.transactionDate),
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
                        // CARD LAST 4
                        InfoRow(
                          label: 'CARD LAST 4:',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.credit_card_outlined,
                                size: 20,
                                color: Color(0xFF4A90D9),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  key: const ValueKey<String>(
                                    'expense.cardLast4',
                                  ),
                                  controller: _cardLast4Controller,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
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
                        RecurringExpenseOption(
                          value: _isRecurringExpense,
                          startDate: _recurringStartDate,
                          frequency: _recurringFrequency,
                          onChanged: (value) {
                            setState(() {
                              _isRecurringExpense = value;
                              if (value) {
                                _recurringStartDate = _data.transactionDate;
                              }
                            });
                          },
                          onPickStartDate: _pickRecurringStartDate,
                          onFrequencyChanged: (value) {
                            setState(() => _recurringFrequency = value);
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

// ─────────────────────────────────────────────────────────────────────────────
// Scanner Area (auto-mode only)
// ─────────────────────────────────────────────────────────────────────────────

class _AutoEntryHeader extends StatelessWidget {
  final bool hasExtractedData;

  const _AutoEntryHeader({required this.hasExtractedData});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          hasExtractedData ? 'EXTRACTED DATA' : 'EXPENSE DATA',
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
  final VoidCallback onTap;
  const _ScannerArea({
    required this.imageBytes,
    required this.isScanning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 180,
      child: ColoredBox(
        color: Colors.white,
        child: isScanning
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF1A2340)),
                    SizedBox(height: 12),
                    Text(
                      'Scanning check...',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              )
            : imageBytes != null
            ? SizedBox(
                width: double.infinity,
                height: 180,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(imageBytes!, fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
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
                      style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
