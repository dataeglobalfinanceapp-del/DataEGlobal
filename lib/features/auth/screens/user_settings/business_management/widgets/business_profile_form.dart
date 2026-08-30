import 'package:flutter/material.dart';

import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/models/business_profile_validator.dart';

import '../business_profile_form_controller.dart';

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
  late final BusinessProfileFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BusinessProfileFormController(widget.profile);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final result = await _controller.submit(widget.onSave);
    if (result == BusinessProfileSubmission.invalid) {
      _formKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final canSave = _controller.validation.isValid;

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
                        controller: _controller.businessNameController,
                        enabled: !_controller.isSaving,
                        maxLength: 120,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Business Name *',
                        ),
                        validator: (_) => _controller.errorFor(
                          BusinessProfileField.businessName,
                        ),
                      ),
                      TextFormField(
                        key: const ValueKey('businessManagement.dba'),
                        controller: _controller.dbaController,
                        enabled: !_controller.isSaving,
                        maxLength: 120,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'DBA *'),
                        validator: (_) =>
                            _controller.errorFor(BusinessProfileField.dba),
                      ),
                      TextFormField(
                        key: const ValueKey('businessManagement.address'),
                        controller: _controller.addressController,
                        enabled: !_controller.isSaving,
                        maxLength: 240,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                        ),
                        validator: (_) =>
                            _controller.errorFor(BusinessProfileField.address),
                      ),
                      TextFormField(
                        key: const ValueKey('businessManagement.ein'),
                        controller: _controller.einController,
                        enabled: !_controller.isSaving,
                        maxLength: 20,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'EIN *'),
                        validator: (_) =>
                            _controller.errorFor(BusinessProfileField.ein),
                      ),
                      TextFormField(
                        key: const ValueKey('businessManagement.email'),
                        controller: _controller.emailController,
                        enabled: !_controller.isSaving,
                        maxLength: 254,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: 'Email *'),
                        validator: (_) =>
                            _controller.errorFor(BusinessProfileField.email),
                      ),
                      TextFormField(
                        key: const ValueKey('businessManagement.phone'),
                        controller: _controller.phoneController,
                        enabled: !_controller.isSaving,
                        maxLength: 30,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(labelText: 'Phone *'),
                        validator: (_) =>
                            _controller.errorFor(BusinessProfileField.phone),
                        onFieldSubmitted: (_) {
                          if (canSave && !_controller.isSaving) _save();
                        },
                      ),
                      if (_controller.saveError case final error?) ...[
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
                        onPressed: _controller.isSaving || !canSave
                            ? null
                            : _save,
                        child: _controller.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
      },
    );
  }
}
