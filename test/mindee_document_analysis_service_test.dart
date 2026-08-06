import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

import 'package:savetep/features/auth/screens/scan_screen/mindee/document_analysis_service.dart';
import 'package:savetep/features/auth/screens/scan_screen/mindee/mindee_analysis_models.dart';
import 'package:savetep/features/auth/screens/scan_screen/mindee/mindee_config.dart';
import 'package:savetep/features/auth/screens/scan_screen/mindee/mindee_providers.dart';

void main() {
  group('MindeeConfig', () {
    test('rejects a missing API key', () {
      expect(
        () => MindeeConfig.validate(
          apiKeyValue: '',
          expenseModelIdValue: 'expense-model',
          depositModelIdValue: 'deposit-model',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a missing expense model ID', () {
      expect(
        () => MindeeConfig.validate(
          apiKeyValue: 'test-key',
          expenseModelIdValue: '',
          depositModelIdValue: 'deposit-model',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a missing deposit model ID', () {
      expect(
        () => MindeeConfig.validate(
          apiKeyValue: 'test-key',
          expenseModelIdValue: 'expense-model',
          depositModelIdValue: '',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('file validation', () {
    test('maps supported extensions to MIME types', () {
      expect(mediaTypeForFileName('receipt.jpg').mimeType, 'image/jpeg');
      expect(mediaTypeForFileName('receipt.JPEG').mimeType, 'image/jpeg');
      expect(mediaTypeForFileName('receipt.png').mimeType, 'image/png');
    });

    test('rejects an unsupported extension before upload', () async {
      var requestCount = 0;
      final service = _service(
        MockClient((request) async {
          requestCount++;
          return http.Response('', 500);
        }),
      );

      await expectLater(
        service.analyze(
          image: _image(<int>[1], name: 'receipt.gif'),
          type: ScanTransactionType.expense,
          cancellationToken: CancellationToken(),
        ),
        throwsUnsupportedError,
      );
      expect(requestCount, 0);
    });

    test('rejects an empty image before upload', () async {
      var requestCount = 0;
      final service = _service(
        MockClient((request) async {
          requestCount++;
          return http.Response('', 500);
        }),
      );

      await expectLater(
        service.analyze(
          image: _image(<int>[], name: 'receipt.jpg'),
          type: ScanTransactionType.expense,
          cancellationToken: CancellationToken(),
        ),
        throwsA(isA<EmptyDocumentException>()),
      );
      expect(requestCount, 0);
    });

    test('rejects an image larger than 10 MB before upload', () async {
      var requestCount = 0;
      final service = _service(
        MockClient((request) async {
          requestCount++;
          return http.Response('', 500);
        }),
      );

      await expectLater(
        service.analyze(
          image: _image(
            Uint8List(MindeeDocumentAnalysisService.maximumFileSizeBytes + 1),
            name: 'receipt.png',
          ),
          type: ScanTransactionType.deposit,
          cancellationToken: CancellationToken(),
        ),
        throwsA(isA<FileSizeLimitExceededException>()),
      );
      expect(requestCount, 0);
    });
  });

  group('enqueue and polling', () {
    test('validates configuration before reading or uploading', () async {
      var requestCount = 0;
      final service = MindeeDocumentAnalysisService(
        httpClient: MockClient((request) async {
          requestCount++;
          return http.Response('', 500);
        }),
        apiKey: '',
        expenseModelId: 'expense-model',
        depositModelId: 'deposit-model',
      );

      await expectLater(
        service.analyze(
          image: _image(<int>[1], name: 'receipt.jpg'),
          type: ScanTransactionType.expense,
          cancellationToken: CancellationToken(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(requestCount, 0);
    });

    for (final testCase in <(ScanTransactionType, String)>[
      (ScanTransactionType.expense, 'expense-model'),
      (ScanTransactionType.deposit, 'deposit-model'),
    ]) {
      test('selects ${testCase.$1.name} model in multipart request', () async {
        late http.Request enqueueRequest;
        final client = _successfulClient(
          onEnqueue: (request) => enqueueRequest = request,
        );
        final service = _service(client);

        await service.analyze(
          image: _image(<int>[1, 2, 3], name: 'receipt.jpg'),
          type: testCase.$1,
          cancellationToken: CancellationToken(),
        );

        expect(enqueueRequest.headers['authorization'], 'raw-test-key');
        expect(enqueueRequest.headers['accept'], 'application/json');
        final body = latin1.decode(enqueueRequest.bodyBytes);
        expect(body, contains('name="model_id"'));
        expect(body, contains(testCase.$2));
        expect(body, contains('name="file"'));
        expect(body, contains('filename="receipt.jpg"'));
        expect(body, contains('content-type: image/jpeg'));
      });
    }

    test('requires polling_url inside the top-level job object', () async {
      final service = _service(
        MockClient((request) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'polling_url': 'https://mindee.test/jobs/wrong',
              'job': <String, Object?>{'status': 'Waiting'},
            }),
            200,
          );
        }),
      );

      await expectLater(
        service.analyze(
          image: _image(<int>[1], name: 'receipt.jpg'),
          type: ScanTransactionType.expense,
          cancellationToken: CancellationToken(),
        ),
        throwsA(isA<MindeeResponseParseException>()),
      );
    });

    test('uses job.result_url as readiness signal for any status', () async {
      final result =
          await _service(
            _successfulClient(pollStatus: 'A-New-Success-Name'),
          ).analyze(
            image: _image(<int>[1], name: 'receipt.png'),
            type: ScanTransactionType.deposit,
            cancellationToken: CancellationToken(),
          );

      expect(result.inferenceId, 'inference-1');
      expect(result.numberValue('total_amount'), 12.5);
    });

    test(
      'does not follow a completed polling redirect automatically',
      () async {
        bool? pollFollowRedirects;
        var resultRequestCount = 0;
        final service = _service(
          MockClient((request) async {
            if (request.method == 'POST') return _enqueueResponse;
            if (request.url.path == '/jobs/1') {
              pollFollowRedirects = request.followRedirects;
              return http.Response(
                '',
                303,
                headers: <String, String>{'location': '/results/1'},
              );
            }
            if (request.url.path == '/results/1') {
              resultRequestCount++;
              return _resultResponse;
            }
            return http.Response('not found', 404);
          }),
        );

        final result = await service.analyze(
          image: _image(<int>[1], name: 'receipt.jpg'),
          type: ScanTransactionType.expense,
          cancellationToken: CancellationToken(),
        );

        expect(pollFollowRedirects, isFalse);
        expect(resultRequestCount, 1);
        expect(result.inferenceId, 'inference-1');
      },
    );

    test('rejects a polling redirect without a result location', () async {
      final service = _service(
        MockClient((request) async {
          if (request.method == 'POST') return _enqueueResponse;
          return http.Response('', 303);
        }),
      );

      await expectLater(
        service.analyze(
          image: _image(<int>[1], name: 'receipt.jpg'),
          type: ScanTransactionType.expense,
          cancellationToken: CancellationToken(),
        ),
        throwsA(isA<MindeeResponseParseException>()),
      );
    });

    test('applies initial and between-poll delays', () async {
      var pollCount = 0;
      final waits = <Duration>[];
      final client = MockClient((request) async {
        if (request.method == 'POST') return _enqueueResponse;
        if (request.url.path == '/jobs/1') {
          pollCount++;
          return http.Response(
            jsonEncode(<String, Object?>{
              'job': <String, Object?>{
                'status': 'Waiting',
                'polling_url': 'https://mindee.test/jobs/1',
                'result_url': pollCount == 1
                    ? null
                    : 'https://mindee.test/results/1',
              },
            }),
            200,
          );
        }
        return _resultResponse;
      });
      final service = _service(
        client,
        initialDelay: const Duration(seconds: 3),
        pollingDelay: const Duration(milliseconds: 1500),
        delay: (duration) async => waits.add(duration),
      );

      await service.analyze(
        image: _image(<int>[1], name: 'receipt.jpg'),
        type: ScanTransactionType.expense,
        cancellationToken: CancellationToken(),
      );

      expect(waits, <Duration>[
        const Duration(seconds: 3),
        const Duration(milliseconds: 1500),
      ]);
      expect(pollCount, 2);
    });

    test('wall-clock timeout stops polling after the initial delay', () async {
      var now = DateTime(2026, 8, 6);
      var pollCount = 0;
      final service = _service(
        MockClient((request) async {
          if (request.method == 'POST') return _enqueueResponse;
          pollCount++;
          return http.Response('', 500);
        }),
        clock: () => now,
        delay: (duration) async => now = now.add(const Duration(seconds: 91)),
      );

      await expectLater(
        service.analyze(
          image: _image(<int>[1], name: 'receipt.jpg'),
          type: ScanTransactionType.expense,
          cancellationToken: CancellationToken(),
        ),
        throwsA(isA<MindeePollingTimeoutException>()),
      );
      expect(pollCount, 0);
    });

    test('slow HTTP responses cannot bypass the wall-clock deadline', () async {
      var now = DateTime(2026, 8, 6);
      var resultRequestCount = 0;
      final service = _service(
        MockClient((request) async {
          if (request.method == 'POST') return _enqueueResponse;
          if (request.url.path == '/jobs/1') {
            now = now.add(const Duration(seconds: 91));
            return _readyPollResponse();
          }
          resultRequestCount++;
          return _resultResponse;
        }),
        clock: () => now,
      );

      await expectLater(
        service.analyze(
          image: _image(<int>[1], name: 'receipt.jpg'),
          type: ScanTransactionType.expense,
          cancellationToken: CancellationToken(),
        ),
        throwsA(isA<MindeePollingTimeoutException>()),
      );
      expect(resultRequestCount, 0);
    });

    test('cancellation before enqueue prevents all requests', () async {
      var requestCount = 0;
      final token = CancellationToken()..cancel();
      final service = _service(
        MockClient((request) async {
          requestCount++;
          return http.Response('', 500);
        }),
      );

      await expectLater(
        service.analyze(
          image: _image(<int>[1], name: 'receipt.jpg'),
          type: ScanTransactionType.expense,
          cancellationToken: token,
        ),
        throwsA(isA<MindeeRequestCancelledException>()),
      );
      expect(requestCount, 0);
    });

    test('cancellation during polling prevents the result request', () async {
      final token = CancellationToken();
      var resultRequestCount = 0;
      final service = _service(
        MockClient((request) async {
          if (request.method == 'POST') return _enqueueResponse;
          if (request.url.path == '/jobs/1') {
            token.cancel();
            return _readyPollResponse();
          }
          resultRequestCount++;
          return _resultResponse;
        }),
      );

      await expectLater(
        service.analyze(
          image: _image(<int>[1], name: 'receipt.jpg'),
          type: ScanTransactionType.expense,
          cancellationToken: token,
        ),
        throwsA(isA<MindeeRequestCancelledException>()),
      );
      expect(resultRequestCount, 0);
    });

    test('failed job status produces a typed exception', () async {
      final service = _service(
        MockClient((request) async {
          if (request.method == 'POST') return _enqueueResponse;
          return http.Response(
            jsonEncode(<String, Object?>{
              'job': <String, Object?>{
                'id': 'job-1',
                'status': 'Failed',
                'polling_url': request.url.toString(),
                'result_url': null,
              },
            }),
            200,
          );
        }),
      );

      await expectLater(
        service.analyze(
          image: _image(<int>[1], name: 'receipt.jpg'),
          type: ScanTransactionType.expense,
          cancellationToken: CancellationToken(),
        ),
        throwsA(isA<MindeeProcessingException>()),
      );
    });
  });

  group('strict field parsing', () {
    test('missing and null fields return null', () {
      const result = MindeeAnalysisResult(
        fields: <String, MindeeFieldValue>{
          'null_string': MindeeFieldValue(),
          'null_number': MindeeFieldValue(),
        },
      );

      expect(result.stringValue('missing'), isNull);
      expect(result.stringValue('null_string'), isNull);
      expect(result.numberValue('missing'), isNull);
      expect(result.numberValue('null_number'), isNull);
    });

    test('present values with the wrong type throw typed exceptions', () {
      const result = MindeeAnalysisResult(
        fields: <String, MindeeFieldValue>{
          'amount': MindeeFieldValue(value: '12.50'),
          'payee': MindeeFieldValue(value: 42),
        },
      );

      expect(
        () => result.numberValue('amount'),
        throwsA(isA<MindeeFieldParseException>()),
      );
      expect(
        () => result.stringValue('payee'),
        throwsA(isA<MindeeFieldParseException>()),
      );
    });

    test('final fields are read only from inference.result.fields', () async {
      final result = await _service(_successfulClient()).analyze(
        image: _image(<int>[1], name: 'receipt.jpeg'),
        type: ScanTransactionType.expense,
        cancellationToken: CancellationToken(),
      );

      expect(result.numberValue('total_amount'), 12.5);
      expect(result.stringValue('polling_only_field'), isNull);
    });
  });

  test('Riverpod provider closes its HTTP client on disposal', () {
    final client = _CloseTrackingClient();
    final container = ProviderContainer(
      overrides: [
        mindeeHttpClientFactoryProvider.overrideWithValue(() => client),
      ],
    );

    expect(container.read(mindeeHttpClientProvider), same(client));
    expect(client.isClosed, isFalse);

    container.dispose();
    expect(client.isClosed, isTrue);
  });
}

MindeeDocumentAnalysisService _service(
  http.Client client, {
  Duration initialDelay = Duration.zero,
  Duration pollingDelay = Duration.zero,
  Duration pollingTimeout = const Duration(seconds: 90),
  DateTime Function()? clock,
  Future<void> Function(Duration)? delay,
}) {
  return MindeeDocumentAnalysisService(
    httpClient: client,
    apiKey: 'raw-test-key',
    expenseModelId: 'expense-model',
    depositModelId: 'deposit-model',
    initialDelay: initialDelay,
    pollingDelay: pollingDelay,
    pollingTimeout: pollingTimeout,
    clock: clock,
    delay: delay,
  );
}

XFile _image(List<int> bytes, {required String name}) {
  return XFile.fromData(Uint8List.fromList(bytes), name: name, path: name);
}

MockClient _successfulClient({
  void Function(http.Request request)? onEnqueue,
  String pollStatus = 'Success',
}) {
  return MockClient((request) async {
    if (request.method == 'POST') {
      onEnqueue?.call(request);
      return _enqueueResponse;
    }
    if (request.url.path == '/jobs/1') {
      return _readyPollResponse(status: pollStatus);
    }
    if (request.url.path == '/results/1') return _resultResponse;
    return http.Response('not found', 404);
  });
}

http.Response get _enqueueResponse => http.Response(
  jsonEncode(<String, Object?>{
    'job': <String, Object?>{
      'id': 'job-1',
      'status': 'Waiting',
      'polling_url': 'https://mindee.test/jobs/1',
      'result_url': null,
    },
  }),
  200,
);

http.Response _readyPollResponse({String status = 'Success'}) => http.Response(
  jsonEncode(<String, Object?>{
    'job': <String, Object?>{
      'id': 'job-1',
      'status': status,
      'polling_url': 'https://mindee.test/jobs/1',
      'result_url': 'https://mindee.test/results/1',
      'fields': <String, Object?>{
        'polling_only_field': <String, Object?>{'value': 'ignored'},
      },
    },
  }),
  200,
);

http.Response get _resultResponse => http.Response(
  jsonEncode(<String, Object?>{
    'inference': <String, Object?>{
      'id': 'inference-1',
      'result': <String, Object?>{
        'fields': <String, Object?>{
          'total_amount': <String, Object?>{'value': 12.5},
        },
      },
    },
  }),
  200,
);

class _CloseTrackingClient extends http.BaseClient {
  bool isClosed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }

  @override
  void close() {
    isClosed = true;
    super.close();
  }
}
