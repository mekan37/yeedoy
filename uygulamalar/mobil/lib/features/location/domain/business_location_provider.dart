import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/business_location_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class BusinessLocationState {
  const BusinessLocationState({
    this.latitude,
    this.longitude,
    this.isSaving = false,
    this.saveSuccess = false,
    this.error,
  });

  final double? latitude;
  final double? longitude;
  final bool isSaving;
  final bool saveSuccess;
  final Object? error;

  bool get hasCoordinates => latitude != null && longitude != null;

  BusinessLocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isSaving,
    bool? saveSuccess,
    Object? error,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BusinessLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSaving: isSaving ?? this.isSaving,
      saveSuccess: saveSuccess ?? (clearSuccess ? false : this.saveSuccess),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Riverpod 3.x stili: factory arg alır, notifier constructor'da saklar,
/// build() arg almaz.
final businessLocationProvider = AsyncNotifierProvider.autoDispose
    .family<BusinessLocationNotifier, BusinessLocationState, String>(
  (arg) => BusinessLocationNotifier(arg),
);

class BusinessLocationNotifier extends AsyncNotifier<BusinessLocationState> {
  BusinessLocationNotifier(this._businessId);

  final String _businessId;

  @override
  Future<BusinessLocationState> build() async {
    final coords = await ref
        .read(businessLocationRepositoryProvider)
        .fetchLocation(_businessId);
    return BusinessLocationState(
      latitude: coords?['latitude'],
      longitude: coords?['longitude'],
    );
  }

  Future<void> save(double lat, double lng) async {
    final current = state.asData?.value ?? const BusinessLocationState();
    state = AsyncData(
      current.copyWith(isSaving: true, clearError: true, clearSuccess: true),
    );
    try {
      await ref
          .read(businessLocationRepositoryProvider)
          .updateLocation(_businessId, lat, lng);
      state = AsyncData(
        current.copyWith(
          latitude: lat,
          longitude: lng,
          isSaving: false,
          saveSuccess: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(isSaving: false, error: e, clearSuccess: true),
      );
    }
  }
}
