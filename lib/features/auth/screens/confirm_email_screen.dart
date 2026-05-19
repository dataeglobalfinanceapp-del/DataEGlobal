Future<void> confirmSignUp(String email, String code) async {
  try {
    final result = await Amplify.Auth.confirmSignUp(
      username: email,
      confirmationCode: code,
    );
    if (result.isSignUpComplete) {
      // navigate to LoginScreen
    }
  } on AuthException catch (e) {
    safePrint('Confirm error: ${e.message}');
  }
}

// Resend code if user didn't get it:
Future<void> resendCode(String email) async {
  await Amplify.Auth.resendSignUpCode(username: email);
}