import 'package:savetep/features/auth/services/auth_service.dart';

import '../models/auth_models.dart';

abstract interface class AuthRepository {
  Future<bool> isSignedIn();

  Future<bool> signIn(String usernameOrEmail, String password);

  Future<bool> confirmSignIn(String challengeResponse);

  Future<AuthSignUpAttempt> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  Future<bool> confirmSignUp(String email, String code);

  Future<AuthCodeDeliveryInfo?> resendSignUpCode(String email);

  Future<void> sendResetCode(String email);

  Future<void> confirmReset({
    required String email,
    required String code,
    required String newPassword,
  });
}

class ServiceAuthRepository implements AuthRepository {
  const ServiceAuthRepository();

  @override
  Future<bool> isSignedIn() => AuthService.isSignedIn();

  @override
  Future<bool> signIn(String usernameOrEmail, String password) {
    return AuthService.signIn(usernameOrEmail, password);
  }

  @override
  Future<bool> confirmSignIn(String challengeResponse) {
    return AuthService.confirmSignIn(challengeResponse);
  }

  @override
  Future<AuthSignUpAttempt> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return AuthService.signUp(
      email: email,
      password: password,
      fullName: fullName,
    ).then(
      (attempt) => AuthSignUpAttempt(
        needsConfirmation: attempt.needsConfirmation,
        codeDelivery: _mapDelivery(attempt.codeDelivery),
      ),
    );
  }

  @override
  Future<bool> confirmSignUp(String email, String code) {
    return AuthService.confirmSignUp(email, code);
  }

  @override
  Future<AuthCodeDeliveryInfo?> resendSignUpCode(String email) async {
    final delivery = await AuthService.resendSignUpCode(email);
    return _mapDelivery(delivery);
  }

  @override
  Future<void> sendResetCode(String email) {
    return AuthService.sendResetCode(email);
  }

  @override
  Future<void> confirmReset({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return AuthService.confirmReset(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  static AuthCodeDeliveryInfo? _mapDelivery(CodeDeliveryInfo? delivery) {
    if (delivery == null) return null;
    return AuthCodeDeliveryInfo(
      destination: delivery.destination,
      deliveryMedium: delivery.deliveryMedium,
    );
  }
}
