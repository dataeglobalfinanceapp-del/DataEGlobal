import 'dart:io';
import 'dart:typed_data';

Future<String> printPdfFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
    throw UnsupportedError('PDF printing is available on web and desktop.');
  }

  final directory = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}biztrack_print',
  );
  await directory.create(recursive: true);

  final safeFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
  final file = File('${directory.path}${Platform.pathSeparator}$safeFileName');
  await file.writeAsBytes(bytes, flush: true);

  if (Platform.isWindows) {
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      "Start-Process -FilePath '${_powerShellQuote(file.path)}' -Verb Print",
    ]);
    if (result.exitCode != 0) {
      throw Exception(_processError(result));
    }
    return 'Sent to default printer';
  }

  final result = await Process.run('lp', [file.path]);
  if (result.exitCode != 0) {
    throw Exception(_processError(result));
  }
  return 'Sent to default printer';
}

String _powerShellQuote(String value) => value.replaceAll("'", "''");

String _processError(ProcessResult result) {
  final stderr = result.stderr.toString().trim();
  final stdout = result.stdout.toString().trim();
  if (stderr.isNotEmpty) return stderr;
  if (stdout.isNotEmpty) return stdout;
  return 'Printer command failed with exit code ${result.exitCode}.';
}
