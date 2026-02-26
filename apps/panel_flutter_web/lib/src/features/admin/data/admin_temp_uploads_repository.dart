import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/network/supabase_provider.dart';
import '../domain/admin_temp_upload_item.dart';

final adminTempUploadsRepositoryProvider = Provider<AdminTempUploadsRepository>(
  (ref) {
    final client = ref.watch(supabaseProvider);
    return AdminTempUploadsRepository(client);
  },
);

class AdminTempUploadsRepository {
  AdminTempUploadsRepository(this._client);

  final SupabaseClient _client;

  Future<List<AdminTempUploadItem>> listPending({int limit = 50}) async {
    try {
      final rows = await _client
          .from('temp_uploads')
          .select(
            'id,business_id,kind,storage_bucket,storage_path,status,created_at',
          )
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(limit);
      final items = (rows as List)
          .whereType<Map>()
          .map(
            (row) => AdminTempUploadItem.fromMap(row.cast<String, dynamic>()),
          )
          .toList(growable: false);

      return Future.wait(
        items.map((item) async {
          if (item.storagePath.trim().isEmpty) return item;
          try {
            final url = await _client.storage
                .from(item.storageBucket)
                .createSignedUrl(item.storagePath, 60 * 60);
            return item.copyWith(previewUrl: url);
          } catch (_) {
            return item;
          }
        }),
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> promote({
    required String tempUploadId,
    required String assetType,
    int menuVersion = 1,
  }) async {
    try {
      await _client.rpc(
        'promote_temp_upload_to_menu_asset_v1',
        params: {
          'p_temp_upload_id': tempUploadId,
          'p_asset_type': assetType,
          'p_menu_version': menuVersion,
        },
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> reject({
    required String tempUploadId,
    required String note,
    required String reviewerId,
  }) async {
    try {
      await _client
          .from('temp_uploads')
          .update({
            'status': 'rejected',
            'review_note': note.trim(),
            'reviewed_by': reviewerId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tempUploadId);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
