import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:savetep/services/card_last_four.dart';
import 'package:savetep/services/money_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class ScannedDepositData {
  final String orderNumber;
  final double totalAmount;
  final double creditDeposit;
  final String cardLastFour;
  final double cash;
  final double giftCard;
  final double other;
  final DateTime transactionDate;
  final XFile? receiptImage;

  ScannedDepositData({
    this.orderNumber = '01',
    this.totalAmount = 0,
    this.creditDeposit = 0,
    String cardLastFour = '',
    this.cash = 0,
    this.giftCard = 0,
    this.other = 0,
    required this.transactionDate,
    this.receiptImage,
  }) : cardLastFour = normalizeCardLastFour(cardLastFour);

  ScannedDepositData copyWith({
    String? orderNumber,
    double? totalAmount,
    double? creditDeposit,
    String? cardLastFour,
    double? cash,
    double? giftCard,
    double? other,
    DateTime? transactionDate,
    XFile? receiptImage,
  }) {
    return ScannedDepositData(
      orderNumber: orderNumber ?? this.orderNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      creditDeposit: creditDeposit ?? this.creditDeposit,
      cardLastFour: cardLastFour ?? this.cardLastFour,
      cash: cash ?? this.cash,
      giftCard: giftCard ?? this.giftCard,
      other: other ?? this.other,
      transactionDate: transactionDate ?? this.transactionDate,
      receiptImage: receiptImage ?? this.receiptImage,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class DepositAmountReviewWarning extends StatelessWidget {
  const DepositAmountReviewWarning({super.key});
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
        'The extracted total does not match the payment breakdown. Review the payment amounts before saving.',
        style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, height: 1.5),
      ),
    );
  }
}

class DepositDataCard extends StatelessWidget {
  final TextEditingController orderNumberController;
  final TextEditingController totalAmountController;
  final TextEditingController creditDepositController;
  final TextEditingController cardLastFourController;
  final TextEditingController cashController;
  final TextEditingController giftCardController;
  final TextEditingController otherController;
  final DateTime transactionDate;
  final Uint8List? receiptImageBytes;
  final bool allowTotalEditing;
  final VoidCallback onDeleteTap;
  final VoidCallback onDateTap;

  const DepositDataCard({
    super.key,
    required this.orderNumberController,
    required this.totalAmountController,
    required this.creditDepositController,
    required this.cardLastFourController,
    required this.cashController,
    required this.giftCardController,
    required this.otherController,
    required this.transactionDate,
    required this.receiptImageBytes,
    this.allowTotalEditing = false,
    required this.onDeleteTap,
    required this.onDateTap,
  });

  String _fmt(DateTime d) =>
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
              const Icon(
                Icons.receipt_long_outlined,
                size: 20,
                color: Color(0xFF888888),
              ),
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
                      horizontal: 4,
                      vertical: 6,
                    ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TotalAmountDisplay(
                  label: 'TOTAL AMOUNT',
                  controller: totalAmountController,
                  thumbnailBytes: receiptImageBytes,
                  isEditable: allowTotalEditing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallDataField(
                  label: 'CARD LAST 4',
                  controller: cardLastFourController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  fieldKey: const ValueKey('deposit.cardLastFour'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallAmountField(
                  label: 'CREDIT/DEBIT',
                  controller: creditDepositController,
                  fieldKey: const ValueKey('deposit.creditDebitAmount'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallAmountField(
                  label: 'CASH',
                  controller: cashController,
                  fieldKey: const ValueKey('deposit.cashAmount'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallAmountField(
                  label: 'GIFT CARD',
                  controller: giftCardController,
                  fieldKey: const ValueKey('deposit.giftCardAmount'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallAmountField(
                  label: 'OTHER',
                  controller: otherController,
                  fieldKey: const ValueKey('deposit.otherAmount'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),
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
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 20,
                      color: Color(0xFF4A90D9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmt(transactionDate),
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

class _TotalAmountDisplay extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Uint8List? thumbnailBytes;
  final bool isEditable;
  const _TotalAmountDisplay({
    required this.label,
    required this.controller,
    this.thumbnailBytes,
    this.isEditable = false,
  });

  Future<void> _editTotal(BuildContext context) async {
    final editController = TextEditingController(text: controller.text);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit total amount'),
        content: TextField(
          key: const ValueKey('deposit.totalAmount'),
          controller: editController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(prefixText: r'$'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, editController.text),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    editController.dispose();
    if (updated != null) controller.text = updated;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
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
                const SizedBox(height: 4),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final amount = value.text.isEmpty ? '0.00' : value.text;
                    return SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '\$$amount',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2340),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (isEditable)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      key: const ValueKey('deposit.editTotalAmount'),
                      onPressed: () => _editTotal(context),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit total amount',
                      visualDensity: VisualDensity.compact,
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

class _SmallAmountField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Key? fieldKey;

  const _SmallAmountField({
    required this.label,
    required this.controller,
    this.fieldKey,
  });

  @override
  Widget build(BuildContext context) {
    return _SmallDataField(
      label: label,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      prefixText: r'$',
      fieldKey: fieldKey,
    );
  }
}

class _SmallDataField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final String? prefixText;
  final Key? fieldKey;

  const _SmallDataField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.inputFormatters,
    this.prefixText,
    this.fieldKey,
  });

  @override
  Widget build(BuildContext context) {
    const fieldTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A2340),
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
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
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: fieldTextStyle,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              prefixText: prefixText,
              prefixStyle: prefixText == null ? null : fieldTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class DepositCameraPermissionDialog extends StatelessWidget {
  const DepositCameraPermissionDialog({super.key});

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
              child: const Icon(
                Icons.videocam_outlined,
                size: 28,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: 'Allow '),
                  TextSpan(
                    text: 'Save Tep',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' to take pictures and record video'),
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

class DepositDeleteConfirmDialog extends StatelessWidget {
  const DepositDeleteConfirmDialog({super.key});

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
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'DELETE DEPOSIT?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This will permanently remove this deposit and cannot be undone.',
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

class DepositReviewDialog extends StatelessWidget {
  final ScannedDepositData data;
  final bool isManual;

  const DepositReviewDialog({
    super.key,
    required this.data,
    required this.isManual,
  });

  String _fmtCurrency(double value) => formatMoney(value);

  String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                color: Color(0xFF1A2340),
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Review Deposit',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make sure everything is correct before saving.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            DepositReviewRow(
              label: 'Entry Type',
              value: isManual ? 'Manual' : 'Scan',
            ),
            DepositReviewRow(label: 'Order Number', value: data.orderNumber),
            DepositReviewRow(
              label: 'Transaction Date',
              value: _fmtDate(data.transactionDate),
            ),
            DepositReviewRow(
              label: 'Total Amount',
              value: _fmtCurrency(data.totalAmount),
              isEmphasis: true,
            ),
            const Divider(height: 22, color: Color(0xFFE5E7EB)),
            DepositReviewRow(
              label: 'Credit/Debit',
              value: _fmtCurrency(data.creditDeposit),
            ),
            DepositReviewRow(label: 'Card Last 4', value: data.cardLastFour),
            DepositReviewRow(label: 'Cash', value: _fmtCurrency(data.cash)),
            DepositReviewRow(
              label: 'Gift Card',
              value: _fmtCurrency(data.giftCard),
            ),
            DepositReviewRow(label: 'Other', value: _fmtCurrency(data.other)),
            const SizedBox(height: 20),
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
                      'Edit',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
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
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w600),
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

class DepositReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasis;

  const DepositReviewRow({
    super.key,
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isEmphasis
                    ? const Color(0xFF1A2340)
                    : const Color(0xFF111827),
                fontSize: isEmphasis ? 18 : 14,
                fontWeight: isEmphasis ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
