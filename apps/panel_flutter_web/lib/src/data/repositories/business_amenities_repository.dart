import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../features/business/domain/business_amenity.dart';

final businessAmenitiesRepositoryProvider = Provider<BusinessAmenitiesRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return BusinessAmenitiesRepository(client);
});

class _AmenityCacheEntry {
  const _AmenityCacheEntry({required this.items, required this.fetchedAt});
  final List<BusinessAmenity> items;
  final DateTime fetchedAt;
}

class BusinessAmenitiesRepository {
  BusinessAmenitiesRepository(this.client);
  final SupabaseClient client;

  static const Duration _ttl = Duration(minutes: 5);
  static final Map<String, _AmenityCacheEntry> _cache = {};

  Future<List<BusinessAmenity>> listAllAmenities() async {
    try {
      final res = await client
          .from('business_amenities')
          .select('id,key,label,icon')
          .order('label');
      return (res as List)
          .whereType<Map>()
          .map((m) => BusinessAmenity.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<BusinessAmenity>> listBusinessAmenities(
    String businessId, {
    bool force = false,
  }) async {
    final cached = _cache[businessId];
    if (!force && cached != null) {
      final age = DateTime.now().difference(cached.fetchedAt);
      if (age < _ttl) return cached.items;
    }

    try {
      final res = await client.rpc('get_business_amenities_v1', params: {
        'p_business_id': businessId,
      });
      final items = (res as List)
          .whereType<Map>()
          .map((m) => BusinessAmenity.fromMap(m.cast<String, dynamic>()))
          .toList();
      _cache[businessId] = _AmenityCacheEntry(items: items, fetchedAt: DateTime.now());
      return items;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> updateBusinessAmenities({
    required String businessId,
    required List<String> amenityKeys,
  }) async {
    try {
      await client.rpc('owner_update_business_amenities_v1', params: {
        'p_business_id': businessId,
        'p_amenity_keys': amenityKeys,
      });
      _cache.remove(businessId);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
