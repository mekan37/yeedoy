import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/domain/auth_providers.dart';
import 'legal_models.dart';
import 'legal_repository.dart';

final legalAcceptanceSnapshotProvider =
    FutureProvider.autoDispose<PolicyAcceptanceSnapshot?>((ref) async {
      final user = ref.watch(userProvider);
      if (user == null) return null;
      return ref.read(legalRepositoryProvider).loadAcceptanceSnapshot();
    });

final legalRequestOverviewProvider =
    FutureProvider.autoDispose<LegalRequestOverview?>((ref) async {
      final user = ref.watch(userProvider);
      if (user == null) return null;
      return ref.read(legalRepositoryProvider).loadRequestOverview();
    });
