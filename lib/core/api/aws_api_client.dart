import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'access_token_provider.dart';

enum ApiMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE'),
  head('HEAD'),
  options('OPTIONS');

  final String wireValue;

  const ApiMethod(this.wireValue);

  bool get isSafeReplay =>
      this == ApiMethod.get ||
      this == ApiMethod.head ||
      this == ApiMethod.options;
}

class ApiRequest {
  final ApiMethod method;
  final String path;
  final String logPath;
  final Map<String, String> query;
  final Map<String, String> headers;
  final Object? jsonBody;
  final bool authenticated;
  final bool retryOnUnauthorized;
  final bool retryTransient;

  ApiRequest({
    required this.method,
    required this.path,
    String? logPath,
    this.query = const <String, String>{},
    this.headers = const <String, String>{},
    this.jsonBody,
    this.authenticated = true,
    bool? retryOnUnauthorized,
    bool? retryTransient,
  }) : logPath = logPath ?? path,
       retryOnUnauthorized = retryOnUnauthorized ?? method.isSafeReplay,
       retryTransient = retryTransient ?? method.isSafeReplay {
    if (!path.startsWith('/')) {
      throw ArgumentError.value(path, 'path', 'must start with /');
    }
    final Uri parsedPath = Uri.parse(path);
    if (parsedPath.hasScheme ||
        parsedPath.hasAuthority ||
        parsedPath.hasQuery ||
        parsedPath.hasFragment) {
      throw ArgumentError.value(
        path,
        'path',
        'must contain only an absolute API path',
      );
    }
    String decodedPath;
    try {
      decodedPath = Uri.decodeFull(path);
    } on FormatException {
      throw ArgumentError.value(path, 'path', 'must use valid URI encoding');
    }
    if (decodedPath.split('/').any((String segment) => segment == '..')) {
      throw ArgumentError.value(path, 'path', 'must not traverse directories');
    }
    if (headers.keys.any(
      (String key) => key.toLowerCase() == 'authorization',
    )) {
      throw ArgumentError(
        'Authorization is managed by AwsApiClient and cannot be overridden.',
      );
    }
  }
}

class ApiResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Object? data;

  const ApiResponse({
    required this.statusCode,
    required this.headers,
    this.data,
  });
}

enum ApiFailureKind {
  badRequest,
  requestTimeout,
  unauthenticated,
  forbidden,
  notFound,
  conflict,
  precondition,
  unprocessable,
  rateLimited,
  server,
  unexpectedStatus,
}

class ApiHttpException implements Exception {
  final ApiFailureKind kind;
  final int statusCode;
  final String? requestId;

  const ApiHttpException({
    required this.kind,
    required this.statusCode,
    this.requestId,
  });

  factory ApiHttpException.forStatus(int statusCode, {String? requestId}) {
    final ApiFailureKind kind = switch (statusCode) {
      400 => ApiFailureKind.badRequest,
      408 => ApiFailureKind.requestTimeout,
      401 => ApiFailureKind.unauthenticated,
      403 => ApiFailureKind.forbidden,
      404 => ApiFailureKind.notFound,
      409 => ApiFailureKind.conflict,
      412 => ApiFailureKind.precondition,
      422 => ApiFailureKind.unprocessable,
      429 => ApiFailureKind.rateLimited,
      >= 500 && <= 599 => ApiFailureKind.server,
      _ => ApiFailureKind.unexpectedStatus,
    };
    return ApiHttpException(
      kind: kind,
      statusCode: statusCode,
      requestId: requestId,
    );
  }

  @override
  String toString() {
    final String suffix = requestId == null ? '' : ' (request $requestId)';
    return 'ApiHttpException: HTTP $statusCode, ${kind.name}$suffix';
  }
}

enum ApiTransportFailureKind { timeout, connection, malformedResponse }

class ApiTransportException implements Exception {
  final ApiTransportFailureKind kind;
  final String message;
  final Object? cause;

  const ApiTransportException(this.kind, this.message, {this.cause});

  @override
  String toString() => 'ApiTransportException: ${kind.name}: $message';
}

class ApiLogEntry {
  final ApiMethod method;
  final String path;
  final int? statusCode;
  final Duration duration;
  final String? requestId;

  const ApiLogEntry({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.duration,
    this.requestId,
  });
}

typedef ApiLogSink = void Function(ApiLogEntry entry);
typedef ApiRetryDelay = Future<void> Function(Duration duration);
typedef ApiAuthenticationFailureHandler = Future<void> Function();

class AwsApiClient {
  static const Duration defaultTimeout = Duration(seconds: 20);

  final Uri _baseUrl;
  final AccessTokenProvider _accessTokenProvider;
  final http.Client _httpClient;
  final Duration _timeout;
  final ApiLogSink? _logSink;
  final ApiRetryDelay _retryDelay;
  final ApiAuthenticationFailureHandler? _onAuthenticationFailure;
  final bool _ownsHttpClient;

  Future<String>? _refreshInFlight;
  bool _isClosed = false;

  AwsApiClient({
    required Uri baseUrl,
    required AccessTokenProvider accessTokenProvider,
    http.Client? httpClient,
    Duration timeout = defaultTimeout,
    ApiLogSink? logSink,
    ApiRetryDelay retryDelay = _defaultRetryDelay,
    ApiAuthenticationFailureHandler? onAuthenticationFailure,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _accessTokenProvider = accessTokenProvider,
       _httpClient = httpClient ?? http.Client(),
       _timeout = timeout,
       _logSink = logSink,
       _retryDelay = retryDelay,
       _onAuthenticationFailure = onAuthenticationFailure,
       _ownsHttpClient = httpClient == null {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
  }

  Future<ApiResponse> request(ApiRequest request) async {
    if (_isClosed) {
      throw StateError('AwsApiClient has been closed.');
    }

    String? token = request.authenticated
        ? await _accessTokenProvider.getAccessToken()
        : null;
    var refreshedUnauthorized = false;
    var transientRetries = 0;
    late ApiResponse response;

    while (true) {
      response = await _send(request, token: token);
      if (response.statusCode == 401 &&
          request.authenticated &&
          !refreshedUnauthorized) {
        try {
          token = await _forceRefreshAccessToken();
        } on Object {
          await _handleAuthenticationFailure();
          rethrow;
        }
        refreshedUnauthorized = true;
        if (request.retryOnUnauthorized) continue;
      }
      if (request.retryTransient &&
          request.method.isSafeReplay &&
          _isTransient(response.statusCode) &&
          transientRetries < 2) {
        await _retryDelay(_retryDuration(response, transientRetries));
        transientRetries += 1;
        continue;
      }
      break;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 &&
          request.authenticated &&
          request.retryOnUnauthorized) {
        await _handleAuthenticationFailure();
      }
      throw ApiHttpException.forStatus(
        response.statusCode,
        requestId: _requestId(response.headers),
      );
    }
    return response;
  }

  Future<ApiResponse> get(
    String path, {
    String? logPath,
    Map<String, String> query = const <String, String>{},
    Map<String, String> headers = const <String, String>{},
    bool authenticated = true,
  }) {
    return request(
      ApiRequest(
        method: ApiMethod.get,
        path: path,
        logPath: logPath,
        query: query,
        headers: headers,
        authenticated: authenticated,
      ),
    );
  }

  Future<ApiResponse> post(
    String path, {
    String? logPath,
    Map<String, String> query = const <String, String>{},
    Map<String, String> headers = const <String, String>{},
    Object? jsonBody,
    bool authenticated = true,
    bool retryOnUnauthorized = false,
  }) {
    return request(
      ApiRequest(
        method: ApiMethod.post,
        path: path,
        logPath: logPath,
        query: query,
        headers: headers,
        jsonBody: jsonBody,
        authenticated: authenticated,
        retryOnUnauthorized: retryOnUnauthorized,
      ),
    );
  }

  Future<ApiResponse> put(
    String path, {
    String? logPath,
    Map<String, String> query = const <String, String>{},
    Map<String, String> headers = const <String, String>{},
    Object? jsonBody,
    bool authenticated = true,
    bool retryOnUnauthorized = false,
  }) {
    return request(
      ApiRequest(
        method: ApiMethod.put,
        path: path,
        logPath: logPath,
        query: query,
        headers: headers,
        jsonBody: jsonBody,
        authenticated: authenticated,
        retryOnUnauthorized: retryOnUnauthorized,
      ),
    );
  }

  Future<ApiResponse> patch(
    String path, {
    String? logPath,
    Map<String, String> query = const <String, String>{},
    Map<String, String> headers = const <String, String>{},
    Object? jsonBody,
    bool authenticated = true,
    bool retryOnUnauthorized = false,
  }) {
    return request(
      ApiRequest(
        method: ApiMethod.patch,
        path: path,
        logPath: logPath,
        query: query,
        headers: headers,
        jsonBody: jsonBody,
        authenticated: authenticated,
        retryOnUnauthorized: retryOnUnauthorized,
      ),
    );
  }

  Future<ApiResponse> delete(
    String path, {
    String? logPath,
    Map<String, String> query = const <String, String>{},
    Map<String, String> headers = const <String, String>{},
    Object? jsonBody,
    bool authenticated = true,
    bool retryOnUnauthorized = false,
  }) {
    return request(
      ApiRequest(
        method: ApiMethod.delete,
        path: path,
        logPath: logPath,
        query: query,
        headers: headers,
        jsonBody: jsonBody,
        authenticated: authenticated,
        retryOnUnauthorized: retryOnUnauthorized,
      ),
    );
  }

  Future<ApiResponse> _send(
    ApiRequest request, {
    required String? token,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    int? statusCode;
    String? responseRequestId;
    try {
      final Uri uri = _buildUri(request.path, request.query);
      final http.Request httpRequest = http.Request(
        request.method.wireValue,
        uri,
      );
      httpRequest.headers.addAll(<String, String>{
        'Accept': 'application/json',
        ...request.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (request.jsonBody != null) {
        httpRequest.headers['Content-Type'] = 'application/json';
        httpRequest.body = jsonEncode(request.jsonBody);
      }

      final http.StreamedResponse streamedResponse = await _httpClient
          .send(httpRequest)
          .timeout(_timeout);
      final http.Response response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(_timeout);
      statusCode = response.statusCode;
      responseRequestId = _requestId(response.headers);
      Object? data;
      try {
        data = _decodeBody(response);
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) rethrow;
        data = null;
      }
      return ApiResponse(
        statusCode: response.statusCode,
        headers: Map<String, String>.unmodifiable(response.headers),
        data: data,
      );
    } on TimeoutException catch (error) {
      throw ApiTransportException(
        ApiTransportFailureKind.timeout,
        'The API request timed out.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw ApiTransportException(
        ApiTransportFailureKind.connection,
        'The API request could not be completed.',
        cause: error,
      );
    } on FormatException catch (error) {
      throw ApiTransportException(
        ApiTransportFailureKind.malformedResponse,
        'The API returned malformed JSON.',
        cause: error,
      );
    } finally {
      stopwatch.stop();
      _logSink?.call(
        ApiLogEntry(
          method: request.method,
          path: request.logPath,
          statusCode: statusCode,
          duration: stopwatch.elapsed,
          requestId: responseRequestId,
        ),
      );
    }
  }

  Future<String> _forceRefreshAccessToken() {
    final Future<String>? pending = _refreshInFlight;
    if (pending != null) return pending;

    late final Future<String> refresh;
    refresh = _accessTokenProvider
        .getAccessToken(forceRefresh: true)
        .whenComplete(() {
          if (identical(_refreshInFlight, refresh)) {
            _refreshInFlight = null;
          }
        });
    _refreshInFlight = refresh;
    return refresh;
  }

  Uri _buildUri(String path, Map<String, String> query) {
    final String base = _baseUrl.toString();
    final Uri uri = Uri.parse('$base$path');
    return query.isEmpty ? uri : uri.replace(queryParameters: query);
  }

  static Object? _decodeBody(http.Response response) {
    if (response.statusCode == 204 || response.bodyBytes.isEmpty) return null;
    final String body = utf8.decode(response.bodyBytes);
    if (body.trim().isEmpty) return null;

    final String? contentType = response.headers['content-type'];
    final String trimmed = body.trimLeft();
    final bool looksLikeJson =
        contentType?.toLowerCase().contains('json') == true ||
        trimmed.startsWith('{') ||
        trimmed.startsWith('[');
    return looksLikeJson ? jsonDecode(body) : body;
  }

  static String? _requestId(Map<String, String> headers) {
    return headers['x-request-id'] ??
        headers['x-amzn-requestid'] ??
        headers['x-amzn-request-id'];
  }

  static bool _isTransient(int statusCode) {
    return statusCode == 408 ||
        statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  static Duration _retryDuration(ApiResponse response, int retryIndex) {
    final int? retryAfterSeconds = int.tryParse(
      response.headers['retry-after']?.trim() ?? '',
    );
    if (retryAfterSeconds != null && retryAfterSeconds >= 0) {
      return Duration(seconds: retryAfterSeconds.clamp(0, 5).toInt());
    }
    return Duration(milliseconds: 250 * (1 << retryIndex));
  }

  static Future<void> _defaultRetryDelay(Duration duration) {
    return Future<void>.delayed(duration);
  }

  Future<void> _handleAuthenticationFailure() async {
    try {
      await _onAuthenticationFailure?.call();
    } on Object {
      // Preserve the authentication/API failure that triggered this cleanup.
    }
  }

  static Uri _normalizeBaseUrl(Uri baseUrl) {
    if (baseUrl.scheme != 'https' ||
        baseUrl.host.isEmpty ||
        baseUrl.hasQuery ||
        baseUrl.hasFragment ||
        baseUrl.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'must be an absolute HTTPS URL without credentials/query/fragment',
      );
    }
    final String path = baseUrl.path == '/'
        ? ''
        : baseUrl.path.replaceFirst(RegExp(r'/$'), '');
    return baseUrl.replace(path: path);
  }

  void close() {
    if (_isClosed) return;
    _isClosed = true;
    if (_ownsHttpClient) _httpClient.close();
  }

  @Deprecated('Use endpoint-specific REST repositories instead.')
  Future<String?> read(String key) {
    throw UnsupportedError(
      'Key/value AWS reads are not part of the SaveTep REST API.',
    );
  }

  @Deprecated('Use endpoint-specific REST repositories instead.')
  Future<void> write(String key, String value) {
    throw UnsupportedError(
      'Key/value AWS writes are not part of the SaveTep REST API.',
    );
  }
}
