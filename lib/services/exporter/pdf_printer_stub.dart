import 'dart:typed_data';

Future<String> printPdfFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  throw UnsupportedError('PDF printing is not available on this platform.');
}
