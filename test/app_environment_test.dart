import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:savetep/core/config/amplify_auth_configuration.dart';
import 'package:savetep/core/config/app_environment.dart';

void main() {
  group('AppEnvironment', () {
    test('defaults to the reversible legacy Cognito configuration', () {
      final AppEnvironment environment = AppEnvironment.fromValues(
        const <String, String>{},
      );

      expect(environment.authEnvironment, AuthEnvironment.legacy);
      expect(environment.awsRegion, 'us-west-2');
      expect(environment.apiBaseUrl, isNull);

      final Map<String, Object?> output =
          jsonDecode(buildAmplifyAuthConfiguration(environment))
              as Map<String, Object?>;
      final Map<String, Object?> auth = output['auth']! as Map<String, Object?>;
      expect(auth['user_pool_id'], 'us-west-2_xNm6pbRWo');
      expect(auth['identity_pool_id'], isNotNull);
    });

    test('builds Singapore Auth without an Identity Pool', () {
      final AppEnvironment environment = AppEnvironment.fromValues(
        _singaporeValues(),
      );

      expect(environment.name, 'dev');
      expect(environment.authEnvironment, AuthEnvironment.singaporeDev);
      expect(
        environment.requiredApiBaseUrl,
        Uri.parse('https://api-dev.save-tep.us'),
      );

      final Map<String, Object?> output =
          jsonDecode(buildAmplifyAuthConfiguration(environment))
              as Map<String, Object?>;
      final Map<String, Object?> auth = output['auth']! as Map<String, Object?>;
      expect(auth['aws_region'], AppEnvironment.singaporeRegion);
      expect(auth['user_pool_id'], 'ap-southeast-1_3ob6DVAln');
      expect(auth['user_pool_client_id'], '2dkdkbefs65ipd52egvfve23gu');
      expect(auth, isNot(contains('identity_pool_id')));
    });

    test('rejects a missing Singapore value', () {
      final Map<String, String> values = _singaporeValues()
        ..remove('COGNITO_USER_POOL_CLIENT_ID');

      expect(
        () => AppEnvironment.fromValues(values),
        throwsA(
          isA<StateError>().having(
            (StateError error) => error.message,
            'message',
            contains('COGNITO_USER_POOL_CLIENT_ID'),
          ),
        ),
      );
    });

    test('rejects an invalid API URL', () {
      final Map<String, String> values = _singaporeValues()
        ..['API_BASE_URL'] = 'api-dev.save-tep.us';

      expect(
        () => AppEnvironment.fromValues(values),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects an insecure remote API URL', () {
      final Map<String, String> values = _singaporeValues()
        ..['API_BASE_URL'] = 'http://api-dev.save-tep.us';

      expect(
        () => AppEnvironment.fromValues(values),
        throwsA(
          isA<StateError>().having(
            (StateError error) => error.message,
            'message',
            contains('HTTPS'),
          ),
        ),
      );
    });

    test('permits HTTP localhost only through the test-only option', () {
      final Map<String, String> values = _singaporeValues()
        ..['API_BASE_URL'] = 'http://localhost:8080';

      expect(
        () => AppEnvironment.fromValues(values),
        throwsA(isA<StateError>()),
      );

      final AppEnvironment environment = AppEnvironment.fromValues(
        values,
        allowInsecureLocalhostForTesting: true,
      );
      expect(environment.requiredApiBaseUrl.scheme, 'http');
    });

    test('rejects Region, pool, and issuer mismatches', () {
      final Map<String, String> wrongRegion = _singaporeValues()
        ..['AWS_REGION'] = 'us-west-2';
      final Map<String, String> wrongPool = _singaporeValues()
        ..['COGNITO_USER_POOL_ID'] = 'us-west-2_example';
      final Map<String, String> wrongIssuer = _singaporeValues()
        ..['COGNITO_ISSUER_URL'] =
            'https://cognito-idp.us-west-2.amazonaws.com/'
            'ap-southeast-1_3ob6DVAln';

      expect(
        () => AppEnvironment.fromValues(wrongRegion),
        throwsA(isA<StateError>()),
      );
      expect(
        () => AppEnvironment.fromValues(wrongPool),
        throwsA(isA<StateError>()),
      );
      expect(
        () => AppEnvironment.fromValues(wrongIssuer),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects an unknown auth environment and placeholder terms', () {
      expect(
        () => AppEnvironment.fromValues(const <String, String>{
          'AUTH_ENV': 'production',
        }),
        throwsA(isA<StateError>()),
      );

      final Map<String, String> values = _singaporeValues()
        ..['TERMS_VERSION'] = '<DISPLAYED_TERMS_VERSION>';
      expect(
        () => AppEnvironment.fromValues(values),
        throwsA(isA<StateError>()),
      );
    });
  });
}

Map<String, String> _singaporeValues() => <String, String>{
  'AUTH_ENV': 'singapore-dev',
  'APP_ENV': 'dev',
  'API_BASE_URL': 'https://api-dev.save-tep.us',
  'AWS_REGION': 'ap-southeast-1',
  'COGNITO_USER_POOL_ID': 'ap-southeast-1_3ob6DVAln',
  'COGNITO_USER_POOL_CLIENT_ID': '2dkdkbefs65ipd52egvfve23gu',
  'COGNITO_ISSUER_URL':
      'https://cognito-idp.ap-southeast-1.amazonaws.com/'
      'ap-southeast-1_3ob6DVAln',
  'TERMS_VERSION': '2026-09-06',
};
