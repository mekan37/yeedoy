import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../config/dev_overrides.dart';
import '../growth/funnel_tracker.dart';
import '../storage/dev_overrides_prefs.dart';
import '../storage/location_prefs.dart';
import '../analytics/analytics_repository.dart';
import '../errors/app_error_codes.dart';
import '../../features/discovery/domain/discovery_search_notifier.dart';
import '../../features/smart_feed/domain/smart_feed_controller.dart';
import 'location_mapping.dart';
import 'user_location_repository.dart';

class UserLocationState {
  const UserLocationState({
    required this.city,
    required this.district,
    required this.neighborhood,
    required this.mode,
    required this.loading,
    required this.permissionDenied,
    required this.error,
  });

  final String? city;
  final String? district;
  final String? neighborhood;
  final String mode;
  final bool loading;
  final bool permissionDenied;
  final Object? error;

  bool get hasLocation =>
      (city ?? '').trim().isNotEmpty && (district ?? '').trim().isNotEmpty;

  UserLocationState copyWith({
    String? city,
    String? district,
    String? neighborhood,
    String? mode,
    bool? loading,
    bool? permissionDenied,
    Object? error,
  }) {
    return UserLocationState(
      city: city ?? this.city,
      district: district ?? this.district,
      neighborhood: neighborhood ?? this.neighborhood,
      mode: mode ?? this.mode,
      loading: loading ?? this.loading,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      error: error,
    );
  }

  factory UserLocationState.initial() {
    return const UserLocationState(
      city: null,
      district: null,
      neighborhood: null,
      mode: 'auto',
      loading: true,
      permissionDenied: false,
      error: null,
    );
  }
}

final userLocationProvider =
    NotifierProvider<UserLocationController, UserLocationState>(
      UserLocationController.new,
    );

class UserLocationController extends Notifier<UserLocationState> {
  @override
  UserLocationState build() {
    ref.listen(devOverridesProvider, (prev, next) {
      final had = prev?.hasTestLocation ?? false;
      if (next.hasTestLocation) {
        unawaited(
          _applyLocation(
            city: next.testCity!,
            district: next.testDistrict!,
            mode: 'dev',
            persist: false,
          ),
        );
        return;
      }
      if (had && !next.hasTestLocation) {
        unawaited(_bootstrap());
      }
    });
    Future.microtask(_bootstrap);
    return UserLocationState.initial();
  }

  Future<void> _bootstrap() async {
    final overrides = await DevOverridesPrefs.read();
    final overrideCity = (overrides.$2 ?? '').trim();
    final overrideDistrict = (overrides.$3 ?? '').trim();
    if (overrideCity.isNotEmpty && overrideDistrict.isNotEmpty) {
      final normalized = canonicalCityDistrict(overrideCity, overrideDistrict);
      state = state.copyWith(
        city: normalized.city,
        district: normalized.district,
        mode: 'dev',
        loading: false,
        permissionDenied: false,
        error: null,
      );
      await _syncFeatures(city: normalized.city, district: normalized.district);
      return;
    }

    final local = await LocationPrefs.readExtended();
    if (local != null && !state.hasLocation) {
      state = state.copyWith(
        city: local.$1,
        district: local.$2,
        neighborhood: local.$3,
        loading: true,
      );
    }

    final repo = ref.read(userLocationRepositoryProvider);
    final prefs = await repo.getPrefs();
    if (prefs != null) {
      final city = (prefs['city'] ?? '').toString();
      final district = (prefs['district'] ?? '').toString();
      final neighborhood = (prefs['neighborhood'] ?? '').toString();
      final mode = (prefs['mode'] ?? 'auto').toString();
      if (city.isNotEmpty && district.isNotEmpty) {
        state = state.copyWith(
          city: city,
          district: district,
          neighborhood: neighborhood.isEmpty ? null : neighborhood,
          mode: mode,
          loading: false,
          permissionDenied: false,
          error: null,
        );
        await _syncFeatures(city: city, district: district);
        if (mode == 'manual') return;
      }
    }

    await useAutoLocation();
  }

  Future<void> useAutoLocation() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final (lat, lng) = await _getLocation();
      final resolved = await _reverseGeocode(lat, lng);
      if (resolved == null) {
        state = state.copyWith(
          loading: false,
          error: Exception(AppErrorCodes.locationResolveFailed),
        );
        return;
      }
      await _applyLocation(
        city: resolved.$1,
        district: resolved.$2,
        neighborhood: resolved.$3,
        mode: 'auto',
        persist: true,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      state = state.copyWith(loading: false, permissionDenied: true, error: e);
    }
  }

  Future<void> setManualLocation({
    required String city,
    required String district,
    String? neighborhood,
    bool persist = true,
  }) async {
    await _applyLocation(
      city: city,
      district: district,
      neighborhood: neighborhood,
      mode: 'manual',
      persist: persist,
    );
  }

  Future<void> _applyLocation({
    required String city,
    required String district,
    String? neighborhood,
    required String mode,
    required bool persist,
    double? lat,
    double? lng,
  }) async {
    final normalized = canonicalCityDistrict(city, district);
    final nextCity = normalized.city;
    final nextDistrict = normalized.district;
    final nextNeighborhood = (neighborhood ?? '').trim().isEmpty
        ? null
        : neighborhood!.trim();
    if (nextCity.isEmpty || nextDistrict.isEmpty) return;

    if (state.city == nextCity &&
        state.district == nextDistrict &&
        state.neighborhood == nextNeighborhood &&
        state.mode == mode) {
      state = state.copyWith(
        loading: false,
        permissionDenied: false,
        error: null,
      );
      return;
    }

    state = state.copyWith(
      city: nextCity,
      district: nextDistrict,
      neighborhood: nextNeighborhood,
      mode: mode,
      loading: false,
      permissionDenied: false,
      error: null,
    );

    if (persist) {
      await LocationPrefs.save(
        city: nextCity,
        district: nextDistrict,
        neighborhood: nextNeighborhood,
      );
      await ref
          .read(userLocationRepositoryProvider)
          .upsertPrefs(
            city: nextCity,
            district: nextDistrict,
            neighborhood: nextNeighborhood,
            mode: mode,
            lat: lat,
            lng: lng,
          );
      await trackFunnelStepOnce(
        ref.read(analyticsRepositoryProvider),
        step: FunnelStep.locationSet,
        source: 'user_location',
        meta: {'mode': mode, 'city': nextCity, 'district': nextDistrict},
      );
    } else {
      await LocationPrefs.addRecent(city: nextCity, district: nextDistrict);
    }

    await _syncFeatures(city: nextCity, district: nextDistrict);
  }

  Future<void> _syncFeatures({
    required String city,
    required String district,
  }) async {
    await ref
        .read(discoverySearchProvider.notifier)
        .setLocation(city: city, district: district);
    await ref
        .read(smartFeedProvider.notifier)
        .setLocation(city: city, district: district);
  }

  Future<(double lat, double lng)> _getLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw Exception(AppErrorCodes.locationPermissionRequired);
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return (pos.latitude, pos.longitude);
  }

  Future<(String city, String district, String? neighborhood)?> _reverseGeocode(
    double lat,
    double lng,
  ) async {
    final list = await placemarkFromCoordinates(lat, lng);
    if (list.isEmpty) return null;
    final place = list.first;
    final city = (place.administrativeArea ?? place.subAdministrativeArea ?? '')
        .trim();
    final district = (place.subAdministrativeArea ?? place.locality ?? '')
        .trim();
    final neighborhood = (place.subLocality ?? place.locality ?? '').trim();
    if (city.isEmpty || district.isEmpty) return null;
    final cleanedNeighborhood = neighborhood.isEmpty || neighborhood == district
        ? null
        : neighborhood;
    final normalized = canonicalCityDistrict(city, district);
    return (normalized.city, normalized.district, cleanedNeighborhood);
  }
}
