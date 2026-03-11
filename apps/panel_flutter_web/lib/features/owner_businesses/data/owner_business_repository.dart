import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/memory_ttl_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/owner_business_models.dart';

final ownerBusinessRepositoryProvider = Provider<OwnerBusinessRepository>((
  ref,
) {
  return OwnerBusinessRepository(ref.watch(supabaseProvider));
});

class OwnerBusinessRepository {
  OwnerBusinessRepository(this.client);
  final SupabaseClient client;
  static const _businessCachePrefix = 'owner_businesses:';
  static const _submissionsCachePrefix = 'owner_business_submissions:';
  static const _ttl = Duration(minutes: 2);

  Future<List<OwnerBusiness>> listMyBusinesses({
    int limit = 50,
    int offset = 0,
    String? actorUserId,
    String? roleOverride,
  }) async {
    try {
      final key =
          '$_businessCachePrefix$limit:$offset:${actorUserId ?? ''}:${roleOverride ?? ''}';
      return MemoryTtlCache.instance.getOrLoad<List<OwnerBusiness>>(
        key: key,
        ttl: _ttl,
        loader: () async {
          dynamic res;
          try {
            final params = <String, Object?>{
              'p_limit': limit,
              'p_offset': offset,
            };
            if (actorUserId != null) {
              params['p_user_id'] = actorUserId;
            }
            if (roleOverride != null) {
              params['p_role_override'] = roleOverride;
            }
            res = await client.rpc(
              actorUserId == null
                  ? 'owner_list_accessible_businesses_v1'
                  : 'admin_list_user_business_access_v1',
              params: params,
            );
          } catch (_) {
            if (actorUserId != null) rethrow;
            try {
              res = await client.rpc(
                'owner_list_my_businesses_v2',
                params: {'p_status': 'approved', 'p_limit': limit, 'p_offset': offset},
              );
            } catch (_) {
              res = await client.rpc(
                'owner_list_my_businesses_v1',
                params: {'p_status': 'approved', 'p_limit': limit, 'p_offset': offset},
              );
            }
          }
          final rows = (res as List?) ?? const [];
          final items = rows
              .whereType<Map>()
              .map((row) => OwnerBusiness.fromMap(row.cast<String, dynamic>()))
              .toList();
          final slugs = await _fetchBusinessSlugs(
            items.map((e) => e.businessId).where((e) => e.isNotEmpty).toList(),
          );
          return items
              .map(
                (item) => item.copyWith(
                  slug: slugs[item.businessId]?.slug ?? item.slug,
                  publicSlug: slugs[item.businessId]?.publicSlug ?? item.publicSlug,
                ),
              )
              .toList();
        },
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String> submitNewBusiness({
    required String name,
    required String city,
    required String district,
    required String category,
    required String address,
    String? phone,
    String? website,
  }) async {
    try {
      final res = await client.rpc(
        'owner_submit_new_business_v1',
        params: {
          'p_name': name,
          'p_city': city,
          'p_district': district,
          'p_category': category,
          'p_address': address,
          'p_phone': phone,
          'p_website': website,
        },
      );
      if (res is Map && res['ok'] == true) {
        MemoryTtlCache.instance.invalidatePrefix(_submissionsCachePrefix);
        return (res['request_id'] ?? '').toString();
      }
      throw Exception((res is Map ? res['error'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<BusinessSubmission>> listMySubmissions({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final key =
          '$_submissionsCachePrefix$limit:$offset:${(status ?? '').trim()}';
      return MemoryTtlCache.instance.getOrLoad<List<BusinessSubmission>>(
        key: key,
        ttl: _ttl,
        loader: () async {
          final res = await client.rpc(
            'owner_list_my_business_submissions_v1',
            params: {'p_status': status, 'p_limit': limit, 'p_offset': offset},
          );
          final rows = (res as List?) ?? const [];
          return rows
              .whereType<Map>()
              .map((row) => BusinessSubmission.fromMap(row.cast<String, dynamic>()))
              .toList();
        },
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> updateCommerceLinks({
    required String businessId,
    String? reservationUrl,
    String? orderYemeksepetiUrl,
    String? orderTrendyolgoUrl,
    String? orderGetirUrl,
  }) async {
    try {
      final res = await client.rpc(
        'owner_update_business_commerce_links_v1',
        params: {
          'p_business_id': businessId,
          'p_reservation_url': reservationUrl,
          'p_order_yemeksepeti_url': orderYemeksepetiUrl,
          'p_order_trendyolgo_url': orderTrendyolgoUrl,
          'p_order_getir_url': orderGetirUrl,
        },
      );
      if (res is Map && res['ok'] == true) {
        MemoryTtlCache.instance.invalidatePrefix(_businessCachePrefix);
        return;
      }
      throw Exception((res is Map ? res['code'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, _BusinessSlugMeta>> _fetchBusinessSlugs(
    List<String> businessIds,
  ) async {
    if (businessIds.isEmpty) return const {};
    final result = <String, _BusinessSlugMeta>{};

    try {
      final res = await client
          .from('businesses')
          .select('id,slug,public_slug')
          .inFilter('id', businessIds);
      for (final row in (res as List?) ?? const []) {
        if (row is! Map) continue;
        final map = row.cast<String, dynamic>();
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;
        result[id] = _BusinessSlugMeta(
          slug: _nullableString(map['slug']),
          publicSlug: _nullableString(map['public_slug']),
        );
      }
      return result;
    } catch (_) {
      // Backward-compatible fallback for DBs where public_slug is not deployed yet.
    }

    try {
      final res = await client
          .from('businesses')
          .select('id,slug')
          .inFilter('id', businessIds);
      for (final row in (res as List?) ?? const []) {
        if (row is! Map) continue;
        final map = row.cast<String, dynamic>();
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;
        result[id] = _BusinessSlugMeta(
          slug: _nullableString(map['slug']),
          publicSlug: null,
        );
      }
    } catch (_) {
      // no-op
    }
    return result;
  }
}

class _BusinessSlugMeta {
  const _BusinessSlugMeta({
    required this.slug,
    required this.publicSlug,
  });

  final String? slug;
  final String? publicSlug;
}

String? _nullableString(Object? value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return null;
  return text;
}
