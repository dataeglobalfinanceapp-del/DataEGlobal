import 'package:image_picker/image_picker.dart';

import '../mindee/mindee_analysis_models.dart';
import '../mindee/mindee_mapping.dart';
import 'scan_deposit_screen.dart';

class DepositMindeeMapper {
  const DepositMindeeMapper();

  ScannedDepositData map({
    required MindeeAnalysisResult result,
    required XFile image,
    required DateTime fallbackDate,
    required String currentAutomaticOrderNumber,
  }) {
    return ScannedDepositData(
      orderNumber: currentAutomaticOrderNumber,
      totalAmount: result.numberValue('total_amount') ?? 0,
      creditDeposit: result.numberValue('credit_debit_amount') ?? 0,
      cardLastFour:
          normalizeOptionalCardLast4(result.stringValue('card_last4')) ?? '',
      cash: result.numberValue('cash_amount') ?? 0,
      giftCard: result.numberValue('gift_card_amount') ?? 0,
      other: result.numberValue('other_amount') ?? 0,
      transactionDate: parseMindeeDate(
        result.stringValue('transaction_date'),
        fallback: fallbackDate,
      ),
      receiptImage: image,
    );
  }
}
