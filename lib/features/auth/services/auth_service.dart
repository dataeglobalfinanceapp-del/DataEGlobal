import 'package:amplify_flutter/amplify_flutter.dart';

class AuthService {

  // ─────────────────────────────────────────────────────────────────────────────
  // SESSION RESTORE
  // Amplify stores tokens securely:
  //   iOS     → Keychain
  //   Android → EncryptedSharedPreferences
  // Tokens refresh automatically while the refresh token is valid.
  // You never manage tokens yourself.
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } on AuthException catch (e) {
      safePrint('Session check error: ${e.message}');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SIGN UP — Step 1: create account
  // Returns true when a confirmation code was sent (expected happy path).
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<bool> signUp(String email, String password) async {
    try {
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
          },
        ),
      );
      return result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp;
    } on AuthException catch (e) {
      safePrint('Sign up error: ${e.message}');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SIGN UP — Step 2: confirm email with code
  // Returns true when sign-up is complete.
  // ─────────────────────────────────────────────────────────────────────────────

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
  static Future<void> resendSignUpCode(String email) async {
    try {
      await Amplify.Auth.resendSignUpCode(username: email);
    } on AuthException catch (e) {
      safePrint('Resend code error: ${e.message}');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SIGN IN
  // Returns true when the user is fully signed in.
  // ─────────────────────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────────────────────
  // FORGOT PASSWORD — Step 1: request reset code
  // ─────────────────────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────────────────────
  // FORGOT PASSWORD — Step 2: confirm code + new password
  // ─────────────────────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────────────────────────────────────

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