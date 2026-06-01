// ignore_for_file: deprecated_member_use

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/errors/app_error_codes.dart';
import '../../menus/data/menu_item_search_repository.dart';
import '../../menus/domain/menu_item_search_model.dart';

final todayPickProvider = NotifierProvider.autoDispose<TodayPickController, TodayPickState>(
  TodayPickController.new,
);

class TodayPickState {
  const TodayPickState({
    required this.loading,
    required this.radiusKm,
    required this.needsLocation,
    this.item,
    this.error,
    this.userLat,
    this.userLng,
  });

  final bool loading;
  final int radiusKm;
  final bool needsLocation;
  final MenuItemSearchResult? item;
  final Object? error;
  final double? userLat;
  final double? userLng;

  factory TodayPickState.initial() => const TodayPickState(
    loading: false,
    radiusKm: 5,
    needsLocation: false,
    item: null,
    error: null,
    userLat: null,
    userLng: null,
  );

  TodayPickState copyWith({
    bool? loading,
    int? radiusKm,
    bool? needsLocation,
    MenuItemSearchResult? item,
    Object? error,
    double? userLat,
    double? userLng,
  }) {
    return TodayPickState(
      loading: loading ?? this.loading,
      radiusKm: radiusKm ?? this.radiusKm,
      needsLocation: needsLocation ?? this.needsLocation,
      item: item ?? this.item,
      error: error,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
    );
  }
}

class TodayPickController extends Notifier<TodayPickState> {
  int _requestId = 0;

  @override
  TodayPickState build() {
    return TodayPickState.initial();
  }

  Future<void> pickOne({bool force = false}) async {
    final reqId = ++_requestId;
    state = state.copyWith(loading: true, error: null, needsLocation: false);
    try {
      final ok = await _ensureLocation();
      if (!ok) {
        if (reqId != _requestId) return;
        state = state.copyWith(loading: false, needsLocation: true);
        return;
      }
      final item = await ref
          .read(menuItemSearchRepositoryProvider)
          .pickOneMenuItem(
            userLat: state.userLat!,
            userLng: state.userLng!,
            radiusKm: state.radiusKm,
          );
      if (reqId != _requestId) return;
      state = state.copyWith(loading: false, item: item, error: null);
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> setRadius(int km) async {
    state = state.copyWith(radiusKm: km);
  }

  Future<void> requestLocation() async {
    state = state.copyWith(error: null);
    final ok = await _ensureLocation();
    if (ok) {
      await pickOne(force: true);
    } else {
      state = state.copyWith(needsLocation: true, loading: false);
    }
  }

  Future<bool> _ensureLocation() async {
    if (state.userLat != null && state.userLng != null) return true;
    try {
      final (lat, lng) = await _getLocation();
      state = state.copyWith(userLat: lat, userLng: lng);
      return true;
    } catch (_) {
      return false;
    }
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
      desiredAccuracy: LocationAccuracy.high,
    );
    return (pos.latitude, pos.longitude);
  }
}
