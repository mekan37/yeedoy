import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/profile_repository.dart';

final myReputationScoreProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return 0;
  return ref.read(profileRepositoryProvider).fetchMyReputationScore();
});
