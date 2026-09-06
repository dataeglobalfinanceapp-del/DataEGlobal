enum AuthEnvironment {
  legacy('legacy'),
  singaporeDev('singapore-dev');

  final String value;

  const AuthEnvironment(this.value);

  static AuthEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'legacy' => AuthEnvironment.legacy,
      'singapore-dev' => AuthEnvironment.singaporeDev,
      _ => throw StateError('AUTH_ENV must be either legacy or singapore-dev.'),
    };
  }
}

/// Validated, compile-time application and authentication configuration.
///
/// Cognito pool and client identifiers are public configuration. Credentials,
/// passwords, tokens, and private service keys must never be added here.
class AppEnvironment {
  static const String singaporeRegion = 'ap-southeast-1';

  static const String _legacyRegion = 'us-west-2';
  static const String _legacyUserPoolId = 'us-west-2_xNm6pbRWo';
  static const String _legacyUserPoolClientId = '4anojfft7aboek6tnna6gc28bs';

  final String name;
  final AuthEnvironment authEnvironment;
  final Uri? apiBaseUrl;
  final String awsRegion;
  final String cognitoUserPoolId;
  final String cognitoUserPoolClientId;
  final Uri cognitoIssuerUrl;
  final String? termsVersion;

  const AppEnvironment._({
    required this.name,
    required this.authEnvironment,
    required this.apiBaseUrl,
    required this.awsRegion,
    required this.cognitoUserPoolId,
    required this.cognitoUserPoolClientId,
    required this.cognitoIssuerUrl,
    required this.termsVersion,
  });

  /// Reads values supplied with `--dart-define` or
  /// `--dart-define-from-file` and validates them before startup continues.
  factory AppEnvironment.fromCompileTime() {
    return AppEnvironment.fromValues(<String, String>{
      'AUTH_ENV': const String.fromEnvironment(
        'AUTH_ENV',
        defaultValue: 'legacy',
      ),
      'APP_ENV': const String.fromEnvironment('APP_ENV'),
      'API_BASE_URL': const String.fromEnvironment('API_BASE_URL'),
      'AWS_REGION': const String.fromEnvironment('AWS_REGION'),
      'COGNITO_USER_POOL_ID': const String.fromEnvironment(
        'COGNITO_USER_POOL_ID',
      ),
      'COGNITO_USER_POOL_CLIENT_ID': const String.fromEnvironment(
        'COGNITO_USER_POOL_CLIENT_ID',
      ),
      'COGNITO_ISSUER_URL': const String.fromEnvironment('COGNITO_ISSUER_URL'),
      'TERMS_VERSION': const String.fromEnvironment('TERMS_VERSION'),
    });
  }

  /// Parses a value map so configuration validation can be unit tested
  /// without changing process-wide compile-time definitions.
  factory AppEnvironment.fromValues(
    Map<String, String> values, {
    bool allowInsecureLocalhostForTesting = false,
  }) {
    final AuthEnvironment authEnvironment = AuthEnvironment.parse(
      values['AUTH_ENV'] ?? 'legacy',
    );

    if (authEnvironment == AuthEnvironment.legacy) {
      return AppEnvironment._legacy(
        name: _optional(values, 'APP_ENV') ?? 'legacy',
      );
    }

    final String name = _required(values, 'APP_ENV');
    if (name != 'dev') {
      throw StateError('APP_ENV must be dev when AUTH_ENV is singapore-dev.');
    }

    final String awsRegion = _required(values, 'AWS_REGION');
    if (awsRegion != singaporeRegion) {
      throw StateError('AWS_REGION must be ap-southeast-1 for singapore-dev.');
    }

    final Uri apiBaseUrl = _parseApiBaseUrl(
      _required(values, 'API_BASE_URL'),
      allowInsecureLocalhostForTesting: allowInsecureLocalhostForTesting,
    );
    final String userPoolId = _required(values, 'COGNITO_USER_POOL_ID');
    final String userPoolClientId = _required(
      values,
      'COGNITO_USER_POOL_CLIENT_ID',
    );
    final Uri issuerUrl = _parseIssuerUrl(
      _required(values, 'COGNITO_ISSUER_URL'),
    );
    final String termsVersion = _required(values, 'TERMS_VERSION');

    if (!userPoolId.startsWith('${awsRegion}_')) {
      throw StateError(
        'COGNITO_USER_POOL_ID does not match the configured AWS_REGION.',
      );
    }

    final String expectedIssuerHost = 'cognito-idp.$awsRegion.amazonaws.com';
    if (issuerUrl.host != expectedIssuerHost ||
        issuerUrl.path != '/$userPoolId') {
      throw StateError(
        'COGNITO_ISSUER_URL does not match AWS_REGION and '
        'COGNITO_USER_POOL_ID.',
      );
    }

    return AppEnvironment._(
      name: name,
      authEnvironment: authEnvironment,
      apiBaseUrl: apiBaseUrl,
      awsRegion: awsRegion,
      cognitoUserPoolId: userPoolId,
      cognitoUserPoolClientId: userPoolClientId,
      cognitoIssuerUrl: issuerUrl,
      termsVersion: termsVersion,
    );
  }

  factory AppEnvironment._legacy({required String name}) {
    return AppEnvironment._(
      name: name,
      authEnvironment: AuthEnvironment.legacy,
      apiBaseUrl: null,
      awsRegion: _legacyRegion,
      cognitoUserPoolId: _legacyUserPoolId,
      cognitoUserPoolClientId: _legacyUserPoolClientId,
      cognitoIssuerUrl: Uri.https(
        'cognito-idp.$_legacyRegion.amazonaws.com',
        '/$_legacyUserPoolId',
      ),
      termsVersion: null,
    );
  }

  Uri get requiredApiBaseUrl {
    final Uri? value = apiBaseUrl;
    if (value == null) {
      throw StateError('API_BASE_URL is unavailable while AUTH_ENV is legacy.');
    }
    return value;
  }

  static String _required(Map<String, String> values, String key) {
    final String? value = _optional(values, key);
    if (value == null || _isPlaceholder(value)) {
      throw StateError('$key must be configured.');
    }
    return value;
  }

  static String? _optional(Map<String, String> values, String key) {
    final String value = values[key]?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static bool _isPlaceholder(String value) {
    return value.startsWith('<') && value.endsWith('>');
  }

  static Uri _parseApiBaseUrl(
    String value, {
    required bool allowInsecureLocalhostForTesting,
  }) {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL must be an absolute URL.');
    }
    if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) {
      throw StateError(
        'API_BASE_URL must not contain credentials, a query, or a fragment.',
      );
    }

    final bool isLocalhost =
        uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1';
    final bool permitsHttp =
        allowInsecureLocalhostForTesting && isLocalhost && uri.scheme == 'http';
    if (uri.scheme != 'https' && !permitsHttp) {
      throw StateError('API_BASE_URL must use HTTPS.');
    }
    return uri;
  }

  static Uri _parseIssuerUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.hasPort ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      throw StateError('COGNITO_ISSUER_URL must be a valid HTTPS URL.');
    }
    return uri;
  }
}
