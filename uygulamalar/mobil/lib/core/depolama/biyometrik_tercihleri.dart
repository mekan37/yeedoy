import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Biyometrik giriş tercihleri ve oturum token saklama.
class BiyometrikTercihleri {
  const BiyometrikTercihleri._();

  static const _enabledKey  = 'biyometrik_giris_aktif_v1';
  static const _accessKey   = 'biyometrik_access_token_v1';
  static const _refreshKey  = 'biyometrik_refresh_token_v1';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Tercih ────────────────────────────────────────────────────────────────

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (!value) await clearTokens();
  }

  // ── Token saklama ─────────────────────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey,  value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  static Future<({String? accessToken, String? refreshToken})> loadTokens() async {
    final access  = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    return (accessToken: access, refreshToken: refresh);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  static Future<bool> hasStoredTokens() async {
    final refresh = await _storage.read(key: _refreshKey);
    return refresh != null && refresh.isNotEmpty;
  }
}
