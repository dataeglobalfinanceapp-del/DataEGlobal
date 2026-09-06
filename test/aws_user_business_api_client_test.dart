import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:savetep/core/api/access_token_provider.dart';
import 'package:savetep/core/api/aws_api_client.dart';
import 'package:savetep/features/auth/data/remote/aws_user_business_api_client.dart';
import 'package:savetep/features/auth/data/remote/user_business_remote_repositories.dart';

void main() {
  test('adapter preserves encoded IDs and logs a route template', () async {
    late Uri requestedUrl;
    final logEntries = <ApiLogEntry>[];
    final client = AwsApiClient(
      baseUrl: Uri.parse('https://api.example.test'),
      accessTokenProvider: const _StaticTokenProvider(),
      logSink: logEntries.add,
      httpClient: MockClient((http.Request request) async {
        requestedUrl = request.url;
        return http.Response(
          jsonEncode(<String, Object?>{
            'id': 'business/id',
            'name': 'Lotus Nails',
            'type': 'NAIL_SALON',
            'currency': 'USD',
            'timezone': 'America/Los_Angeles',
            'state': 'CA',
            'referralCode': null,
            'createdAt': '2026-09-06T02:03:04.000Z',
            'updatedAt': '2026-09-06T03:04:05.000Z',
          }),
          200,
        );
      }),
    );

    final repository = ApiBusinessRepository(AwsUserBusinessApiClient(client));
    await repository.getBusiness('business/id');

    expect(
      requestedUrl.toString(),
      'https://api.example.test/businesses/business%2Fid',
    );
    expect(logEntries.single.path, '/businesses/{businessId}');
  });
}

class _StaticTokenProvider implements AccessTokenProvider {
  const _StaticTokenProvider();

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async => 'token';
}
