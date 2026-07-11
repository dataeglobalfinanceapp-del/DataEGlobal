part of '../payroll_screen.dart';

class _PayrollSettingsScreen extends StatefulWidget {
  final PayrollController controller;

  const _PayrollSettingsScreen({required this.controller});

  @override
  State<_PayrollSettingsScreen> createState() => _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends State<_PayrollSettingsScreen> {
  static const List<int> _processDayOptions = <int>[1, 2, 3, 5, 7, 10, 14];

  Future<void> _pickPayDate() async {
    final PayrollRecord payroll = widget.controller.state.payroll;
    final DateTime firstSelectableDate =
        PayrollPayDateValidator.firstSelectablePayDate();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: PayrollPayDateValidator.normalizePayDate(payroll.payDate),
      firstDate: firstSelectableDate,
      lastDate: DateTime(2100, 12, 31),
      currentDate: AppClock.now,
      helpText: 'Choose pay date',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      selectableDayPredicate: (DateTime date) {
        return PayrollPayDateValidator.isSelectablePayDate(date);
      },
    );
    if (picked == null || !mounted) return;

    widget.controller.setPayDate(picked);
  }

  Future<void> _pickBiweeklyPeriodBeginDate() async {
    final PayrollRecord payroll = widget.controller.state.payroll;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: payroll.biweeklyPeriodBeginDate,
      firstDate: PayrollScheduleCalculator.earliestBiweeklyPeriodBeginDate(),
      lastDate: PayrollScheduleCalculator.latestBiweeklyPeriodBeginDate(),
      currentDate: AppClock.now,
      helpText: 'Choose period begin date',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      selectableDayPredicate: (DateTime date) {
        return PayrollScheduleCalculator.isSelectableBiweeklyPeriodBeginDate(
          date,
        );
      },
    );
    if (picked == null || !mounted) return;

    widget.controller.setBiweeklyPeriodBeginDate(picked);
  }

  Future<void> _chooseProcessDays() async {
    final PayrollRecord payroll = widget.controller.state.payroll;
    final int? selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _PayrollTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Process Payroll',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              for (final int days in _processDayOptions)
                ListTile(
                  leading: Icon(
                    days == payroll.processDaysBefore
                        ? Icons.check_circle
                        : Icons.calendar_month_outlined,
                    color: days == payroll.processDaysBefore
                        ? _PayrollTokens.success
                        : _PayrollTokens.textMuted,
                  ),
                  title: Text('$days days before pay date'),
                  subtitle: Text(
                    _formatDate(payroll.payDate.subtract(Duration(days: days))),
                  ),
                  onTap: () => Navigator.pop(context, days),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;

    widget.controller.setProcessDaysBefore(selected);
  }

  void _handlePayrollScheduleChanged(PayrollSchedule schedule) {
    widget.controller.setSchedule(schedule);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PayrollTokens.screenBackground,
      appBar: AppBar(
        backgroundColor: _PayrollTokens.surface,
        elevation: 0,
        title: const Text(
          'Payroll Settings',
          style: _PayrollTokens.appBarTitle,
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (BuildContext context, Widget? child) {
          final PayrollViewState state = widget.controller.state;
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: _PayrollTokens.pagePadding,
            child: _PayrollSettingsForm(
              state: state,
              onProcessPayrollDateChanged: _chooseProcessDays,
              onPayDateChanged: _pickPayDate,
              onPayrollScheduleChanged: _handlePayrollScheduleChanged,
              onPeriodBeginDateChanged: _pickBiweeklyPeriodBeginDate,
            ),
          );
        },
      ),
    );
  }
}

class _PayrollSettingsForm extends StatelessWidget {
  final PayrollViewState state;
  final VoidCallback onProcessPayrollDateChanged;
  final VoidCallback onPayDateChanged;
  final ValueChanged<PayrollSchedule> onPayrollScheduleChanged;
  final VoidCallback onPeriodBeginDateChanged;

  const _PayrollSettingsForm({
    required this.state,
    required this.onProcessPayrollDateChanged,
    required this.onPayDateChanged,
    required this.onPayrollScheduleChanged,
    required this.onPeriodBeginDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final PayrollRecord payroll = state.payroll;

    return Container(
      decoration: _PayrollTokens.panelDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ProcessDateField(
            processDate: payroll.processDate,
            onTap: onProcessPayrollDateChanged,
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _PayrollTokens.divider),
          const SizedBox(height: 18),
          _ResponsiveFieldPair(
            first: _DateInputTile(
              label: 'PAY DATE',
              value: _formatDate(payroll.payDate),
              onTap: onPayDateChanged,
            ),
            second: _ScheduleDropdown(
              value: payroll.schedule,
              onChanged: onPayrollScheduleChanged,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _PayrollTokens.divider),
          const SizedBox(height: 18),
          _PayPeriodSection(
            payroll: payroll,
            onPickBiweeklyPeriodBeginDate: onPeriodBeginDateChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(
                Icons.notifications_active_outlined,
                color: _PayrollTokens.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payroll.processInstruction,
                  style: _PayrollTokens.helperText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
