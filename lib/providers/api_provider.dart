import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/core/api/access_token_provider.dart';
import 'package:savetep/core/api/aws_api_client.dart';
import 'package:savetep/core/config/app_environment.dart';
import 'package:savetep/features/auth/data/remote/aws_user_business_api_client.dart';
import 'package:savetep/features/auth/data/remote/business_api_models.dart';
import 'package:savetep/features/auth/data/remote/user_api_models.dart';
import 'package:savetep/features/auth/data/remote/user_business_api_client.dart';
import 'package:savetep/features/auth/data/remote/user_business_remote_repositories.dart';
import 'package:savetep/features/auth/services/auth_service.dart';
import 'package:savetep/features/auth/services/pending_terms_acceptance_service.dart';
import 'package:savetep/providers/account_profile_provider.dart';
import 'package:savetep/providers/business_profile_provider.dart';
import 'package:savetep/providers/expense_category_provider.dart';

final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => AppEnvironment.fromCompileTime(),
);

final accessTokenProvider = Provider<AccessTokenProvider>(
  (ref) => const AmplifyCognitoAccessTokenProvider(),
);

final awsApiClientProvider = Provider<AwsApiClient>((ref) {
  final AppEnvironment environment = ref.watch(appEnvironmentProvider);
  final AwsApiClient client = AwsApiClient(
    baseUrl: environment.requiredApiBaseUrl,
    accessTokenProvider: ref.watch(accessTokenProvider),
    logSink: kDebugMode ? _debugApiLog : null,
    onAuthenticationFailure: () async {
      await AuthService.signOut();
      ref.invalidate(remoteUserBusinessContextProvider);
      ref.invalidate(businessSetupStatusProvider);
      ref.invalidate(accountProfileProvider);
      ref.invalidate(businessProfileProvider);
      ref.invalidate(activeExpenseCategoriesProvider);
    },
  );
  ref.onDispose(client.close);
  return client;
});

final userBusinessApiClientProvider = Provider<UserBusinessApiClient>((ref) {
  return AwsUserBusinessApiClient(ref.watch(awsApiClientProvider));
});

final remoteMeRepositoryProvider = Provider<RemoteMeRepository>((ref) {
  return ApiMeRepository(ref.watch(userBusinessApiClientProvider));
});

final remoteBusinessRepositoryProvider = Provider<RemoteBusinessRepository>((
  ref,
) {
  return ApiBusinessRepository(ref.watch(userBusinessApiClientProvider));
});

final remoteActiveBusinessRepositoryProvider =
    Provider<RemoteActiveBusinessRepository>((ref) {
      return ApiActiveBusinessRepository(
        ref.watch(userBusinessApiClientProvider),
      );
    });

final pendingTermsAcceptanceRepositoryProvider =
    Provider<PendingTermsAcceptanceRepository>(
      (ref) => const PendingTermsAcceptanceService(),
    );

class RemoteUserBusinessContext {
  final MeResponseDto me;
  final BusinessResponseDto? activeBusiness;
  final List<BusinessResponseDto> availableBusinesses;

  RemoteUserBusinessContext({
    required this.me,
    required this.activeBusiness,
    required Iterable<BusinessResponseDto> availableBusinesses,
  }) : availableBusinesses = List<BusinessResponseDto>.unmodifiable(
         availableBusinesses,
       );

  String? get activeBusinessId => activeBusiness?.id;
}

final remoteUserBusinessContextProvider =
    AsyncNotifierProvider<
      RemoteUserBusinessContextController,
      RemoteUserBusinessContext?
    >(RemoteUserBusinessContextController.new);

class RemoteUserBusinessContextController
    extends AsyncNotifier<RemoteUserBusinessContext?> {
  @override
  Future<RemoteUserBusinessContext?> build() async {
    final AppEnvironment environment = ref.watch(appEnvironmentProvider);
    if (environment.authEnvironment == AuthEnvironment.legacy) return null;
    return _load();
  }

  Future<RemoteUserBusinessContext> refresh() async {
    state = const AsyncValue<RemoteUserBusinessContext?>.loading();
    try {
      final RemoteUserBusinessContext context = await _load();
      state = AsyncValue<RemoteUserBusinessContext?>.data(context);
      return context;
    } on Object catch (error, stackTrace) {
      state = AsyncValue<RemoteUserBusinessContext?>.error(error, stackTrace);
      rethrow;
    }
  }

  Future<RemoteUserBusinessContext> setActiveBusiness(String businessId) async {
    final RemoteUserBusinessContext? previous = state.value;
    state = const AsyncValue<RemoteUserBusinessContext?>.loading();
    try {
      final ActiveBusinessResponseDto response = await ref
          .read(remoteActiveBusinessRepositoryProvider)
          .setActiveBusiness(businessId);
      final RemoteUserBusinessContext current = previous ?? await _load();
      final RemoteUserBusinessContext updated = RemoteUserBusinessContext(
        me: current.me,
        activeBusiness: response.business,
        availableBusinesses: current.availableBusinesses,
      );
      state = AsyncValue<RemoteUserBusinessContext?>.data(updated);
      return updated;
    } on Object catch (error, stackTrace) {
      state = AsyncValue<RemoteUserBusinessContext?>.error(error, stackTrace);
      rethrow;
    }
  }

  Future<RemoteUserBusinessContext> updateMe(UpdateMeDto update) async {
    final RemoteUserBusinessContext current = await _currentOrLoad();
    final MeResponseDto me = await ref
        .read(remoteMeRepositoryProvider)
        .updateMe(update);
    final RemoteUserBusinessContext updated = RemoteUserBusinessContext(
      me: me,
      activeBusiness: current.activeBusiness,
      availableBusinesses: current.availableBusinesses,
    );
    state = AsyncValue<RemoteUserBusinessContext?>.data(updated);
    return updated;
  }

  Future<RemoteUserBusinessContext> createAndActivateBusiness(
    CreateBusinessDto business,
  ) async {
    final RemoteUserBusinessContext current = await _currentOrLoad();
    final BusinessResponseDto created = await ref
        .read(remoteBusinessRepositoryProvider)
        .createBusiness(business);
    final ActiveBusinessResponseDto active = await ref
        .read(remoteActiveBusinessRepositoryProvider)
        .setActiveBusiness(created.id);
    final RemoteUserBusinessContext updated = RemoteUserBusinessContext(
      me: current.me,
      activeBusiness: active.business ?? created,
      availableBusinesses: <BusinessResponseDto>[
        ...current.availableBusinesses.where(
          (BusinessResponseDto item) => item.id != created.id,
        ),
        created,
      ],
    );
    state = AsyncValue<RemoteUserBusinessContext?>.data(updated);
    return updated;
  }

  Future<RemoteUserBusinessContext> updateActiveBusiness(
    UpdateBusinessDto update,
  ) async {
    final RemoteUserBusinessContext current = await _currentOrLoad();
    final BusinessResponseDto? active = current.activeBusiness;
    if (active == null) {
      throw StateError('No active business is available to update.');
    }
    final BusinessResponseDto updatedBusiness = await ref
        .read(remoteBusinessRepositoryProvider)
        .updateBusiness(active.id, update);
    final RemoteUserBusinessContext updated = RemoteUserBusinessContext(
      me: current.me,
      activeBusiness: updatedBusiness,
      availableBusinesses: current.availableBusinesses
          .map(
            (BusinessResponseDto item) =>
                item.id == updatedBusiness.id ? updatedBusiness : item,
          )
          .toList(growable: false),
    );
    state = AsyncValue<RemoteUserBusinessContext?>.data(updated);
    return updated;
  }

  Future<RemoteUserBusinessContext> _currentOrLoad() async {
    final RemoteUserBusinessContext? current = state.value;
    return current ?? _load();
  }

  Future<RemoteUserBusinessContext> _load() async {
    final RemoteMeRepository meRepository = ref.read(
      remoteMeRepositoryProvider,
    );
    final RemoteActiveBusinessRepository activeRepository = ref.read(
      remoteActiveBusinessRepositoryProvider,
    );
    final PendingTermsAcceptanceRepository termsRepository = ref.read(
      pendingTermsAcceptanceRepositoryProvider,
    );
    final String? pendingTermsVersion = await termsRepository
        .loadForCurrentUser();
    final MeResponseDto me = await meRepository.fetchMe(
      acceptedTermsVersion: pendingTermsVersion,
    );
    if (pendingTermsVersion != null) {
      await termsRepository.markSubmittedForCurrentUser();
    }
    ActiveBusinessResponseDto active = await activeRepository
        .getActiveBusiness();
    List<BusinessResponseDto> businesses = active.business == null
        ? await ref.read(remoteBusinessRepositoryProvider).listBusinesses()
        : <BusinessResponseDto>[active.business!];

    if (active.business == null && businesses.length == 1) {
      active = await activeRepository.setActiveBusiness(businesses.single.id);
    }

    return RemoteUserBusinessContext(
      me: me,
      activeBusiness: active.business,
      availableBusinesses: businesses,
    );
  }
}

final businessSetupStatusProvider = FutureProvider<bool>((ref) async {
  final AppEnvironment environment = ref.watch(appEnvironmentProvider);
  if (environment.authEnvironment == AuthEnvironment.legacy) {
    final profile = await ref.watch(businessProfileProvider.future);
    return profile.setupCompleted;
  }

  final RemoteUserBusinessContext? context = await ref.watch(
    remoteUserBusinessContextProvider.future,
  );
  return context?.activeBusiness != null;
});

void _debugApiLog(ApiLogEntry entry) {
  final String status = entry.statusCode?.toString() ?? 'transport-error';
  final String requestId = entry.requestId == null
      ? ''
      : ' requestId=${entry.requestId}';
  debugPrint(
    'API ${entry.method.wireValue} ${entry.path} $status '
    '${entry.duration.inMilliseconds}ms$requestId',
  );
}
