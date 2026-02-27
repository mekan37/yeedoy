import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_locations_repository.dart';

class AdminLocationsState {
  const AdminLocationsState({
    required this.previewCount,
    required this.isLoading,
    required this.error,
  });

  final int previewCount;
  final bool isLoading;
  final Object? error;

  factory AdminLocationsState.initial() => const AdminLocationsState(
        previewCount: 0,
        isLoading: false,
        error: null,
      );

  AdminLocationsState copyWith({
    int? previewCount,
    bool? isLoading,
    Object? error,
  }) {
    return AdminLocationsState(
      previewCount: previewCount ?? this.previewCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final adminLocationsControllerProvider =
    NotifierProvider<AdminLocationsController, AdminLocationsState>(
  AdminLocationsController.new,
);

class AdminLocationsController extends Notifier<AdminLocationsState> {
  @override
  AdminLocationsState build() => AdminLocationsState.initial();

  Future<int> preview({
    required String table,
    required String column,
    required String from,
    required bool caseInsensitive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final count = await ref.read(adminLocationsRepositoryProvider).previewReplace(
            table: table,
            column: column,
            from: from,
            caseInsensitive: caseInsensitive,
          );
      state = state.copyWith(isLoading: false, previewCount: count);
      return count;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  Future<void> apply({
    required String table,
    required String column,
    required String from,
    required String to,
    required bool caseInsensitive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(adminLocationsRepositoryProvider).applyReplace(
            table: table,
            column: column,
            from: from,
            to: to,
            caseInsensitive: caseInsensitive,
          );
      state = state.copyWith(isLoading: false, previewCount: 0);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  void clearPreview() {
    state = state.copyWith(previewCount: 0);
  }
}
