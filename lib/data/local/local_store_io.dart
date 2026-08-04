import 'dart:io';

import 'package:path_provider/path_provider.dart';

typedef LocalStoreDirectoryProvider = Future<Directory> Function();

Future<String?> readLocalValue(
  String key, {
  LocalStoreDirectoryProvider? directoryProvider,
}) async {
  final file = await localStoreFile(key, directoryProvider: directoryProvider);
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> writeLocalValue(
  String key,
  String value, {
  LocalStoreDirectoryProvider? directoryProvider,
}) async {
  final file = await localStoreFile(key, directoryProvider: directoryProvider);
  await file.parent.create(recursive: true);
  await file.writeAsString(value);
}

Future<File> localStoreFile(
  String key, {
  LocalStoreDirectoryProvider? directoryProvider,
}) async {
  final root = await (directoryProvider ?? getApplicationSupportDirectory)();
  final directory = Directory(
    '${root.path}${Platform.pathSeparator}savetep'
    '${Platform.pathSeparator}local_data',
  );

  return File('${directory.path}${Platform.pathSeparator}$key.json');
}
