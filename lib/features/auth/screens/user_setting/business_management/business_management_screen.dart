import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/models/business_profile_validator.dart';
import 'package:savetep/providers/business_profile_provider.dart';

import '../widgets/user_setting_detail_scaffold.dart';

class BusinessManagementScreen extends ConsumerWidget {
  final bool isSetupFlow;

  const BusinessManagementScreen({super.key, this.isSetupFlow = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(businessProfileProvider);

    return UserSettingDetailScaffold(
      title: isSetupFlow ? 'Business Management Setup' : 'Business Management',
      icon: Icons.business_outlined,
      accentColor: const Color(0xFF38A9E8),
      showBackButton: !isSetupFlow,
      child: profile.when(
        data: (profile) => BusinessProfileForm(
          profile: profile,
          isSetupFlow: isSetupFlow,
          onSave: (updatedProfile) async {
            await ref
                .read(businessProfileProvider.notifier)
                .save(updatedProfile);
            if (!context.mounted) return;

            if (isSetupFlow) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Business information saved.')),
              );
            }
          },
        ),
        loading: () => const CircularProgressIndicator(),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load the business information: $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(businessProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BusinessProfileForm extends StatefulWidget {
  final BusinessProfile profile;
  final bool isSetupFlow;
  final Future<void> Function(BusinessProfile profile) onSave;

  const BusinessProfileForm({
    super.key,
    required this.profile,
    required this.isSetupFlow,
    required this.onSave,
  });

  @override
  State<BusinessProfileForm> createState() => _BusinessProfileFormState();
}

class _BusinessProfileFormState extends State<BusinessProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessNameController;
  late final TextEditingController _dbaController;
  late final TextEditingController _addressController;
  late final TextEditingController _einController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(
      text: widget.profile.businessName,
    );
    _dbaController = TextEditingController(text: widget.profile.dba);
    _addressController = TextEditingController(text: widget.profile.address);
    _einController = TextEditingController(text: widget.profile.ein);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _dbaController.dispose();
    _addressController.dispose();
    _einController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  BusinessProfile get _draft => widget.profile.copyWith(
    businessName: _businessNameController.text,
    dba: _dbaController.text,
    address: _addressController.text,
    ein: _einController.text,
    email: _emailController.text,
    phone: _phoneController.text,
    setupCompleted: false,
  );

  void _fieldChanged(String _) {
    setState(() => _saveError = null);
  }

  Future<void> _save() async {
    if (_saving) return;
    final profile = _draft.normalized();
    if (!BusinessProfileValidator.validate(profile).isValid) {
      _formKey.currentState?.validate();
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(profile);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saveError = 'Could not save business information: $error';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _errorFor(BusinessProfileField field) {
    return BusinessProfileValidator.validate(_draft).errorFor(field);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = BusinessProfileValidator.validate(_draft).isValid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isSetupFlow
                        ? 'Set up your business'
                        : 'Business information',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isSetupFlow
                        ? 'Complete all fields before continuing to Home.'
                        : 'Edit the business information used by your account.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('businessManagement.businessName'),
                    controller: _businessNameController,
                    enabled: !_saving,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Business Name *',
                    ),
                    validator: (_) =>
                        _errorFor(BusinessProfileField.businessName),
                    onChanged: _fieldChanged,
                  ),
                  TextFormField(
                    key: const ValueKey('businessManagement.dba'),
                    controller: _dbaController,
                    enabled: !_saving,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'DBA *'),
                    validator: (_) => _errorFor(BusinessProfileField.dba),
                    onChanged: _fieldChanged,
                  ),
                  TextFormField(
                    key: const ValueKey('businessManagement.address'),
                    controller: _addressController,
                    enabled: !_saving,
                    maxLength: 240,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(labelText: 'Address *'),
                    validator: (_) => _errorFor(BusinessProfileField.address),
                    onChanged: _fieldChanged,
                  ),
                  TextFormField(
                    key: const ValueKey('businessManagement.ein'),
                    controller: _einController,
                    enabled: !_saving,
                    maxLength: 20,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'EIN *'),
                    validator: (_) => _errorFor(BusinessProfileField.ein),
                    onChanged: _fieldChanged,
                  ),
                  TextFormField(
                    key: const ValueKey('businessManagement.email'),
                    controller: _emailController,
                    enabled: !_saving,
                    maxLength: 254,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    validator: (_) => _errorFor(BusinessProfileField.email),
                    onChanged: _fieldChanged,
                  ),
                  TextFormField(
                    key: const ValueKey('businessManagement.phone'),
                    controller: _phoneController,
                    enabled: !_saving,
                    maxLength: 30,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(labelText: 'Phone *'),
                    validator: (_) => _errorFor(BusinessProfileField.phone),
                    onChanged: _fieldChanged,
                    onFieldSubmitted: (_) {
                      if (canSave && !_saving) _save();
                    },
                  ),
                  if (_saveError case final error?) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
                      key: const ValueKey('businessManagement.saveError'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('businessManagement.saveButton'),
                    onPressed: _saving || !canSave ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isSetupFlow ? 'Continue' : 'Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
