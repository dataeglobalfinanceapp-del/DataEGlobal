import 'package:savetep/features/auth/services/account_profile_service.dart';

abstract interface class PendingAccountProfileRepository {
  Future<void> stageNewAccount({
    required String email,
    required String fullName,
  });

  Future<void> completeOnboarding({
    required String email,
    required String fullName,
    String? businessName,
  });
}

class ServicePendingAccountProfileRepository
    implements PendingAccountProfileRepository {
  const ServicePendingAccountProfileRepository();

  @override
  Future<void> stageNewAccount({
    required String email,
    required String fullName,
  }) {
    return AccountProfileService.stageNewAccount(
      email: email,
      fullName: fullName,
    );
  }

  @override
  Future<void> completeOnboarding({
    required String email,
    required String fullName,
    String? businessName,
  }) {
    return AccountProfileService.completePendingOnboarding(
      email: email,
      fullName: fullName,
      businessName: businessName,
    );
  }
}
