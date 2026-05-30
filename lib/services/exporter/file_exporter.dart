import 'dart:typed_data';

import 'file_exporter_stub.dart'
    if (dart.library.html) 'file_exporter_web.dart'
    if (dart.library.io) 'file_exporter_io.dart';

class FileExporter {
  static Future<String> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) {
    return saveFile(fileName: fileName, bytes: bytes, mimeType: mimeType);
  }
}
