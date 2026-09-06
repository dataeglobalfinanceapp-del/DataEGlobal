enum UserBusinessApiMethod { get, post, patch, put, delete }

class UserBusinessApiRequest {
  final UserBusinessApiMethod method;
  final String path;
  final Map<String, String> query;
  final Map<String, String> headers;
  final Map<String, Object?>? jsonBody;

  const UserBusinessApiRequest({
    required this.method,
    required this.path,
    this.query = const <String, String>{},
    this.headers = const <String, String>{},
    this.jsonBody,
  });
}

class UserBusinessApiResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Object? data;

  const UserBusinessApiResponse({
    required this.statusCode,
    this.headers = const <String, String>{},
    this.data,
  });
}

/// Feature-local boundary for the shared authenticated API client.
///
/// An adapter should forward [UserBusinessApiRequest] to `AwsApiClient.request`
/// with authentication and one safe unauthorized retry enabled. Keeping the
/// boundary here lets the local profile repositories remain available during
/// rollout and rollback.
abstract interface class UserBusinessApiClient {
  Future<UserBusinessApiResponse> send(UserBusinessApiRequest request);
}

class UserBusinessApiProtocolException implements Exception {
  final String operation;
  final int? statusCode;
  final String message;

  const UserBusinessApiProtocolException({
    required this.operation,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';
    return 'UserBusinessApiProtocolException: $operation$status: $message';
  }
}
