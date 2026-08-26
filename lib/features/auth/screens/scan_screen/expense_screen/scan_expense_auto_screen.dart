import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:savetep/features/auth/screens/scan_screen/mindee/mindee_analysis_models.dart';
import 'package:savetep/features/auth/screens/scan_screen/mindee/mindee_mapping.dart';
import 'package:savetep/features/auth/screens/scan_screen/mindee/mindee_providers.dart';
import 'package:savetep/providers/expense_category_provider.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/money_formatter.dart';
import 'package:savetep/services/recurring_expense_reminder_service.dart';
import 'mindee_expense_fields.dart';
import 'scan_expense_screen.dart';

class ScanExpenseAutoScreen extends ConsumerStatefulWidget {
  const ScanExpenseAutoScreen({super.key});

  @override
  ConsumerState<ScanExpenseAutoScreen> createState() =>
      _ScanExpenseAutoScreenState();
}

class _ScanExpenseAutoScreenState extends ConsumerState<ScanExpenseAutoScreen> {
  Uint8List? _scannedImageBytes;
  bool _isScanning = false;
  bool _hasExtractedData = false;
  bool _isSaving = false;
  bool _isRecurringExpense = false;
  bool _cameraPermissionWasDenied = false;
  CancellationToken? _activeCancellationToken;
  ExpenseScheduleFrequency _recurringFrequency =
      ExpenseScheduleFrequency.monthly;

  late ScannedExpenseData _data;
  late DateTime _recurringStartDate;
  late TextEditingController _totalAmountController;
  late TextEditingController _tipsGratuityController;
  late TextEditingController _payeeController;
  late TextEditingController _cardLast4Controller;

  @override
  void initState() {
    super.initState();
    _data = ScannedExpenseData(transactionDate: AppClock.now);
    _recurringStartDate = _data.transactionDate;
    _totalAmountController = TextEditingController();
    _tipsGratuityController = TextEditingController();
    _payeeController = TextEditingController();
    _cardLast4Controller = TextEditingController();
  }

  @override
  void dispose() {
    _activeCancellationToken?.cancel();
    _totalAmountController.dispose();
    _tipsGratuityController.dispose();
    _payeeController.dispose();
    _cardLast4Controller.dispose();
    super.dispose();
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  // ── Camera picker ─────────────────────────────────────────────────────────

  Future<void> _takePhoto() async {
    if (_cameraPermissionWasDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera access is disabled. Enable it in Settings to take a photo.',
          ),
        ),
      );
      return;
    }

    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isScanning) return;
    debugPrint('[ScanExpense] Starting camera capture.');
    setState(() => _isScanning = true);
    CancellationToken? requestToken;
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
      if (!mounted) return;

      _activeCancellationToken?.cancel();
      requestToken = CancellationToken();
      _activeCancellationToken = requestToken;
      final currentCategory =
          _effectiveCategory(_readAvailableCategories()) ?? _data.category;
      final pendingData = ScannedExpenseData(
        transactionDate: AppClock.now,
        category: currentCategory,
        receiptImage: picked,
      );
      setState(() {
        _scannedImageBytes = bytes;
        _hasExtractedData = false;
        _data = pendingData;
        _recurringStartDate = pendingData.transactionDate;
      });
      _syncControllers(pendingData);

      final extractedData = await _extractExpenseData(
        picked,
        cancellationToken: requestToken,
        currentCategory: currentCategory,
      );
      requestToken.throwIfCancelled();
      if (!mounted || !identical(_activeCancellationToken, requestToken)) {
        return;
      }
      setState(() {
        _isScanning = false;
        _hasExtractedData = true;
        _data = extractedData;
        _recurringStartDate = extractedData.transactionDate;
      });
      _syncControllers(extractedData);
      debugPrint('[ScanExpense] Scan extraction completed successfully.');
    } on MindeeRequestCancelledException {
      return;
    } catch (error, stackTrace) {
      if (error is PlatformException &&
          (error.code == 'camera_access_denied' ||
              error.code == 'camera_access_restricted')) {
        debugPrint('[ScanExpense] Camera access was denied: ${error.code}.');
        if (mounted) {
          setState(() {
            _isScanning = false;
            _cameraPermissionWasDenied = true;
          });
        }
        return;
      }
      debugPrint('[ScanExpense] Mindee analysis failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted &&
          (requestToken == null ||
              identical(_activeCancellationToken, requestToken))) {
        setState(() {
          _isScanning = false;
          _hasExtractedData = false;
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

  Future<ScannedExpenseData> _extractExpenseData(
    XFile picked, {
    required CancellationToken cancellationToken,
    required ExpenseCategory currentCategory,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await container
        .read(documentAnalysisServiceProvider)
        .analyze(
          image: picked,
          type: ScanTransactionType.expense,
          cancellationToken: cancellationToken,
        );
    cancellationToken.throwIfCancelled();
    return container
        .read(expenseMindeeMapperProvider)
        .map(
          result: result,
          image: picked,
          fallbackDate: AppClock.now,
          currentCategory: currentCategory,
        );
  }

  void _syncControllers(ScannedExpenseData data) {
    _totalAmountController.text = data.totalAmount > 0
        ? data.totalAmount.toStringAsFixed(2)
        : '';
    _tipsGratuityController.text = data.tipsGratuity > 0
        ? data.tipsGratuity.toStringAsFixed(2)
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
      _activeCancellationToken?.cancel();
      _activeCancellationToken = null;
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
      final updatedDate = replaceDateOnly(_data.transactionDate, picked);
      setState(() {
        _data = _data.copyWith(transactionDate: updatedDate);
        if (!_isRecurringExpense) {
          _recurringStartDate = updatedDate;
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
    final List<ExpenseCategory> categories = _readAvailableCategories();
    final ExpenseCategory? activeCategory = _effectiveCategory(categories);
    if (activeCategory == null) {
      _showCategoryUnavailableMessage();
      return;
    }
    final selected = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          CategoryPickerSheet(selected: activeCategory, categories: categories),
    );
    if (selected != null && mounted) {
      setState(() => _data = _data.copyWith(category: selected));
    }
  }

  // ── Confirm & Save ────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    final ExpenseCategory? activeCategory = _effectiveCategory(
      _readAvailableCategories(),
    );
    if (activeCategory == null) {
      _showCategoryUnavailableMessage();
      return;
    }
    final String? cardLast4;
    try {
      cardLast4 = normalizeOptionalCardLast4(_cardLast4Controller.text);
    } on MindeeFieldParseException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card last four must contain exactly four digits.'),
        ),
      );
      return;
    }
    final updatedData = _data.copyWith(
      totalAmount: parseMoney(_totalAmountController.text),
      tipsGratuity: parseMoney(_tipsGratuityController.text),
      category: activeCategory,
      payee: _payeeController.text.trim(),
      cardLast4: cardLast4,
      clearCardLast4: cardLast4 == null,
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ExpenseReviewDialog(data: updatedData),
    );
    if (shouldSave != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      if (_isRecurringExpense) {
        await RecurringExpenseReminderService.saveRecurringExpenseWithReminder(
          checkNumber: '',
          totalAmount: updatedData.totalAmount,
          tipsGratuity: updatedData.tipsGratuity,
          transactionDate: updatedData.transactionDate,
          startDate: _recurringStartDate,
          category: updatedData.category.name,
          payee: updatedData.payee,
          isManual: false,
          frequency: _recurringFrequency.label,
        );
      } else {
        await LiabilityService.saveExpense(
          checkNumber: '',
          totalAmount: updatedData.totalAmount,
          tipsGratuity: updatedData.tipsGratuity,
          transactionDate: updatedData.transactionDate,
          category: updatedData.category.name,
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

  List<ExpenseCategory> _readAvailableCategories() {
    return ref
        .read(activeExpenseCategoriesProvider)
        .when(
          data: (List<ExpenseCategory> categories) => categories,
          loading: () => const <ExpenseCategory>[],
          error: (_, _) => const <ExpenseCategory>[],
        );
  }

  void _showCategoryUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense categories are not available yet.'),
      ),
    );
  }

  ExpenseCategory? _effectiveCategory(List<ExpenseCategory> categories) {
    for (final ExpenseCategory category in categories) {
      if (category.id == _data.category.id) return category;
    }
    return categories.firstOrNull;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final List<ExpenseCategory> availableCategories = ref
        .watch(activeExpenseCategoriesProvider)
        .when(
          data: (List<ExpenseCategory> categories) => categories,
          loading: () => const <ExpenseCategory>[],
          error: (_, _) => const <ExpenseCategory>[],
        );
    final ExpenseCategory? activeCategory = _effectiveCategory(
      availableCategories,
    );
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
            onPressed: _isScanning ? null : _takePhoto,
            tooltip: 'Scan receipt',
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
                  'Payee: ${_data.payee.isEmpty ? '-' : _data.payee}  |  Amount: ${formatMoney(_data.totalAmount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
            _ScannerArea(
              imageBytes: _scannedImageBytes,
              isScanning: _isScanning,
              onTap: _takePhoto,
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
                        Row(
                          children: [
                            const Text(
                              'EXPENSE DETAILS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Color(0xFF555555),
                              ),
                            ),
                            const Spacer(),
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
                              child: _ExpenseCurrencyField(
                                fieldKey: const ValueKey<String>(
                                  'expense.totalAmount',
                                ),
                                label: 'TOTAL AMOUNT',
                                controller: _totalAmountController,
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
                        _ExpenseCurrencyField(
                          fieldKey: const ValueKey<String>(
                            'expense.tipsGratuity',
                          ),
                          label: 'TIPS & GRATUITY',
                          controller: _tipsGratuityController,
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
                            onTap: activeCategory == null
                                ? null
                                : _showCategoryPicker,
                            child: Row(
                              children: [
                                Icon(
                                  activeCategory?.icon ?? Icons.hourglass_empty,
                                  size: 20,
                                  color: const Color(0xFF4A90D9),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  activeCategory?.name ?? 'Unavailable',
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
                                  key: const ValueKey<String>('expense.payee'),
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

class _ExpenseCurrencyField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final TextEditingController controller;

  const _ExpenseCurrencyField({
    required this.fieldKey,
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
            key: fieldKey,
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
      height: 180,
      child: ColoredBox(
        color: Colors.white,
        child: imageBytes != null
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
                      'Scanning receipt...',
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
                      'Tap to scan receipt',
                      style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
