import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/suggestion.dart';

final mySuggestionsRepositoryProvider = Provider<MySuggestionsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return MySuggestionsRepository(client);
});

class MySuggestionsRepository {
  MySuggestionsRepository(this.client);
  final SupabaseClient client;

  Future<List<BusinessSuggestion>> getMySuggestions({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final List<dynamic> res = await client
          .from('business_suggestions')
          .select(
            'id,name,category,status,created_at,city,district,admin_note,approved_business_id',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return res
          .whereType<Map>()
          .map((m) => BusinessSuggestion.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
