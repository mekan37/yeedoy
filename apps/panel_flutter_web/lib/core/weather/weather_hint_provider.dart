import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

final weatherHintProvider = FutureProvider<String?>((ref) async {
  ref.keepAlive();
  return WeatherHintRepository.instance.getHint();
});

class WeatherHintRepository {
  WeatherHintRepository._();

  static final WeatherHintRepository instance = WeatherHintRepository._();

  DateTime? _lastFetch;
  String? _lastHint;

  Future<String?> getHint() async {
    final now = DateTime.now();
    if (_lastFetch != null &&
        now.difference(_lastFetch!) < const Duration(minutes: 30)) {
      return _lastHint;
    }

    final position = await _getPosition();
    if (position == null) return null;

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': position.latitude.toStringAsFixed(4),
      'longitude': position.longitude.toStringAsFixed(4),
      'current': 'weather_code,temperature_2m,precipitation',
      'timezone': 'auto',
    });

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      final code = (current?['weather_code'] as num?)?.toInt();
      final precipitation = (current?['precipitation'] as num?)?.toDouble();
      final temperature = (current?['temperature_2m'] as num?)?.toDouble();
      final hint = _hintFor(
        code: code,
        precipitation: precipitation,
        temperature: temperature,
      );
      _lastFetch = now;
      _lastHint = hint;
      return hint;
    } catch (_) {
      return null;
    }
  }

  Future<Position?> _getPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

String? _hintFor({
  required int? code,
  required double? precipitation,
  required double? temperature,
}) {
  final rainCodes = <int>{
    51,
    53,
    55,
    56,
    57,
    61,
    63,
    65,
    66,
    67,
    80,
    81,
    82,
    95,
    96,
    99,
  };
  final snowCodes = <int>{71, 73, 75, 77, 85, 86};
  final clearCodes = <int>{0, 1, 2};

  if ((precipitation ?? 0) >= 0.2 ||
      (code != null && rainCodes.contains(code))) {
    return 'Yağmurlu hava • sıcak bir şey iyi gider';
  }
  if (code != null && snowCodes.contains(code)) {
    return 'Soğuk hava • sıcak çorba iyi gider';
  }
  if (temperature != null && temperature >= 28) {
    return 'Sıcak hava • serin bir şey iyi gider';
  }
  if (code != null && clearCodes.contains(code)) {
    return 'Hava açık • dış mekân keyifli';
  }
  return null;
}
