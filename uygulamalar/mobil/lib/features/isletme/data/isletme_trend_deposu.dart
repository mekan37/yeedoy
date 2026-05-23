import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../domain/isletme_trend_ogesi.dart';

final businessTrendingRepositoryProvider = Provider<BusinessTrendingRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return BusinessTrendingRepository(client);
});

class BusinessTrendingRepository {
  BusinessTrendingRepository(this.client);
  final SupabaseClient client;

  Future<List<BusinessTrendingItem>> listTrendingItems({
    required String businessId,
    int limit = 6,
  }) async {
    try {
      final res = await client.rpc('get_business_trending_items_v1', params: {
        'p_business_id': businessId,
        'p_limit': limit,
      });
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => BusinessTrendingItem.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

