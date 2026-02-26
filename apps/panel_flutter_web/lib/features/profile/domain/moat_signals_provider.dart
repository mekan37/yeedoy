import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/profile_repo.dart';
import 'user_moat_signals.dart';

final myMoatSignalsProvider = FutureProvider<UserMoatSignals?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;
  return ref.read(profileRepoProvider).getMyMoatSignals();
});
