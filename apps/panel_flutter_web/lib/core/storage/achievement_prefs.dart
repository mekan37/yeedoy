import 'package:shared_preferences/shared_preferences.dart';

class AchievementPrefs {
  static const _kSeenUnlockedIds = 'achievement_seen_unlocked_ids_v1';

  static Future<Set<String>> getSeenUnlockedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kSeenUnlockedIds) ?? const <String>[];
    return list.where((e) => e.trim().isNotEmpty).toSet();
  }

  static Future<void> saveSeenUnlockedIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final values = ids.toList()..sort();
    await prefs.setStringList(_kSeenUnlockedIds, values);
  }
}
