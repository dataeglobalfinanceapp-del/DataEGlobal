enum AuthSignInChallengeType {
  verificationCode,
  newPassword,
  mfaSelection,
  emailAddress,
  customChallenge,
  actionRequired,
}

class AuthSignInChallengeRequired implements Exception {
  final AuthSignInChallengeType type;
  final String stepName;
  final String prompt;
  final String inputLabel;
  final bool obscureInput;
  final bool canRespond;

  const AuthSignInChallengeRequired({
    required this.type,
    required this.stepName,
    required this.prompt,
    required this.inputLabel,
    required this.obscureInput,
    required this.canRespond,
  });

  factory AuthSignInChallengeRequired.fromStep(
    String stepName, {
    String? destination,
  }) {
    final String destinationText = destination == null
        ? ''
        : ' sent to $destination';
    return switch (stepName) {
      'confirmSignInWithSmsMfaCode' ||
      'confirmSignInWithTotpMfaCode' ||
      'confirmSignInWithOtpCode' => AuthSignInChallengeRequired(
        type: AuthSignInChallengeType.verificationCode,
        stepName: stepName,
        prompt: 'Enter the verification code$destinationText.',
        inputLabel: 'VERIFICATION CODE',
        obscureInput: false,
        canRespond: true,
      ),
      'confirmSignInWithNewPassword' => AuthSignInChallengeRequired(
        type: AuthSignInChallengeType.newPassword,
        stepName: stepName,
        prompt: 'Choose a new password to complete sign-in.',
        inputLabel: 'NEW PASSWORD',
        obscureInput: true,
        canRespond: true,
      ),
      'continueSignInWithMfaSelection' ||
      'continueSignInWithMfaSetupSelection' => AuthSignInChallengeRequired(
        type: AuthSignInChallengeType.mfaSelection,
        stepName: stepName,
        prompt: 'Enter the available MFA method: SMS, TOTP, or EMAIL.',
        inputLabel: 'MFA METHOD',
        obscureInput: false,
        canRespond: true,
      ),
      'continueSignInWithEmailMfaSetup' => AuthSignInChallengeRequired(
        type: AuthSignInChallengeType.emailAddress,
        stepName: stepName,
        prompt: 'Enter the email address to use for MFA.',
        inputLabel: 'MFA EMAIL',
        obscureInput: false,
        canRespond: true,
      ),
      'confirmSignInWithCustomChallenge' => AuthSignInChallengeRequired(
        type: AuthSignInChallengeType.customChallenge,
        stepName: stepName,
        prompt: 'Enter the requested sign-in challenge response.',
        inputLabel: 'CHALLENGE RESPONSE',
        obscureInput: false,
        canRespond: true,
      ),
      'continueSignInWithTotpSetup' => AuthSignInChallengeRequired(
        type: AuthSignInChallengeType.actionRequired,
        stepName: stepName,
        prompt:
            'Authenticator setup is required before sign-in can continue. '
            'Use an account with TOTP already configured or contact support.',
        inputLabel: 'AUTHENTICATOR SETUP',
        obscureInput: false,
        canRespond: false,
      ),
      'resetPassword' => AuthSignInChallengeRequired(
        type: AuthSignInChallengeType.actionRequired,
        stepName: stepName,
        prompt: 'Reset the account password, then start sign-in again.',
        inputLabel: 'PASSWORD RESET REQUIRED',
        obscureInput: false,
        canRespond: false,
      ),
      'confirmSignUp' => AuthSignInChallengeRequired(
        type: AuthSignInChallengeType.actionRequired,
        stepName: stepName,
        prompt: 'Confirm the account registration, then start sign-in again.',
        inputLabel: 'ACCOUNT CONFIRMATION REQUIRED',
        obscureInput: false,
        canRespond: false,
      ),
      _ => AuthSignInChallengeRequired(
        type: AuthSignInChallengeType.actionRequired,
        stepName: stepName,
        prompt:
            'This account requires an unsupported sign-in step. '
            'Update the app or contact support.',
        inputLabel: 'ADDITIONAL SIGN-IN REQUIRED',
        obscureInput: false,
        canRespond: false,
      ),
    };
  }

  @override
  String toString() => prompt;
}
