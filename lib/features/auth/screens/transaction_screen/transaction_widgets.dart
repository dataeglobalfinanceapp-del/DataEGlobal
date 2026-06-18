part of 'transaction_screen.dart';

class _LoadingTransactionsList extends StatelessWidget {
  const _LoadingTransactionsList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const <Widget>[
        SizedBox(
          height: 360,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  final _TransactionViewState state;
  final ValueChanged<_TransactionKind> onKindChanged;
  final ValueChanged<_TransactionFilter> onFilterChanged;
  final VoidCallback onCategoryTap;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<_TransactionItem> onDelete;
  final VoidCallback onExportPdf;
  final VoidCallback onPrintPdf;
  final VoidCallback onExportExcel;

  const _TransactionList({
    required this.state,
    required this.onKindChanged,
    required this.onFilterChanged,
    required this.onCategoryTap,
    required this.onYearChanged,
    required this.onToggleGroup,
    required this.onDelete,
    required this.onExportPdf,
    required this.onPrintPdf,
    required this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    final int entryCount = state.entries.length;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _TransactionTokens.pagePadding,
      itemCount: entryCount + 2,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _TransactionHeader(
            state: state,
            onKindChanged: onKindChanged,
            onFilterChanged: onFilterChanged,
            onCategoryTap: onCategoryTap,
            onYearChanged: onYearChanged,
          );
        }

        if (index == entryCount + 1) {
          return _ExportActions(
            onExportPdf: onExportPdf,
            onPrintPdf: onPrintPdf,
            onExportExcel: onExportExcel,
          );
        }

        final _TransactionListEntry entry = state.entries[index - 1];
        return switch (entry) {
          _TransactionGroupEntry(
            :final _TransactionGroup group,
            :final bool isExpanded,
          ) =>
            _TransactionGroupHeaderCard(
              group: group,
              isExpanded: isExpanded,
              onToggle: () => onToggleGroup(group.key),
            ),
          _TransactionTableHeaderEntry() => const _TransactionTableHeaderCard(),
          _TransactionItemEntry(
            :final _TransactionItem item,
            :final bool isLastInGroup,
          ) =>
            _TransactionItemCard(
              item: item,
              isExpense: state.kind == _TransactionKind.expense,
              isLastInGroup: isLastInGroup,
              onDelete: () => onDelete(item),
            ),
          _EmptyTransactionEntry() => _EmptyTransactions(kind: state.kind),
        };
      },
    );
  }
}

class _TransactionHeader extends StatelessWidget {
  final _TransactionViewState state;
  final ValueChanged<_TransactionKind> onKindChanged;
  final ValueChanged<_TransactionFilter> onFilterChanged;
  final VoidCallback onCategoryTap;
  final ValueChanged<int> onYearChanged;

  const _TransactionHeader({
    required this.state,
    required this.onKindChanged,
    required this.onFilterChanged,
    required this.onCategoryTap,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _SummaryPanel(
          totalDeposits: state.totalDeposits,
          totalSaving: state.totalSaving,
          totalDepositIncome: state.totalDepositIncome,
          totalExpenses: state.totalExpenses,
          totalAvailableIncome: state.totalAvailableIncome,
        ),
        const SizedBox(height: 10),
        _KindToggle(kind: state.kind, onChanged: onKindChanged),
        const SizedBox(height: 10),
        _CategorySelector(
          enabled: state.kind == _TransactionKind.expense,
          label: state.category ?? 'Category',
          onTap: onCategoryTap,
        ),
        const SizedBox(height: 10),
        _FilterBar(filter: state.filter, onChanged: onFilterChanged),
        const SizedBox(height: 12),
        _YearSelector(
          year: state.year,
          onPrev: () => onYearChanged(-1),
          onNext: () => onYearChanged(1),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final double totalDeposits;
  final double totalSaving;
  final double totalDepositIncome;
  final double totalExpenses;
  final double totalAvailableIncome;

  const _SummaryPanel({
    required this.totalDeposits,
    required this.totalSaving,
    required this.totalDepositIncome,
    required this.totalExpenses,
    required this.totalAvailableIncome,
  });

  @override
  Widget build(BuildContext context) {
    final Color incomeColor = totalAvailableIncome > 0
        ? _TransactionTokens.success
        : _TransactionTokens.expenseHot;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _TransactionTokens.primary,
        borderRadius: BorderRadius.circular(_TransactionTokens.cardRadius),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: _SummaryLabel(label: 'AVAILABLE INCOME')),
              Text(
                formatMoney(totalAvailableIncome),
                style: _TransactionTokens.reserveValue.copyWith(
                  color: incomeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryValue(
                  label: 'TOTAL EXPENSE',
                  value: formatMoney(totalExpenses),
                  color: _TransactionTokens.expenseHot,
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  label: 'INCOME',
                  value: formatMoney(totalDepositIncome),
                  color: _TransactionTokens.primaryBlue,
                  alignRight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryValue(
                  label: 'SAVING',
                  value: formatMoney(totalSaving),
                  color: _TransactionTokens.warning,
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  label: 'TOTAL DEPOSIT',
                  value: formatMoney(totalDeposits),
                  color: _TransactionTokens.successBright,
                  alignRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryLabel extends StatelessWidget {
  final String label;

  const _SummaryLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: _TransactionTokens.summaryLabel);
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignRight;

  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        _SummaryLabel(label: label),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: _TransactionTokens.summaryValue.copyWith(color: color),
        ),
      ],
    );
  }
}

class _KindToggle extends StatelessWidget {
  final _TransactionKind kind;
  final ValueChanged<_TransactionKind> onChanged;

  const _KindToggle({required this.kind, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _TransactionTokens.surface,
        borderRadius: BorderRadius.circular(_TransactionTokens.controlRadius),
        border: Border.all(color: _TransactionTokens.border),
      ),
      child: Row(
        children: <Widget>[
          _ToggleButton(
            label: 'Deposit',
            isActive: kind == _TransactionKind.deposit,
            onTap: () => onChanged(_TransactionKind.deposit),
          ),
          _ToggleButton(
            label: 'Expense',
            isActive: kind == _TransactionKind.expense,
            onTap: () => onChanged(_TransactionKind.expense),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_TransactionTokens.controlRadius),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? _TransactionTokens.primary
                : _TransactionTokens.surface,
            borderRadius: BorderRadius.circular(
              _TransactionTokens.controlRadius,
            ),
          ),
          child: Text(
            label,
            style: _TransactionTokens.toggleLabel.copyWith(
              color: isActive ? Colors.white : _TransactionTokens.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  const _CategorySelector({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(_TransactionTokens.controlRadius),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _TransactionTokens.surface,
          borderRadius: BorderRadius.circular(_TransactionTokens.controlRadius),
          boxShadow: _TransactionTokens.softShadow,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.chevron_right,
              size: 18,
              color: enabled
                  ? _TransactionTokens.onSurfaceMuted
                  : _TransactionTokens.iconDisabled,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                enabled ? label : 'Category',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _TransactionTokens.categoryLabel.copyWith(
                  color: enabled
                      ? _TransactionTokens.onSurface
                      : _TransactionTokens.onSurfaceDisabled,
                ),
              ),
            ),
            const Icon(
              Icons.grid_view,
              color: _TransactionTokens.iconBlue,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _TransactionFilter filter;
  final ValueChanged<_TransactionFilter> onChanged;

  const _FilterBar({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _TransactionTokens.surface,
        borderRadius: BorderRadius.circular(_TransactionTokens.controlRadius),
        boxShadow: _TransactionTokens.softShadow,
      ),
      child: Row(
        children: <Widget>[
          _FilterOptionButton(
            label: 'Weekly',
            value: _TransactionFilter.weekly,
            activeValue: filter,
            onChanged: onChanged,
          ),
          _FilterOptionButton(
            label: 'Monthly',
            value: _TransactionFilter.monthly,
            activeValue: filter,
            onChanged: onChanged,
          ),
          _FilterOptionButton(
            label: 'Quarterly',
            value: _TransactionFilter.quarterly,
            activeValue: filter,
            onChanged: onChanged,
          ),
          _FilterOptionButton(
            label: 'Yearly',
            value: _TransactionFilter.yearly,
            activeValue: filter,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterOptionButton extends StatelessWidget {
  final String label;
  final _TransactionFilter value;
  final _TransactionFilter activeValue;
  final ValueChanged<_TransactionFilter> onChanged;

  const _FilterOptionButton({
    required this.label,
    required this.value,
    required this.activeValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = activeValue == value;

    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(_TransactionTokens.controlRadius),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? _TransactionTokens.primary
                : _TransactionTokens.surface,
            borderRadius: BorderRadius.circular(
              _TransactionTokens.controlRadius,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _TransactionTokens.filterLabel.copyWith(
              color: isActive ? Colors.white : _TransactionTokens.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _YearSelector({
    required this.year,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, size: 20),
        ),
        Text('$year', style: _TransactionTokens.yearLabel),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}

class _TransactionGroupHeaderCard extends StatelessWidget {
  final _TransactionGroup group;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _TransactionGroupHeaderCard({
    required this.group,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = isExpanded
        ? const BorderRadius.vertical(
            top: Radius.circular(_TransactionTokens.cardRadius),
          )
        : BorderRadius.circular(_TransactionTokens.cardRadius);

    return Container(
      margin: EdgeInsets.only(bottom: isExpanded ? 0 : 10),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: _TransactionTokens.cardShadow,
      ),
      child: Material(
        color: _TransactionTokens.surface,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: <Widget>[
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _TransactionTokens.groupTitle,
                  ),
                ),
                Text(
                  formatMoney(group.total),
                  style: _TransactionTokens.groupAmount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTableHeaderCard extends StatelessWidget {
  const _TransactionTableHeaderCard();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: _TransactionTokens.surface),
      child: Column(
        children: <Widget>[
          Divider(height: 1, color: _TransactionTokens.border),
          _TransactionTableHeader(),
        ],
      ),
    );
  }
}

class _TransactionItemCard extends StatelessWidget {
  final _TransactionItem item;
  final bool isExpense;
  final bool isLastInGroup;
  final VoidCallback onDelete;

  const _TransactionItemCard({
    required this.item,
    required this.isExpense,
    required this.isLastInGroup,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLastInGroup ? 10 : 0),
      decoration: BoxDecoration(
        color: _TransactionTokens.surface,
        borderRadius: isLastInGroup
            ? const BorderRadius.vertical(
                bottom: Radius.circular(_TransactionTokens.cardRadius),
              )
            : BorderRadius.zero,
      ),
      child: Column(
        children: <Widget>[
          _TransactionItemRow(
            item: item,
            isExpense: isExpense,
            onDelete: onDelete,
          ),
          if (!isLastInGroup)
            const Divider(height: 1, color: _TransactionTokens.divider),
        ],
      ),
    );
  }
}

class _TransactionTableHeader extends StatelessWidget {
  const _TransactionTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: _TransactionTokens.tableHeaderPadding,
      child: Row(
        children: <Widget>[
          SizedBox(width: 42, child: _TableHeaderText('DATE')),
          SizedBox(width: 8),
          Expanded(child: _TableHeaderText('DESCRIPTION')),
          SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: _TableHeaderText('AMOUNT', textAlign: TextAlign.right),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: _TableHeaderText('METHOD', textAlign: TextAlign.center),
          ),
          SizedBox(width: 4),
          SizedBox(
            width: 30,
            child: Icon(
              Icons.delete_outline,
              size: 14,
              color: _TransactionTokens.textInactive,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String label;
  final TextAlign textAlign;

  const _TableHeaderText(this.label, {this.textAlign = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: _TransactionTokens.tableHeader,
    );
  }
}

class _TransactionItemRow extends StatelessWidget {
  final _TransactionItem item;
  final bool isExpense;
  final VoidCallback onDelete;

  const _TransactionItemRow({
    required this.item,
    required this.isExpense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _TransactionTokens.tableRowPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 42,
            child: Text(
              _shortDate(item.date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _TransactionTokens.tableCell,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _TransactionTokens.tableCell,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                formatMoney(item.amount),
                textAlign: TextAlign.right,
                style: _TransactionTokens.tableAmount.copyWith(
                  color: isExpense
                      ? _TransactionTokens.danger
                      : _TransactionTokens.textStrong,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox.square(
            dimension: 34,
            child: Center(
              child: Icon(item.icon, size: 18, color: item.iconColor),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox.square(
            dimension: 30,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: _TransactionTokens.dangerDark,
              ),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _EmptyTransactions extends StatelessWidget {
  final _TransactionKind kind;

  const _EmptyTransactions({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
      decoration: BoxDecoration(
        color: _TransactionTokens.surface,
        borderRadius: BorderRadius.circular(_TransactionTokens.cardRadius),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            kind == _TransactionKind.deposit
                ? Icons.account_balance_wallet_outlined
                : Icons.receipt_long_outlined,
            color: _TransactionTokens.textInactive,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            kind == _TransactionKind.deposit
                ? 'No deposit history for this view.'
                : 'No expense history for this view.',
            textAlign: TextAlign.center,
            style: _TransactionTokens.emptyLabel,
          ),
        ],
      ),
    );
  }
}

class _ExportActions extends StatelessWidget {
  final VoidCallback onExportPdf;
  final VoidCallback onPrintPdf;
  final VoidCallback onExportExcel;

  const _ExportActions({
    required this.onExportPdf,
    required this.onPrintPdf,
    required this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ExportButton(
            icon: Icons.picture_as_pdf,
            label: 'PDF',
            color: _TransactionTokens.danger,
            onTap: onExportPdf,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ExportButton(
            icon: Icons.print_outlined,
            label: 'Print',
            color: _TransactionTokens.primaryBlue,
            onTap: onPrintPdf,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ExportButton(
            icon: Icons.table_chart,
            label: 'Excel',
            color: _TransactionTokens.success,
            onTap: onExportExcel,
          ),
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _TransactionTokens.onSurface,
        backgroundColor: _TransactionTokens.surface,
        side: const BorderSide(color: _TransactionTokens.border),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_TransactionTokens.controlRadius),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, maxLines: 1, style: _TransactionTokens.exportLabel),
          ],
        ),
      ),
    );
  }
}

class _CategoryBottomSheet extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;

  const _CategoryBottomSheet({
    required this.categories,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: ListView.builder(
          itemCount: categories.length + 3,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return const _SheetHandle();
            }

            if (index == 1) {
              return ListTile(
                title: const Text('All Categories'),
                trailing: selectedCategory == null
                    ? const Icon(Icons.check, color: _TransactionTokens.primary)
                    : null,
                onTap: () => Navigator.pop(context),
              );
            }

            if (index == categories.length + 2) {
              return const SizedBox(height: 12);
            }

            final String category = categories[index - 2];
            return ListTile(
              title: Text(category),
              trailing: category == selectedCategory
                  ? const Icon(Icons.check, color: _TransactionTokens.primary)
                  : null,
              onTap: () => Navigator.pop(context, category),
            );
          },
        ),
      ),
    );
  }
}

class _ExportRangeBottomSheet extends StatelessWidget {
  final String actionLabel;

  const _ExportRangeBottomSheet({required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _SheetHandle(),
          Text('$actionLabel by', style: _TransactionTokens.sheetTitle),
          const SizedBox(height: 8),
          _ExportPeriodTile(
            icon: Icons.calendar_view_week,
            title: 'Week',
            subtitle: 'Choose any day in the week',
            onTap: () => Navigator.pop(context, _ExportPeriod.week),
          ),
          _ExportPeriodTile(
            icon: Icons.calendar_month,
            title: 'Month',
            subtitle: 'Choose month and year',
            onTap: () => Navigator.pop(context, _ExportPeriod.month),
          ),
          _ExportPeriodTile(
            icon: Icons.event_available,
            title: 'Year',
            subtitle: 'Choose year only',
            onTap: () => Navigator.pop(context, _ExportPeriod.year),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: _TransactionTokens.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ExportPeriodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportPeriodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _TransactionTokens.primaryBlue),
      title: Text(title, style: _TransactionTokens.tileTitle),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _DeleteTransactionDialog extends StatelessWidget {
  final _TransactionItem item;
  final String kindLabel;
  final bool isRecurringExpense;

  const _DeleteTransactionDialog({
    required this.item,
    required this.kindLabel,
    required this.isRecurringExpense,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isRecurringExpense ? 'Delete recurring expense?' : 'Delete $kindLabel?',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(item.title, style: _TransactionTokens.dialogStrong),
          const SizedBox(height: 6),
          Text(
            '${_TransactionDateUtils.fullDate(item.date)}  |  ${formatMoney(item.amount)}',
          ),
          if (item.detail.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              item.detail,
              style: const TextStyle(color: _TransactionTokens.textMuted),
            ),
          ],
          if (isRecurringExpense) ...<Widget>[
            const SizedBox(height: 10),
            const Text(
              'This will stop the recurring expense starting this month. Previous monthly entries will stay in history.',
              style: TextStyle(color: _TransactionTokens.dangerDark),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _TransactionTokens.dangerDark,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
