import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_repository.dart';
import 'admin_models.dart';

class AdminDashboardState {
  const AdminDashboardState({required this.counts, required this.sla});

  final AdminQueueCounts counts;
  final AdminSlaMetrics sla;
}

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardController, AdminDashboardState>(
        AdminDashboardController.new);

class AdminDashboardController extends AsyncNotifier<AdminDashboardState> {
  @override
  Future<AdminDashboardState> build() async {
    return _load();
  }

  Future<AdminDashboardState> _load() async {
    final repo = ref.read(adminRepositoryProvider);
    final counts = await repo.getQueueCounts();
    final sla = await repo.getSlaMetrics();
    return AdminDashboardState(counts: counts, sla: sla);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}
