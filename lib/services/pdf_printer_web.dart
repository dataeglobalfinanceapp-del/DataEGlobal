// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<String> printPdfFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final frame = html.IFrameElement()
    ..src = url
    ..style.position = 'fixed'
    ..style.right = '0'
    ..style.bottom = '0'
    ..style.width = '0'
    ..style.height = '0'
    ..style.border = '0';

  html.document.body?.children.add(frame);
  await frame.onLoad.first.timeout(
    const Duration(seconds: 3),
    onTimeout: () => html.Event('timeout'),
  );
  final printWindow = frame.contentWindow;
  if (printWindow != null) {
    final dynamic window = printWindow;
    window.focus();
    window.print();
  }

  Timer(const Duration(minutes: 1), () {
    frame.remove();
    html.Url.revokeObjectUrl(url);
  });

  return 'Print dialog opened';
}
