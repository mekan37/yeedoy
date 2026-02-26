import 'package:shared_preferences/shared_preferences.dart';

class DevOverridesPrefs {
  static const _kTestUserId = 'dev_test_user_id_v1';
  static const _kTestCity = 'dev_test_city_v1';
  static const _kTestDistrict = 'dev_test_district_v1';

  static Future<(String? userId, String? city, String? district)> read() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getString(_kTestUserId),
      prefs.getString(_kTestCity),
      prefs.getString(_kTestDistrict),
    );
  }

  static Future<void> setTestUserId(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final value = userId?.trim() ?? '';
    if (value.isEmpty) {
      await prefs.remove(_kTestUserId);
      return;
    }
    await prefs.setString(_kTestUserId, value);
  }

  static Future<void> setTestLocation({
    required String city,
    required String district,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTestCity, city.trim());
    await prefs.setString(_kTestDistrict, district.trim());
  }

  static Future<void> clearTestLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTestCity);
    await prefs.remove(_kTestDistrict);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTestUserId);
    await prefs.remove(_kTestCity);
    await prefs.remove(_kTestDistrict);
  }
}
