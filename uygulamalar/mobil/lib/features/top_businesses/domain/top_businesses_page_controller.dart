import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../discovery/domain/discovery_search_notifier.dart';
import '../data/top_businesses_repository.dart';
import 'top_business.dart';

final topBusinessesListProvider = AsyncNotifierProvider.autoDispose.family<
    TopBusinessesListController, List<TopBusiness>, String>(
  (arg) => TopBusinessesListController(arg),
);

class TopBusinessesListController extends AsyncNotifier<List<TopBusiness>> {
  TopBusinessesListController(this.period);
  final String period;

  static const int _limit = 5;
  static const int _minReviews = 0;

  @override
  Future<List<TopBusiness>> build() async {
    final loc = ref.watch(
      discoverySearchProvider.select((s) => (s.userLat, s.userLng)),
    );
    return ref.read(topBusinessesRepositoryProvider).fetchTopBusinesses(
          period: period,
          limit: _limit,
          minReviews: _minReviews,
          userLat: loc.$1,
          userLng: loc.$2,
        );
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    final loc = ref.read(
      discoverySearchProvider.select((s) => (s.userLat, s.userLng)),
    );
    state = await AsyncValue.guard(() {
      return ref.read(topBusinessesRepositoryProvider).fetchTopBusinesses(
            period: period,
            limit: _limit,
            minReviews: _minReviews,
            userLat: loc.$1,
            userLng: loc.$2,
            force: force,
          );
    });
  }
}
