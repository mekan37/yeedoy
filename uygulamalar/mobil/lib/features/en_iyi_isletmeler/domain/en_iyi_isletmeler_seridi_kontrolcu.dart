import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'en_iyi_isletme.dart';
import '../data/en_iyi_isletmeler_deposu.dart';

class _TopBusinessesController extends AsyncNotifier<List<TopBusiness>> {
  _TopBusinessesController(this.period, this.limit, this.minReviews);
  final String period;
  final int limit;
  final int minReviews;

  @override
  Future<List<TopBusiness>> build() async {
    return ref.read(topBusinessesRepositoryProvider).fetchTopBusinesses(
          period: period,
          limit: limit,
          minReviews: minReviews,
        );
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(topBusinessesRepositoryProvider).fetchTopBusinesses(
            period: period,
            limit: limit,
            minReviews: minReviews,
            force: force,
          );
    });
  }
}

final topBusinessesWeekProvider =
    AsyncNotifierProvider<_TopBusinessesController, List<TopBusiness>>(
  () => _TopBusinessesController('week', 6, 2),
);

final topBusinessesMonthProvider =
    AsyncNotifierProvider<_TopBusinessesController, List<TopBusiness>>(
  () => _TopBusinessesController('month', 6, 2),
);

