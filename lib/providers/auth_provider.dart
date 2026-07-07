import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/features/auth/services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

final authStateProvider = AsyncNotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthStatus> {
  @override
  Future<AuthStatus> build() async {
    return _fetchAuthStatus();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue<AuthStatus>.loading();
    state = await AsyncValue.guard(() async {
      final isSignedIn = await AuthService.signIn(email, password);
      return isSignedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue<AuthStatus>.loading();
    state = await AsyncValue.guard(() async {
      await AuthService.signOut();
      return AuthStatus.unauthenticated;
    });
  }

  Future<void> confirmSignUp(String email, String code) async {
    state = const AsyncValue<AuthStatus>.loading();
    state = await AsyncValue.guard(() async {
      final isComplete = await AuthService.confirmSignUp(email, code);
      if (!isComplete) return AuthStatus.unauthenticated;

      return _fetchAuthStatus();
    });
  }

  Future<AuthStatus> _fetchAuthStatus() async {
    final session = await AuthService.fetchAuthSession();
    return session.isSignedIn
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
  }
}
