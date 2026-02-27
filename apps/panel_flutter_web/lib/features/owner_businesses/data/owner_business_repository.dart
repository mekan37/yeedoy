import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<List<OwnerBusiness>> listMyBusinesses({
    String status = 'approved',
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      dynamic res;
      try {
        res = await client.rpc(
          'owner_list_my_businesses_v2',
          params: {'p_status': status, 'p_limit': limit, 'p_offset': offset},
        );
      } catch (_) {
        res = await client.rpc(
          'owner_list_my_businesses_v1',
          params: {'p_status': status, 'p_limit': limit, 'p_offset': offset},
        );
      }
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => OwnerBusiness.fromMap(row.cast<String, dynamic>()))
          .toList();
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
      final res = await client.rpc(
        'owner_list_my_business_submissions_v1',
        params: {'p_status': status, 'p_limit': limit, 'p_offset': offset},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => BusinessSubmission.fromMap(row.cast<String, dynamic>()))
          .toList();
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
      if (res is Map && res['ok'] == true) return;
      throw Exception((res is Map ? res['code'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
