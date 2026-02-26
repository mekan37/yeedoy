import 'package:shared_preferences/shared_preferences.dart';

class InboxPrefs {
  static const _readIdsKey = 'inbox_read_ids_v1';

  static Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_readIdsKey) ?? const <String>[];
    return values.where((e) => e.trim().isNotEmpty).toSet();
  }

  static Future<void> saveReadIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey, ids.toList()..sort());
  }
}
