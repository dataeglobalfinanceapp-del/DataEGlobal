import 'package:image_picker/image_picker.dart';

import '../mindee/mindee_analysis_models.dart';
import '../mindee/mindee_mapping.dart';
import 'mindee_expense_fields.dart';
import 'scan_expense_screen.dart';

class ExpenseMindeeMapper {
  const ExpenseMindeeMapper();

  ScannedExpenseData map({
    required MindeeAnalysisResult result,
    required XFile image,
    required DateTime fallbackDate,
    required ExpenseCategory currentCategory,
  }) {
    return ScannedExpenseData(
      totalAmount: result.numberValue(MindeeExpenseFields.totalAmount) ?? 0,
      tipsGratuity: result.numberValue(MindeeExpenseFields.tipsGratuity) ?? 0,
      transactionDate: parseMindeeExpenseDateTime(
        dateValue: result.stringValue(MindeeExpenseFields.date),
        timeValue: result.stringValue(MindeeExpenseFields.time),
        fallback: fallbackDate,
      ),
      category: mapExpenseCategory(
        result.stringValue(MindeeExpenseFields.purchaseCategory),
        currentCategory: currentCategory,
      ),
      payee: result.stringValue(MindeeExpenseFields.supplierName) ?? '',
      cardLast4: normalizeOptionalCardLast4(
        result.stringValue(MindeeExpenseFields.cardLast4),
      ),
      receiptImage: image,
    );
  }

  ExpenseCategory mapExpenseCategory(
    String? value, {
    required ExpenseCategory currentCategory,
  }) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return currentCategory;
    }

    for (final category in ExpenseCategory.values) {
      if (category.label.toLowerCase() == normalized) return category;
    }
    return currentCategory;
  }
}
