import 'package:shared_preferences/shared_preferences.dart';

class FeatureFlagsPrefs {
  static const _kPrefix = 'ff_';

  static Future<Map<String, bool>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_kPrefix));
    final result = <String, bool>{};
    for (final key in keys) {
      final value = prefs.getBool(key);
      if (value != null) {
        result[key.substring(_kPrefix.length)] = value;
      }
    }
    return result;
  }

  static Future<bool?> readFlag(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_kPrefix$key');
  }

  static Future<void> setFlag(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kPrefix$key', value);
  }

  static Future<void> removeFlag(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kPrefix$key');
  }
}
