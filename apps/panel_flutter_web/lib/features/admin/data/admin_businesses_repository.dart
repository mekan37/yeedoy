import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/memory_ttl_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';
import '../domain/admin_models.dart';

final adminBusinessesRepositoryProvider = Provider<AdminBusinessesRepository>((
  ref,
) {
  final client = ref.watch(supabaseProvider);
  return AdminBusinessesRepository(client);
});

class AdminBusinessesRepository {
  AdminBusinessesRepository(this.client);
  final SupabaseClient client;
  static const _cachePrefix = 'admin_businesses:';
  static const _detailCachePrefix = 'admin_business_detail:';
  static const _ttl = Duration(seconds: 45);

  Future<List<AdminBusinessItem>> listBusinesses({
    int limit = 50,
    int offset = 0,
    String? query,
    String? city,
    String? district,
  }) async {
    try {
      final key =
          '$_cachePrefix$limit:$offset:${(query ?? '').trim()}:${(city ?? '').trim()}:${(district ?? '').trim()}';
      return MemoryTtlCache.instance.getOrLoad<List<AdminBusinessItem>>(
        key: key,
        ttl: _ttl,
        loader: () async {
          final res = await client.rpc(
            'admin_list_businesses_v1',
            params: {
              'p_limit': limit,
              'p_offset': offset,
              'p_q': (query ?? '').trim().isEmpty ? null : query,
              'p_city': (city ?? '').trim().isEmpty ? null : city,
              'p_district': (district ?? '').trim().isEmpty ? null : district,
            },
          );
          if (res is List) {
            final items = res
                .whereType<Map>()
                .map((m) => AdminBusinessItem.fromMap(m.cast<String, dynamic>()))
                .toList();
            final slugs = await _fetchBusinessSlugs(
              items.map((e) => e.id).where((e) => e.isNotEmpty).toList(),
            );
            return items
                .map(
                  (item) => item.copyWith(
                    slug: slugs[item.id]?.slug ?? item.slug,
                    publicSlug: slugs[item.id]?.publicSlug ?? item.publicSlug,
                  ),
                )
                .toList();
          }
          return const <AdminBusinessItem>[];
        },
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<AdminBusinessItem?> fetchBusinessById({
    required String businessId,
  }) async {
    try {
      return MemoryTtlCache.instance.getOrLoad<AdminBusinessItem?>(
        key: '$_detailCachePrefix$businessId',
        ttl: _ttl,
        loader: () async {
          final row = await client
              .from('businesses')
              .select(
                'id,name,category,address,city,district,lat,lng,logo_url,cover_url,created_at,assigned_to,is_verified',
              )
              .eq('id', businessId)
              .maybeSingle();
          if (row == null) return null;
          return AdminBusinessItem.fromMap(row.cast<String, dynamic>());
        },
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> updateBusiness({
    required String businessId,
    required String name,
    String? category,
    String? address,
    String? city,
    String? district,
    double? lat,
    double? lng,
    String? logoUrl,
    String? coverUrl,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_update_business_v1',
        params: {
          'p_business_id': businessId,
          'p_name': name.trim(),
          'p_category': (category ?? '').trim().isEmpty
              ? null
              : category!.trim(),
          'p_address': (address ?? '').trim().isEmpty ? null : address!.trim(),
          'p_city': (city ?? '').trim().isEmpty ? null : city!.trim(),
          'p_district': (district ?? '').trim().isEmpty
              ? null
              : district!.trim(),
          'p_lat': lat,
          'p_lng': lng,
          'p_logo_url': (logoUrl ?? '').trim().isEmpty ? null : logoUrl!.trim(),
          'p_cover_url': (coverUrl ?? '').trim().isEmpty
              ? null
              : coverUrl!.trim(),
        },
        reason: 'business_updated',
        targetType: 'businesses',
        targetId: businessId,
      );
      _invalidateBusinessCaches();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> setBusinessAssignment({
    required String businessId,
    String? assignedTo,
  }) async {
    final normalizedAssignedTo = (assignedTo ?? '').trim();
    try {
      await client
          .from('businesses')
          .update({
            'assigned_to': normalizedAssignedTo.isEmpty
                ? null
                : normalizedAssignedTo,
          })
          .eq('id', businessId)
          .select('id')
          .maybeSingle();
      await invokeAdminRpcWrite(
        client,
        rpcName: 'log_admin_action_v1',
        params: {
          'p_action': normalizedAssignedTo.isEmpty
              ? 'business.unassigned'
              : 'business.assigned',
          'p_target_table': 'businesses',
          'p_target_id': businessId,
          'p_meta': {
            'assigned_to': normalizedAssignedTo.isEmpty
                ? null
                : normalizedAssignedTo,
          },
        },
        reason: normalizedAssignedTo.isEmpty
            ? 'business_unassigned'
            : 'business_assigned',
        targetType: 'businesses',
        targetId: businessId,
      );
      _invalidateBusinessCaches();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<AdminBusinessItem>> findMergeCandidates({
    required AdminBusinessItem source,
    int limit = 8,
  }) async {
    final name = source.name.trim();
    if (name.length < 2) return const [];
    try {
      var q = client
          .from('businesses')
          .select(
            'id,name,category,address,city,district,lat,lng,logo_url,cover_url,created_at',
          )
          .neq('id', source.id)
          .ilike('name', '%$name%');
      final city = (source.city ?? '').trim();
      if (city.isNotEmpty) q = q.eq('city', city);
      final district = (source.district ?? '').trim();
      if (district.isNotEmpty) q = q.eq('district', district);
      final res = await q.limit(limit);
      return (res as List)
          .whereType<Map>()
          .map((m) => AdminBusinessItem.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> logMergeProposal({
    required String primaryBusinessId,
    required String duplicateBusinessId,
    String? note,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'log_admin_action_v1',
        params: {
          'p_action': 'business.merge_proposed',
          'p_target_table': 'businesses',
          'p_target_id': duplicateBusinessId,
          'p_meta': {
            'primary_business_id': primaryBusinessId,
            'duplicate_business_id': duplicateBusinessId,
            'note': (note ?? '').trim(),
          },
        },
        reason: (note ?? '').trim().isEmpty
            ? 'business_merge_proposed'
            : note!.trim(),
        targetType: 'businesses',
        targetId: duplicateBusinessId,
      );
      _invalidateBusinessCaches();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, dynamic>> mergeBusinesses({
    required String primaryBusinessId,
    required String duplicateBusinessId,
    String? note,
    bool dryRun = false,
  }) async {
    try {
      final res = await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_merge_businesses_v1',
        params: {
          'p_primary_business_id': primaryBusinessId,
          'p_duplicate_business_id': duplicateBusinessId,
          'p_admin_note': (note ?? '').trim().isEmpty ? null : note!.trim(),
          'p_dry_run': dryRun,
        },
        reason: (note ?? '').trim().isEmpty ? 'business_merge' : note!.trim(),
        targetType: 'businesses',
        targetId: duplicateBusinessId,
      );
      if (res is Map) return res.cast<String, dynamic>();
      return {'ok': true};
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  void _invalidateBusinessCaches() {
    MemoryTtlCache.instance.invalidatePrefix(_cachePrefix);
    MemoryTtlCache.instance.invalidatePrefix(_detailCachePrefix);
  }

  Future<Map<String, BusinessRiskSignal>> fetchRiskSignals(
    List<String> businessIds,
  ) async {
    if (businessIds.isEmpty) return const {};
    try {
      final businessRows = await client
          .from('businesses')
          .select('id,address,phone')
          .inFilter('id', businessIds);
      final mediaRows = await client
          .from('business_media')
          .select('business_id')
          .inFilter('business_id', businessIds);
      final reviewRows = await client
          .from('reviews')
          .select('business_id')
          .eq('status', 'approved')
          .inFilter('business_id', businessIds);
      final favRows = await client
          .from('favorites')
          .select('business_id')
          .inFilter('business_id', businessIds);

      final mediaCount = <String, int>{};
      for (final row in (mediaRows as List?) ?? const []) {
        if (row is! Map) continue;
        final id = (row['business_id'] ?? '').toString();
        if (id.isEmpty) continue;
        mediaCount[id] = (mediaCount[id] ?? 0) + 1;
      }

      final reviewCount = <String, int>{};
      for (final row in (reviewRows as List?) ?? const []) {
        if (row is! Map) continue;
        final id = (row['business_id'] ?? '').toString();
        if (id.isEmpty) continue;
        reviewCount[id] = (reviewCount[id] ?? 0) + 1;
      }

      final favCount = <String, int>{};
      for (final row in (favRows as List?) ?? const []) {
        if (row is! Map) continue;
        final id = (row['business_id'] ?? '').toString();
        if (id.isEmpty) continue;
        favCount[id] = (favCount[id] ?? 0) + 1;
      }

      final result = <String, BusinessRiskSignal>{};
      for (final row in (businessRows as List?) ?? const []) {
        if (row is! Map) continue;
        final data = row.cast<String, dynamic>();
        final id = (data['id'] ?? '').toString();
        if (id.isEmpty) continue;
        final addressMissing = (data['address'] ?? '')
            .toString()
            .trim()
            .isEmpty;
        final phoneMissing = (data['phone'] ?? '').toString().trim().isEmpty;
        final photos = mediaCount[id] ?? 0;
        final engagement = (reviewCount[id] ?? 0) + (favCount[id] ?? 0);
        final missCount =
            (addressMissing ? 1 : 0) +
            (phoneMissing ? 1 : 0) +
            (photos == 0 ? 1 : 0) +
            (engagement == 0 ? 1 : 0);
        result[id] = BusinessRiskSignal(
          missingAddress: addressMissing,
          missingPhone: phoneMissing,
          photoCount: photos,
          engagementCount: engagement,
          suspicious: missCount >= 3,
          riskScore: missCount,
        );
      }
      return result;
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
      // Backward-compatible fallback when public_slug is not deployed.
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

class BusinessRiskSignal {
  const BusinessRiskSignal({
    required this.missingAddress,
    required this.missingPhone,
    required this.photoCount,
    required this.engagementCount,
    required this.suspicious,
    required this.riskScore,
  });

  final bool missingAddress;
  final bool missingPhone;
  final int photoCount;
  final int engagementCount;
  final bool suspicious;
  final int riskScore;
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
