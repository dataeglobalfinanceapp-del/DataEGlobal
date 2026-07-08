part of 'transaction_screen.dart';

enum _TransactionKind {
  deposit,
  expense;

  String get label {
    return switch (this) {
      _TransactionKind.deposit => 'deposit',
      _TransactionKind.expense => 'expense',
    };
  }
}

enum _TransactionFilter { weekly, monthly, quarterly, yearly }

extension _TransactionFilterLabel on _TransactionFilter {
  String get label {
    return switch (this) {
      _TransactionFilter.weekly => 'Weekly',
      _TransactionFilter.monthly => 'Monthly',
      _TransactionFilter.quarterly => 'Quarterly',
      _TransactionFilter.yearly => 'Yearly',
    };
  }
}

enum _ExportPeriod { week, month, year }

sealed class _TransactionListEntry {
  const _TransactionListEntry();
}

final class _TransactionGroupEntry extends _TransactionListEntry {
  final _TransactionGroup group;
  final bool isExpanded;

  const _TransactionGroupEntry({required this.group, required this.isExpanded});
}

final class _TransactionTableHeaderEntry extends _TransactionListEntry {
  const _TransactionTableHeaderEntry();
}

final class _TransactionItemEntry extends _TransactionListEntry {
  final _TransactionItem item;
  final bool isLastInGroup;

  const _TransactionItemEntry({
    required this.item,
    required this.isLastInGroup,
  });
}

final class _EmptyTransactionEntry extends _TransactionListEntry {
  const _EmptyTransactionEntry();
}

class _TransactionViewState {
  final bool isLoading;
  final _TransactionKind kind;
  final _TransactionFilter filter;
  final int year;
  final DateTimeRange expenseDateRange;
  final String? category;
  final double totalDeposits;
  final double totalExpenses;
  final double estimatedTaxToPay;
  final double selectedCategoryExpenseTotal;
  final List<String> expenseCategories;
  final List<_TransactionGroup> groups;
  final List<_TransactionListEntry> entries;

  const _TransactionViewState({
    required this.isLoading,
    required this.kind,
    required this.filter,
    required this.year,
    required this.expenseDateRange,
    required this.category,
    required this.totalDeposits,
    required this.totalExpenses,
    required this.estimatedTaxToPay,
    required this.selectedCategoryExpenseTotal,
    required this.expenseCategories,
    required this.groups,
    required this.entries,
  });

  factory _TransactionViewState.initial({
    required int year,
    required DateTimeRange expenseDateRange,
    String? category,
  }) {
    return _TransactionViewState(
      isLoading: true,
      kind: _TransactionKind.expense,
      filter: _TransactionFilter.monthly,
      year: year,
      expenseDateRange: expenseDateRange,
      category: category,
      totalDeposits: 0,
      totalExpenses: 0,
      estimatedTaxToPay: 0,
      selectedCategoryExpenseTotal: 0,
      expenseCategories: const <String>[],
      groups: const <_TransactionGroup>[],
      entries: const <_TransactionListEntry>[],
    );
  }

  double get totalAvailableDeposit => totalDeposits - totalExpenses;
}

class _MutableGroup<T> {
  final String key;
  final String title;
  final List<T> records = <T>[];
  double total = 0;

  _MutableGroup({required this.key, required this.title});
}

class _TransactionGroup {
  final String key;
  final String title;
  final double total;
  final List<_TransactionItem> items;

  const _TransactionGroup({
    required this.key,
    required this.title,
    required this.total,
    required this.items,
  });
}

class _TransactionItem {
  final String id;
  final _TransactionKind kind;
  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final String detail;
  final String cardLastFour;
  final bool showsCardLastFour;
  final IconData icon;
  final Color iconColor;
  final bool isRecurring;

  const _TransactionItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.detail,
    this.cardLastFour = '',
    this.showsCardLastFour = false,
    required this.icon,
    required this.iconColor,
    this.isRecurring = false,
  });
}

class _TransactionPdfPayload {
  final String fileName;
  final Uint8List bytes;

  const _TransactionPdfPayload({required this.fileName, required this.bytes});
}

class _TransactionExcelPayload {
  final String fileName;
  final Uint8List bytes;

  const _TransactionExcelPayload({required this.fileName, required this.bytes});
}

class _ExportRange {
  final _ExportPeriod period;
  final DateTime start;
  final DateTime end;
  final String label;
  final String fileToken;

  const _ExportRange({
    required this.period,
    required this.start,
    required this.end,
    required this.label,
    required this.fileToken,
  });

  String get periodTitle {
    return switch (period) {
      _ExportPeriod.week => 'Weekly',
      _ExportPeriod.month => 'Monthly',
      _ExportPeriod.year => 'Yearly',
    };
  }
}

class _MonthYear {
  final int month;
  final int year;

  const _MonthYear({required this.month, required this.year});
}

class _TransactionTokens {
  const _TransactionTokens._();

  static const Color screenBackground = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF171638);
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color iconBlue = Color(0xFF3B82F6);
  static const Color depositBlue = Color(0xFF2563EB);
  static const Color onSurface = Colors.black87;
  static const Color onSurfaceMuted = Colors.black54;
  static const Color onSurfaceDisabled = Colors.black38;
  static const Color iconDisabled = Colors.black26;
  static const Color textStrong = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textInactive = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color dateRangeSelected = Color(0xFF006B5F);
  static const Color dateRangeInactive = Color(0xFFFFFEF7);
  static const Color dateRangeInactiveBorder = Color(0xFFD7DDCC);
  static const Color dateRangeInactiveText = Color(0xFF10201B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color giftBlue = Color(0xFF0EA5E9);
  static const Color warning = Color(0xFFF59E0B);
  static const Color recurring = Color(0xFF0F766E);

  static const double cardRadius = 4;
  static const double controlRadius = 3;
  static const double dateRangeRadius = 8;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 24);
  static const EdgeInsets tableHeaderPadding = EdgeInsets.fromLTRB(
    12,
    9,
    10,
    7,
  );
  static const EdgeInsets tableRowPadding = EdgeInsets.fromLTRB(12, 8, 10, 8);

  static const double tableDateWidth = 42;
  static const double tableLastFourWidth = 38;
  static const double tableAmountWidth = 70;
  static const double tableMethodWidth = 34;
  static const double tableDeleteWidth = 30;

  static const List<BoxShadow> softShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const TextStyle appBarTitle = TextStyle(
    color: Colors.black87,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle toggleLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle categoryLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle filterLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle dateRangeLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle yearLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle groupTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle groupAmount = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle tableHeader = TextStyle(
    color: textMuted,
    fontSize: 8,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.3,
  );
  static const TextStyle tableCell = TextStyle(
    color: textStrong,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle tableAmount = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle tableLastFour = TextStyle(
    color: textMuted,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle tableCategory = TextStyle(
    color: primaryBlue,
    fontSize: 10,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle emptyLabel = TextStyle(
    color: textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle exportLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle sheetTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle tileTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle dialogStrong = TextStyle(fontWeight: FontWeight.w700);
}

const List<String> _shortMonthNames = <String>[
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _monthNames = <String>[
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
];
