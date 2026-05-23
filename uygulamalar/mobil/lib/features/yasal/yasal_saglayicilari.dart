import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../kimlik/domain/kimlik_saglayicilari.dart';
import 'yasal_modeller.dart';
import 'yasal_deposu.dart';

final legalAcceptanceSnapshotProvider =
    FutureProvider<PolicyAcceptanceSnapshot?>((ref) async {
      final user = ref.watch(userProvider);
      if (user == null) return null;
      return ref.read(legalRepositoryProvider).loadAcceptanceSnapshot();
    });

final legalRequestOverviewProvider =
    FutureProvider<LegalRequestOverview?>((ref) async {
      final user = ref.watch(userProvider);
      if (user == null) return null;
      return ref.read(legalRepositoryProvider).loadRequestOverview();
    });



