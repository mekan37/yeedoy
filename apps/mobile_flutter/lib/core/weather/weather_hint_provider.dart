import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

final weatherHintDataProvider = FutureProvider<WeatherHintData?>((ref) async {
  ref.keepAlive();
  return WeatherHintRepository.instance.getData();
});

final weatherHintProvider = FutureProvider<String?>((ref) async {
  final data = await ref.watch(weatherHintDataProvider.future);
  if (data == null) return null;
  return _backendHintForKind(data.kind);
});

enum WeatherHintKind { rainy, snowy, hot, clear }

class WeatherHintData {
  const WeatherHintData({
    required this.kind,
    this.weatherCode,
    this.temperatureC,
    this.precipitationMm,
  });

  final WeatherHintKind kind;
  final int? weatherCode;
  final double? temperatureC;
  final double? precipitationMm;
}

class WeatherHintRepository {
  WeatherHintRepository._();

  static final WeatherHintRepository instance = WeatherHintRepository._();

  DateTime? _lastFetch;
  WeatherHintData? _lastData;

  Future<WeatherHintData?> getData() async {
    final now = DateTime.now();
    if (_lastFetch != null &&
        now.difference(_lastFetch!) < const Duration(minutes: 30)) {
      return _lastData;
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
      final kind = _kindFor(
        code: code,
        precipitation: precipitation,
        temperature: temperature,
      );
      if (kind == null) return null;
      final next = WeatherHintData(
        kind: kind,
        weatherCode: code,
        temperatureC: temperature,
        precipitationMm: precipitation,
      );
      _lastFetch = now;
      _lastData = next;
      return next;
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

WeatherHintKind? _kindFor({
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
    return WeatherHintKind.rainy;
  }
  if (code != null && snowCodes.contains(code)) {
    return WeatherHintKind.snowy;
  }
  if (temperature != null && temperature >= 28) {
    return WeatherHintKind.hot;
  }
  if (code != null && clearCodes.contains(code)) {
    return WeatherHintKind.clear;
  }
  return null;
}

String _backendHintForKind(WeatherHintKind kind) {
  switch (kind) {
    case WeatherHintKind.rainy:
      return 'Sicak bir sey iyi gider';
    case WeatherHintKind.snowy:
      return 'Sicak corba iyi gider';
    case WeatherHintKind.hot:
      return 'Serin bir sey iyi gider';
    case WeatherHintKind.clear:
      return 'Dis mekan keyifli';
  }
}
