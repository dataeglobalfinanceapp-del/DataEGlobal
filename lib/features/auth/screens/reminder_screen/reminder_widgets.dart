part of 'reminder_screen.dart';

final TextInputFormatter _moneyInputFormatter =
    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,12},?\d{0,3}\.?\d{0,2}'));

class _LoadingReminderList extends StatelessWidget {
  const _LoadingReminderList();

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

class _ReminderList extends StatelessWidget {
  final _ReminderViewState state;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onTapDate;
  final ValueChanged<ReminderRecord> onEditAmount;
  final ValueChanged<ReminderRecord> onDelete;
  final ValueChanged<ReminderRecord> onMarkFinished;

  const _ReminderList({
    required this.state,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTapDate,
    required this.onEditAmount,
    required this.onDelete,
    required this.onMarkFinished,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _ReminderTokens.pagePadding,
      itemCount: state.entries.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _ReminderHeader(
            state: state,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
            onTapDate: onTapDate,
          );
        }

        final _ReminderListEntry entry = state.entries[index - 1];
        return switch (entry) {
          _ReminderRecordEntry(
            :final ReminderRecord record,
            :final double remainingBalanceThisYear,
          ) =>
            _ReminderCard(
              record: record,
              remainingBalanceThisYear: remainingBalanceThisYear,
              onEditAmount: () => onEditAmount(record),
              onDelete: () => onDelete(record),
              onMarkFinished: () => onMarkFinished(record),
            ),
          _EmptyReminderEntry() => const _EmptyReminderList(),
        };
      },
    );
  }
}

class _ReminderHeader extends StatelessWidget {
  final _ReminderViewState state;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onTapDate;

  const _ReminderHeader({
    required this.state,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTapDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _MonthHeader(
          visibleMonth: state.visibleMonth,
          onPrev: onPreviousMonth,
          onNext: onNextMonth,
        ),
        const SizedBox(height: 10),
        _CalendarGrid(days: state.calendarDays, onTapDate: onTapDate),
        const SizedBox(height: 14),
        const _ReminderSectionHeader(),
      ],
    );
  }
}

class _ReminderSectionHeader extends StatelessWidget {
  const _ReminderSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text('PAYMENT OBLIGATIONS', style: _ReminderTokens.sectionLabel),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime visibleMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.visibleMonth,
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
        Text(
          '${_monthNames[visibleMonth.month]} ${visibleMonth.year}',
          style: _ReminderTokens.monthTitle,
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final List<_CalendarDayModel> days;
  final ValueChanged<DateTime> onTapDate;

  const _CalendarGrid({required this.days, required this.onTapDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: _ReminderTokens.surface,
        borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
        boxShadow: _ReminderTokens.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          const _WeekdayRow(),
          const SizedBox(height: 8),
          for (int row = 0; row < 6; row += 1)
            Row(
              children: <Widget>[
                for (int column = 0; column < 7; column += 1)
                  Expanded(
                    child: _CalendarDayCell(
                      day: days[(row * 7) + column],
                      onTap: onTapDate,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(child: _WeekdayLabel('SUN')),
        Expanded(child: _WeekdayLabel('MON')),
        Expanded(child: _WeekdayLabel('TUE')),
        Expanded(child: _WeekdayLabel('WED')),
        Expanded(child: _WeekdayLabel('THU')),
        Expanded(child: _WeekdayLabel('FRI')),
        Expanded(child: _WeekdayLabel('SAT')),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: _ReminderTokens.weekdayLabel,
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final _CalendarDayModel day;
  final ValueChanged<DateTime> onTap;

  const _CalendarDayCell({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color background = day.hasReminders
        ? const Color(0xFFD64A4A)
        : day.isToday
        ? _ReminderTokens.today
        : Colors.transparent;
    final Color foreground = day.hasReminders || day.isToday
        ? Colors.white
        : day.isInVisibleMonth
        ? _ReminderTokens.textStrong
        : _ReminderTokens.textInactive;

    return InkWell(
      borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
      onTap: () => onTap(day.date),
      child: SizedBox(
        height: 32,
        child: Center(
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
            ),
            child: Text(
              '${day.date.day}',
              style: TextStyle(
                color: foreground,
                fontSize: 10,
                fontWeight: day.hasReminders || day.isToday
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderRecord record;
  final double remainingBalanceThisYear;
  final VoidCallback onEditAmount;
  final VoidCallback onDelete;
  final VoidCallback onMarkFinished;

  const _ReminderCard({
    required this.record,
    required this.remainingBalanceThisYear,
    required this.onEditAmount,
    required this.onDelete,
    required this.onMarkFinished,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: _ReminderTokens.paymentObligationBackground,
        borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
        boxShadow: _ReminderTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: _ReminderLineText(
                  label: 'Category Name',
                  value: record.category,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: _ReminderLineText(label: 'Payee', value: record.payee),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 0,
                child: _ReminderLineText(
                  label: 'Frequency',
                  value: record.reminderCount,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: _ReminderLineText(
                  label: 'Due Date',
                  value: _ReminderDateUtils.fullDate(record.date),
                  alignRight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                flex: 2,
                child: _ReminderAmountText(amount: record.amount),
              ),
              if (record.isRecurring) ...<Widget>[
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: _ReminderRemainingBalanceText(
                    amount: remainingBalanceThisYear,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              _ReminderIconActionButton(
                tooltip: 'Completed',
                icon: Icons.check_circle,
                iconColor: _ReminderTokens.success,
                onPressed: onMarkFinished,
              ),
              const SizedBox(width: 6),
              _ReminderIconActionButton(
                tooltip: 'Edit Amount',
                icon: Icons.edit_outlined,
                iconColor: _ReminderTokens.blue,
                onPressed: onEditAmount,
              ),
              const SizedBox(width: 4),
              _ReminderIconActionButton(
                tooltip: 'Delete',
                icon: Icons.delete_outline,
                iconColor: _ReminderTokens.dangerDark,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderLineText extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;

  const _ReminderLineText({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: _ReminderTokens.compactLineText,
      ),
    );
  }
}

class _ReminderAmountText extends StatelessWidget {
  final double amount;

  const _ReminderAmountText({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Amount ${formatMoney(amount)}',
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatMoney(amount),
            style: _ReminderTokens.compactAmount,
          ),
        ),
      ),
    );
  }
}

class _ReminderRemainingBalanceText extends StatelessWidget {
  final double amount;

  const _ReminderRemainingBalanceText({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Remaining balance this year ${formatMoney(amount)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Remaining balance this year',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _ReminderTokens.compactBalanceLabel,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(amount),
              style: _ReminderTokens.compactBalanceAmount,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderIconActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _ReminderIconActionButton({
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 28,
      child: IconButton(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: _ReminderTokens.compactActionBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
          ),
        ),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}

class _EmptyReminderList extends StatelessWidget {
  const _EmptyReminderList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: _ReminderTokens.surface,
        borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.notifications_none,
            color: _ReminderTokens.textInactive,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Tap a date to create a reminder.',
            textAlign: TextAlign.center,
            style: _ReminderTokens.emptyLabel,
          ),
        ],
      ),
    );
  }
}

class _AmountEditDialog extends StatefulWidget {
  final ReminderRecord record;

  const _AmountEditDialog({required this.record});

  @override
  State<_AmountEditDialog> createState() => _AmountEditDialogState();
}

class _AmountEditDialogState extends State<_AmountEditDialog> {
  late final TextEditingController _controller;
  late bool _applyToSeries;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.record.amount.toStringAsFixed(2),
    );
    _applyToSeries = widget.record.isRecurring;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit amount'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[_moneyInputFormatter],
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: r'$',
            ),
          ),
          if (widget.record.isRecurring) ...<Widget>[
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _applyToSeries,
              onChanged: (bool value) {
                setState(() => _applyToSeries = value);
              },
              title: const Text(
                'Apply to all recurring reminders',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final double amount = parseMoney(_controller.text);
            if (amount <= 0) return;
            Navigator.pop(
              context,
              _AmountEditResult(
                amount: amount,
                applyToSeries: widget.record.isRecurring && _applyToSeries,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DeleteRecurringReminderDialog extends StatelessWidget {
  const _DeleteRecurringReminderDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete recurring schedule?'),
      content: const Text(
        'This removes future reminders and linked recurring expenses. Completed expense history is kept.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _ReminderTokens.dangerDark,
          ),
          onPressed: () => Navigator.pop(context, ReminderDeleteScope.series),
          child: const Text('Delete schedule'),
        ),
      ],
    );
  }
}

class _DeleteReminderDialog extends StatelessWidget {
  const _DeleteReminderDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete reminder?'),
      content: const Text('This reminder will be permanently deleted.'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _ReminderTokens.dangerDark,
          ),
          onPressed: () => Navigator.pop(context, ReminderDeleteScope.single),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class _CreateReminderList extends StatelessWidget {
  final List<_ReminderFormData> forms;
  final ValueChanged<_ReminderFormData> onPickDate;
  final ValueChanged<_ReminderFormData> onRemove;
  final VoidCallback onAdd;
  final void Function(_ReminderFormData form, String category)
  onCategoryChanged;
  final void Function(_ReminderFormData form, String count)
  onReminderCountChanged;

  const _CreateReminderList({
    required this.forms,
    required this.onPickDate,
    required this.onRemove,
    required this.onAdd,
    required this.onCategoryChanged,
    required this.onReminderCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: _ReminderTokens.createPagePadding,
      itemCount: forms.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == forms.length) {
          return _AddReminderButton(onPressed: onAdd);
        }

        final _ReminderFormData form = forms[index];
        return _ReminderForm(
          form: form,
          canRemove: forms.length > 1,
          onPickDate: () => onPickDate(form),
          onRemove: () => onRemove(form),
          onCategoryChanged: (String category) {
            onCategoryChanged(form, category);
          },
          onReminderCountChanged: (String count) {
            onReminderCountChanged(form, count);
          },
        );
      },
    );
  }
}

class _AddReminderButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddReminderButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.note_add_outlined,
          color: _ReminderTokens.iconBlue,
        ),
        label: const Text(
          'Add more reminder',
          style: _ReminderTokens.addButtonLabel,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
          ),
          side: const BorderSide(color: _ReminderTokens.inputBorder),
        ),
      ),
    );
  }
}

class _ReminderForm extends StatelessWidget {
  final _ReminderFormData form;
  final bool canRemove;
  final VoidCallback onPickDate;
  final VoidCallback onRemove;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onReminderCountChanged;

  const _ReminderForm({
    required this.form,
    required this.canRemove,
    required this.onPickDate,
    required this.onRemove,
    required this.onCategoryChanged,
    required this.onReminderCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: <Widget>[
          if (canRemove)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  color: _ReminderTokens.danger,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _FormFieldShell(
                  label: 'DATE',
                  isRequired: true,
                  child: InkWell(
                    onTap: onPickDate,
                    child: _InputLikeBox(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(_ReminderDateUtils.fullDate(form.date)),
                          ),
                          const Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: _ReminderTokens.iconBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _FormFieldShell(
                  label: 'CATEGORY',
                  isRequired: true,
                  child: _InputLikeBox(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: form.category,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.grid_view,
                          size: 18,
                          color: _ReminderTokens.iconBlue,
                        ),
                        items: _categoryItems,
                        onChanged: (String? value) {
                          if (value == null) return;
                          onCategoryChanged(value);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _FormFieldShell(
                  label: 'AMOUNT',
                  isRequired: true,
                  child: _InputLikeBox(
                    child: TextField(
                      controller: form.amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        _moneyInputFormatter,
                      ],
                      decoration: const InputDecoration(
                        hintText: 'e.g: \$120.00',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _FormFieldShell(
                  label: 'REMINDER COUNT',
                  child: _InputLikeBox(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: form.reminderCount,
                        isExpanded: true,
                        items: _reminderCountItems,
                        onChanged: (String? value) {
                          if (value == null) return;
                          onReminderCountChanged(value);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final List<DropdownMenuItem<String>> _categoryItems = _categories
      .map<DropdownMenuItem<String>>(
        (String category) =>
            DropdownMenuItem<String>(value: category, child: Text(category)),
      )
      .toList(growable: false);

  static final List<DropdownMenuItem<String>> _reminderCountItems =
      _reminderCounts
          .map<DropdownMenuItem<String>>(
            (String count) =>
                DropdownMenuItem<String>(value: count, child: Text(count)),
          )
          .toList(growable: false);
}

class _FormFieldShell extends StatelessWidget {
  final String label;
  final bool isRequired;
  final Widget child;

  const _FormFieldShell({
    required this.label,
    required this.child,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RichText(
          text: TextSpan(
            style: _ReminderTokens.fieldLabel,
            children: <InlineSpan>[
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: _ReminderTokens.danger),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InputLikeBox extends StatelessWidget {
  final Widget child;

  const _InputLikeBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _ReminderTokens.surface,
        borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
        boxShadow: _ReminderTokens.inputShadow,
      ),
      child: DefaultTextStyle(style: _ReminderTokens.inputText, child: child),
    );
  }
}
