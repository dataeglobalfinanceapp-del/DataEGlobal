import 'local_store_stub.dart'
    if (dart.library.html) 'local_store_web.dart'
    if (dart.library.io) 'local_store_io.dart';

class LocalStore {
  static Future<String?> read(String key) => readLocalValue(key);

  static Future<void> write(String key, String value) =>
      writeLocalValue(key, value);
}
