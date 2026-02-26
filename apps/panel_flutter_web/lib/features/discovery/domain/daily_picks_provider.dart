import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/discovery_repo.dart';
import 'top_business.dart';

final dailyPicksProvider = FutureProvider<List<TopBusiness>>((ref) async {
  return ref.read(discoveryRepoProvider).getDailyPicks(limit: 3);
});
