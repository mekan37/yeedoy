import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

const _clientIdKey = 'analytics_client_id';

Future<String> getAnalyticsClientId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_clientIdKey);
  if (existing != null && existing.trim().isNotEmpty) {
    return existing;
  }
  final created = _generateClientId();
  await prefs.setString(_clientIdKey, created);
  return created;
}

String _generateClientId() {
  // Random() (kriptografik olmayan) yerine Random.secure(): bu client_id
  // sunucu tarafında bazı günlük rate-limit anahtarlarının bir parçası —
  // tahmin edilebilir olması limiti kolayca aşmayı mümkün kılıyordu.
  final rand = Random.secure();
  final time = DateTime.now().microsecondsSinceEpoch;
  final salt = rand.nextInt(1 << 32);
  return '$time-$salt';
}
