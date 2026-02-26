import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/visits_repo.dart';

final myVisitedIdsProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return <String>{};
  return ref.read(visitsRepoProvider).listMyVisitedBusinessIds(user.id);
});

// Refresh: call `ref.invalidate(myVisitedIdsProvider);` to force reload
