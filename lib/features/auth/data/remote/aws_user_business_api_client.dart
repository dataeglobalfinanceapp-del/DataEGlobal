import 'package:savetep/core/api/aws_api_client.dart';

import 'user_business_api_client.dart';

class AwsUserBusinessApiClient implements UserBusinessApiClient {
  final AwsApiClient _client;

  const AwsUserBusinessApiClient(this._client);

  @override
  Future<UserBusinessApiResponse> send(UserBusinessApiRequest request) async {
    final ApiMethod method = switch (request.method) {
      UserBusinessApiMethod.get => ApiMethod.get,
      UserBusinessApiMethod.post => ApiMethod.post,
      UserBusinessApiMethod.patch => ApiMethod.patch,
      UserBusinessApiMethod.put => ApiMethod.put,
      UserBusinessApiMethod.delete => ApiMethod.delete,
    };
    final ApiResponse response = await _client.request(
      ApiRequest(
        method: method,
        path: request.path,
        logPath: _logPath(request.path),
        query: request.query,
        headers: request.headers,
        jsonBody: request.jsonBody,
      ),
    );
    return UserBusinessApiResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      data: response.data,
    );
  }

  String _logPath(String path) {
    if (!path.startsWith('/businesses/')) return path;
    final segments = path.split('/');
    if (segments.length < 3) return path;
    segments[2] = '{businessId}';
    return segments.join('/');
  }
}
