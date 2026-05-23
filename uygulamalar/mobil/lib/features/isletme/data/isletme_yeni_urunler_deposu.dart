import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../domain/isletme_yeni_urun.dart';

final businessNewItemsRepositoryProvider = Provider<BusinessNewItemsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return BusinessNewItemsRepository(client);
});

class BusinessNewItemsRepository {
  BusinessNewItemsRepository(this.client);
  final SupabaseClient client;

  Future<List<BusinessNewItem>> listNewItems({
    required String businessId,
    int limit = 6,
  }) async {
    try {
      final res = await client.rpc('get_business_new_items_v1', params: {
        'p_business_id': businessId,
        'p_limit': limit,
      });
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => BusinessNewItem.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

