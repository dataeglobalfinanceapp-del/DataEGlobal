class SaveDepositRequest {
  final String orderNumber;
  final double totalAmount;
  final double creditDeposit;
  final double cash;
  final double giftCard;
  final double other;
  final DateTime transactionDate;
  final bool isManual;

  const SaveDepositRequest({
    required this.orderNumber,
    required this.totalAmount,
    required this.creditDeposit,
    required this.cash,
    required this.giftCard,
    required this.other,
    required this.transactionDate,
    required this.isManual,
  });

  Map<String, dynamic> toJson() => {
    'orderNumber': orderNumber,
    'totalAmount': totalAmount,
    'creditDeposit': creditDeposit,
    'cash': cash,
    'giftCard': giftCard,
    'other': other,
    'transactionDate': transactionDate.toIso8601String(),
    'isManual': isManual,
  };
}
