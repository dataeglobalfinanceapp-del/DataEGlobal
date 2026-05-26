class LiabilityService {
  static final List<DepositRecord> _deposits = [];
  static final List<ExpenseRecord> _expenses = [];

  static Future<void> saveDeposit({
    required String orderNumber,
    required double totalAmount,
    required double creditDebt,
    required double cash,
    required double giftCard,
    required double other,
    required DateTime transactionDate,
    required bool isManual,
  }) async {
    _deposits.add(
      DepositRecord(
        orderNumber: orderNumber,
        totalAmount: totalAmount,
        creditDebt: creditDebt,
        cash: cash,
        giftCard: giftCard,
        other: other,
        transactionDate: transactionDate,
        isManual: isManual,
      ),
    );
  }

  static List<DepositRecord> get deposits => List.unmodifiable(_deposits);

  static Future<void> saveExpense({
    required String checkNumber,
    required double totalAmount,
    required DateTime transactionDate,
    required String category,
    required String payee,
    required bool isManual,
  }) async {
    _expenses.add(
      ExpenseRecord(
        checkNumber: checkNumber,
        totalAmount: totalAmount,
        transactionDate: transactionDate,
        category: category,
        payee: payee,
        isManual: isManual,
      ),
    );
  }

  static List<ExpenseRecord> get expenses => List.unmodifiable(_expenses);
}

class DepositRecord {
  final String orderNumber;
  final double totalAmount;
  final double creditDebt;
  final double cash;
  final double giftCard;
  final double other;
  final DateTime transactionDate;
  final bool isManual;

  const DepositRecord({
    required this.orderNumber,
    required this.totalAmount,
    required this.creditDebt,
    required this.cash,
    required this.giftCard,
    required this.other,
    required this.transactionDate,
    required this.isManual,
  });
}

class ExpenseRecord {
  final String checkNumber;
  final double totalAmount;
  final DateTime transactionDate;
  final String category;
  final String payee;
  final bool isManual;

  const ExpenseRecord({
    required this.checkNumber,
    required this.totalAmount,
    required this.transactionDate,
    required this.category,
    required this.payee,
    required this.isManual,
  });
}
