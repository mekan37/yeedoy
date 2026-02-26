import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_moderation_repository.dart';
import 'admin_moderation_models.dart';

class AdminAppealsState {
  const AdminAppealsState({
    required this.items,
    required this.templates,
    required this.statusFilter,
    required this.isLoading,
    required this.error,
  });

  final List<AdminAppealItem> items;
  final List<ModerationDecisionTemplate> templates;
  final String statusFilter;
  final bool isLoading;
  final Object? error;

  factory AdminAppealsState.initial() => const AdminAppealsState(
    items: <AdminAppealItem>[],
    templates: <ModerationDecisionTemplate>[],
    statusFilter: 'pending',
    isLoading: false,
    error: null,
  );

  AdminAppealsState copyWith({
    List<AdminAppealItem>? items,
    List<ModerationDecisionTemplate>? templates,
    String? statusFilter,
    bool? isLoading,
    Object? error,
  }) {
    return AdminAppealsState(
      items: items ?? this.items,
      templates: templates ?? this.templates,
      statusFilter: statusFilter ?? this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final adminAppealsControllerProvider =
    NotifierProvider<AdminAppealsController, AdminAppealsState>(
      AdminAppealsController.new,
    );

class AdminAppealsController extends Notifier<AdminAppealsState> {
  @override
  AdminAppealsState build() {
    Future.microtask(refresh);
    return AdminAppealsState.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(adminModerationRepositoryProvider);
      final results = await Future.wait([
        repository.listAppeals(status: state.statusFilter),
        repository.listTemplates(scope: 'appeal'),
      ]);
      state = state.copyWith(
        isLoading: false,
        items: results[0] as List<AdminAppealItem>,
        templates: results[1] as List<ModerationDecisionTemplate>,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> setStatusFilter(String status) async {
    state = state.copyWith(statusFilter: status);
    await refresh();
  }

  Future<void> decide({
    required String appealId,
    required String decision,
    required String note,
  }) async {
    final repository = ref.read(adminModerationRepositoryProvider);
    await repository.decideAppeal(
      appealId: appealId,
      decision: decision,
      note: note,
    );
    await refresh();
  }
}
