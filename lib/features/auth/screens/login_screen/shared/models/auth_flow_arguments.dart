import 'auth_models.dart';
import 'package:savetep/features/auth/models/business_profile.dart';

class ConfirmSignUpArguments {
  final String email;
  final String fullName;
  final AuthCodeDeliveryInfo? codeDelivery;

  const ConfirmSignUpArguments({
    required this.email,
    required this.fullName,
    this.codeDelivery,
  });
}

class BusinessNameOnboardingArguments {
  final String email;
  final String fullName;

  const BusinessNameOnboardingArguments({
    required this.email,
    required this.fullName,
  });
}

class BusinessCategoryOnboardingArguments {
  final BusinessProfile businessProfile;
  final Set<String>? initialSelectedCategoryIds;

  const BusinessCategoryOnboardingArguments({
    required this.businessProfile,
    this.initialSelectedCategoryIds,
  });
}
