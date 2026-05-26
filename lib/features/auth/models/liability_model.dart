enum LiabilityTab { loan, debt }

class LiabilityEntry {
  final String name;
  final String date;
  final double starting;
  final double minimum;
  final int percent;

  const LiabilityEntry({
    required this.name,
    required this.date,
    required this.starting,
    required this.minimum,
    required this.percent,
  });
}

class MonthlyLiability {
  final int month;
  final double total;
  final List<LiabilityEntry> entries;
  bool isExpanded;

  MonthlyLiability({
    required this.month,
    required this.total,
    required this.entries,
    this.isExpanded = false,
  });

  String get monthName => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month];
}

class LiabilityData {
  static const double totalOwn = 23392.00;
  static const double percent = 52.5;
  static const double totalPayOff = 12290.00;
  static const double balance = 11102.00;

  static List<MonthlyLiability> loanMonths(int year) => [
    MonthlyLiability(
      month: 1,
      total: 1510.00,
      isExpanded: true,
      entries: const [
        LiabilityEntry(
          name: 'Motorbike Loan',
          date: '01/10',
          starting: 130,
          minimum: 24,
          percent: 5,
        ),
        LiabilityEntry(
          name: 'Phone',
          date: '01/04',
          starting: 130,
          minimum: 24,
          percent: 5,
        ),
        LiabilityEntry(
          name: 'Peer-to-peer...',
          date: '01/23',
          starting: 130,
          minimum: 24,
          percent: 5,
        ),
        LiabilityEntry(
          name: 'Car Loan',
          date: '01/31',
          starting: 130,
          minimum: 24,
          percent: 5,
        ),
        LiabilityEntry(
          name: 'Overdraft',
          date: '01/24',
          starting: 130,
          minimum: 24,
          percent: 6,
        ),
        LiabilityEntry(
          name: 'Car Loan',
          date: '01/31',
          starting: 130,
          minimum: 24,
          percent: 9,
        ),
      ],
    ),
    MonthlyLiability(month: 2, total: 2000, entries: []),
    MonthlyLiability(month: 3, total: 2000, entries: []),
    MonthlyLiability(month: 4, total: 2000, entries: []),
    MonthlyLiability(month: 5, total: 2000, entries: []),
    MonthlyLiability(month: 6, total: 2000, entries: []),
    MonthlyLiability(month: 7, total: 2000, entries: []),
    MonthlyLiability(month: 8, total: 2000, entries: []),
    MonthlyLiability(month: 9, total: 2000, entries: []),
    MonthlyLiability(month: 10, total: 2000, entries: []),
    MonthlyLiability(month: 11, total: 2000, entries: []),
    MonthlyLiability(month: 12, total: 2000, entries: []),
  ];

  static List<MonthlyLiability> debtMonths(int year) => [
    MonthlyLiability(month: 1, total: 800, entries: []),
    MonthlyLiability(month: 2, total: 950, entries: []),
    MonthlyLiability(month: 3, total: 1100, entries: []),
    MonthlyLiability(month: 4, total: 750, entries: []),
    MonthlyLiability(month: 5, total: 900, entries: []),
    MonthlyLiability(month: 6, total: 1050, entries: []),
    MonthlyLiability(month: 7, total: 870, entries: []),
    MonthlyLiability(month: 8, total: 920, entries: []),
    MonthlyLiability(month: 9, total: 1000, entries: []),
    MonthlyLiability(month: 10, total: 1100, entries: []),
    MonthlyLiability(month: 11, total: 980, entries: []),
    MonthlyLiability(month: 12, total: 1200, entries: []),
  ];
}
