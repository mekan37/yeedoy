import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/network/supabase_provider.dart';
import '../data/smart_reco_repository.dart';
import 'smart_reco_models.dart';

final smartRecoRepositoryProvider = Provider<SmartRecoRepository>((ref) {
  return SmartRecoRepository(
    ref.watch(supabaseProvider),
    ref.watch(requestCacheProvider),
  );
});

final smartRecoProvider = FutureProvider.autoDispose
    .family<List<SmartRecommendation>, SmartRecoQuery>((ref, query) async {
  return ref.read(smartRecoRepositoryProvider).fetchRecommendations(query);
});
