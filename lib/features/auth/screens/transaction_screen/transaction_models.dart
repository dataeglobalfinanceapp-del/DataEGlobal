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
  final String? category;
  final double totalDeposits;
  final double totalExpenses;
  final List<String> expenseCategories;
  final List<_TransactionGroup> groups;
  final List<_TransactionListEntry> entries;

  const _TransactionViewState({
    required this.isLoading,
    required this.kind,
    required this.filter,
    required this.year,
    required this.category,
    required this.totalDeposits,
    required this.totalExpenses,
    required this.expenseCategories,
    required this.groups,
    required this.entries,
  });

  factory _TransactionViewState.initial(int year) {
    return _TransactionViewState(
      isLoading: true,
      kind: _TransactionKind.deposit,
      filter: _TransactionFilter.weekly,
      year: year,
      category: null,
      totalDeposits: 0,
      totalExpenses: 0,
      expenseCategories: const <String>[],
      groups: const <_TransactionGroup>[],
      entries: const <_TransactionListEntry>[],
    );
  }

  double get totalReserves => totalDeposits - totalExpenses;
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
