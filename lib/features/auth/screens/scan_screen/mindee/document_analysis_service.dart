import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'mindee_analysis_models.dart';
import 'mindee_config.dart';

abstract interface class DocumentAnalysisService {
  Future<MindeeAnalysisResult> analyze({
    required XFile image,
    required ScanTransactionType type,
    required CancellationToken cancellationToken,
  });
}

class MindeeDocumentAnalysisService implements DocumentAnalysisService {
  static const int maximumFileSizeBytes = 10 * 1024 * 1024;

  final http.Client httpClient;
  final String apiKey;
  final String expenseModelId;
  final String depositModelId;
  final String enqueueUrl;
  final Duration initialDelay;
  final Duration pollingDelay;
  final Duration pollingTimeout;
  final DateTime Function()? clock;
  final Future<void> Function(Duration)? delay;

  const MindeeDocumentAnalysisService({
    required this.httpClient,
    this.apiKey = MindeeConfig.apiKey,
    this.expenseModelId = MindeeConfig.expenseModelId,
    this.depositModelId = MindeeConfig.depositModelId,
    this.enqueueUrl = MindeeConfig.enqueueUrl,
    this.initialDelay = MindeePollingOptions.initialDelay,
    this.pollingDelay = MindeePollingOptions.pollingDelay,
    this.pollingTimeout = MindeePollingOptions.timeout,
    this.clock,
    this.delay,
  });

  Map<String, String> get _headers => <String, String>{
    'Authorization': apiKey,
    'Accept': 'application/json',
  };

  DateTime _now() => clock?.call() ?? DateTime.now();

  Future<void> _wait(Duration duration) =>
      delay?.call(duration) ?? Future<void>.delayed(duration);

  String modelIdFor(ScanTransactionType type) {
    return switch (type) {
      ScanTransactionType.expense => expenseModelId,
      ScanTransactionType.deposit => depositModelId,
    };
  }

  @override
  Future<MindeeAnalysisResult> analyze({
    required XFile image,
    required ScanTransactionType type,
    required CancellationToken cancellationToken,
  }) async {
    MindeeConfig.validate(
      apiKeyValue: apiKey,
      expenseModelIdValue: expenseModelId,
      depositModelIdValue: depositModelId,
    );
    if (kReleaseMode) {
      throw StateError(
        'Direct Mindee analysis is disabled in release builds. Use it only for private local testing.',
      );
    }

    cancellationToken.throwIfCancelled();
    final mediaType = mediaTypeForFileName(image.name);
    final declaredLength = await image.length();
    cancellationToken.throwIfCancelled();
    if (declaredLength > maximumFileSizeBytes) {
      throw const FileSizeLimitExceededException();
    }

    cancellationToken.throwIfCancelled();
    final bytes = await image.readAsBytes();
    cancellationToken.throwIfCancelled();
    if (bytes.isEmpty) throw const EmptyDocumentException();
    if (bytes.length > maximumFileSizeBytes) {
      throw const FileSizeLimitExceededException();
    }

    final request = http.MultipartRequest('POST', Uri.parse(enqueueUrl))
      ..headers.addAll(_headers)
      ..fields['model_id'] = modelIdFor(type)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
          contentType: mediaType,
        ),
      );

    cancellationToken.throwIfCancelled();
    final streamedResponse = await httpClient.send(request);
    cancellationToken.throwIfCancelled();
    final response = await http.Response.fromStream(streamedResponse);
    cancellationToken.throwIfCancelled();
    _validateHttpResponse(response);

    final decoded = decodeJsonObject(response.body);
    final job = requireMap(decoded, 'job');
    final initialResultUrl = readNullableString(job, 'result_url');
    final initialStatus = readNullableString(job, 'status');
    if (isFailedJobStatus(initialStatus)) {
      throw MindeeProcessingException(
        jobId: readNullableString(job, 'id'),
        status: initialStatus,
      );
    }
    final resultUrl =
        initialResultUrl != null && initialResultUrl.trim().isNotEmpty
        ? initialResultUrl
        : await waitForResultUrl(
            initialPollingUrl: _requirePollingUrl(job),
            cancellationToken: cancellationToken,
          );

    cancellationToken.throwIfCancelled();
    final resultResponse = await httpClient.get(
      Uri.parse(resultUrl),
      headers: _headers,
    );
    cancellationToken.throwIfCancelled();
    _validateHttpResponse(resultResponse);
    cancellationToken.throwIfCancelled();

    return _parseFinalResult(decodeJsonObject(resultResponse.body));
  }

  Future<String> waitForResultUrl({
    required String initialPollingUrl,
    required CancellationToken cancellationToken,
  }) async {
    final deadline = _now().add(pollingTimeout);

    cancellationToken.throwIfCancelled();
    await _wait(initialDelay);
    cancellationToken.throwIfCancelled();

    var pollingUrl = initialPollingUrl;
    while (true) {
      cancellationToken.throwIfCancelled();
      _throwIfTimedOut(deadline);

      final remaining = deadline.difference(_now());
      cancellationToken.throwIfCancelled();
      final pollingUri = Uri.parse(pollingUrl);
      final pollingRequest = http.Request('GET', pollingUri)
        ..headers.addAll(_headers)
        ..followRedirects = false;
      final response = await httpClient
          .send(pollingRequest)
          .then(http.Response.fromStream)
          .timeout(
            remaining,
            onTimeout: () => throw const MindeePollingTimeoutException(),
          );
      cancellationToken.throwIfCancelled();
      _throwIfTimedOut(deadline);

      final redirectResultUrl = _readRedirectResultUrl(response, pollingUri);
      if (redirectResultUrl != null) return redirectResultUrl;

      _validateHttpResponse(response);

      final decoded = decodeJsonObject(response.body);
      final job = requireMap(decoded, 'job');
      final resultUrl = readNullableString(job, 'result_url');
      if (resultUrl != null && resultUrl.trim().isNotEmpty) {
        return resultUrl;
      }

      final status = readNullableString(job, 'status');
      if (isFailedJobStatus(status)) {
        throw MindeeProcessingException(
          jobId: readNullableString(job, 'id'),
          status: status,
        );
      }

      final updatedPollingUrl = readNullableString(job, 'polling_url');
      if (updatedPollingUrl != null && updatedPollingUrl.trim().isNotEmpty) {
        pollingUrl = updatedPollingUrl;
      }

      cancellationToken.throwIfCancelled();
      await _wait(pollingDelay);
      cancellationToken.throwIfCancelled();
    }
  }

  String? _readRedirectResultUrl(http.Response response, Uri pollingUri) {
    if (!_isRedirectStatus(response.statusCode)) return null;

    final location = response.headers['location'];
    if (location == null || location.trim().isEmpty) {
      throw const MindeeResponseParseException(
        'Mindee polling redirect did not include a location header.',
      );
    }

    return pollingUri.resolve(location.trim()).toString();
  }

  String _requirePollingUrl(Map<String, dynamic> job) {
    final pollingUrl = readNullableString(job, 'polling_url');
    if (pollingUrl == null || pollingUrl.trim().isEmpty) {
      throw const MindeeResponseParseException(
        'Mindee enqueue response did not include job.polling_url.',
      );
    }
    return pollingUrl;
  }

  MindeeAnalysisResult _parseFinalResult(Map<String, dynamic> decoded) {
    final inference = requireMap(decoded, 'inference');
    final result = requireMap(inference, 'result');
    final rawFields = requireMap(result, 'fields');
    final fields = <String, MindeeFieldValue>{};

    for (final entry in rawFields.entries) {
      final rawField = entry.value;
      if (rawField is! Map<String, dynamic>) {
        throw MindeeFieldParseException(
          fieldName: entry.key,
          expectedType: 'field object',
          actualType: rawField.runtimeType.toString(),
        );
      }

      final confidence = rawField['confidence'];
      if (confidence != null && confidence is! String && confidence is! num) {
        throw MindeeFieldParseException(
          fieldName: '${entry.key}.confidence',
          expectedType: 'string or number',
          actualType: confidence.runtimeType.toString(),
        );
      }
      fields[entry.key] = MindeeFieldValue(
        value: rawField['value'],
        confidence: confidence?.toString(),
      );
    }

    return MindeeAnalysisResult(
      inferenceId: readNullableString(inference, 'id'),
      fields: Map<String, MindeeFieldValue>.unmodifiable(fields),
    );
  }

  void _throwIfTimedOut(DateTime deadline) {
    if (_now().isAfter(deadline)) {
      throw const MindeePollingTimeoutException();
    }
  }

  void _validateHttpResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    switch (response.statusCode) {
      case 400:
        debugPrint('Invalid Mindee request or malformed multipart data.');
      case 401:
        debugPrint('Mindee authentication failed. Check MINDEE_V2_API_KEY.');
      case 402:
        debugPrint('Mindee quota, plan, or billing restriction.');
      case 422:
        debugPrint('Mindee rejected the document or model input.');
      case 429:
        debugPrint('Mindee rate limit reached. Retry later.');
        _logRetryHeaders(response.headers);
      default:
        if (response.statusCode >= 500 && response.statusCode <= 599) {
          debugPrint('Mindee service error.');
        } else {
          debugPrint(
            'Mindee request failed with status ${response.statusCode}.',
          );
        }
    }
    throw MindeeHttpException(response.statusCode);
  }

  void _logRetryHeaders(Map<String, String> headers) {
    const safeHeaderNames = <String>{
      'retry-after',
      'x-ratelimit-limit',
      'x-ratelimit-remaining',
      'x-ratelimit-reset',
    };
    for (final name in safeHeaderNames) {
      final value = headers[name];
      if (value != null) debugPrint('Mindee $name: $value');
    }
  }
}

bool _isRedirectStatus(int statusCode) {
  return statusCode == 301 ||
      statusCode == 302 ||
      statusCode == 303 ||
      statusCode == 307 ||
      statusCode == 308;
}

http.MediaType mediaTypeForFileName(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return http.MediaType('image', 'jpeg');
  }
  if (lower.endsWith('.png')) {
    return http.MediaType('image', 'png');
  }

  throw UnsupportedError('Only JPG, JPEG, and PNG images are supported.');
}

bool isFailedJobStatus(String? status) {
  final normalized = status?.trim().toLowerCase();
  return normalized == 'failed' ||
      normalized == 'failure' ||
      normalized == 'error' ||
      normalized == 'cancelled' ||
      normalized == 'canceled';
}

class EmptyDocumentException implements Exception {
  const EmptyDocumentException();

  @override
  String toString() => 'The selected image is empty.';
}

class FileSizeLimitExceededException implements Exception {
  const FileSizeLimitExceededException();

  @override
  String toString() => 'The selected image exceeds the 10 MB limit.';
}
