final Map<String, String> _values = {};

Future<String?> readLocalValue(String key) async => _values[key];

Future<void> writeLocalValue(String key, String value) async {
  _values[key] = value;
}
