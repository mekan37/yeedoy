import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPrefs {
  static const _kCity = 'pref_city';
  static const _kDistrict = 'pref_district';
  static const _kNeighborhood = 'pref_neighborhood';
  static const _kRecent = 'pref_recent_locations'; // json list

  static Future<(String city, String district)?> read() async {
    final sp = await SharedPreferences.getInstance();
    final city = sp.getString(_kCity);
    final district = sp.getString(_kDistrict);
    if (city == null || district == null) return null;
    return (city, district);
  }

  static Future<(String city, String district, String? neighborhood)?>
  readExtended() async {
    final sp = await SharedPreferences.getInstance();
    final city = sp.getString(_kCity);
    final district = sp.getString(_kDistrict);
    if (city == null || district == null) return null;
    final neighborhood = sp.getString(_kNeighborhood);
    return (city, district, neighborhood);
  }

  static Future<void> save({
    required String city,
    required String district,
    String? neighborhood,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCity, city);
    await sp.setString(_kDistrict, district);
    if (neighborhood == null || neighborhood.trim().isEmpty) {
      await sp.remove(_kNeighborhood);
    } else {
      await sp.setString(_kNeighborhood, neighborhood.trim());
    }
    await addRecent(city: city, district: district);
  }

  static Future<List<(String city, String district)>> readRecent() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kRecent);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list
          .map(
            (e) => (
              (e['city'] ?? '').toString(),
              (e['district'] ?? '').toString(),
            ),
          )
          .where((t) => t.$1.isNotEmpty && t.$2.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addRecent({
    required String city,
    required String district,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final existing = await readRecent();

    // remove if already exists
    final cleaned = existing
        .where((t) => !(t.$1 == city && t.$2 == district))
        .toList();

    // prepend new
    cleaned.insert(0, (city, district));

    // cap
    final capped = cleaned.take(5).toList();

    final jsonList = capped
        .map((t) => {'city': t.$1, 'district': t.$2})
        .toList();
    await sp.setString(_kRecent, jsonEncode(jsonList));
  }
}
