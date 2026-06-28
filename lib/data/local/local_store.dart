import 'local_store_stub.dart'
    if (dart.library.html) 'local_store_web.dart'
    if (dart.library.io) 'local_store_io.dart';

class LocalStore {
  static Future<String?> Function(String key)? _readOverride;
  static Future<void> Function(String key, String value)? _writeOverride;

  static Future<String?> read(String key) {
    final readOverride = _readOverride;
    if (readOverride != null) return readOverride(key);

    return readLocalValue(key);
  }

  static Future<void> write(String key, String value) {
    final writeOverride = _writeOverride;
    if (writeOverride != null) return writeOverride(key, value);

    return writeLocalValue(key, value);
  }

  static void setOverridesForTesting({
    required Future<String?> Function(String key) read,
    required Future<void> Function(String key, String value) write,
  }) {
    _readOverride = read;
    _writeOverride = write;
  }

  static void resetOverridesForTesting() {
    _readOverride = null;
    _writeOverride = null;
  }
}
