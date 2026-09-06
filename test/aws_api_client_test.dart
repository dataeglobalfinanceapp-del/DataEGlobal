import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:savetep/core/api/access_token_provider.dart';
import 'package:savetep/core/api/aws_api_client.dart';

void main() {
  group('AwsApiClient', () {
    test('adds access token and decodes a JSON response', () async {
      final tokenProvider = _FakeAccessTokenProvider();
      late http.Request captured;
      final client = AwsApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        accessTokenProvider: tokenProvider,
        httpClient: MockClient((http.Request request) async {
          captured = request;
          return http.Response(
            jsonEncode(<String, Object?>{'id': 'user-1'}),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final response = await client.get(
        '/me',
        query: const <String, String>{'page': '1'},
      );

      expect(captured.url.toString(), 'https://api.example.test/me?page=1');
      expect(captured.headers['Authorization'], 'Bearer initial-token');
      expect(response.data, <String, Object?>{'id': 'user-1'});
      expect(tokenProvider.regularCalls, 1);
      expect(tokenProvider.refreshCalls, 0);
    });

    test('forces one refresh and safely replays a GET after 401', () async {
      final tokenProvider = _FakeAccessTokenProvider();
      final seenTokens = <String?>[];
      var calls = 0;
      final client = AwsApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        accessTokenProvider: tokenProvider,
        httpClient: MockClient((http.Request request) async {
          calls += 1;
          seenTokens.add(request.headers['Authorization']);
          return calls == 1
              ? http.Response('', 401)
              : http.Response('{"ok":true}', 200);
        }),
      );

      final response = await client.get('/me');

      expect(response.data, <String, Object?>{'ok': true});
      expect(calls, 2);
      expect(seenTokens, <String?>[
        'Bearer initial-token',
        'Bearer refreshed-token',
      ]);
      expect(tokenProvider.refreshCalls, 1);
    });

    test('does not replay a write after 401 by default', () async {
      final tokenProvider = _FakeAccessTokenProvider();
      var calls = 0;
      final client = AwsApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        accessTokenProvider: tokenProvider,
        httpClient: MockClient((http.Request request) async {
          calls += 1;
          return http.Response('', 401);
        }),
      );

      await expectLater(
        client.post('/businesses', jsonBody: <String, Object?>{'name': 'A'}),
        throwsA(
          isA<ApiHttpException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having(
                (error) => error.kind,
                'kind',
                ApiFailureKind.unauthenticated,
              ),
        ),
      );
      expect(calls, 1);
      expect(tokenProvider.refreshCalls, 1);
    });

    test('cleans up authentication after a repeated GET 401', () async {
      var cleanupCalls = 0;
      final client = AwsApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        accessTokenProvider: _FakeAccessTokenProvider(),
        onAuthenticationFailure: () async => cleanupCalls += 1,
        httpClient: MockClient((_) async => http.Response('', 401)),
      );

      await expectLater(client.get('/me'), throwsA(isA<ApiHttpException>()));

      expect(cleanupCalls, 1);
    });

    test('retries transient GET failures with bounded Retry-After', () async {
      var calls = 0;
      final delays = <Duration>[];
      final client = AwsApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        accessTokenProvider: _FakeAccessTokenProvider(),
        retryDelay: (Duration duration) async => delays.add(duration),
        httpClient: MockClient((http.Request request) async {
          calls += 1;
          if (calls == 1) {
            return http.Response(
              '',
              429,
              headers: <String, String>{'retry-after': '99'},
            );
          }
          return http.Response('{}', 200);
        }),
      );

      await client.get('/me');

      expect(calls, 2);
      expect(delays, const <Duration>[Duration(seconds: 5)]);
    });

    test('supports unauthenticated health and empty 204 responses', () async {
      final tokenProvider = _FakeAccessTokenProvider();
      late http.Request captured;
      final client = AwsApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        accessTokenProvider: tokenProvider,
        httpClient: MockClient((http.Request request) async {
          captured = request;
          return http.Response('', 204);
        }),
      );

      final response = await client.get('/health', authenticated: false);

      expect(response.statusCode, 204);
      expect(response.data, isNull);
      expect(captured.headers, isNot(contains('Authorization')));
      expect(tokenProvider.regularCalls, 0);
    });

    test('maps status safely and retains a request id', () async {
      final client = AwsApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        accessTokenProvider: _FakeAccessTokenProvider(),
        httpClient: MockClient(
          (_) async => http.Response(
            '{"private":"do not expose"}',
            422,
            headers: <String, String>{'x-request-id': 'request-123'},
          ),
        ),
      );

      await expectLater(
        client.post('/expenses'),
        throwsA(
          isA<ApiHttpException>()
              .having(
                (error) => error.kind,
                'kind',
                ApiFailureKind.unprocessable,
              )
              .having((error) => error.requestId, 'requestId', 'request-123')
              .having(
                (error) => error.toString(),
                'safe message',
                isNot(contains('private')),
              ),
        ),
      );
    });

    test(
      'logs route template but never query or authorization values',
      () async {
        final entries = <ApiLogEntry>[];
        final client = AwsApiClient(
          baseUrl: Uri.parse('https://api.example.test'),
          accessTokenProvider: _FakeAccessTokenProvider(),
          logSink: entries.add,
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        );

        await client.get(
          '/businesses/72b0f164-17ff-445c-bf7b-0d22a80ce54f',
          logPath: '/businesses/{businessId}',
          query: const <String, String>{'email': 'private@example.com'},
        );

        expect(entries.single.path, '/businesses/{businessId}');
        expect(entries.single.statusCode, 200);
        expect(entries.single.path, isNot(contains('private@example.com')));
      },
    );

    test('rejects caller authorization and path traversal', () {
      expect(
        () => ApiRequest(
          method: ApiMethod.get,
          path: '/me',
          headers: const <String, String>{'authorization': 'unsafe'},
        ),
        throwsArgumentError,
      );
      expect(
        () => ApiRequest(method: ApiMethod.get, path: '/../admin'),
        throwsArgumentError,
      );
    });

    test('normalizes malformed JSON into a transport failure', () async {
      final client = AwsApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        accessTokenProvider: _FakeAccessTokenProvider(),
        httpClient: MockClient(
          (_) async => http.Response(
            '{not-json',
            200,
            headers: <String, String>{'content-type': 'application/json'},
          ),
        ),
      );

      await expectLater(
        client.get('/me'),
        throwsA(
          isA<ApiTransportException>().having(
            (error) => error.kind,
            'kind',
            ApiTransportFailureKind.malformedResponse,
          ),
        ),
      );
    });

    test('times out a request using the configured bound', () async {
      final responseCompleter = Completer<http.Response>();
      final client = AwsApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        accessTokenProvider: _FakeAccessTokenProvider(),
        timeout: const Duration(milliseconds: 1),
        httpClient: MockClient((_) => responseCompleter.future),
      );

      await expectLater(
        client.get('/me'),
        throwsA(
          isA<ApiTransportException>().having(
            (error) => error.kind,
            'kind',
            ApiTransportFailureKind.timeout,
          ),
        ),
      );
    });
  });
}

class _FakeAccessTokenProvider implements AccessTokenProvider {
  int regularCalls = 0;
  int refreshCalls = 0;

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      refreshCalls += 1;
      return 'refreshed-token';
    }
    regularCalls += 1;
    return 'initial-token';
  }
}
