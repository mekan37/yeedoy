import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../features/admin/data/admin_user_access_repository.dart';
import 'business_rbac.dart';

class AdminImpersonationState {
  const AdminImpersonationState({
    this.userId,
    this.roleOverride,
    this.userLabel,
  });

  final String? userId;
  final OwnerTeamRole? roleOverride;
  final String? userLabel;

  bool get isActive => userId != null && userId!.isNotEmpty;
}

final adminImpersonationProvider = StateProvider<AdminImpersonationState>(
  (ref) => const AdminImpersonationState(),
);

class AdminImpersonationActions {
  AdminImpersonationActions(this._ref);

  final Ref _ref;

  Future<void> start({
    required String userId,
    OwnerTeamRole? roleOverride,
    String? userLabel,
  }) async {
    await _ref
        .read(adminUserAccessRepositoryProvider)
        .logImpersonation(
          userId: userId,
          action: 'start',
          roleOverride: roleOverride,
        );
    _ref.read(adminImpersonationProvider.notifier).state = AdminImpersonationState(
      userId: userId,
      roleOverride: roleOverride,
      userLabel: userLabel,
    );
  }

  Future<void> stop() async {
    final current = _ref.read(adminImpersonationProvider);
    final userId = current.userId;
    if (userId == null || userId.isEmpty) {
      _ref.read(adminImpersonationProvider.notifier).state =
          const AdminImpersonationState();
      return;
    }
    await _ref
        .read(adminUserAccessRepositoryProvider)
        .logImpersonation(
          userId: userId,
          action: 'stop',
          roleOverride: current.roleOverride,
        );
    _ref.read(adminImpersonationProvider.notifier).state =
        const AdminImpersonationState();
  }
}

final adminImpersonationActionsProvider = Provider<AdminImpersonationActions>(
  (ref) => AdminImpersonationActions(ref),
);
