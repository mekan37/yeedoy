import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/profile_repo.dart';
import 'weekly_missions.dart';

final myWeeklyMissionsProvider = FutureProvider<WeeklyMissions>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) {
    return WeeklyMissions(
      weekStart: DateTime.now(),
      reviewsDone: 0,
      visitsDone: 0,
      votesDone: 0,
      reviewsGoal: 1,
      visitsGoal: 3,
      votesGoal: 3,
      completedCount: 0,
    );
  }
  return ref.read(profileRepoProvider).getMyWeeklyMissions();
});
