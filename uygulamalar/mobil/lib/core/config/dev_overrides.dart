import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/dev_overrides_prefs.dart';

class DevOverrides {
  const DevOverrides({
    required this.testUserId,
    required this.testCity,
    required this.testDistrict,
  });

  final String? testUserId;
  final String? testCity;
  final String? testDistrict;

  bool get hasTestUser => (testUserId ?? '').trim().isNotEmpty;
  bool get hasTestLocation =>
      (testCity ?? '').trim().isNotEmpty &&
      (testDistrict ?? '').trim().isNotEmpty;

  factory DevOverrides.empty() =>
      const DevOverrides(testUserId: null, testCity: null, testDistrict: null);

  DevOverrides copyWith({
    String? testUserId,
    String? testCity,
    String? testDistrict,
  }) {
    return DevOverrides(
      testUserId: testUserId ?? this.testUserId,
      testCity: testCity ?? this.testCity,
      testDistrict: testDistrict ?? this.testDistrict,
    );
  }
}

final devOverridesProvider =
    NotifierProvider<DevOverridesController, DevOverrides>(
      DevOverridesController.new,
    );

/// Test kullanıcı-id/konum override'ları — yalnızca geliştirme içindir.
/// `kDebugMode` kapısı olmadan, üretim build'inde de local storage'tan
/// (bir gün yanlışlıkla yazılırsa) sessizce okunup analitik client-id'yi
/// veya arama konumunu değiştirebilirdi (B60). Release build'de bu sınıf
/// prefs'i hiç okumaz/yazmaz, her zaman boş kalır.
class DevOverridesController extends Notifier<DevOverrides> {
  @override
  DevOverrides build() {
    if (kDebugMode) Future.microtask(_loadFromPrefs);
    return DevOverrides.empty();
  }

  Future<void> _loadFromPrefs() async {
    final (userId, city, district) = await DevOverridesPrefs.read();
    state = state.copyWith(
      testUserId: userId,
      testCity: city,
      testDistrict: district,
    );
  }

  Future<void> setTestUserId(String? userId) async {
    if (!kDebugMode) return;
    final value = userId?.trim() ?? '';
    if (value.isEmpty) {
      state = state.copyWith(testUserId: null);
      await DevOverridesPrefs.setTestUserId(null);
      return;
    }
    state = state.copyWith(testUserId: value);
    await DevOverridesPrefs.setTestUserId(value);
  }

  Future<void> setTestLocation({
    required String city,
    required String district,
  }) async {
    if (!kDebugMode) return;
    final nextCity = city.trim();
    final nextDistrict = district.trim();
    if (nextCity.isEmpty || nextDistrict.isEmpty) return;
    state = state.copyWith(testCity: nextCity, testDistrict: nextDistrict);
    await DevOverridesPrefs.setTestLocation(
      city: nextCity,
      district: nextDistrict,
    );
  }

  Future<void> clearTestLocation() async {
    if (!kDebugMode) return;
    state = state.copyWith(testCity: null, testDistrict: null);
    await DevOverridesPrefs.clearTestLocation();
  }

  Future<void> clearAll() async {
    if (!kDebugMode) return;
    state = DevOverrides.empty();
    await DevOverridesPrefs.clearAll();
  }
}
