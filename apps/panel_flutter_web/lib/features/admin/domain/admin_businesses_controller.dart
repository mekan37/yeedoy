import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_businesses_repository.dart';
import 'admin_models.dart';

class AdminBusinessesState {
  const AdminBusinessesState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.query,
    required this.city,
    required this.district,
  });

  final List<AdminBusinessItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String query;
  final String city;
  final String district;

  factory AdminBusinessesState.initial() => const AdminBusinessesState(
        items: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
        query: '',
        city: '',
        district: '',
      );

  AdminBusinessesState copyWith({
    List<AdminBusinessItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    String? query,
    String? city,
    String? district,
  }) {
    return AdminBusinessesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      query: query ?? this.query,
      city: city ?? this.city,
      district: district ?? this.district,
    );
  }
}

final adminBusinessesControllerProvider =
    NotifierProvider<AdminBusinessesController, AdminBusinessesState>(
  AdminBusinessesController.new,
);

class AdminBusinessesController extends Notifier<AdminBusinessesState> {
  static const int pageSize = 50;
  Timer? _debounce;

  @override
  AdminBusinessesState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(loadInitial);
    return AdminBusinessesState.initial();
  }

  Future<bool> loadInitial({bool force = false}) async {
    if (state.isLoading && !force) return false;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final repo = ref.read(adminBusinessesRepositoryProvider);
      final items = await repo.listBusinesses(
        limit: pageSize,
        offset: 0,
        query: state.query,
        city: state.city,
        district: state.district,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == pageSize,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final repo = ref.read(adminBusinessesRepositoryProvider);
      final items = await repo.listBusinesses(
        limit: pageSize,
        offset: state.items.length,
        query: state.query,
        city: state.city,
        district: state.district,
      );
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoadingMore: false,
        hasMore: items.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<bool> refresh({bool force = false}) async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      items: [],
      error: null,
    );
    return loadInitial(force: true);
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), loadInitial);
  }

  void setCity(String city) {
    state = state.copyWith(city: city);
    loadInitial();
  }

  void setDistrict(String district) {
    state = state.copyWith(district: district);
    loadInitial();
  }

  Future<void> applyFilters({
    required String query,
    required String city,
    required String district,
  }) async {
    _debounce?.cancel();
    state = state.copyWith(
      query: query,
      city: city,
      district: district,
    );
    await loadInitial(force: true);
  }

  Future<void> updateBusiness({
    required String businessId,
    required String name,
    String? category,
    String? address,
    String? city,
    String? district,
    double? lat,
    double? lng,
    String? logoUrl,
    String? coverUrl,
  }) async {
    final prev = state.items;
    final next = prev
        .map((b) => b.id == businessId
            ? _copyBusiness(
                b,
                name: name,
                category: category,
                address: address,
                city: city,
                district: district,
                lat: lat,
                lng: lng,
                logoUrl: logoUrl,
                coverUrl: coverUrl,
              )
            : b)
        .toList();
    state = state.copyWith(items: next);
    try {
      await ref.read(adminBusinessesRepositoryProvider).updateBusiness(
            businessId: businessId,
            name: name,
            category: category,
            address: address,
            city: city,
            district: district,
            lat: lat,
            lng: lng,
            logoUrl: logoUrl,
            coverUrl: coverUrl,
          );
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }
}

AdminBusinessItem _copyBusiness(
  AdminBusinessItem b, {
  String? name,
  String? category,
  String? address,
  String? city,
  String? district,
  double? lat,
  double? lng,
  String? logoUrl,
  String? coverUrl,
}) {
  return AdminBusinessItem(
    id: b.id,
    name: name ?? b.name,
    createdAt: b.createdAt,
    category: category ?? b.category,
    address: address ?? b.address,
    city: city ?? b.city,
    district: district ?? b.district,
    lat: lat ?? b.lat,
    lng: lng ?? b.lng,
    logoUrl: logoUrl ?? b.logoUrl,
    coverUrl: coverUrl ?? b.coverUrl,
    assignedTo: b.assignedTo,
    isVerified: b.isVerified,
  );
}
