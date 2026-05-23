import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/depolama/offline_mutation_idempotency.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../domain/kalabalik_modelleri.dart';

final crowdRepositoryProvider = Provider<CrowdRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return CrowdRepository(client);
});

class CrowdRepository {
  CrowdRepository(this.client);
  final SupabaseClient client;

  Future<BusinessCrowdStatus> fetchBusinessCrowd(String businessId) async {
    try {
      final res = await client.rpc('get_business_crowd_v1', params: {
        'p_business_id': businessId,
      });
      return BusinessCrowdStatus.fromMap((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> submitPresence({
    required String businessId,
    required String crowd,
  }) async {
    try {
      final bucketStart = _presenceBucketStartUtc(DateTime.now().toUtc());
      final token = await createOfflineMutationIdempotencyToken(
        action: 'submit_presence',
        payload: {
          'business_id': businessId,
          'crowd': crowd,
          'bucket_start_utc': bucketStart.toIso8601String(),
        },
      );
      final params = {
        'p_business_id': businessId,
        'p_crowd': crowd,
      };
      dynamic res;
      try {
        res = await client.rpc(
          'submit_presence_v2',
          params: {
            ...params,
            'p_idempotency_key': token.idempotencyKey,
          },
        );
      } catch (e) {
        if (!_isMissingRpcError(e, 'submit_presence_v2')) rethrow;
        res = await client.rpc('submit_presence_v1', params: params);
      }
      if (res is Map && res['ok'] == true) {
        return;
      }
      throw Exception((res is Map ? res['error'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

DateTime _presenceBucketStartUtc(DateTime value) {
  final minuteBucket = (value.minute ~/ 15) * 15;
  return DateTime.utc(
    value.year,
    value.month,
    value.day,
    value.hour,
    minuteBucket,
  );
}

bool _isMissingRpcError(Object error, String rpcName) {
  final text = error.toString().toLowerCase();
  final normalized = rpcName.toLowerCase();
  return text.contains(normalized) &&
      (text.contains('could not find') ||
          text.contains('does not exist') ||
          text.contains('not found') ||
          text.contains('undefined function') ||
          text.contains('pgrst202'));
}

