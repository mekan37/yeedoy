import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/memory_ttl_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/owner_menu_models.dart';

final ownerMenuRepositoryProvider = Provider<OwnerMenuRepository>((ref) {
  return OwnerMenuRepository(ref.watch(supabaseProvider));
});

class OwnerMenuRepository {
  OwnerMenuRepository(this.client);
  final SupabaseClient client;
  static const _menuCachePrefix = 'owner_menus:';
  static const _ttl = Duration(seconds: 45);

  Future<List<OwnerMenu>> listMenus({required String businessId}) async {
    try {
      return MemoryTtlCache.instance.getOrLoad<List<OwnerMenu>>(
        key: '$_menuCachePrefix$businessId',
        ttl: _ttl,
        loader: () async {
          final List<dynamic> res = await client
              .from('menus')
              .select(
                'id,business_id,title,status,kind,active_from,active_to,created_at,updated_at,version,source,confidence_score',
              )
              .eq('business_id', businessId)
              .order('created_at', ascending: false);
          return res
              .whereType<Map>()
              .map((m) => OwnerMenu.fromMap(m.cast<String, dynamic>()))
              .toList();
        },
      );
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<OwnerRpcResult> createMenu({
    required String businessId,
    required String title,
    String? kind,
    DateTime? activeFrom,
    DateTime? activeTo,
  }) async {
    try {
      final res = await client.rpc(
        'owner_create_menu_v1',
        params: {
          'p_business_id': businessId,
          'p_title': title.trim(),
          'p_kind': (kind ?? '').trim().isEmpty ? null : kind!.trim(),
          'p_active_from': activeFrom?.toIso8601String(),
          'p_active_to': activeTo?.toIso8601String(),
        },
      );
      final result = OwnerRpcResult.fromResponse(res);
      if (!result.ok) {
        throw OwnerMenuException(
          result.code ?? 'unknown',
          result.message ?? 'Bilinmeyen hata',
        );
      }
      _invalidateMenuCache(businessId);
      return result;
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<OwnerRpcResult> updateMenu({
    required String menuId,
    String? title,
    String? kind,
    DateTime? activeFrom,
    DateTime? activeTo,
  }) async {
    try {
      final res = await client.rpc(
        'owner_update_menu_v1',
        params: {
          'p_menu_id': menuId,
          'p_title': title?.trim(),
          'p_kind': kind?.trim(),
          'p_active_from': activeFrom?.toIso8601String(),
          'p_active_to': activeTo?.toIso8601String(),
        },
      );
      final result = OwnerRpcResult.fromResponse(res);
      if (!result.ok) {
        throw OwnerMenuException(
          result.code ?? 'unknown',
          result.message ?? 'Bilinmeyen hata',
        );
      }
      MemoryTtlCache.instance.invalidatePrefix(_menuCachePrefix);
      return result;
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<OwnerRpcResult> archiveMenu({required String menuId}) async {
    try {
      final res = await client.rpc(
        'owner_archive_menu_v1',
        params: {'p_menu_id': menuId},
      );
      final result = OwnerRpcResult.fromResponse(res);
      if (!result.ok) {
        throw OwnerMenuException(
          result.code ?? 'unknown',
          result.message ?? 'Bilinmeyen hata',
        );
      }
      MemoryTtlCache.instance.invalidatePrefix(_menuCachePrefix);
      return result;
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<OwnerRpcResult> publishMenu({required String menuId}) async {
    try {
      final res = await client.rpc(
        'owner_publish_menu_v1',
        params: {'p_menu_id': menuId},
      );
      final result = OwnerRpcResult.fromResponse(res);
      if (!result.ok) {
        throw OwnerMenuException(
          result.code ?? 'unknown',
          result.message ?? 'Bilinmeyen hata',
        );
      }
      MemoryTtlCache.instance.invalidatePrefix(_menuCachePrefix);
      return result;
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<List<OwnerMenuSection>> listSections({required String menuId}) async {
    try {
      final res = await client.rpc(
        'get_menu_sections_v1',
        params: {'p_menu_id': menuId},
      );
      return (res as List)
          .map(
            (row) =>
                OwnerMenuSection.fromMap((row as Map).cast<String, dynamic>()),
          )
          .toList();
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<OwnerRpcResult> createSection({
    required String menuId,
    required String title,
    int? sortOrder,
  }) async {
    try {
      final res = await client.rpc(
        'owner_create_menu_section_v1',
        params: {
          'p_menu_id': menuId,
          'p_title': title.trim(),
          'p_sort_order': sortOrder,
        },
      );
      final result = OwnerRpcResult.fromResponse(res);
      if (!result.ok) {
        throw OwnerMenuException(
          result.code ?? 'unknown',
          result.message ?? 'Bilinmeyen hata',
        );
      }
      return result;
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<OwnerRpcResult> updateSection({
    required String sectionId,
    required String title,
  }) async {
    try {
      final res = await client.rpc(
        'owner_update_menu_section_v1',
        params: {'p_section_id': sectionId, 'p_title': title.trim()},
      );
      final result = OwnerRpcResult.fromResponse(res);
      if (!result.ok) {
        throw OwnerMenuException(
          result.code ?? 'unknown',
          result.message ?? 'Bilinmeyen hata',
        );
      }
      return result;
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<OwnerRpcResult> deleteSection({
    required String sectionId,
    required bool deleteItems,
  }) async {
    try {
      final res = await client.rpc(
        'owner_delete_menu_section_v1',
        params: {'p_section_id': sectionId, 'p_delete_items': deleteItems},
      );
      final result = OwnerRpcResult.fromResponse(res);
      if (!result.ok) {
        throw OwnerMenuException(
          result.code ?? 'unknown',
          result.message ?? 'Bilinmeyen hata',
        );
      }
      return result;
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<OwnerRpcResult> reorderSections({
    required String menuId,
    required List<String> sectionIds,
  }) async {
    try {
      final res = await client.rpc(
        'owner_reorder_menu_sections_v1',
        params: {'p_menu_id': menuId, 'p_section_ids': sectionIds},
      );
      final result = OwnerRpcResult.fromResponse(res);
      if (!result.ok) {
        throw OwnerMenuException(
          result.code ?? 'unknown',
          result.message ?? 'Bilinmeyen hata',
        );
      }
      return result;
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<List<OwnerMenuItem>> listItems({
    required String sectionId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc(
        'get_menu_items_v2',
        params: {
          'p_section_id': sectionId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return (res as List)
          .map(
            (row) =>
                OwnerMenuItem.fromMap((row as Map).cast<String, dynamic>()),
          )
          .toList();
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<OwnerRpcResult> createItem({
    required String sectionId,
    required String name,
    String? description,
    int? priceCents,
    String currency = 'TRY',
    int? catalogItemId,
  }) async {
    try {
      final res = await client.rpc(
        'owner_create_menu_item_v1',
        params: {
          'p_section_id': sectionId,
          'p_name': name.trim(),
          'p_description': (description ?? '').trim(),
          'p_price_cents': priceCents,
          'p_currency': currency.trim(),
          'p_catalog_item_id': catalogItemId,
        },
      );
      final result = OwnerRpcResult.fromResponse(res);
      if (!result.ok) {
        throw OwnerMenuException(
          result.code ?? 'unknown',
          result.message ?? 'Bilinmeyen hata',
        );
      }
      return result;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<OwnerRpcResult> updateItem({
    required String itemId,
    String? name,
    String? description,
    int? priceCents,
    String? currency,
    int? catalogItemId,
  }) async {
    try {
      final res = await client.rpc(
        'owner_update_menu_item_v1',
        params: {
          'p_item_id': itemId,
          'p_name': name?.trim(),
          'p_description': description?.trim(),
          'p_price_cents': priceCents,
          'p_currency': currency?.trim(),
          'p_catalog_item_id': catalogItemId,
        },
      );
      final result = OwnerRpcResult.fromResponse(res);
      if (!result.ok) {
        throw OwnerMenuException(
          result.code ?? 'unknown',
          result.message ?? 'Bilinmeyen hata',
        );
      }
      return result;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<OwnerRpcResult> archiveItem({required String itemId}) async {
    try {
      final res = await client.rpc(
        'owner_archive_menu_item_v1',
        params: {'p_item_id': itemId},
      );
      final result = OwnerRpcResult.fromResponse(res);
      if (!result.ok) {
        throw OwnerMenuException(
          result.code ?? 'unknown',
          result.message ?? 'Bilinmeyen hata',
        );
      }
      return result;
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<List<OwnerMenuItemVariant>> listItemVariants({
    required String itemId,
  }) async {
    try {
      final res = await client
          .from('menu_item_variants')
          .select(
            'id,menu_item_id,label,price_cents,currency,is_default,is_available,sort_order',
          )
          .eq('menu_item_id', itemId)
          .order('sort_order', ascending: true);
      return (res as List)
          .whereType<Map>()
          .map(
            (row) => OwnerMenuItemVariant.fromMap(row.cast<String, dynamic>()),
          )
          .toList(growable: false);
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<void> createItemVariant({
    required String itemId,
    required String label,
    required int priceCents,
    String currency = 'TRY',
    bool isDefault = false,
  }) async {
    try {
      if (isDefault) {
        await client
            .from('menu_item_variants')
            .update({'is_default': false})
            .eq('menu_item_id', itemId);
      }
      final maxSortRow = await client
          .from('menu_item_variants')
          .select('sort_order')
          .eq('menu_item_id', itemId)
          .order('sort_order', ascending: false)
          .limit(1)
          .maybeSingle();
      final nextSort = ((maxSortRow?['sort_order'] as num?)?.toInt() ?? -1) + 1;
      await client.from('menu_item_variants').insert({
        'menu_item_id': itemId,
        'label': label.trim(),
        'price_cents': priceCents,
        'currency': currency.trim().isEmpty ? 'TRY' : currency.trim(),
        'is_default': isDefault,
        'is_available': true,
        'sort_order': nextSort,
      });
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<void> setDefaultItemVariant({
    required String itemId,
    required String variantId,
  }) async {
    try {
      await client
          .from('menu_item_variants')
          .update({'is_default': false})
          .eq('menu_item_id', itemId);
      await client
          .from('menu_item_variants')
          .update({'is_default': true})
          .eq('id', variantId)
          .eq('menu_item_id', itemId);
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<void> deleteItemVariant({required String variantId}) async {
    try {
      await client.from('menu_item_variants').delete().eq('id', variantId);
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  Future<Map<String, dynamic>> getPublicMenuShare({
    required String menuId,
  }) async {
    try {
      final res = await client.rpc(
        'public_menu_share_view_v1',
        params: {'p_menu_id': menuId},
      );
      if (res is Map) return res.cast<String, dynamic>();
      if (res is List && res.isNotEmpty && res.first is Map) {
        return (res.first as Map).cast<String, dynamic>();
      }
      return {'menu': null, 'sections': []};
    } catch (e) {
      _rethrowMapped(e);
    }
  }

  void _invalidateMenuCache(String businessId) {
    MemoryTtlCache.instance.invalidate('$_menuCachePrefix$businessId');
  }
}

Never _rethrowMapped(Object error) {
  if (error is OwnerMenuException) {
    throw error;
  }
  throw Exception(AppErrorMapper.message(error));
}
