import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hero_repository.dart';
import 'hero_models.dart';

final heroesProvider =
    AsyncNotifierProvider.autoDispose<HeroesController, List<HeroEntry>>(HeroesController.new);

class HeroesController extends AsyncNotifier<List<HeroEntry>> {
  @override
  Future<List<HeroEntry>> build() async {
    return ref.read(heroRepositoryProvider).listHeroes();
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(heroRepositoryProvider).listHeroes();
    });
  }
}

final weeklyLeaderboardProvider =
    AsyncNotifierProvider.autoDispose<WeeklyLeaderboardController, List<WeeklyLeaderboardEntry>>(
  WeeklyLeaderboardController.new,
);

class WeeklyLeaderboardController
    extends AsyncNotifier<List<WeeklyLeaderboardEntry>> {
  @override
  Future<List<WeeklyLeaderboardEntry>> build() async {
    return ref.read(heroRepositoryProvider).listWeeklyLeaderboard(limit: 10);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(heroRepositoryProvider).listWeeklyLeaderboard(limit: 10),
    );
  }
}
