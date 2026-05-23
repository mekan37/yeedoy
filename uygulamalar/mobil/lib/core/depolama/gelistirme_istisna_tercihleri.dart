import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Developer test overrides — only active in debug/profile builds.
// Uses FlutterSecureStorage (EncryptedSharedPreferences on Android,
// Keychain on iOS) to prevent other apps reading test credentials.
class DevOverridesPrefs {
  static const _kTestUserId = 'dev_test_user_id_v1';
  static const _kTestCity = 'dev_test_city_v1';
  static const _kTestDistrict = 'dev_test_district_v1';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // In production builds all operations are no-ops.
  static bool get _enabled => !kReleaseMode;

  static Future<(String? userId, String? city, String? district)> read() async {
    if (!_enabled) return (null, null, null);
    final userId = await _storage.read(key: _kTestUserId);
    final city = await _storage.read(key: _kTestCity);
    final district = await _storage.read(key: _kTestDistrict);
    return (userId, city, district);
  }

  static Future<void> setTestUserId(String? userId) async {
    if (!_enabled) return;
    final value = userId?.trim() ?? '';
    if (value.isEmpty) {
      await _storage.delete(key: _kTestUserId);
      return;
    }
    await _storage.write(key: _kTestUserId, value: value);
  }

  static Future<void> setTestLocation({
    required String city,
    required String district,
  }) async {
    if (!_enabled) return;
    await _storage.write(key: _kTestCity, value: city.trim());
    await _storage.write(key: _kTestDistrict, value: district.trim());
  }

  static Future<void> clearTestLocation() async {
    if (!_enabled) return;
    await _storage.delete(key: _kTestCity);
    await _storage.delete(key: _kTestDistrict);
  }

  static Future<void> clearAll() async {
    if (!_enabled) return;
    await _storage.delete(key: _kTestUserId);
    await _storage.delete(key: _kTestCity);
    await _storage.delete(key: _kTestDistrict);
  }
}
