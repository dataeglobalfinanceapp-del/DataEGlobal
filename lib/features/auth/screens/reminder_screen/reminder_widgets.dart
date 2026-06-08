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
  final ValueChanged<ReminderRecord> onTapReminder;

  const _ReminderList({
    required this.state,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTapDate,
    required this.onTapReminder,
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
          _ReminderRecordEntry(:final ReminderRecord record) => _ReminderCard(
            record: record,
            onTap: () => onTapReminder(record),
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
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            'PAYMENT OBLIGATIONS',
            style: _ReminderTokens.sectionLabel,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('View all', style: _ReminderTokens.viewAllLabel),
        ),
      ],
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
        ? _ReminderTokens.success
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
  final VoidCallback onTap;

  const _ReminderCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _ReminderTokens.surface,
        borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
        border: Border(
          left: BorderSide(color: _ReminderTokens.successAccent, width: 3),
        ),
        boxShadow: _ReminderTokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          contentPadding: _ReminderTokens.cardTilePadding,
          onTap: onTap,
          title: Text(
            _ReminderDateUtils.fullDate(record.date),
            style: _ReminderTokens.cardTitle,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(record.payee, style: _ReminderTokens.cardBody),
                if (record.isRecurring) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    record.reminderCount,
                    style: const TextStyle(
                      color: _ReminderTokens.recurringText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formatMoney(record.amount),
                style: const TextStyle(
                  color: _ReminderTokens.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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

class _ReminderPickerSheet extends StatelessWidget {
  final DateTime date;
  final List<ReminderRecord> reminders;

  const _ReminderPickerSheet({required this.date, required this.reminders});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: ListView.builder(
          itemCount: reminders.length + 4,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return const _SheetHandle();
            }

            if (index == 1) {
              return Text(
                _ReminderDateUtils.fullDate(date),
                textAlign: TextAlign.center,
                style: _ReminderTokens.sheetTitle,
              );
            }

            if (index == 2) {
              return const SizedBox(height: 8);
            }

            if (index == reminders.length + 3) {
              return ListTile(
                leading: const Icon(Icons.add, color: _ReminderTokens.blue),
                title: const Text('Add another reminder'),
                onTap: () => Navigator.pop(context),
              );
            }

            final ReminderRecord record = reminders[index - 3];
            return ListTile(
              title: Text(record.payee),
              subtitle: Text(
                record.isRecurring
                    ? '${record.category} | ${record.reminderCount}'
                    : record.category,
              ),
              trailing: Text(
                formatMoney(record.amount),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () => Navigator.pop(context, record),
            );
          },
        ),
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
            color: _ReminderTokens.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
      ],
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
      title: const Text('Delete recurring reminder?'),
      content: const Text(
        'Do you want to delete only this reminder or every reminder in this recurring series?',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ReminderDeleteScope.single),
          child: const Text('Just this one'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _ReminderTokens.dangerDark,
          ),
          onPressed: () => Navigator.pop(context, ReminderDeleteScope.series),
          child: const Text('Delete all'),
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

class _ReminderDetailDialog extends StatefulWidget {
  final ReminderRecord record;
  final Future<void> Function(bool value) onAlertChanged;

  const _ReminderDetailDialog({
    required this.record,
    required this.onAlertChanged,
  });

  @override
  State<_ReminderDetailDialog> createState() => _ReminderDetailDialogState();
}

class _ReminderDetailDialogState extends State<_ReminderDetailDialog> {
  late bool _alertEnabled;
  bool _isUpdatingAlert = false;

  @override
  void initState() {
    super.initState();
    _alertEnabled = widget.record.alertEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_ReminderTokens.dialogRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _DueBadge(record: widget.record),
            const SizedBox(height: 28),
            const Text('AMOUNT DUE', style: _ReminderTokens.amountLabel),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatMoney(widget.record.amount),
                style: _ReminderTokens.amountValue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _ReminderDateUtils.fullDate(widget.record.date),
              style: _ReminderTokens.detailDate,
            ),
            if (widget.record.isRecurring) ...<Widget>[
              const SizedBox(height: 6),
              _RecurringLabel(label: widget.record.reminderCount),
            ],
            const SizedBox(height: 26),
            _PayeeRow(payee: widget.record.payee),
            const SizedBox(height: 24),
            _AlertToggleRow(
              enabled: _alertEnabled,
              isBusy: _isUpdatingAlert,
              onChanged: _handleAlertChanged,
            ),
            const SizedBox(height: 18),
            _ReminderEditDeleteActions(
              onEdit: () {
                Navigator.pop(context, _ReminderDetailAction.editAmount);
              },
              onDelete: () {
                Navigator.pop(context, _ReminderDetailAction.delete);
              },
            ),
            const SizedBox(height: 28),
            _ReminderPostponeCloseActions(
              onPostpone: () {
                Navigator.pop(context, _ReminderDetailAction.postpone);
              },
              onClose: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAlertChanged(bool value) async {
    setState(() => _isUpdatingAlert = true);
    await widget.onAlertChanged(value);
    if (!mounted) return;
    setState(() {
      _alertEnabled = value;
      _isUpdatingAlert = false;
    });
  }
}

class _DueBadge extends StatelessWidget {
  final ReminderRecord record;

  const _DueBadge({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _ReminderTokens.warningSoft,
        borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
        border: Border.all(color: _ReminderTokens.today),
      ),
      child: Text(
        _ReminderDateUtils.dueLabel(record.date),
        style: const TextStyle(
          color: _ReminderTokens.warningDark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RecurringLabel extends StatelessWidget {
  final String label;

  const _RecurringLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _ReminderTokens.recurringSoft,
        borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
        border: Border.all(color: _ReminderTokens.recurringBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.repeat,
            size: 13,
            color: _ReminderTokens.recurringText,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _ReminderTokens.recurringText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayeeRow extends StatelessWidget {
  final String payee;

  const _PayeeRow({required this.payee});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(
          Icons.person_add_alt_1_outlined,
          size: 20,
          color: _ReminderTokens.successAccent,
        ),
        const SizedBox(width: 10),
        const Text('PAYEE', style: _ReminderTokens.payeeLabel),
        const Spacer(),
        Flexible(
          child: Text(
            payee,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: _ReminderTokens.payeeValue,
          ),
        ),
      ],
    );
  }
}

class _AlertToggleRow extends StatelessWidget {
  final bool enabled;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  const _AlertToggleRow({
    required this.enabled,
    required this.isBusy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _ReminderTokens.alertPanel,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: _ReminderTokens.alertIcon,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Alert Notifications', style: _ReminderTokens.alertTitle),
              SizedBox(height: 3),
              Text(
                'Receive reminders for this event',
                style: _ReminderTokens.alertBody,
              ),
            ],
          ),
        ),
        Switch(
          value: enabled,
          activeThumbColor: _ReminderTokens.primary,
          onChanged: isBusy ? null : onChanged,
        ),
      ],
    );
  }
}

class _ReminderEditDeleteActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderEditDeleteActions({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  _ReminderTokens.controlRadius,
                ),
              ),
            ),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit amount'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _ReminderTokens.dangerDark,
              side: const BorderSide(color: _ReminderTokens.dangerBorder),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  _ReminderTokens.controlRadius,
                ),
              ),
            ),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete'),
          ),
        ),
      ],
    );
  }
}

class _ReminderPostponeCloseActions extends StatelessWidget {
  final VoidCallback onPostpone;
  final VoidCallback onClose;

  const _ReminderPostponeCloseActions({
    required this.onPostpone,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: _ReminderTokens.softPanel,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  _ReminderTokens.controlRadius,
                ),
              ),
            ),
            onPressed: onPostpone,
            child: const Text(
              'Postpone',
              style: TextStyle(color: _ReminderTokens.textStrong),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _ReminderTokens.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  _ReminderTokens.controlRadius,
                ),
              ),
            ),
            onPressed: onClose,
            child: const Text('Close'),
          ),
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
