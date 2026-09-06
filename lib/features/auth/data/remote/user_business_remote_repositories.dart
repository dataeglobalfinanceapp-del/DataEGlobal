import 'package:savetep/features/auth/data/remote/business_api_models.dart';
import 'package:savetep/features/auth/data/remote/user_api_models.dart';
import 'package:savetep/features/auth/data/remote/user_business_api_client.dart';

abstract interface class RemoteMeRepository {
  Future<MeResponseDto> fetchMe({String? acceptedTermsVersion});

  Future<MeResponseDto> updateMe(UpdateMeDto update);
}

class ApiMeRepository implements RemoteMeRepository {
  static const String termsVersionHeader = 'X-Terms-Version';

  final UserBusinessApiClient _client;

  const ApiMeRepository(this._client);

  @override
  Future<MeResponseDto> fetchMe({String? acceptedTermsVersion}) async {
    final headers = _termsHeaders(acceptedTermsVersion);
    final response = await _client.send(
      UserBusinessApiRequest(
        method: UserBusinessApiMethod.get,
        path: '/me',
        headers: headers,
      ),
    );
    _expectStatus(response, expected: 200, operation: 'GET /me');
    return MeResponseDto.fromJson(
      _responseObject(response, operation: 'GET /me'),
    );
  }

  @override
  Future<MeResponseDto> updateMe(UpdateMeDto update) async {
    final response = await _client.send(
      UserBusinessApiRequest(
        method: UserBusinessApiMethod.patch,
        path: '/me',
        jsonBody: update.toJson(),
      ),
    );
    _expectStatus(response, expected: 200, operation: 'PATCH /me');
    return MeResponseDto.fromJson(
      _responseObject(response, operation: 'PATCH /me'),
    );
  }

  Map<String, String> _termsHeaders(String? acceptedTermsVersion) {
    if (acceptedTermsVersion == null) return const <String, String>{};
    if (acceptedTermsVersion.trim().isEmpty ||
        acceptedTermsVersion.length > 64) {
      throw ArgumentError.value(
        acceptedTermsVersion,
        'acceptedTermsVersion',
        'must contain 1 to 64 characters',
      );
    }
    return <String, String>{termsVersionHeader: acceptedTermsVersion};
  }
}

abstract interface class RemoteBusinessRepository {
  Future<List<BusinessResponseDto>> listBusinesses();

  Future<BusinessResponseDto> createBusiness(CreateBusinessDto business);

  Future<BusinessResponseDto> getBusiness(String businessId);

  Future<BusinessResponseDto> updateBusiness(
    String businessId,
    UpdateBusinessDto update,
  );

  Future<DeactivationDisclosureResponseDto> getDeactivationDisclosure(
    String businessId,
  );

  Future<void> deactivateBusiness(
    String businessId,
    DeactivateBusinessDto deactivation,
  );
}

class ApiBusinessRepository implements RemoteBusinessRepository {
  final UserBusinessApiClient _client;

  const ApiBusinessRepository(this._client);

  @override
  Future<List<BusinessResponseDto>> listBusinesses() async {
    final response = await _client.send(
      const UserBusinessApiRequest(
        method: UserBusinessApiMethod.get,
        path: '/businesses',
      ),
    );
    _expectStatus(response, expected: 200, operation: 'GET /businesses');
    final data = response.data;
    if (data is! List) {
      throw const UserBusinessApiProtocolException(
        operation: 'GET /businesses',
        message: 'Expected a JSON array response body.',
      );
    }
    return data
        .map((item) => BusinessResponseDto.fromJson(_jsonObject(item)))
        .toList(growable: false);
  }

  @override
  Future<BusinessResponseDto> createBusiness(CreateBusinessDto business) async {
    final response = await _client.send(
      UserBusinessApiRequest(
        method: UserBusinessApiMethod.post,
        path: '/businesses',
        jsonBody: business.toJson(),
      ),
    );
    _expectStatus(response, expected: 201, operation: 'POST /businesses');
    return BusinessResponseDto.fromJson(
      _responseObject(response, operation: 'POST /businesses'),
    );
  }

  @override
  Future<BusinessResponseDto> getBusiness(String businessId) async {
    final path = _businessPath(businessId);
    final response = await _client.send(
      UserBusinessApiRequest(method: UserBusinessApiMethod.get, path: path),
    );
    _expectStatus(response, expected: 200, operation: 'GET $path');
    return BusinessResponseDto.fromJson(
      _responseObject(response, operation: 'GET $path'),
    );
  }

  @override
  Future<BusinessResponseDto> updateBusiness(
    String businessId,
    UpdateBusinessDto update,
  ) async {
    final path = _businessPath(businessId);
    final response = await _client.send(
      UserBusinessApiRequest(
        method: UserBusinessApiMethod.patch,
        path: path,
        jsonBody: update.toJson(),
      ),
    );
    _expectStatus(response, expected: 200, operation: 'PATCH $path');
    return BusinessResponseDto.fromJson(
      _responseObject(response, operation: 'PATCH $path'),
    );
  }

  @override
  Future<DeactivationDisclosureResponseDto> getDeactivationDisclosure(
    String businessId,
  ) async {
    final path = '${_businessPath(businessId)}/deactivation-disclosure';
    final response = await _client.send(
      UserBusinessApiRequest(method: UserBusinessApiMethod.get, path: path),
    );
    _expectStatus(response, expected: 200, operation: 'GET $path');
    return DeactivationDisclosureResponseDto.fromJson(
      _responseObject(response, operation: 'GET $path'),
    );
  }

  @override
  Future<void> deactivateBusiness(
    String businessId,
    DeactivateBusinessDto deactivation,
  ) async {
    final path = _businessPath(businessId);
    final response = await _client.send(
      UserBusinessApiRequest(
        method: UserBusinessApiMethod.delete,
        path: path,
        jsonBody: deactivation.toJson(),
      ),
    );
    _expectStatus(response, expected: 204, operation: 'DELETE $path');
  }
}

abstract interface class RemoteActiveBusinessRepository {
  Future<ActiveBusinessResponseDto> getActiveBusiness();

  Future<ActiveBusinessResponseDto> setActiveBusiness(String businessId);
}

class ApiActiveBusinessRepository implements RemoteActiveBusinessRepository {
  static const String _path = '/me/active-business';

  final UserBusinessApiClient _client;

  const ApiActiveBusinessRepository(this._client);

  @override
  Future<ActiveBusinessResponseDto> getActiveBusiness() async {
    final response = await _client.send(
      const UserBusinessApiRequest(
        method: UserBusinessApiMethod.get,
        path: _path,
      ),
    );
    _expectStatus(response, expected: 200, operation: 'GET $_path');
    return ActiveBusinessResponseDto.fromJson(
      _responseObject(response, operation: 'GET $_path'),
    );
  }

  @override
  Future<ActiveBusinessResponseDto> setActiveBusiness(String businessId) async {
    if (businessId.trim().isEmpty) {
      throw ArgumentError.value(businessId, 'businessId', 'must not be empty');
    }
    final response = await _client.send(
      UserBusinessApiRequest(
        method: UserBusinessApiMethod.put,
        path: _path,
        jsonBody: SetActiveBusinessDto(businessId: businessId).toJson(),
      ),
    );
    _expectStatus(response, expected: 200, operation: 'PUT $_path');
    return ActiveBusinessResponseDto.fromJson(
      _responseObject(response, operation: 'PUT $_path'),
    );
  }
}

String _businessPath(String businessId) {
  if (businessId.trim().isEmpty) {
    throw ArgumentError.value(businessId, 'businessId', 'must not be empty');
  }
  return '/businesses/${Uri.encodeComponent(businessId)}';
}

void _expectStatus(
  UserBusinessApiResponse response, {
  required int expected,
  required String operation,
}) {
  if (response.statusCode == expected) return;
  throw UserBusinessApiProtocolException(
    operation: operation,
    statusCode: response.statusCode,
    message: 'Expected HTTP $expected.',
  );
}

Map<String, Object?> _responseObject(
  UserBusinessApiResponse response, {
  required String operation,
}) {
  try {
    return _jsonObject(response.data);
  } on FormatException {
    throw UserBusinessApiProtocolException(
      operation: operation,
      statusCode: response.statusCode,
      message: 'Expected a JSON object response body.',
    );
  }
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  throw const FormatException('Expected a JSON object.');
}
