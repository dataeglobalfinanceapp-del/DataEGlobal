Future<void> signIn(String email, String password) async {
  try {
    final result = await Amplify.Auth.signIn(
      username: email,
      password: password,
    );
    if (result.isSignedIn) {
      // navigate to home
    }
  } on AuthException catch (e) {
    safePrint('Sign in error: ${e.message}');
  }
}

Future<void> signOut() async {
  await Amplify.Auth.signOut();
}