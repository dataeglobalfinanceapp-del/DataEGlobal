part of '../payroll_screen.dart';

class _PayrollSetupCard extends StatelessWidget {
  final PayrollViewState state;

  const _PayrollSetupCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final PayrollRecord payroll = state.payroll;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 560;

        return Container(
          decoration: _PayrollTokens.panelDecoration,
          padding: EdgeInsets.all(narrow ? 16 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _PayrollHeaderMetrics(
                balance: state.balance,
                totalPay: state.payPeriodTotalPay,
              ),
              if (payroll.unconfirmedEmployeeCount > 0) ...<Widget>[
                const SizedBox(height: 16),
                const Divider(height: 1, color: _PayrollTokens.divider),
                const SizedBox(height: 16),
                _PayrollConfirmationCaution(
                  unconfirmedCount: payroll.unconfirmedEmployeeCount,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PayrollConfirmationCaution extends StatelessWidget {
  final int unconfirmedCount;

  const _PayrollConfirmationCaution({required this.unconfirmedCount});

  @override
  Widget build(BuildContext context) {
    final String employeeLabel = unconfirmedCount == 1
        ? 'employee still needs'
        : 'employees still need';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _PayrollTokens.warningBackground,
        borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            color: _PayrollTokens.warning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$unconfirmedCount $employeeLabel to confirm payroll.',
              style: _PayrollTokens.cautionText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollHeaderMetrics extends StatelessWidget {
  final double balance;
  final double totalPay;

  const _PayrollHeaderMetrics({required this.balance, required this.totalPay});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SummaryMetric(label: 'BALANCE', value: formatMoney(balance)),
              const SizedBox(height: 16),
              _SummaryMetric(label: 'TOTAL PAY', value: formatMoney(totalPay)),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _SummaryMetric(
                label: 'BALANCE',
                value: formatMoney(balance),
              ),
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 76, color: _PayrollTokens.divider),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryMetric(
                label: 'TOTAL PAY',
                value: formatMoney(totalPay),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 16),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: _PayrollTokens.balanceValue),
        ),
      ],
    );
  }
}

class _ProcessDateField extends StatelessWidget {
  final DateTime processDate;
  final VoidCallback onTap;

  const _ProcessDateField({required this.processDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('PROCESS PAYROLL DATE', style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        _TappableField(
          value: _formatDate(processDate),
          icon: Icons.calendar_month_outlined,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _ResponsiveFieldPair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsiveFieldPair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            children: <Widget>[first, const SizedBox(height: 14), second],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: first),
            const SizedBox(width: 14),
            Container(width: 1, height: 70, color: _PayrollTokens.divider),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _DateInputTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final Key? fieldKey;

  const _DateInputTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.fieldKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        _TappableField(
          key: fieldKey,
          value: value,
          icon: Icons.calendar_month_outlined,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _PayPeriodSection extends StatelessWidget {
  final PayrollRecord payroll;
  final VoidCallback onPickBiweeklyPeriodBeginDate;

  const _PayPeriodSection({
    required this.payroll,
    required this.onPickBiweeklyPeriodBeginDate,
  });

  @override
  Widget build(BuildContext context) {
    final Widget payPeriodField = _ReadOnlyField(
      label: 'PAY PERIOD',
      value:
          '${_formatDate(payroll.payPeriodStart)} - ${_formatDate(payroll.payPeriodEnd)}',
      trailing: const Icon(
        Icons.keyboard_arrow_down,
        color: _PayrollTokens.textMuted,
      ),
    );

    if (payroll.schedule != PayrollSchedule.biWeekly) {
      return payPeriodField;
    }

    return _ResponsiveFieldPair(
      first: _DateInputTile(
        label: 'Period begin date',
        value: _formatDate(payroll.biweeklyPeriodBeginDate),
        fieldKey: const ValueKey<String>('payroll.biweeklyPeriodBeginDate'),
        onTap: onPickBiweeklyPeriodBeginDate,
      ),
      second: payPeriodField,
    );
  }
}

class _ScheduleDropdown extends StatelessWidget {
  final PayrollSchedule value;
  final ValueChanged<PayrollSchedule> onChanged;

  const _ScheduleDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('PAYROLL SCHEDULE', style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        DropdownButtonFormField<PayrollSchedule>(
          initialValue: value,
          icon: const Icon(Icons.keyboard_arrow_down),
          isExpanded: true,
          decoration: _PayrollTokens.inputDecoration,
          items: PayrollSchedule.values
              .map(
                (PayrollSchedule schedule) => DropdownMenuItem<PayrollSchedule>(
                  value: schedule,
                  child: Text(schedule.label),
                ),
              )
              .toList(growable: false),
          onChanged: (PayrollSchedule? schedule) {
            if (schedule == null) return;
            onChanged(schedule);
          },
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: _PayrollTokens.inputBoxDecoration,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _PayrollTokens.inputText,
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }
}

class _TappableField extends StatelessWidget {
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _TappableField({
    super.key,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: _PayrollTokens.inputBoxDecoration,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _PayrollTokens.inputText,
                ),
              ),
              Icon(icon, color: _PayrollTokens.textMuted, size: 25),
            ],
          ),
        ),
      ),
    );
  }
}
