part of '../payroll_screen.dart';

class _EmployeeInformationDialog extends StatefulWidget {
  final PayrollEmployee employee;
  final _EmployeeChanged onEmployeeChanged;
  final ValueChanged<String> onRemoveEmployee;

  const _EmployeeInformationDialog({
    required this.employee,
    required this.onEmployeeChanged,
    required this.onRemoveEmployee,
  });

  @override
  State<_EmployeeInformationDialog> createState() =>
      _EmployeeInformationDialogState();
}

class _EmployeeInformationDialogState
    extends State<_EmployeeInformationDialog> {
  static const List<String> _jobTypes = <String>[
    'Hourly',
    'Salary',
    'Contractor',
    'Part Time',
    'Full Time',
  ];

  late PayrollEmployee _employee;
  late final TextEditingController _nameController;
  late final TextEditingController _birthdayController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _dateHireController;
  late final TextEditingController _linkW4Controller;
  late String? _jobType;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _nameController = TextEditingController(text: _employee.name);
    _birthdayController = TextEditingController(text: _employee.birthday);
    _phoneController = TextEditingController(text: _employee.phone);
    _addressController = TextEditingController(text: _employee.address);
    _dateHireController = TextEditingController(text: _employee.dateHire);
    _linkW4Controller = TextEditingController(text: _employee.linkW4);
    _jobType = _jobTypes.contains(_employee.jobType) ? _employee.jobType : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateHireController.dispose();
    _linkW4Controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  Future<void> _confirm() async {
    final PayrollEmployee updated = _employee.copyWith(
      name: _nameController.text.trim().isEmpty
          ? _employee.name
          : _nameController.text.trim(),
      birthday: _birthdayController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      dateHire: _dateHireController.text.trim(),
      jobType: _jobType ?? '',
      linkW4: _linkW4Controller.text.trim(),
    );
    await widget.onEmployeeChanged(
      _employee.id,
      name: updated.name,
      birthday: updated.birthday,
      phone: updated.phone,
      address: updated.address,
      dateHire: updated.dateHire,
      jobType: updated.jobType,
      linkW4: updated.linkW4,
    );
    if (!mounted) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _employee = updated;
      _isEditing = false;
    });
  }

  Future<void> _remove() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text('Are you sure you want to remove this employee?'),
          actions: <Widget>[
            TextButton(
              key: const ValueKey<String>('payroll.employeeInfo.cancelRemove'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const ValueKey<String>('payroll.employeeInfo.confirmRemove'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    widget.onRemoveEmployee(_employee.id);
    Navigator.pop(context);
  }

  List<_EmployeeDetailData> get _details {
    return <_EmployeeDetailData>[
      _EmployeeDetailData(label: 'Full Name', value: _employee.name),
      _EmployeeDetailData(label: 'Birthday', value: _employee.birthday),
      _EmployeeDetailData(label: 'Phone', value: _employee.phone),
      _EmployeeDetailData(label: 'Address', value: _employee.address),
      _EmployeeDetailData(label: 'Date Hire', value: _employee.dateHire),
      _EmployeeDetailData(label: 'Job Type', value: _employee.jobType),
      if (_employee.linkW4.trim().isNotEmpty)
        _EmployeeDetailData(label: 'W4', value: _employee.linkW4),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: _PayrollTokens.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_PayrollTokens.cardRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: screenSize.height - 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Employee Information',
                      style: _PayrollTokens.cardTitle,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>('payroll.employeeInfo.edit'),
                    tooltip: 'Edit employee',
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit_outlined),
                    style: IconButton.styleFrom(
                      foregroundColor: _PayrollTokens.textMuted,
                      side: const BorderSide(color: _PayrollTokens.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _PayrollTokens.controlRadius,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const ValueKey<String>('payroll.employeeInfo.close'),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: _PayrollTokens.textMuted,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: _isEditing
                    ? _EmployeeInformationEditFields(
                        nameController: _nameController,
                        birthdayController: _birthdayController,
                        phoneController: _phoneController,
                        addressController: _addressController,
                        dateHireController: _dateHireController,
                        linkW4Controller: _linkW4Controller,
                        jobType: _jobType,
                        jobTypes: _jobTypes,
                        showW4: _employee.linkW4.trim().isNotEmpty,
                        onJobTypeChanged: (String? value) {
                          if (value == null) return;
                          setState(() => _jobType = value);
                        },
                      )
                    : _EmployeeDetailGrid(details: _details),
              ),
            ),
            if (_isEditing) ...<Widget>[
              const Divider(height: 1, color: _PayrollTokens.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 112,
                        height: 48,
                        child: OutlinedButton(
                          key: const ValueKey<String>(
                            'payroll.employeeInfo.remove',
                          ),
                          onPressed: _remove,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _PayrollTokens.controlRadius,
                              ),
                            ),
                          ),
                          child: const Text('Remove'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 128,
                        height: 48,
                        child: FilledButton(
                          key: const ValueKey<String>(
                            'payroll.employeeInfo.confirm',
                          ),
                          onPressed: _confirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: _PayrollTokens.tabSelected,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _PayrollTokens.controlRadius,
                              ),
                            ),
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmployeeInformationEditFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController birthdayController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController dateHireController;
  final TextEditingController linkW4Controller;
  final String? jobType;
  final List<String> jobTypes;
  final bool showW4;
  final ValueChanged<String?> onJobTypeChanged;

  const _EmployeeInformationEditFields({
    required this.nameController,
    required this.birthdayController,
    required this.phoneController,
    required this.addressController,
    required this.dateHireController,
    required this.linkW4Controller,
    required this.jobType,
    required this.jobTypes,
    required this.showW4,
    required this.onJobTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool twoColumns = constraints.maxWidth >= 520;
        const double gap = 16;
        final double fieldWidth = twoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: 16,
          children: <Widget>[
            SizedBox(
              width: fieldWidth,
              child: _EmployeeInformationTextField(
                fieldKey: const ValueKey<String>(
                  'payroll.employeeInfo.fullName',
                ),
                label: 'Full Name',
                controller: nameController,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _EmployeeInformationTextField(
                fieldKey: const ValueKey<String>(
                  'payroll.employeeInfo.birthday',
                ),
                label: 'Birthday',
                controller: birthdayController,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _EmployeeInformationTextField(
                fieldKey: const ValueKey<String>('payroll.employeeInfo.phone'),
                label: 'Phone',
                controller: phoneController,
                keyboardType: TextInputType.phone,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _EmployeeInformationTextField(
                fieldKey: const ValueKey<String>(
                  'payroll.employeeInfo.dateHire',
                ),
                label: 'Date Hire',
                controller: dateHireController,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _EmployeeInformationJobTypeField(
                value: jobType,
                jobTypes: jobTypes,
                onChanged: onJobTypeChanged,
              ),
            ),
            SizedBox(
              width: constraints.maxWidth,
              child: _EmployeeInformationTextField(
                fieldKey: const ValueKey<String>(
                  'payroll.employeeInfo.address',
                ),
                label: 'Address',
                controller: addressController,
                minLines: 2,
                maxLines: 3,
              ),
            ),
            if (showW4)
              SizedBox(
                width: constraints.maxWidth,
                child: _EmployeeInformationTextField(
                  fieldKey: const ValueKey<String>('payroll.employeeInfo.w4'),
                  label: 'W4',
                  controller: linkW4Controller,
                  keyboardType: TextInputType.url,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmployeeInformationTextField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  const _EmployeeInformationTextField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _PayrollTokens.detailLabel),
        const SizedBox(height: 8),
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          style: _PayrollTokens.detailValue,
          decoration: _PayrollTokens.inputDecoration,
        ),
      ],
    );
  }
}

class _EmployeeInformationJobTypeField extends StatelessWidget {
  final String? value;
  final List<String> jobTypes;
  final ValueChanged<String?> onChanged;

  const _EmployeeInformationJobTypeField({
    required this.value,
    required this.jobTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Job Type', style: _PayrollTokens.detailLabel),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const ValueKey<String>('payroll.employeeInfo.jobType'),
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: _PayrollTokens.inputDecoration,
          hint: Text('Select job type', style: _PayrollTokens.inputHint),
          items: <DropdownMenuItem<String>>[
            for (final String jobType in jobTypes)
              DropdownMenuItem<String>(value: jobType, child: Text(jobType)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _EmployeeDetailGrid extends StatelessWidget {
  final List<_EmployeeDetailData> details;

  const _EmployeeDetailGrid({required this.details});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool twoColumns = constraints.maxWidth >= 520;
        const double gap = 18;
        final double width = twoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: 22,
          children: <Widget>[
            for (final _EmployeeDetailData detail in details)
              SizedBox(
                width: width,
                child: _EmployeeDetailLine(
                  label: detail.label,
                  value: detail.value,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmployeeDetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _EmployeeDetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Text(label, style: _PayrollTokens.detailLabel),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            style: _PayrollTokens.detailValue,
          ),
        ),
      ],
    );
  }
}

class _EmployeeDetailData {
  final String label;
  final String value;

  const _EmployeeDetailData({required this.label, required this.value});
}

class _AddEmployeeDialog extends StatefulWidget {
  final EmployeeDocumentEmailService emailService;

  const _AddEmployeeDialog({required this.emailService});

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  static const List<String> _jobTypes = <String>[
    'Hourly',
    'Salary',
    'Contractor',
    'Part Time',
    'Full Time',
  ];
  static const List<String> _payMethods = <String>[
    'Direct Deposit',
    'Check',
    'Cash',
    'Payroll Card',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateHireController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _linkW4Controller = TextEditingController();

  String? _jobType;
  String? _payMethod;

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthdayController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateHireController.dispose();
    _rateController.dispose();
    _linkW4Controller.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final DateTime today = _dateOnly(AppClock.now);
    await _pickDate(
      controller: _birthdayController,
      helpText: 'Choose birthday',
      initialDate: DateTime(today.year - 25, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
    );
  }

  Future<void> _pickDateHire() async {
    await _pickDate(
      controller: _dateHireController,
      helpText: 'Choose date hire',
      initialDate: _dateOnly(AppClock.now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required String helpText,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(controller.text) ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
    );
    if (picked == null || !mounted) return;

    setState(() => controller.text = _formatDate(picked));
  }

  Future<void> _sendW4Email() async {
    final String? recipientEmail = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _W4EmailRecipientDialog(),
    );
    if (recipientEmail == null || !mounted) return;

    try {
      await widget.emailService.sendW4Email(
        W4EmailRequest(
          recipientEmail: recipientEmail,
          employeeName: _fullNameController.text,
          linkW4: _linkW4Controller.text,
        ),
      );
      if (!mounted) return;

      _showMessage('Email draft opened');
    } on EmployeeDocumentEmailException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to send W4 email');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final EmployeeFormData formData = EmployeeFormData.fromInput(
      fullName: _fullNameController.text,
      birthday: _birthdayController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      dateHire: _dateHireController.text,
      jobType: _jobType ?? '',
      rateText: _rateController.text,
      payMethod: _payMethod ?? '',
      linkW4: _linkW4Controller.text,
    );

    Navigator.pop(context, formData.toPayrollEmployee());
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: _PayrollTokens.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_PayrollTokens.cardRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 860,
          maxHeight: screenSize.height - 48,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stacked = constraints.maxWidth < 640;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 20, 12),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Add New Employee',
                          style: _PayrollTokens.dialogTitle,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey<String>(
                          'payroll.addEmployee.close',
                        ),
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: _PayrollTokens.textMuted,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                    child: Form(
                      key: _formKey,
                      child: _AddEmployeeFieldRows(
                        stacked: stacked,
                        rows: <List<Widget>>[
                          <Widget>[
                            _AddEmployeeTextField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.fullName',
                              ),
                              label: 'Full Name',
                              requiredField: true,
                              controller: _fullNameController,
                              hintText: 'Enter full name',
                              validator:
                                  EmployeeFormValidators.validateRequiredName,
                              textInputAction: TextInputAction.next,
                            ),
                            _AddEmployeeDropdownField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.jobType',
                              ),
                              label: 'Job Type',
                              optional: true,
                              value: _jobType,
                              hintText: 'Select job type (optional)',
                              items: _jobTypes,
                              onChanged: (String? value) =>
                                  setState(() => _jobType = value),
                            ),
                          ],
                          <Widget>[
                            _AddEmployeeDateField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.birthday',
                              ),
                              label: 'Birthday',
                              optional: true,
                              controller: _birthdayController,
                              onTap: _pickBirthday,
                            ),
                            _AddEmployeeTextField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.rate',
                              ),
                              label: 'Rate',
                              requiredField: true,
                              controller: _rateController,
                              hintText: 'Enter rate',
                              prefixText: r'$',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              validator:
                                  EmployeeFormValidators.validateRequiredRate,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                          <Widget>[
                            _AddEmployeeTextField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.phone',
                              ),
                              label: 'Phone',
                              optional: true,
                              controller: _phoneController,
                              hintText: 'Enter phone number',
                              keyboardType: TextInputType.phone,
                              validator:
                                  EmployeeFormValidators.validateOptionalPhone,
                              textInputAction: TextInputAction.next,
                            ),
                            _AddEmployeeDropdownField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.payMethod',
                              ),
                              label: 'Pay Method',
                              optional: true,
                              value: _payMethod,
                              hintText: 'Select pay method (optional)',
                              items: _payMethods,
                              onChanged: (String? value) =>
                                  setState(() => _payMethod = value),
                            ),
                          ],
                          <Widget>[
                            _AddEmployeeTextField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.address',
                              ),
                              label: 'Address',
                              requiredField: true,
                              controller: _addressController,
                              hintText: 'Enter address',
                              minLines: 3,
                              maxLines: 3,
                              validator:
                                  EmployeeFormValidators.validateRequiredText,
                              textInputAction: TextInputAction.newline,
                            ),
                            _AddEmployeeW4Field(
                              controller: _linkW4Controller,
                              onSendEmail: _sendW4Email,
                            ),
                          ],
                          <Widget>[
                            _AddEmployeeDateField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.dateHire',
                              ),
                              label: 'Date Hire',
                              optional: true,
                              controller: _dateHireController,
                              onTap: _pickDateHire,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: _PayrollTokens.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 22),
                  child: Align(
                    alignment: stacked
                        ? Alignment.center
                        : Alignment.centerRight,
                    child: SizedBox(
                      width: stacked ? double.infinity : 120,
                      height: 48,
                      child: FilledButton(
                        key: const ValueKey<String>('payroll.addEmployee.done'),
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _PayrollTokens.tabSelected,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _PayrollTokens.controlRadius,
                            ),
                          ),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddEmployeeFieldRows extends StatelessWidget {
  final bool stacked;
  final List<List<Widget>> rows;

  const _AddEmployeeFieldRows({required this.stacked, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < rows.length; index += 1) ...<Widget>[
          if (stacked)
            for (
              int fieldIndex = 0;
              fieldIndex < rows[index].length;
              fieldIndex += 1
            ) ...<Widget>[
              rows[index][fieldIndex],
              if (fieldIndex < rows[index].length - 1)
                const SizedBox(height: 18),
            ]
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: rows[index].first),
                const SizedBox(width: 24),
                Expanded(
                  child: rows[index].length > 1
                      ? rows[index][1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          if (index < rows.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _AddEmployeeTextField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final bool requiredField;
  final bool optional;
  final TextEditingController controller;
  final String hintText;
  final String? prefixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;

  const _AddEmployeeTextField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.hintText,
    this.requiredField = false,
    this.optional = false,
    this.prefixText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return _AddEmployeeFieldFrame(
      label: label,
      requiredField: requiredField,
      optional: optional,
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        textInputAction: textInputAction,
        style: _PayrollTokens.inputText,
        decoration: _PayrollTokens.inputDecoration.copyWith(
          hintText: hintText,
          hintStyle: _PayrollTokens.inputHint,
          prefixText: prefixText == null ? null : '$prefixText  ',
          prefixStyle: _PayrollTokens.inputText,
        ),
      ),
    );
  }
}

class _AddEmployeeW4Field extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendEmail;

  const _AddEmployeeW4Field({
    required this.controller,
    required this.onSendEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AddEmployeeTextField(
          fieldKey: const ValueKey<String>('payroll.addEmployee.linkW4'),
          label: 'Link W4',
          optional: true,
          controller: controller,
          hintText: 'Enter link to W4 (optional)',
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey<String>('payroll.addEmployee.linkW4.sendEmail'),
          onPressed: onSendEmail,
          icon: const Icon(Icons.mail_outline, size: 18),
          label: const Text('Send Email'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _PayrollTokens.tabSelected,
            side: const BorderSide(color: _PayrollTokens.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddEmployeeDateField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final bool optional;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _AddEmployeeDateField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.onTap,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return _AddEmployeeFieldFrame(
      label: label,
      optional: optional,
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        readOnly: true,
        onTap: onTap,
        style: _PayrollTokens.inputText,
        decoration: _PayrollTokens.inputDecoration.copyWith(
          hintText: 'MM/DD/YYYY',
          hintStyle: _PayrollTokens.inputHint,
          suffixIcon: IconButton(
            tooltip: 'Choose $label',
            onPressed: onTap,
            icon: const Icon(Icons.calendar_month_outlined),
            color: _PayrollTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

class _W4EmailRecipientDialog extends StatefulWidget {
  const _W4EmailRecipientDialog();

  @override
  State<_W4EmailRecipientDialog> createState() =>
      _W4EmailRecipientDialogState();
}

class _W4EmailRecipientDialogState extends State<_W4EmailRecipientDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(context, _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _PayrollTokens.surface,
      title: const Text('Send W4 Email'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const ValueKey<String>('payroll.w4Email.recipient'),
          controller: _emailController,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: EmployeeFormValidators.validateEmailAddress,
          onFieldSubmitted: (_) => _confirm(),
          decoration: _PayrollTokens.inputDecoration.copyWith(
            labelText: 'Email address',
            hintText: 'name@example.com',
            hintStyle: _PayrollTokens.inputHint,
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('payroll.w4Email.cancel'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey<String>('payroll.w4Email.send'),
          onPressed: _confirm,
          style: FilledButton.styleFrom(
            backgroundColor: _PayrollTokens.tabSelected,
            foregroundColor: Colors.white,
          ),
          child: const Text('Send'),
        ),
      ],
    );
  }
}

class _AddEmployeeDropdownField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final bool optional;
  final String? value;
  final String hintText;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _AddEmployeeDropdownField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return _AddEmployeeFieldFrame(
      label: label,
      optional: optional,
      child: DropdownButtonFormField<String>(
        key: fieldKey,
        initialValue: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down),
        decoration: _PayrollTokens.inputDecoration,
        hint: Text(hintText, style: _PayrollTokens.inputHint),
        items: <DropdownMenuItem<String>>[
          for (final String item in items)
            DropdownMenuItem<String>(value: item, child: Text(item)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _AddEmployeeFieldFrame extends StatelessWidget {
  final String label;
  final bool requiredField;
  final bool optional;
  final Widget child;

  const _AddEmployeeFieldFrame({
    required this.label,
    required this.child,
    this.requiredField = false,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AddEmployeeLabel(
          label: label,
          requiredField: requiredField,
          optional: optional,
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AddEmployeeLabel extends StatelessWidget {
  final String label;
  final bool requiredField;
  final bool optional;

  const _AddEmployeeLabel({
    required this.label,
    required this.requiredField,
    required this.optional,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: _PayrollTokens.dialogFieldLabel,
        children: <InlineSpan>[
          TextSpan(text: label),
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          if (optional)
            TextSpan(
              text: ' (optional)',
              style: _PayrollTokens.dialogOptionalLabel,
            ),
        ],
      ),
    );
  }
}
