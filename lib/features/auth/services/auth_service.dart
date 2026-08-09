import 'package:amplify_flutter/amplify_flutter.dart';

class AuthService {
  // ─────────────────────────────────────────────────────────────────────────
  // SESSION RESTORE
  // Amplify stores tokens securely:
  //   iOS     → Keychain
  //   Android → EncryptedSharedPreferences
  // Tokens refresh automatically while the refresh token is valid.
  // ─────────────────────────────────────────────────────────────────────────

  static Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } on AuthException catch (e) {
      safePrint('Session check error: ${e.message}');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN UP — Step 1: create account
  // Returns true when a confirmation code was sent (expected happy path).
  // ─────────────────────────────────────────────────────────────────────────

  static Future<AuthSession> fetchAuthSession() {
    return Amplify.Auth.fetchAuthSession();
  }

  static Future<SignUpAttempt> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
            AuthUserAttributeKey.name: fullName,
          },
        ),
      );
      final delivery = CodeDeliveryInfo.fromAuth(
        result.nextStep.codeDeliveryDetails,
      );
      if (delivery != null) {
        safePrint('Sign up code delivery: ${delivery.message}');
      } else {
        safePrint('Sign up next step: ${result.nextStep.signUpStep}');
      }
      return SignUpAttempt(
        needsConfirmation:
            result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp,
        codeDelivery: delivery,
      );
    } on AuthException catch (e) {
      safePrint('Sign up error: ${e.message}');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN UP — Step 2: confirm email with code
  // Returns true when sign-up is complete.
  // ─────────────────────────────────────────────────────────────────────────

  static Future<bool> confirmSignUp(String email, String code) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: code,
      );
      return result.isSignUpComplete;
    } on AuthException catch (e) {
      safePrint('Confirm sign up error: ${e.message}');
      rethrow;
    }
  }

  // Resend code if the user didn't receive it
  static Future<CodeDeliveryInfo?> resendSignUpCode(String email) async {
    try {
      final result = await Amplify.Auth.resendSignUpCode(username: email);
      final delivery = CodeDeliveryInfo.fromAuth(result.codeDeliveryDetails);
      if (delivery != null) {
        safePrint('Resent sign up code delivery: ${delivery.message}');
      }
      return delivery;
    } on AuthException catch (e) {
      safePrint('Resend code error: ${e.message}');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN IN
  // Returns true when the user is fully signed in.
  // ─────────────────────────────────────────────────────────────────────────

  static Future<bool> signIn(String email, String password) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      return result.isSignedIn;
    } on AuthException catch (e) {
      safePrint('Sign in error: ${e.message}');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FORGOT PASSWORD — Step 1: request reset code
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> sendResetCode(String email) async {
    try {
      final result = await Amplify.Auth.resetPassword(username: email);
      if (result.nextStep.updateStep !=
          AuthResetPasswordStep.confirmResetPasswordWithCode) {
        safePrint('Unexpected reset step: ${result.nextStep.updateStep}');
      }
    } on AuthException catch (e) {
      safePrint('Reset error: ${e.message}');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FORGOT PASSWORD — Step 2: confirm code + new password
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> confirmReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: code,
      );
    } on AuthException catch (e) {
      safePrint('Confirm reset error: ${e.message}');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────────────────────────────────

  /// Signs out on this device only.
  static Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  /// Signs out on ALL devices (invalidates tokens server-side).
  static Future<void> globalSignOut() async {
    await Amplify.Auth.signOut(
      options: const SignOutOptions(globalSignOut: true),
    );
  }
}

class SignUpAttempt {
  final bool needsConfirmation;
  final CodeDeliveryInfo? codeDelivery;

  const SignUpAttempt({
    required this.needsConfirmation,
    required this.codeDelivery,
  });
}

class CodeDeliveryInfo {
  final String destination;
  final String deliveryMedium;

  const CodeDeliveryInfo({
    required this.destination,
    required this.deliveryMedium,
  });

  String get message =>
      'Code sent to $destination by ${deliveryMedium.toLowerCase()}';

  static CodeDeliveryInfo? fromAuth(AuthCodeDeliveryDetails? details) {
    if (details == null) return null;
    return CodeDeliveryInfo(
      destination: details.destination ?? 'your registered destination',
      deliveryMedium: details.deliveryMedium.name,
    );
  }
}
