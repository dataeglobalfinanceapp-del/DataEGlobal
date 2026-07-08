import 'package:savetep/services/card_last_four.dart';

class DepositFormValidator {
  static const String cardLastFourMessage =
      'Enter the last 4 digits for the credit/debit card.';

  const DepositFormValidator();

  String? validateCardLastFour({
    required double creditDebitAmount,
    required String cardLastFour,
  }) {
    if (creditDebitAmount <= 0) return null;
    return isValidCardLastFour(cardLastFour) ? null : cardLastFourMessage;
  }
}
