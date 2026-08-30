import 'package:flutter/material.dart';

import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/models/business_profile_validator.dart';

enum BusinessProfileSubmission { saved, invalid, failed, ignored }

class BusinessProfileFormController extends ChangeNotifier {
  final BusinessProfile _initialProfile;

  late final TextEditingController businessNameController;
  late final TextEditingController dbaController;
  late final TextEditingController addressController;
  late final TextEditingController einController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  bool _isSaving = false;
  String? _saveError;

  BusinessProfileFormController(BusinessProfile profile)
    : _initialProfile = profile {
    businessNameController = TextEditingController(text: profile.businessName);
    dbaController = TextEditingController(text: profile.dba);
    addressController = TextEditingController(text: profile.address);
    einController = TextEditingController(text: profile.ein);
    emailController = TextEditingController(text: profile.email);
    phoneController = TextEditingController(text: profile.phone);

    for (final controller in _fieldControllers) {
      controller.addListener(_handleFieldChanged);
    }
  }

  List<TextEditingController> get _fieldControllers => [
    businessNameController,
    dbaController,
    addressController,
    einController,
    emailController,
    phoneController,
  ];

  bool get isSaving => _isSaving;
  String? get saveError => _saveError;

  BusinessProfile get draft => _initialProfile.copyWith(
    businessName: businessNameController.text,
    dba: dbaController.text,
    address: addressController.text,
    ein: einController.text,
    email: emailController.text,
    phone: phoneController.text,
    setupCompleted: false,
  );

  BusinessProfileValidation get validation {
    return BusinessProfileValidator.validate(draft);
  }

  String? errorFor(BusinessProfileField field) => validation.errorFor(field);

  Future<BusinessProfileSubmission> submit(
    Future<void> Function(BusinessProfile profile) onSave,
  ) async {
    if (_isSaving) return BusinessProfileSubmission.ignored;

    final profile = draft.normalized();
    if (!BusinessProfileValidator.validate(profile).isValid) {
      return BusinessProfileSubmission.invalid;
    }

    _isSaving = true;
    _saveError = null;
    notifyListeners();

    try {
      await onSave(profile);
      return BusinessProfileSubmission.saved;
    } on Object catch (error) {
      _saveError = 'Could not save business information: $error';
      return BusinessProfileSubmission.failed;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _handleFieldChanged() {
    _saveError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _fieldControllers) {
      controller
        ..removeListener(_handleFieldChanged)
        ..dispose();
    }
    super.dispose();
  }
}
