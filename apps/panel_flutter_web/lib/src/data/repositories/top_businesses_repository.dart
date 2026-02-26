import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/top_business.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';

final topBusinessesRepositoryProvider = Provider<TopBusinessesRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return TopBusinessesRepository(client);
});

class _CacheEntry {
  const _CacheEntry({required this.data, required this.fetchedAt});
  final List<TopBusiness> data;
  final DateTime fetchedAt;
}

class TopBusinessesRepository {
  TopBusinessesRepository(this.client);
  final SupabaseClient client;

  static const Duration _ttl = Duration(minutes: 10);
  static final Map<String, _CacheEntry> _cache = {};

  Future<List<TopBusiness>> getTopBusinesses({
    required String period,
    int limit = 6,
    int minReviews = 2,
    bool force = false,
  }) async {
    final key = '$period|$limit|$minReviews';
    final cached = _cache[key];
    if (!force && cached != null) {
      final age = DateTime.now().difference(cached.fetchedAt);
      if (age < _ttl) return cached.data;
    }

    try {
      final res = await client.rpc('get_top_businesses_period_v1', params: {
        'p_period': period,
        'p_limit': limit,
        'p_min_reviews': minReviews,
      });

      final list = (res as List).map((e) => TopBusiness.fromMap(e)).toList();
      _cache[key] = _CacheEntry(data: list, fetchedAt: DateTime.now());
      return list;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
