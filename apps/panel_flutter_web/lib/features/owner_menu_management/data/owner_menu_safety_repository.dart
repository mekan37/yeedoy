import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import 'owner_menu_repository.dart';
import '../domain/owner_menu_safety_models.dart';

final ownerMenuSafetyRepositoryProvider = Provider<OwnerMenuSafetyRepository>((
  ref,
) {
  return OwnerMenuSafetyRepository(ref.watch(supabaseProvider));
});

class OwnerMenuSafetyRepository {
  OwnerMenuSafetyRepository(this.client);

  final SupabaseClient client;

  Future<List<OwnerTrashEntry>> listTrash({required String businessId}) async {
    try {
      final res = await client.rpc(
        'list_owner_menu_trash_v1',
        params: {'p_business_id': businessId},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => OwnerTrashEntry.fromMap(row.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> restoreTrashEntry(OwnerTrashEntry entry) async {
    try {
      switch (entry.entityType) {
        case OwnerTrashEntityType.menu:
          await _rpcOk('owner_restore_menu_v1', {'p_menu_id': entry.entityId});
          break;
        case OwnerTrashEntityType.item:
          await _rpcOk(
            'owner_restore_menu_item_v1',
            {'p_item_id': entry.entityId},
          );
          break;
        case OwnerTrashEntityType.photo:
          await _rpcOk(
            'owner_restore_menu_item_photo_v1',
            {'p_photo_id': entry.entityId},
          );
          break;
      }
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> forceDeleteTrashEntry(OwnerTrashEntry entry) async {
    try {
      switch (entry.entityType) {
        case OwnerTrashEntityType.menu:
          await _rpcOk(
            'owner_force_delete_menu_v1',
            {'p_menu_id': entry.entityId},
          );
          break;
        case OwnerTrashEntityType.item:
          await _rpcOk(
            'owner_force_delete_menu_item_v1',
            {'p_item_id': entry.entityId},
          );
          break;
        case OwnerTrashEntityType.photo:
          await _rpcOk(
            'owner_force_delete_menu_item_photo_v1',
            {'p_photo_id': entry.entityId},
          );
          break;
      }
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<OwnerMenuVersionSnapshot>> listMenuVersions({
    required String menuId,
  }) async {
    try {
      final res = await client.rpc(
        'list_owner_menu_versions_v1',
        params: {'p_menu_id': menuId},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map(
            (row) =>
                OwnerMenuVersionSnapshot.fromMap(row.cast<String, dynamic>()),
          )
          .toList(growable: false);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<OwnerMenuVersionDetail> getMenuVersionDetail({
    required String snapshotId,
  }) async {
    try {
      final res = await client.rpc(
        'get_owner_menu_version_detail_v1',
        params: {'p_snapshot_id': snapshotId},
      );
      final map = _asMap(res);
      if (map.isEmpty) {
        throw Exception('not_found');
      }
      return OwnerMenuVersionDetail.fromMap(map);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<OwnerMenuStructureSummary> getCurrentMenuStructure({
    required String menuId,
  }) async {
    try {
      final menuRow = await client
          .from('menus')
          .select('id,title,kind')
          .eq('id', menuId)
          .maybeSingle();
      if (menuRow == null) {
        throw Exception('menu_not_found');
      }

      final menuRepo = OwnerMenuRepository(client);
      final sections = await menuRepo.listSections(menuId: menuId);
      final sectionTitles = sections
          .map((section) => section.title.trim())
          .where((title) => title.isNotEmpty)
          .toList(growable: false);
      final itemNames = <String>[];

      for (final section in sections) {
        var offset = 0;
        const pageSize = 200;
        while (true) {
          final items = await menuRepo.listItems(
            sectionId: section.id,
            limit: pageSize,
            offset: offset,
          );
          for (final item in items) {
            final name = item.name.trim();
            if (name.isNotEmpty) itemNames.add(name);
          }
          if (items.length < pageSize) break;
          offset += pageSize;
        }
      }

      return OwnerMenuStructureSummary(
        menuId: (menuRow['id'] ?? '').toString(),
        menuTitle: (menuRow['title'] ?? '').toString(),
        menuKind: _nullableString(menuRow['kind']),
        sectionTitles: sectionTitles,
        itemNames: itemNames,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<OwnerRestoreVersionResult> restoreMenuVersion({
    required String snapshotId,
    required String archiveCurrentMenuId,
  }) async {
    try {
      final res = await client.rpc(
        'owner_restore_menu_version_v1',
        params: {
          'p_snapshot_id': snapshotId,
          'p_archive_current_menu_id': archiveCurrentMenuId,
        },
      );
      final map = _asMap(res);
      if (map['ok'] == true) {
        return OwnerRestoreVersionResult(
          menuId: (map['menu_id'] ?? '').toString(),
        );
      }
      throw Exception((map['message'] ?? map['code'] ?? 'unknown').toString());
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> _rpcOk(String fn, Map<String, Object?> params) async {
    final res = await client.rpc(fn, params: params);
    final map = _asMap(res);
    if (map['ok'] == true) return;
    throw Exception((map['message'] ?? map['code'] ?? 'unknown').toString());
  }

  Map<String, dynamic> _asMap(dynamic res) {
    if (res is Map) return res.cast<String, dynamic>();
    if (res is List && res.isNotEmpty && res.first is Map) {
      return (res.first as Map).cast<String, dynamic>();
    }
    return const <String, dynamic>{};
  }
}

String? _nullableString(Object? value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return null;
  return text;
}
