import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/features/auth/services/auth_service.dart';
import 'package:savetep/providers/account_profile_provider.dart';
import 'package:savetep/providers/api_provider.dart';
import 'package:savetep/providers/business_profile_provider.dart';
import 'package:savetep/providers/expense_category_provider.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

final authStateProvider = AsyncNotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthStatus> {
  @override
  Future<AuthStatus> build() async {
    return _fetchAuthStatus();
  }

  Future<void> signIn(String usernameOrEmail, String password) async {
    state = const AsyncValue<AuthStatus>.loading();
    state = await AsyncValue.guard(() async {
      final isSignedIn = await AuthService.signIn(usernameOrEmail, password);
      return isSignedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue<AuthStatus>.loading();
    state = await AsyncValue.guard(() async {
      await AuthService.signOut();
      ref.invalidate(remoteUserBusinessContextProvider);
      ref.invalidate(businessSetupStatusProvider);
      ref.invalidate(awsApiClientProvider);
      ref.invalidate(accountProfileProvider);
      ref.invalidate(businessProfileProvider);
      ref.invalidate(activeExpenseCategoriesProvider);
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
