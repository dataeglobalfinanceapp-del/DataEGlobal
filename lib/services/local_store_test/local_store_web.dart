import 'package:web/web.dart' as web;

Future<String?> readLocalValue(String key) async =>
    web.window.localStorage.getItem(key);

Future<void> writeLocalValue(String key, String value) async {
  web.window.localStorage.setItem(key, value);
}
