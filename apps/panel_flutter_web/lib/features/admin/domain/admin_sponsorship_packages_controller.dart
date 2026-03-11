import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_monetization_repository.dart';
import 'admin_models.dart';

class AdminSponsorshipPackagesState {
  const AdminSponsorshipPackagesState({
    required this.items,
    required this.isLoading,
    required this.error,
  });

  final List<AdminSponsorshipPackage> items;
  final bool isLoading;
  final Object? error;

  factory AdminSponsorshipPackagesState.initial() => const AdminSponsorshipPackagesState(
        items: [],
        isLoading: false,
        error: null,
      );

  AdminSponsorshipPackagesState copyWith({
    List<AdminSponsorshipPackage>? items,
    bool? isLoading,
    Object? error,
  }) {
    return AdminSponsorshipPackagesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final adminSponsorshipPackagesControllerProvider =
    NotifierProvider<AdminSponsorshipPackagesController, AdminSponsorshipPackagesState>(
  AdminSponsorshipPackagesController.new,
);

class AdminSponsorshipPackagesController extends Notifier<AdminSponsorshipPackagesState> {
  @override
  AdminSponsorshipPackagesState build() {
    Future.microtask(loadInitial);
    return AdminSponsorshipPackagesState.initial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(adminMonetizationRepositoryProvider);
      final items = await repo.listPackages();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> upsertPackage({
    String? id,
    required String name,
    required String surface,
    required int durationDays,
    required String priceDisplay,
    required int priceCents,
    required String currencyCode,
    required int inventoryLimit,
    required bool isActive,
  }) async {
    final repo = ref.read(adminMonetizationRepositoryProvider);
    await repo.upsertPackage(
      id: id,
      name: name,
      surface: surface,
      durationDays: durationDays,
      priceDisplay: priceDisplay,
      priceCents: priceCents,
      currencyCode: currencyCode,
      inventoryLimit: inventoryLimit,
      isActive: isActive,
    );
    await refresh();
  }
}
