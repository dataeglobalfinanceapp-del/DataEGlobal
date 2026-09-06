import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetep/core/config/app_environment.dart';
import 'package:savetep/features/auth/data/remote/business_api_models.dart';
import 'package:savetep/features/auth/data/remote/user_api_models.dart';
import 'package:savetep/features/auth/data/remote/user_business_remote_repositories.dart';
import 'package:savetep/features/auth/services/pending_terms_acceptance_service.dart';
import 'package:savetep/providers/api_provider.dart';

void main() {
  group('remoteUserBusinessContextProvider', () {
    test('loads /me and an existing active business', () async {
      final meRepository = _FakeMeRepository();
      final activeRepository = _FakeActiveBusinessRepository(
        initialBusiness: _business(),
      );
      final businessRepository = _FakeBusinessRepository(const []);
      final container = _container(
        meRepository: meRepository,
        activeRepository: activeRepository,
        businessRepository: businessRepository,
      );
      addTearDown(container.dispose);

      final context = await container.read(
        remoteUserBusinessContextProvider.future,
      );

      expect(context?.me.id, 'user-1');
      expect(context?.activeBusinessId, 'business-1');
      expect(meRepository.fetchCalls, 1);
      expect(activeRepository.getCalls, 1);
      expect(businessRepository.listCalls, 0);
    });

    test('submits and clears an accepted terms version with /me', () async {
      final meRepository = _FakeMeRepository();
      final termsRepository = _FakePendingTermsRepository('2026-09-01');
      final container = _container(
        meRepository: meRepository,
        activeRepository: _FakeActiveBusinessRepository(
          initialBusiness: _business(),
        ),
        businessRepository: _FakeBusinessRepository(const []),
        termsRepository: termsRepository,
      );
      addTearDown(container.dispose);

      await container.read(remoteUserBusinessContextProvider.future);

      expect(meRepository.termsVersions, <String?>['2026-09-01']);
      expect(termsRepository.markSubmittedCalls, 1);
      expect(termsRepository.pendingVersion, isNull);
    });

    test('selects the only available business when none is active', () async {
      final activeRepository = _FakeActiveBusinessRepository();
      final businessRepository = _FakeBusinessRepository(<BusinessResponseDto>[
        _business(),
      ]);
      final container = _container(
        meRepository: _FakeMeRepository(),
        activeRepository: activeRepository,
        businessRepository: businessRepository,
      );
      addTearDown(container.dispose);

      final context = await container.read(
        remoteUserBusinessContextProvider.future,
      );

      expect(context?.activeBusinessId, 'business-1');
      expect(context?.availableBusinesses, hasLength(1));
      expect(activeRepository.setIds, <String>['business-1']);
    });

    test(
      'creates and activates a business through the context controller',
      () async {
        final activeRepository = _FakeActiveBusinessRepository();
        final businessRepository = _FakeBusinessRepository(const []);
        final container = _container(
          meRepository: _FakeMeRepository(),
          activeRepository: activeRepository,
          businessRepository: businessRepository,
        );
        addTearDown(container.dispose);
        await container.read(remoteUserBusinessContextProvider.future);

        final context = await container
            .read(remoteUserBusinessContextProvider.notifier)
            .createAndActivateBusiness(
              const CreateBusinessDto(
                name: 'Lotus Nails',
                type: BusinessType.nailSalon,
                currency: 'USD',
                timezone: 'America/Los_Angeles',
              ),
            );

        expect(businessRepository.createCalls, 1);
        expect(activeRepository.setIds, <String>['business-1']);
        expect(context.activeBusinessId, 'business-1');
      },
    );

    test('does not construct remote repositories in legacy mode', () async {
      final container = ProviderContainer(
        overrides: [
          appEnvironmentProvider.overrideWithValue(
            AppEnvironment.fromValues(const <String, String>{}),
          ),
          remoteMeRepositoryProvider.overrideWithValue(_ThrowingMeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final context = await container.read(
        remoteUserBusinessContextProvider.future,
      );

      expect(context, isNull);
    });
  });
}

ProviderContainer _container({
  required RemoteMeRepository meRepository,
  required RemoteActiveBusinessRepository activeRepository,
  required RemoteBusinessRepository businessRepository,
  PendingTermsAcceptanceRepository? termsRepository,
}) {
  return ProviderContainer(
    overrides: [
      appEnvironmentProvider.overrideWithValue(_singaporeEnvironment()),
      remoteMeRepositoryProvider.overrideWithValue(meRepository),
      remoteActiveBusinessRepositoryProvider.overrideWithValue(
        activeRepository,
      ),
      remoteBusinessRepositoryProvider.overrideWithValue(businessRepository),
      pendingTermsAcceptanceRepositoryProvider.overrideWithValue(
        termsRepository ?? _FakePendingTermsRepository(null),
      ),
    ],
  );
}

AppEnvironment _singaporeEnvironment() {
  return AppEnvironment.fromValues(const <String, String>{
    'AUTH_ENV': 'singapore-dev',
    'APP_ENV': 'dev',
    'API_BASE_URL': 'https://api-dev.save-tep.us',
    'AWS_REGION': 'ap-southeast-1',
    'COGNITO_USER_POOL_ID': 'ap-southeast-1_pool',
    'COGNITO_USER_POOL_CLIENT_ID': 'client-id',
    'COGNITO_ISSUER_URL':
        'https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_pool',
    'TERMS_VERSION': '2026-09-01',
  });
}

MeResponseDto _me() => MeResponseDto(
  id: 'user-1',
  email: 'owner@example.com',
  locale: 'en-US',
  createdAt: DateTime.utc(2026, 9, 6),
);

BusinessResponseDto _business() => BusinessResponseDto(
  id: 'business-1',
  name: 'Lotus Nails',
  rawType: 'NAIL_SALON',
  currency: 'USD',
  timezone: 'America/Los_Angeles',
  createdAt: DateTime.utc(2026, 9, 6),
  updatedAt: DateTime.utc(2026, 9, 6),
);

class _FakeMeRepository implements RemoteMeRepository {
  int fetchCalls = 0;
  final List<String?> termsVersions = <String?>[];

  @override
  Future<MeResponseDto> fetchMe({String? acceptedTermsVersion}) async {
    fetchCalls += 1;
    termsVersions.add(acceptedTermsVersion);
    return _me();
  }

  @override
  Future<MeResponseDto> updateMe(UpdateMeDto update) async => _me();
}

class _FakePendingTermsRepository implements PendingTermsAcceptanceRepository {
  String? pendingVersion;
  int markSubmittedCalls = 0;

  _FakePendingTermsRepository(this.pendingVersion);

  @override
  Future<String?> loadForCurrentUser() async => pendingVersion;

  @override
  Future<void> markSubmittedForCurrentUser() async {
    markSubmittedCalls += 1;
    pendingVersion = null;
  }
}

class _ThrowingMeRepository implements RemoteMeRepository {
  @override
  Future<MeResponseDto> fetchMe({String? acceptedTermsVersion}) {
    throw StateError('Remote repository should not be read in legacy mode.');
  }

  @override
  Future<MeResponseDto> updateMe(UpdateMeDto update) {
    throw StateError('Remote repository should not be read in legacy mode.');
  }
}

class _FakeActiveBusinessRepository implements RemoteActiveBusinessRepository {
  BusinessResponseDto? _activeBusiness;
  int getCalls = 0;
  final List<String> setIds = <String>[];

  _FakeActiveBusinessRepository({BusinessResponseDto? initialBusiness})
    : _activeBusiness = initialBusiness;

  @override
  Future<ActiveBusinessResponseDto> getActiveBusiness() async {
    getCalls += 1;
    return ActiveBusinessResponseDto(business: _activeBusiness);
  }

  @override
  Future<ActiveBusinessResponseDto> setActiveBusiness(String businessId) async {
    setIds.add(businessId);
    _activeBusiness = _business();
    return ActiveBusinessResponseDto(business: _activeBusiness);
  }
}

class _FakeBusinessRepository implements RemoteBusinessRepository {
  final List<BusinessResponseDto> businesses;
  int listCalls = 0;
  int createCalls = 0;

  _FakeBusinessRepository(this.businesses);

  @override
  Future<List<BusinessResponseDto>> listBusinesses() async {
    listCalls += 1;
    return businesses;
  }

  @override
  Future<BusinessResponseDto> createBusiness(CreateBusinessDto business) async {
    createCalls += 1;
    return _business();
  }

  @override
  Future<void> deactivateBusiness(
    String businessId,
    DeactivateBusinessDto deactivation,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<BusinessResponseDto> getBusiness(String businessId) {
    throw UnimplementedError();
  }

  @override
  Future<DeactivationDisclosureResponseDto> getDeactivationDisclosure(
    String businessId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<BusinessResponseDto> updateBusiness(
    String businessId,
    UpdateBusinessDto update,
  ) {
    throw UnimplementedError();
  }
}
