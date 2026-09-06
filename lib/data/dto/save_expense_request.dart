class SaveExpenseRequest {
  final String checkNumber;
  final double totalAmount;
  final double tipsGratuity;
  final DateTime transactionDate;
  final String categoryId;
  final String category;
  final String payee;
  final bool isManual;
  final String recurringSeriesId;
  final int recurringIndex;
  final int recurringEndMonthKey;
  final String recurringFrequency;

  const SaveExpenseRequest({
    required this.checkNumber,
    required this.totalAmount,
    this.tipsGratuity = 0,
    required this.transactionDate,
    this.categoryId = '',
    required this.category,
    required this.payee,
    required this.isManual,
    this.recurringSeriesId = '',
    this.recurringIndex = 0,
    this.recurringEndMonthKey = 0,
    this.recurringFrequency = '',
  });

  Map<String, dynamic> toJson() => {
    'checkNumber': checkNumber,
    'totalAmount': totalAmount,
    'tipsGratuity': tipsGratuity,
    'transactionDate': transactionDate.toIso8601String(),
    'categoryId': categoryId,
    'category': category,
    'payee': payee,
    'isManual': isManual,
    'recurringSeriesId': recurringSeriesId,
    'recurringIndex': recurringIndex,
    'recurringEndMonthKey': recurringEndMonthKey,
    'recurringFrequency': recurringFrequency,
  };
}
