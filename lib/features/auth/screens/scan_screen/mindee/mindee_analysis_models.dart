import 'dart:convert';

enum ScanTransactionType { deposit, expense }

class CancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const MindeeRequestCancelledException();
    }
  }
}

class MindeeAnalysisResult {
  final String? inferenceId;
  final Map<String, MindeeFieldValue> fields;

  const MindeeAnalysisResult({this.inferenceId, required this.fields});

  String? stringValue(String name) {
    final field = fields[name];
    if (field == null || field.value == null) return null;

    final value = field.value;
    if (value is String) {
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }

    throw MindeeFieldParseException(
      fieldName: name,
      expectedType: 'string',
      actualType: value.runtimeType.toString(),
    );
  }

  double? numberValue(String name) {
    final field = fields[name];
    if (field == null || field.value == null) return null;

    final value = field.value;
    if (value is num) return value.toDouble();

    throw MindeeFieldParseException(
      fieldName: name,
      expectedType: 'number',
      actualType: value.runtimeType.toString(),
    );
  }
}

class MindeeFieldValue {
  final Object? value;
  final String? confidence;

  const MindeeFieldValue({this.value, this.confidence});
}

class MindeeFieldParseException implements FormatException {
  final String fieldName;
  final String expectedType;
  final String actualType;

  const MindeeFieldParseException({
    required this.fieldName,
    required this.expectedType,
    required this.actualType,
  });

  @override
  String get message =>
      'Mindee field "$fieldName" expected $expectedType but received $actualType.';

  @override
  int? get offset => null;

  @override
  Object? get source => null;

  @override
  String toString() => 'MindeeFieldParseException: $message';
}

class MindeeResponseParseException implements FormatException {
  @override
  final String message;

  const MindeeResponseParseException(this.message);

  @override
  int? get offset => null;

  @override
  Object? get source => null;

  @override
  String toString() => 'MindeeResponseParseException: $message';
}

class MindeeRequestCancelledException implements Exception {
  const MindeeRequestCancelledException();

  @override
  String toString() => 'Mindee request cancelled.';
}

class MindeePollingTimeoutException implements Exception {
  const MindeePollingTimeoutException();

  @override
  String toString() => 'Mindee processing timed out.';
}

class MindeeProcessingException implements Exception {
  final String? jobId;
  final String? status;

  const MindeeProcessingException({this.jobId, this.status});

  @override
  String toString() =>
      'Mindee processing failed (job: ${jobId ?? 'unknown'}, status: ${status ?? 'unknown'}).';
}

class MindeeHttpException implements Exception {
  final int statusCode;

  const MindeeHttpException(this.statusCode);

  @override
  String toString() => 'Mindee request failed with status $statusCode.';
}

Map<String, dynamic> decodeJsonObject(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException catch (error) {
    throw MindeeResponseParseException('Mindee returned invalid JSON: $error');
  }

  if (decoded is! Map<String, dynamic>) {
    throw const MindeeResponseParseException(
      'Mindee response must be a JSON object.',
    );
  }
  return decoded;
}

Map<String, dynamic> requireMap(Map<String, dynamic> parent, String key) {
  final value = parent[key];
  if (value is Map<String, dynamic>) return value;

  throw MindeeResponseParseException(
    'Mindee response field "$key" must be an object.',
  );
}

String? readNullableString(Map<String, dynamic> parent, String key) {
  final value = parent[key];
  if (value == null) return null;
  if (value is String) return value;

  throw MindeeFieldParseException(
    fieldName: key,
    expectedType: 'string',
    actualType: value.runtimeType.toString(),
  );
}

String? readOptionalStringField(Map<String, dynamic> fields, String fieldName) {
  final field = fields[fieldName];
  if (field == null) return null;
  if (field is! Map<String, dynamic>) {
    throw MindeeFieldParseException(
      fieldName: fieldName,
      expectedType: 'field object',
      actualType: field.runtimeType.toString(),
    );
  }

  final value = field['value'];
  if (value == null) return null;
  if (value is String) return value;

  throw MindeeFieldParseException(
    fieldName: fieldName,
    expectedType: 'string',
    actualType: value.runtimeType.toString(),
  );
}

double? readOptionalNumberField(Map<String, dynamic> fields, String fieldName) {
  final field = fields[fieldName];
  if (field == null) return null;
  if (field is! Map<String, dynamic>) {
    throw MindeeFieldParseException(
      fieldName: fieldName,
      expectedType: 'field object',
      actualType: field.runtimeType.toString(),
    );
  }

  final value = field['value'];
  if (value == null) return null;
  if (value is num) return value.toDouble();

  throw MindeeFieldParseException(
    fieldName: fieldName,
    expectedType: 'number',
    actualType: value.runtimeType.toString(),
  );
}
