import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_models.dart';

enum SignUpNextStep { confirmEmail, businessNameOnboarding }

class SignUpFlowResult {
  final SignUpNextStep nextStep;
  final String email;
  final String fullName;
  final AuthCodeDeliveryInfo? codeDelivery;
  final String? profileWarning;

  const SignUpFlowResult({
    required this.nextStep,
    required this.email,
    required this.fullName,
    required this.codeDelivery,
    required this.profileWarning,
  });
}
