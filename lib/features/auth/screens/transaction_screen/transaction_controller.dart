part of 'transaction_screen.dart';

class _TransactionController extends ChangeNotifier {
  _TransactionKind _kind = _TransactionKind.deposit;
  _TransactionFilter _filter = _TransactionFilter.weekly;
  int _year = AppClock.now.year;
  String? _category;
  bool _isLoading = true;
  bool _isDisposed = false;
  List<DepositRecord> _deposits = const <DepositRecord>[];
  List<ExpenseRecord> _expenses = const <ExpenseRecord>[];
  final Set<String> _expandedGroups = <String>{};

  _TransactionViewState _state = _TransactionViewState.initial(
    AppClock.now.year,
  );

  _TransactionViewState get state => _state;

  Future<void> loadTransactions() async {
    _setLoading(true);

    final List<DepositRecord> deposits = await LiabilityService.loadDeposits();
    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();
    if (_isDisposed) return;

    _deposits = List<DepositRecord>.unmodifiable(deposits);
    _expenses = List<ExpenseRecord>.unmodifiable(expenses);
    _isLoading = false;
    _rebuildState();
    _notify();
  }

  void setKind(_TransactionKind kind) {
    if (_kind == kind) return;

    _kind = kind;
    _expandedGroups.clear();
    _rebuildState();
    _notify();
  }

  void setFilter(_TransactionFilter filter) {
    if (_filter == filter) return;

    _filter = filter;
    _expandedGroups.clear();
    _rebuildState();
    _notify();
  }

  void setCategory(String? category) {
    if (_category == category) return;

    _category = category;
    _expandedGroups.clear();
    _rebuildState();
    _notify();
  }

  void changeYear(int delta) {
    _year += delta;
    _expandedGroups.clear();
    _rebuildState();
    _notify();
  }

  void toggleGroup(String key) {
    if (_expandedGroups.contains(key)) {
      _expandedGroups.remove(key);
    } else {
      _expandedGroups.add(key);
    }

    _rebuildState();
    _notify();
  }

  Future<bool> deleteItem(_TransactionItem item) async {
    final bool deleted = item.kind == _TransactionKind.deposit
        ? await LiabilityService.deleteDeposit(item.id)
        : await LiabilityService.deleteExpense(item.id);

    if (deleted && !_isDisposed) {
      await loadTransactions();
    }

    return deleted;
  }

  Future<String> exportPdf(_ExportRange range) async {
    final _TransactionPdfPayload pdf = _TransactionReportBuilder.buildPdf(
      kind: _kind,
      category: _category,
      deposits: _deposits,
      expenses: _expenses,
      range: range,
    );

    return PdfExporter.savePdf(fileName: pdf.fileName, bytes: pdf.bytes);
  }

  Future<String> printPdf(_ExportRange range) async {
    final _TransactionPdfPayload pdf = _TransactionReportBuilder.buildPdf(
      kind: _kind,
      category: _category,
      deposits: _deposits,
      expenses: _expenses,
      range: range,
    );

    return PdfPrinter.printPdf(fileName: pdf.fileName, bytes: pdf.bytes);
  }

  Future<String> exportExcel(_ExportRange range) async {
    final _TransactionExcelPayload excel = _TransactionReportBuilder.buildExcel(
      kind: _kind,
      category: _category,
      deposits: _deposits,
      expenses: _expenses,
      range: range,
    );

    return FileExporter.save(
      fileName: excel.fileName,
      bytes: excel.bytes,
      mimeType: 'application/vnd.ms-excel',
    );
  }

  DateTime initialExportDate() {
    return _TransactionDateUtils.initialExportDate(_year);
  }

  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;

    _isLoading = isLoading;
    _rebuildState();
    _notify();
  }

  void _rebuildState() {
    final double totalDeposits = _TransactionDataMapper.totalDeposits(
      _deposits,
      _year,
    );
    final double totalExpenses = _TransactionDataMapper.totalExpenses(
      _expenses,
      _year,
    );
    final List<String> expenseCategories =
        _TransactionDataMapper.expenseCategories(_expenses);
    final List<_TransactionGroup> groups = _TransactionDataMapper.groups(
      kind: _kind,
      filter: _filter,
      year: _year,
      category: _category,
      deposits: _deposits,
      expenses: _expenses,
    );
    final List<_TransactionListEntry> entries =
        _TransactionDataMapper.visibleEntries(
          groups: groups,
          expandedGroups: _expandedGroups,
        );

    _state = _TransactionViewState(
      isLoading: _isLoading,
      kind: _kind,
      filter: _filter,
      year: _year,
      category: _category,
      totalDeposits: totalDeposits,
      totalExpenses: totalExpenses,
      expenseCategories: expenseCategories,
      groups: groups,
      entries: entries,
    );
  }

  void _notify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class _TransactionDataMapper {
  const _TransactionDataMapper._();

  static double totalDeposits(List<DepositRecord> deposits, int year) {
    return deposits
        .where((DepositRecord record) => record.transactionDate.year == year)
        .fold<double>(
          0,
          (double total, DepositRecord record) => total + record.totalAmount,
        );
  }

  static double totalExpenses(List<ExpenseRecord> expenses, int year) {
    return expenses
        .where((ExpenseRecord record) => record.transactionDate.year == year)
        .fold<double>(
          0,
          (double total, ExpenseRecord record) => total + record.totalAmount,
        );
  }

  static List<String> expenseCategories(List<ExpenseRecord> expenses) {
    final List<String> categories = expenses
        .map<String>((ExpenseRecord record) => record.category)
        .where((String category) => category.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    categories.sort();
    return List<String>.unmodifiable(categories);
  }

  static List<_TransactionGroup> groups({
    required _TransactionKind kind,
    required _TransactionFilter filter,
    required int year,
    required String? category,
    required List<DepositRecord> deposits,
    required List<ExpenseRecord> expenses,
  }) {
    if (kind == _TransactionKind.deposit) {
      final List<DepositRecord> records = deposits
          .where((DepositRecord record) => record.transactionDate.year == year)
          .toList(growable: false);
      return _buildDepositGroups(records: records, filter: filter);
    }

    final List<ExpenseRecord> records = expenses
        .where((ExpenseRecord record) {
          final bool matchesYear = record.transactionDate.year == year;
          final bool matchesCategory =
              category == null || record.category == category;
          return matchesYear && matchesCategory;
        })
        .toList(growable: false);

    return _buildExpenseGroups(records: records, filter: filter);
  }

  static List<_TransactionListEntry> visibleEntries({
    required List<_TransactionGroup> groups,
    required Set<String> expandedGroups,
  }) {
    if (groups.isEmpty) {
      return const <_TransactionListEntry>[_EmptyTransactionEntry()];
    }

    final List<_TransactionListEntry> entries = <_TransactionListEntry>[];
    for (final _TransactionGroup group in groups) {
      final bool isExpanded = expandedGroups.contains(group.key);
      entries.add(_TransactionGroupEntry(group: group, isExpanded: isExpanded));

      if (!isExpanded) continue;

      entries.add(const _TransactionTableHeaderEntry());
      for (int index = 0; index < group.items.length; index += 1) {
        entries.add(
          _TransactionItemEntry(
            item: group.items[index],
            isLastInGroup: index == group.items.length - 1,
          ),
        );
      }
    }

    return List<_TransactionListEntry>.unmodifiable(entries);
  }

  static List<_TransactionGroup> _buildDepositGroups({
    required List<DepositRecord> records,
    required _TransactionFilter filter,
  }) {
    return _groupRecords<DepositRecord>(
      records: records,
      filter: filter,
      dateOf: (DepositRecord record) => record.transactionDate,
      amountOf: (DepositRecord record) => record.totalAmount,
      itemBuilder: _depositItems,
    );
  }

  static List<_TransactionGroup> _buildExpenseGroups({
    required List<ExpenseRecord> records,
    required _TransactionFilter filter,
  }) {
    return _groupRecords<ExpenseRecord>(
      records: records,
      filter: filter,
      dateOf: (ExpenseRecord record) => record.transactionDate,
      amountOf: (ExpenseRecord record) => record.totalAmount,
      itemBuilder: (ExpenseRecord record) {
        final String checkDetail =
            'Check #${record.checkNumber.isEmpty ? '-' : record.checkNumber}';
        return <_TransactionItem>[
          _TransactionItem(
            id: record.id,
            kind: _TransactionKind.expense,
            title: record.payee.isEmpty ? record.category : record.payee,
            subtitle: record.category,
            date: record.transactionDate,
            amount: record.totalAmount,
            detail: record.isRecurring
                ? '${record.normalizedRecurringFrequency} recurring | $checkDetail'
                : checkDetail,
            icon: record.isRecurring
                ? Icons.repeat
                : Icons.receipt_long_outlined,
            iconColor: record.isRecurring
                ? _TransactionTokens.recurring
                : _TransactionTokens.danger,
            isRecurring: record.isRecurring,
          ),
        ];
      },
    );
  }

  static List<_TransactionItem> _depositItems(DepositRecord record) {
    final List<_TransactionItem> items = <_TransactionItem>[];

    void addMethod({
      required String label,
      required double amount,
      required IconData icon,
      required Color color,
    }) {
      if (amount <= 0) return;
      items.add(
        _TransactionItem(
          id: record.id,
          kind: _TransactionKind.deposit,
          title: label,
          subtitle: record.orderNumber.isEmpty
              ? record.isManual
                    ? 'Manual entry'
                    : 'Scanned receipt'
              : 'Order #${record.orderNumber}',
          date: record.transactionDate,
          amount: amount,
          detail: record.isManual ? 'Manual entry' : 'Scanned receipt',
          icon: icon,
          iconColor: color,
        ),
      );
    }

    addMethod(
      label: 'Credit/Debit',
      amount: record.creditDebt,
      icon: Icons.credit_card,
      color: _TransactionTokens.depositBlue,
    );
    addMethod(
      label: 'Cash',
      amount: record.cash,
      icon: Icons.payments_outlined,
      color: _TransactionTokens.success,
    );
    addMethod(
      label: 'Gift Card',
      amount: record.giftCard,
      icon: Icons.card_giftcard,
      color: _TransactionTokens.giftBlue,
    );
    addMethod(
      label: 'Other',
      amount: record.other,
      icon: Icons.account_balance_wallet_outlined,
      color: _TransactionTokens.warning,
    );

    if (items.isEmpty) {
      items.add(
        _TransactionItem(
          id: record.id,
          kind: _TransactionKind.deposit,
          title: 'Deposit',
          subtitle: record.orderNumber.isEmpty
              ? '-'
              : 'Order #${record.orderNumber}',
          date: record.transactionDate,
          amount: record.totalAmount,
          detail: record.isManual ? 'Manual entry' : 'Scanned receipt',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: _TransactionTokens.success,
        ),
      );
    }

    return List<_TransactionItem>.unmodifiable(items);
  }

  static List<_TransactionGroup> _groupRecords<T>({
    required List<T> records,
    required _TransactionFilter filter,
    required DateTime Function(T record) dateOf,
    required double Function(T record) amountOf,
    required List<_TransactionItem> Function(T record) itemBuilder,
  }) {
    final Map<String, _MutableGroup<T>> buckets = <String, _MutableGroup<T>>{};

    for (final T record in records) {
      final DateTime date = dateOf(record);
      final String key = _TransactionDateUtils.groupKey(date, filter);
      buckets.putIfAbsent(
        key,
        () => _MutableGroup<T>(
          key: key,
          title: _TransactionDateUtils.groupTitle(date, filter),
        ),
      );
      buckets[key]!.records.add(record);
      buckets[key]!.total += amountOf(record);
    }

    final List<_TransactionGroup> groups = buckets.values
        .map((_MutableGroup<T> bucket) {
          bucket.records.sort((T a, T b) => dateOf(b).compareTo(dateOf(a)));
          return _TransactionGroup(
            key: bucket.key,
            title: bucket.title,
            total: bucket.total,
            items: List<_TransactionItem>.unmodifiable(
              bucket.records.expand<_TransactionItem>(itemBuilder),
            ),
          );
        })
        .toList(growable: false);

    groups.sort(
      (_TransactionGroup a, _TransactionGroup b) =>
          _TransactionDateUtils.sortKey(
            b.key,
          ).compareTo(_TransactionDateUtils.sortKey(a.key)),
    );
    return List<_TransactionGroup>.unmodifiable(groups);
  }
}

class _TransactionReportBuilder {
  const _TransactionReportBuilder._();

  static _TransactionPdfPayload buildPdf({
    required _TransactionKind kind,
    required String? category,
    required List<DepositRecord> deposits,
    required List<ExpenseRecord> expenses,
    required _ExportRange range,
  }) {
    final List<TransactionReportRow> rows = _reportRows(
      kind: kind,
      category: category,
      deposits: deposits,
      expenses: expenses,
      range: range,
    );
    final double total = rows.fold<double>(
      0,
      (double sum, TransactionReportRow row) => sum + row.amount,
    );
    final String typeLabel = kind.reportLabel;
    final String categoryLabel =
        kind == _TransactionKind.expense && category != null
        ? ' - $category'
        : '';
    final Uint8List bytes = YearlyTransactionPdfReport.build(
      reportTitle: '$typeLabel ${range.periodTitle} Report$categoryLabel',
      periodLabel: range.label,
      rows: rows,
      total: total,
    );
    final String categoryPart =
        kind == _TransactionKind.expense && category != null
        ? '-${_TransactionDateUtils.slug(category)}'
        : '';
    final String fileName =
        'FinApp-${typeLabel.toLowerCase()}s-${range.fileToken}$categoryPart.pdf';

    return _TransactionPdfPayload(fileName: fileName, bytes: bytes);
  }

  static _TransactionExcelPayload buildExcel({
    required _TransactionKind kind,
    required String? category,
    required List<DepositRecord> deposits,
    required List<ExpenseRecord> expenses,
    required _ExportRange range,
  }) {
    final List<TransactionReportRow> rows = _reportRows(
      kind: kind,
      category: category,
      deposits: deposits,
      expenses: expenses,
      range: range,
    );
    final double total = rows.fold<double>(
      0,
      (double sum, TransactionReportRow row) => sum + row.amount,
    );
    final String typeLabel = kind.reportLabel;
    final String categoryLabel =
        kind == _TransactionKind.expense && category != null
        ? ' - $category'
        : '';
    final Uint8List bytes = ExcelTransactionReport.build(
      reportTitle: '$typeLabel ${range.periodTitle} Report$categoryLabel',
      periodLabel: range.label,
      transactionType: typeLabel,
      rows: rows,
      total: total,
    );
    final String categoryPart =
        kind == _TransactionKind.expense && category != null
        ? '-${_TransactionDateUtils.slug(category)}'
        : '';
    final String fileName =
        'FinApp-${typeLabel.toLowerCase()}s-${range.fileToken}$categoryPart.xls';

    return _TransactionExcelPayload(fileName: fileName, bytes: bytes);
  }

  static List<TransactionReportRow> _reportRows({
    required _TransactionKind kind,
    required String? category,
    required List<DepositRecord> deposits,
    required List<ExpenseRecord> expenses,
    required _ExportRange range,
  }) {
    return kind == _TransactionKind.deposit
        ? _depositReportRows(deposits: deposits, range: range)
        : _expenseReportRows(
            expenses: expenses,
            category: category,
            range: range,
          );
  }

  static List<TransactionReportRow> _depositReportRows({
    required List<DepositRecord> deposits,
    required _ExportRange range,
  }) {
    final List<DepositRecord> records =
        deposits
            .where(
              (DepositRecord record) => _TransactionDateUtils.isInRange(
                record.transactionDate,
                range,
              ),
            )
            .toList(growable: false)
          ..sort(
            (DepositRecord a, DepositRecord b) =>
                a.transactionDate.compareTo(b.transactionDate),
          );

    return records
        .map<TransactionReportRow>(
          (DepositRecord record) => TransactionReportRow(
            date: record.transactionDate,
            title: record.orderNumber.isEmpty
                ? 'Deposit'
                : 'Order #${record.orderNumber}',
            category: 'Deposit',
            amount: record.totalAmount,
            detail:
                'Cash ${formatMoney(record.cash)}, Credit ${formatMoney(record.creditDebt)}, Gift ${formatMoney(record.giftCard)}, Other ${formatMoney(record.other)}',
          ),
        )
        .toList(growable: false);
  }

  static List<TransactionReportRow> _expenseReportRows({
    required List<ExpenseRecord> expenses,
    required String? category,
    required _ExportRange range,
  }) {
    final List<ExpenseRecord> records =
        expenses
            .where((ExpenseRecord record) {
              final bool matchesRange = _TransactionDateUtils.isInRange(
                record.transactionDate,
                range,
              );
              final bool matchesCategory =
                  category == null || record.category == category;
              return matchesRange && matchesCategory;
            })
            .toList(growable: false)
          ..sort(
            (ExpenseRecord a, ExpenseRecord b) =>
                a.transactionDate.compareTo(b.transactionDate),
          );

    return records
        .map<TransactionReportRow>(
          (ExpenseRecord record) => TransactionReportRow(
            date: record.transactionDate,
            title: record.payee.isEmpty ? record.category : record.payee,
            category: record.category,
            amount: record.totalAmount,
            detail: record.isRecurring
                ? '${record.normalizedRecurringFrequency} recurring | Check #${record.checkNumber.isEmpty ? '-' : record.checkNumber}'
                : 'Check #${record.checkNumber.isEmpty ? '-' : record.checkNumber}',
          ),
        )
        .toList(growable: false);
  }
}

class _TransactionDateUtils {
  const _TransactionDateUtils._();

  static final List<int> exportYears = List<int>.unmodifiable(
    List<int>.generate(101, (int index) => 2000 + index),
  );

  static DateTime initialExportDate(int selectedYear) {
    final DateTime now = AppClock.now;
    final int safeYear = selectedYear.clamp(2000, 2100).toInt();
    if (safeYear == now.year) {
      return DateTime(safeYear, now.month, now.day);
    }
    return DateTime(safeYear);
  }

  static _ExportRange weekRange(DateTime picked) {
    final DateTime day = dateOnly(picked);
    final DateTime start = day.subtract(Duration(days: day.weekday - 1));
    final DateTime end = start.add(const Duration(days: 6));
    return _ExportRange(
      period: _ExportPeriod.week,
      start: start,
      end: end,
      label: '${fullDate(start)} - ${fullDate(end)}',
      fileToken: '${dateToken(start)}-to-${dateToken(end)}',
    );
  }

  static _ExportRange monthRange({required int year, required int month}) {
    final DateTime start = DateTime(year, month);
    final DateTime end = DateTime(year, month + 1, 0);
    return _ExportRange(
      period: _ExportPeriod.month,
      start: start,
      end: end,
      label: '${_monthNames[month]} $year',
      fileToken: '$year-${month.toString().padLeft(2, '0')}',
    );
  }

  static _ExportRange yearRange(int year) {
    final DateTime start = DateTime(year);
    final DateTime end = DateTime(year, 12, 31);
    return _ExportRange(
      period: _ExportPeriod.year,
      start: start,
      end: end,
      label: '$year',
      fileToken: '$year',
    );
  }

  static String groupKey(DateTime date, _TransactionFilter filter) {
    return switch (filter) {
      _TransactionFilter.weekly => '${date.year}-w${weekOfYear(date)}',
      _TransactionFilter.monthly =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}',
      _TransactionFilter.quarterly =>
        '${date.year}-q${((date.month - 1) ~/ 3) + 1}',
      _TransactionFilter.yearly => '${date.year}',
    };
  }

  static String groupTitle(DateTime date, _TransactionFilter filter) {
    return switch (filter) {
      _TransactionFilter.weekly => 'Week ${weekOfYear(date)}',
      _TransactionFilter.monthly => _monthNames[date.month],
      _TransactionFilter.quarterly => 'Quarter ${((date.month - 1) ~/ 3) + 1}',
      _TransactionFilter.yearly => '${date.year}',
    };
  }

  static int sortKey(String key) {
    final String digits = key.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  static int weekOfYear(DateTime date) {
    final DateTime firstDay = DateTime(date.year);
    return ((date.difference(firstDay).inDays + firstDay.weekday) / 7).ceil();
  }

  static bool isInRange(DateTime value, _ExportRange range) {
    final DateTime date = dateOnly(value);
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String dateToken(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String fullDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  static String capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  static String slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

extension on _TransactionKind {
  String get reportLabel {
    return switch (this) {
      _TransactionKind.deposit => 'Deposit',
      _TransactionKind.expense => 'Expense',
    };
  }
}
