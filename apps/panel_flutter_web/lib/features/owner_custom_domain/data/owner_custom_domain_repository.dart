import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/owner_custom_domain_models.dart';

final ownerCustomDomainRepositoryProvider =
    Provider<OwnerCustomDomainRepository>((ref) {
  return OwnerCustomDomainRepository(ref.watch(supabaseProvider));
});

class OwnerCustomDomainRepository {
  OwnerCustomDomainRepository(this._client);
  final SupabaseClient _client;

  Future<CustomDomainInfo?> fetchDomain(String businessId) async {
    try {
      final res = await _client.rpc('get_custom_domain_v1', params: {
        'p_business_id': businessId,
      });
      if (res == null) return null;
      final map = (res as Map).cast<String, dynamic>();
      return CustomDomainInfo.fromMap(map);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<CustomDomainInfo> upsertDomain({
    required String businessId,
    required String domain,
  }) async {
    try {
      final res = await _client.rpc('upsert_custom_domain_v1', params: {
        'p_business_id': businessId,
        'p_domain': domain,
      });
      final map = (res as Map).cast<String, dynamic>();
      return CustomDomainInfo(
        domain: map['domain'] as String,
        dnsTxtToken: map['dns_txt_token'] as String,
        verifiedAt: null,
        isActive: false,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<bool> verifyDomain({
    required String businessId,
    required String domain,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'verify-domain',
        body: {'business_id': businessId, 'domain': domain},
      );
      final map = (res.data as Map).cast<String, dynamic>();
      return map['verified'] == true;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> deleteDomain(String businessId) async {
    try {
      await _client.rpc('delete_custom_domain_v1', params: {
        'p_business_id': businessId,
      });
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
