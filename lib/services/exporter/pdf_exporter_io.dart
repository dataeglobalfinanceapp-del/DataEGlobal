import 'dart:io';
import 'dart:typed_data';

Future<String> savePdfFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  final directory = await _downloadDirectory();
  await directory.create(recursive: true);

  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<Directory> _downloadDirectory() async {
  final userProfile = Platform.environment['USERPROFILE'];
  if (userProfile != null && userProfile.isNotEmpty) {
    return Directory('$userProfile${Platform.pathSeparator}Downloads');
  }

  final home = Platform.environment['HOME'];
  if (home != null && home.isNotEmpty) {
    return Directory('$home${Platform.pathSeparator}Downloads');
  }

  return Directory.current;
}
