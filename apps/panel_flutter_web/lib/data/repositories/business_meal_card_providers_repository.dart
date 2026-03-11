import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_error_mapper.dart';
import '../../core/network/supabase_provider.dart';
import '../../features/business/domain/meal_card_provider_option.dart';

final businessMealCardProvidersRepositoryProvider =
    Provider<BusinessMealCardProvidersRepository>((ref) {
      final client = ref.watch(supabaseProvider);
      return BusinessMealCardProvidersRepository(client);
    });

class _MealCardCacheEntry {
  const _MealCardCacheEntry({required this.items, required this.fetchedAt});

  final List<MealCardProviderOption> items;
  final DateTime fetchedAt;
}

class BusinessMealCardProvidersRepository {
  BusinessMealCardProvidersRepository(this.client);

  final SupabaseClient client;

  static const Duration _ttl = Duration(minutes: 5);
  static final Map<String, _MealCardCacheEntry> _cache = {};

  Future<List<MealCardProviderOption>> listAllProviders() async {
    try {
      final response = await client
          .from('meal_card_providers')
          .select('id,key,name,asset_name,sort_order')
          .eq('is_active', true)
          .order('sort_order')
          .order('name');
      return (response as List)
          .whereType<Map>()
          .map((row) => MealCardProviderOption.fromMap(row.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }

  Future<List<MealCardProviderOption>> listBusinessProviders(
    String businessId, {
    bool force = false,
  }) async {
    final cached = _cache[businessId];
    if (!force && cached != null) {
      final age = DateTime.now().difference(cached.fetchedAt);
      if (age < _ttl) return cached.items;
    }

    try {
      final response = await client.rpc(
        'get_business_meal_card_providers_v1',
        params: {'p_business_id': businessId},
      );
      final items = (response as List)
          .whereType<Map>()
          .map((row) => MealCardProviderOption.fromMap(row.cast<String, dynamic>()))
          .toList(growable: false);
      _cache[businessId] = _MealCardCacheEntry(
        items: items,
        fetchedAt: DateTime.now(),
      );
      return items;
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }

  Future<void> updateBusinessProviders({
    required String businessId,
    required List<String> providerKeys,
  }) async {
    try {
      await client.rpc(
        'owner_update_business_meal_card_providers_v1',
        params: {
          'p_business_id': businessId,
          'p_provider_keys': providerKeys,
        },
      );
      _cache.remove(businessId);
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }
}
