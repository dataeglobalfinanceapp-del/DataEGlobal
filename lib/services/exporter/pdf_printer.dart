import 'dart:typed_data';

import 'pdf_printer_stub.dart'
    if (dart.library.html) 'pdf_printer_web.dart'
    if (dart.library.io) 'pdf_printer_io.dart';

class PdfPrinter {
  static Future<String> printPdf({
    required String fileName,
    required Uint8List bytes,
  }) {
    return printPdfFile(fileName: fileName, bytes: bytes);
  }
}
