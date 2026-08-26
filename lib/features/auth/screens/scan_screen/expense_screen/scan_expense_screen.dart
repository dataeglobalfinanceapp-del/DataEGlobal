import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:savetep/features/auth/models/expense_category.dart';
import 'package:savetep/services/money_formatter.dart';

export 'package:savetep/features/auth/models/expense_category.dart'
    show ExpenseCategory, ExpenseType;

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

extension ExpenseCategoryPresentation on ExpenseCategory {
  IconData get icon => switch (id) {
    'legacy.energy' => Icons.electric_bolt_outlined,
    'legacy.loan_obligation' => Icons.account_balance_outlined,
    'fixed.payroll_wages' => Icons.people_outline,
    'variable.business_license' => Icons.business_center_outlined,
    'legacy.food_purchase' => Icons.restaurant_outlined,
    'legacy.restaurant_supplies' => Icons.inventory_2_outlined,
    'variable.marketing_advertise' => Icons.campaign_outlined,
    'legacy.software' => Icons.computer_outlined,
    'variable.pets_control' => Icons.pest_control_outlined,
    'fixed.internet' => Icons.wifi,
    'variable.repair' => Icons.build_outlined,
    'fixed.business_insurance' => Icons.shield_outlined,
    'fixed.rents' => Icons.home_outlined,
    'variable.office' => Icons.edit_note_outlined,
    'variable.meal_and_entertaiment' => Icons.local_dining,
    'variable.merchant_services' => Icons.account_balance_wallet_outlined,
    'fixed.gas' ||
    'variable.gas_for_mileage' => Icons.local_gas_station_outlined,
    'fixed.water' => Icons.water_drop_outlined,
    'fixed.electrical' => Icons.electric_meter_outlined,
    'variable.gift_donation' => Icons.volunteer_activism_outlined,
    _ =>
      expenseType == ExpenseType.fixed
          ? Icons.account_balance_wallet_outlined
          : Icons.receipt_long_outlined,
  };
}

class ScannedExpenseData {
  final double totalAmount;
  final double tipsGratuity;
  final DateTime transactionDate;
  final ExpenseCategory category;
  final String payee;
  final String? cardLast4;
  final XFile? receiptImage;

  const ScannedExpenseData({
    this.totalAmount = 0,
    this.tipsGratuity = 0,
    required this.transactionDate,
    this.category = ExpenseCategory.energy,
    this.payee = '',
    this.cardLast4,
    this.receiptImage,
  });

  ScannedExpenseData copyWith({
    double? totalAmount,
    double? tipsGratuity,
    DateTime? transactionDate,
    ExpenseCategory? category,
    String? payee,
    String? cardLast4,
    bool clearCardLast4 = false,
    XFile? receiptImage,
  }) {
    return ScannedExpenseData(
      totalAmount: totalAmount ?? this.totalAmount,
      tipsGratuity: tipsGratuity ?? this.tipsGratuity,
      transactionDate: transactionDate ?? this.transactionDate,
      category: category ?? this.category,
      payee: payee ?? this.payee,
      cardLast4: clearCardLast4 ? null : cardLast4 ?? this.cardLast4,
      receiptImage: receiptImage ?? this.receiptImage,
    );
  }
}

enum ExpenseScheduleFrequency {
  weekly('Weekly'),
  biweekly('Biweekly'),
  semiMonthly('Semi-monthly'),
  monthly('Monthly');

  const ExpenseScheduleFrequency(this.label);
  final String label;
}

String formatExpenseDate(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

Future<DateTime?> pickExpenseScheduleDate(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(primary: Color(0xFF1A2340)),
      ),
      child: child!,
    ),
  );
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

class RecurringExpenseOption extends StatelessWidget {
  final bool value;
  final DateTime startDate;
  final ExpenseScheduleFrequency frequency;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPickStartDate;
  final ValueChanged<ExpenseScheduleFrequency> onFrequencyChanged;

  const RecurringExpenseOption({
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
    return ExpenseScheduleOption(
      value: value,
      title: 'RECURRING EXPENSE',
      description: 'Repeat this expense from a start date and frequency.',
      icon: Icons.repeat,
      iconColor: const Color(0xFF2563EB),
      iconBackgroundColor: const Color(0xFFEFF6FF),
      activeColor: const Color(0xFF1A2340),
      startDate: startDate,
      frequency: frequency,
      onChanged: onChanged,
      onPickStartDate: onPickStartDate,
      onFrequencyChanged: onFrequencyChanged,
    );
  }
}

class ExpenseScheduleOption extends StatelessWidget {
  final bool value;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color activeColor;
  final DateTime startDate;
  final ExpenseScheduleFrequency frequency;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPickStartDate;
  final ValueChanged<ExpenseScheduleFrequency> onFrequencyChanged;

  const ExpenseScheduleOption({
    super.key,
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.activeColor,
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
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
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
                  activeThumbColor: activeColor,
                  activeTrackColor: activeColor.withValues(alpha: 0.34),
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
                child: _ExpenseScheduleField(
                  label: 'START DATE',
                  child: InkWell(
                    onTap: onPickStartDate,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatExpenseDate(startDate),
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
                child: _ExpenseScheduleField(
                  label: 'FREQUENCY',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ExpenseScheduleFrequency>(
                      value: frequency,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Color(0xFF4A90D9),
                      ),
                      items: ExpenseScheduleFrequency.values
                          .map(
                            (option) =>
                                DropdownMenuItem<ExpenseScheduleFrequency>(
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
}

class _ExpenseScheduleField extends StatelessWidget {
  final String label;
  final Widget child;

  const _ExpenseScheduleField({required this.label, required this.child});

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
  final List<ExpenseCategory> categories;

  const CategoryPickerSheet({
    super.key,
    required this.selected,
    required this.categories,
  });
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
              ...widget.categories.map((cat) {
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
                    cat.name,
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

class ExpenseReviewDialog extends StatelessWidget {
  final ScannedExpenseData data;

  const ExpenseReviewDialog({super.key, required this.data});

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
              'Review Expense',
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
            ExpenseReviewRow(
              label: 'Transaction Date',
              value: formatExpenseDate(data.transactionDate),
            ),
            ExpenseReviewRow(
              label: 'Total Amount',
              value: formatMoney(data.totalAmount),
              isEmphasis: true,
            ),
            ExpenseReviewRow(
              label: 'Tips & Gratuity',
              value: formatMoney(data.tipsGratuity),
            ),
            const Divider(height: 22, color: Color(0xFFE5E7EB)),
            ExpenseReviewRow(label: 'Category', value: data.category.name),
            ExpenseReviewRow(label: 'Payee', value: data.payee),
            ExpenseReviewRow(label: 'Card Last 4', value: data.cardLast4 ?? ''),
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

class ExpenseReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasis;

  const ExpenseReviewRow({
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
