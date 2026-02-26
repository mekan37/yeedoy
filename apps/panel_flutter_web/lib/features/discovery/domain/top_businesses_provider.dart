import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/discovery_repo.dart';
import 'top_business.dart';

final topWeekProvider = FutureProvider<List<TopBusiness>>((ref) async {
  return ref.read(discoveryRepoProvider).getTopBusinesses(period: 'week', limit: 10, minReviews: 2);
});

final topMonthProvider = FutureProvider<List<TopBusiness>>((ref) async {
  return ref.read(discoveryRepoProvider).getTopBusinesses(period: 'month', limit: 10, minReviews: 3);
});
