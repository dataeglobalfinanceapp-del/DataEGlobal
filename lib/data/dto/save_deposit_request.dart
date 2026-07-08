import 'package:savetep/services/card_last_four.dart';

class SaveDepositRequest {
  final String orderNumber;
  final double totalAmount;
  final double creditDeposit;
  final String cardLastFour;
  final double cash;
  final double giftCard;
  final double other;
  final DateTime transactionDate;
  final bool isManual;

  SaveDepositRequest({
    required this.orderNumber,
    required this.totalAmount,
    required this.creditDeposit,
    String cardLastFour = '',
    required this.cash,
    required this.giftCard,
    required this.other,
    required this.transactionDate,
    required this.isManual,
  }) : cardLastFour = normalizeCardLastFour(cardLastFour);

  Map<String, dynamic> toJson() => {
    'orderNumber': orderNumber,
    'totalAmount': totalAmount,
    'creditDeposit': creditDeposit,
    'cardLastFour': cardLastFour,
    'cash': cash,
    'giftCard': giftCard,
    'other': other,
    'transactionDate': transactionDate.toIso8601String(),
    'isManual': isManual,
  };
}
