import 'dart:convert';

import 'app_environment.dart';

const String _legacyIdentityPoolId =
    'us-west-2:d67c7d2d-b306-41cd-aa50-f2c86fe375fb';

/// Builds Amplify Outputs v1.4 JSON for the selected existing Cognito pool.
String buildAmplifyAuthConfiguration(AppEnvironment environment) {
  final Map<String, Object> auth = <String, Object>{
    'user_pool_id': environment.cognitoUserPoolId,
    'aws_region': environment.awsRegion,
    'user_pool_client_id': environment.cognitoUserPoolClientId,
  };

  if (environment.authEnvironment == AuthEnvironment.legacy) {
    auth.addAll(<String, Object>{
      'identity_pool_id': _legacyIdentityPoolId,
      'mfa_methods': <String>[],
      'standard_required_attributes': <String>['email'],
      'username_attributes': <String>['email'],
      'user_verification_types': <String>['email'],
      'groups': <String>[],
      'mfa_configuration': 'NONE',
      'password_policy': <String, Object>{
        'min_length': 8,
        'require_lowercase': true,
        'require_numbers': true,
        'require_symbols': true,
        'require_uppercase': true,
      },
      'unauthenticated_identities_enabled': true,
    });
  }

  return jsonEncode(<String, Object>{'auth': auth, 'version': '1.4'});
}
