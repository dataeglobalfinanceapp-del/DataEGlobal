import 'dart:typed_data';

import 'pdf_exporter_stub.dart'
    if (dart.library.html) 'pdf_exporter_web.dart'
    if (dart.library.io) 'pdf_exporter_io.dart';

class PdfExporter {
  static Future<String> savePdf({
    required String fileName,
    required Uint8List bytes,
  }) {
    return savePdfFile(fileName: fileName, bytes: bytes);
  }
}
