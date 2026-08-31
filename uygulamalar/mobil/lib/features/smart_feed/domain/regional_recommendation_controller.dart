import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/regional_recommendation_repository.dart';
import 'regional_recommendation_models.dart';

class RegionalRecommendationState {
  const RegionalRecommendationState({required this.city, required this.businesses});

  final String? city;
  final List<RegionalBusiness> businesses;

  static const empty = RegionalRecommendationState(city: null, businesses: []);
}

final regionalRecommendationProvider = NotifierProvider<
    RegionalRecommendationController, RegionalRecommendationState>(
  RegionalRecommendationController.new,
);

class RegionalRecommendationController
    extends Notifier<RegionalRecommendationState> {
  int _requestId = 0;

  @override
  RegionalRecommendationState build() => RegionalRecommendationState.empty;

  Future<void> checkCity(String city) async {
    if (city == state.city) return;
    final reqId = ++_requestId;
    try {
      final businesses =
          await ref.read(regionalRecommendationRepositoryProvider).check(city);
      if (reqId != _requestId) return;
      state = RegionalRecommendationState(city: city, businesses: businesses);
    } catch (_) {
      if (reqId != _requestId) return;
      state = RegionalRecommendationState(city: city, businesses: const []);
    }
  }
}
