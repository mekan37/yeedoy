import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../data/profil_deposu.dart';
import 'haftalik_gorevler.dart';

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
  return ref.read(profileRepositoryProvider).fetchMyWeeklyMissions();
});


