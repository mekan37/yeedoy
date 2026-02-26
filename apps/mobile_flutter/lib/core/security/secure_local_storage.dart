import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  late final SharedPreferencesLocalStorage _webFallback =
      SharedPreferencesLocalStorage(persistSessionKey: persistSessionKey);

  @override
  Future<void> initialize() async {
    if (kIsWeb) {
      await _webFallback.initialize();
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    if (kIsWeb) {
      return _webFallback.hasAccessToken();
    }
    final token = await _secureStorage.read(key: persistSessionKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> accessToken() async {
    if (kIsWeb) {
      return _webFallback.accessToken();
    }
    return _secureStorage.read(key: persistSessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    if (kIsWeb) {
      await _webFallback.removePersistedSession();
      return;
    }
    await _secureStorage.delete(key: persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (kIsWeb) {
      await _webFallback.persistSession(persistSessionString);
      return;
    }
    await _secureStorage.write(
      key: persistSessionKey,
      value: persistSessionString,
    );
  }
}
