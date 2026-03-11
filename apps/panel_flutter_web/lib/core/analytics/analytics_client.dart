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
  final rand = Random();
  final time = DateTime.now().microsecondsSinceEpoch;
  final salt = rand.nextDouble().toString().split('.').last.padRight(8, '0');
  return '$time-$salt';
}
