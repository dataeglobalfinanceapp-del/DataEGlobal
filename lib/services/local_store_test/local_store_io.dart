import 'dart:io';

Future<String?> readLocalValue(String key) async {
  final file = await _storeFile(key);
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> writeLocalValue(String key, String value) async {
  final file = await _storeFile(key);
  await file.parent.create(recursive: true);
  await file.writeAsString(value);
}

Future<File> _storeFile(String key) async {
  final root =
      Platform.environment['APPDATA'] ??
      Platform.environment['HOME'] ??
      Directory.current.path;
  final directory = Directory(
    '$root${Platform.pathSeparator}BizTrack${Platform.pathSeparator}local_data',
  );

  return File('$directory${Platform.pathSeparator}$key.json');
}
