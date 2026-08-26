import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/screens/login_screen/shared/validators/auth_form_validators.dart';

enum BusinessProfileField { businessName, dba, address, ein, email, phone }

class BusinessProfileValidation {
  final Map<BusinessProfileField, String> errors;

  const BusinessProfileValidation(this.errors);

  bool get isValid => errors.isEmpty;

  String? errorFor(BusinessProfileField field) => errors[field];
}

class BusinessProfileValidator {
  const BusinessProfileValidator._();

  static final RegExp _phoneCharacters = RegExp(r'^\+?[0-9() .\-]+$');

  static BusinessProfileValidation validate(BusinessProfile profile) {
    final errors = <BusinessProfileField, String>{};

    void require(BusinessProfileField field, String value, String label) {
      if (value.trim().isEmpty) errors[field] = '$label is required';
    }

    require(
      BusinessProfileField.businessName,
      profile.businessName,
      'Business Name',
    );
    require(BusinessProfileField.dba, profile.dba, 'DBA');
    require(BusinessProfileField.address, profile.address, 'Address');
    require(BusinessProfileField.ein, profile.ein, 'EIN');

    final email = profile.email.trim();
    if (email.isEmpty) {
      errors[BusinessProfileField.email] = 'Email is required';
    } else if (!AuthFormValidators.isValidEmail(email)) {
      errors[BusinessProfileField.email] = 'Enter a valid email address';
    }

    final phone = profile.phone.trim();
    final digitCount = phone.replaceAll(RegExp(r'\D'), '').length;
    if (phone.isEmpty) {
      errors[BusinessProfileField.phone] = 'Phone is required';
    } else if (!_phoneCharacters.hasMatch(phone) ||
        digitCount < 7 ||
        digitCount > 15) {
      errors[BusinessProfileField.phone] = 'Enter a valid phone number';
    }

    return BusinessProfileValidation(errors);
  }
}
