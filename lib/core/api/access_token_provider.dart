import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

abstract interface class AccessTokenProvider {
  Future<String> getAccessToken({bool forceRefresh = false});
}

class AmplifyCognitoAccessTokenProvider implements AccessTokenProvider {
  const AmplifyCognitoAccessTokenProvider();

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async {
    final AuthSession session = await Amplify.Auth.fetchAuthSession(
      options: FetchAuthSessionOptions(forceRefresh: forceRefresh),
    );
    if (!session.isSignedIn || session is! CognitoAuthSession) {
      throw const ApiAccessTokenException('No authenticated Cognito session.');
    }

    try {
      final String token = session.userPoolTokensResult.value.accessToken.raw;
      if (token.trim().isEmpty) {
        throw const ApiAccessTokenException(
          'The Cognito session did not contain an access token.',
        );
      }
      return token;
    } on ApiAccessTokenException {
      rethrow;
    } on Object catch (error) {
      throw ApiAccessTokenException(
        'Could not obtain the Cognito access token.',
        cause: error,
      );
    }
  }
}

class ApiAccessTokenException implements Exception {
  final String message;
  final Object? cause;

  const ApiAccessTokenException(this.message, {this.cause});

  @override
  String toString() => 'ApiAccessTokenException: $message';
}
