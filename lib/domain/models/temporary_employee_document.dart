import 'dart:typed_data';

class TemporaryEmployeeDocument {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final DateTime createdAt;

  const TemporaryEmployeeDocument({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.createdAt,
  });

  int get sizeBytes => bytes.lengthInBytes;
}
