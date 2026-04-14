import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/profile_repository.dart';
import 'achievement.dart';

final myAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return const [];
  return ref.read(profileRepositoryProvider).fetchMyAchievements();
});
