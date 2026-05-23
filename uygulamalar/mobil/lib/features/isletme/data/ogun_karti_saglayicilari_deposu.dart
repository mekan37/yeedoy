import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../domain/ogun_karti_saglayici_secenegi.dart';

final mealCardProvidersRepositoryProvider =
    Provider<MealCardProvidersRepository>((ref) {
      final client = ref.watch(supabaseProvider);
      return MealCardProvidersRepository(client);
    });

class _MealCardCacheEntry {
  const _MealCardCacheEntry({required this.items, required this.fetchedAt});

  final List<MealCardProviderOption> items;
  final DateTime fetchedAt;
}

class MealCardProvidersRepository {
  MealCardProvidersRepository(this.client);

  final SupabaseClient client;

  static const Duration _ttl = Duration(minutes: 5);
  static final Map<String, _MealCardCacheEntry> _businessCache = {};

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
    final cached = _businessCache[businessId];
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
      _businessCache[businessId] = _MealCardCacheEntry(
        items: items,
        fetchedAt: DateTime.now(),
      );
      return items;
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }

  Future<Map<String, List<MealCardProviderOption>>> listBusinessProvidersByIds(
    List<String> businessIds,
  ) async {
    final normalizedIds = businessIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedIds.isEmpty) {
      return const <String, List<MealCardProviderOption>>{};
    }

    try {
      final response = await client.rpc(
        'get_business_meal_card_provider_rows_v1',
        params: {
          'p_business_ids': normalizedIds,
          'p_provider_keys': null,
        },
      );
      final result = <String, List<MealCardProviderOption>>{};
      for (final row in (response as List).whereType<Map>()) {
        final data = row.cast<String, dynamic>();
        final businessId = (data['business_id'] ?? '').toString();
        if (businessId.isEmpty) continue;
        result
            .putIfAbsent(businessId, () => <MealCardProviderOption>[])
            .add(MealCardProviderOption.fromMap(data));
      }
      return result;
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }

  Future<Set<String>> matchBusinessIdsByProviderKeys(
    List<String> providerKeys, {
    List<String>? candidateBusinessIds,
  }) async {
    final normalizedKeys = providerKeys
        .map((key) => key.trim().toLowerCase())
        .where((key) => key.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedKeys.isEmpty) return const <String>{};

    final normalizedIds = candidateBusinessIds
        ?.map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedIds != null && normalizedIds.isEmpty) {
      return const <String>{};
    }

    try {
      final response = await client.rpc(
        'get_business_meal_card_provider_rows_v1',
        params: {
          'p_business_ids': normalizedIds,
          'p_provider_keys': normalizedKeys,
        },
      );
      return (response as List)
          .whereType<Map>()
          .map((row) => (row['business_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }
}


