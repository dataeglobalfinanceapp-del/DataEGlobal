import 'package:flutter/material.dart';
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
// Entry mode
// ─────────────────────────────────────────────────────────────────────────────

enum ScanExpenseEntryMode { automatic, manual }

enum ExpenseReminderFrequency {
  weekly('Weekly'),
  biweekly('Biweekly'),
  semiMonthly('Semi-monthly'),
  monthly('Monthly');

  const ExpenseReminderFrequency(this.label);
  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  final String label;
  final Widget child;
  const InfoRow({super.key, required this.label, required this.child});

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

class RecurringMonthlyOption extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const RecurringMonthlyOption({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.repeat,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECURRING MONTHLY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Color(0xFF555555),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This expense repeats until you delete or edit it. Future monthly entries appear only when each new month starts.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              activeThumbColor: Color(0xFF1A2340),
              activeTrackColor: Color(0x551A2340),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseReminderOption extends StatelessWidget {
  final bool value;
  final DateTime startDate;
  final ExpenseReminderFrequency frequency;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPickStartDate;
  final ValueChanged<ExpenseReminderFrequency> onFrequencyChanged;

  const ExpenseReminderOption({
    super.key,
    required this.value,
    required this.startDate,
    required this.frequency,
    required this.onChanged,
    required this.onPickStartDate,
    required this.onFrequencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFCF8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFF0F766E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADD TO REMINDERS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF555555),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create recurring payment reminders from a custom start date.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: value,
                  activeThumbColor: Color(0xFF0F766E),
                  activeTrackColor: Color(0x550F766E),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
        if (value) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ExpenseReminderField(
                  label: 'START DATE',
                  child: InkWell(
                    onTap: onPickStartDate,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(startDate),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A2340),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: Color(0xFF4A90D9),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ExpenseReminderField(
                  label: 'FREQUENCY',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ExpenseReminderFrequency>(
                      value: frequency,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Color(0xFF4A90D9),
                      ),
                      items: ExpenseReminderFrequency.values
                          .map(
                            (option) =>
                                DropdownMenuItem<ExpenseReminderFrequency>(
                                  value: option,
                                  child: Text(
                                    option.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                          )
                          .toList(growable: false),
                      onChanged: (option) {
                        if (option == null) return;
                        onFrequencyChanged(option);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
}

class _ExpenseReminderField extends StatelessWidget {
  final String label;
  final Widget child;

  const _ExpenseReminderField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(color: const Color(0xFFD0D0D0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

class CategoryPickerSheet extends StatefulWidget {
  final ExpenseCategory selected;
  const CategoryPickerSheet({super.key, required this.selected});
  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  late ExpenseCategory _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                  leading: Icon(
                    cat.icon,
                    size: 22,
                    color: isSelected
                        ? const Color(0xFF1A2340)
                        : const Color(0xFF888888),
                  ),
                  title: Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
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
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
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
        ),
      ),
    );
  }
}

class CameraPermissionDialog extends StatelessWidget {
  const CameraPermissionDialog({super.key});

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

class DeleteConfirmDialog extends StatelessWidget {
  const DeleteConfirmDialog({super.key});

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
              'This will permanently remove this expense and cannot be undone.',
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
