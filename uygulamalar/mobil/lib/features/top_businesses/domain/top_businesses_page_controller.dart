import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/top_businesses_repository.dart';
import 'top_business.dart';

final topBusinessesListProvider = AsyncNotifierProvider.family<
    TopBusinessesListController, List<TopBusiness>, String>(
  TopBusinessesListController.new,
);

class TopBusinessesListController extends AsyncNotifier<List<TopBusiness>> {
  TopBusinessesListController(this.period);
  final String period;

  int get _minReviews => period == 'month' ? 4 : 2;

  @override
  Future<List<TopBusiness>> build() async {
    return ref.read(topBusinessesRepositoryProvider).fetchTopBusinesses(
          period: period,
          limit: 30,
          minReviews: _minReviews,
        );
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(topBusinessesRepositoryProvider).fetchTopBusinesses(
            period: period,
            limit: 30,
            minReviews: _minReviews,
            force: force,
          );
    });
  }
}
