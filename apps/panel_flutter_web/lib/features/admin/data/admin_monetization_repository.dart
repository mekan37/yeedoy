import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';
import '../domain/admin_models.dart';

final adminMonetizationRepositoryProvider =
    Provider<AdminMonetizationRepository>((ref) {
      final client = ref.watch(supabaseProvider);
      return AdminMonetizationRepository(client);
    });

class AdminMonetizationRepository {
  AdminMonetizationRepository(this.client);
  final SupabaseClient client;

  Future<List<AdminSponsorshipPackage>> listPackages() async {
    try {
      final res = await client
          .from('sponsorship_packages')
          .select()
          .order('created_at', ascending: false);
      return (res as List)
          .whereType<Map>()
          .map(
            (m) => AdminSponsorshipPackage.fromMap(m.cast<String, dynamic>()),
          )
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String?> upsertPackage({
    String? id,
    required String name,
    required String surface,
    required int durationDays,
    required String priceDisplay,
    required int priceCents,
    required String currencyCode,
    required int inventoryLimit,
    required bool isActive,
  }) async {
    try {
      final res = await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_upsert_sponsorship_package_v1',
        params: {
          'p_id': id,
          'p_name': name.trim(),
          'p_surface': surface,
          'p_duration_days': durationDays,
          'p_price_display': priceDisplay.trim(),
          'p_price_cents': priceCents,
          'p_currency_code': currencyCode.trim(),
          'p_inventory_limit': inventoryLimit,
          'p_is_active': isActive,
        },
        reason: 'sponsorship_package_upsert',
        targetType: 'sponsorship_packages',
        targetId: id,
      );
      if (res is Map) return res['id']?.toString();
      return null;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<AdminSponsorshipSummary?> fetchSummary() async {
    try {
      final res = await client.rpc('admin_get_sponsorship_summary_v1');
      if (res is List && res.isNotEmpty && res.first is Map) {
        return AdminSponsorshipSummary.fromMap(
          (res.first as Map).cast<String, dynamic>(),
        );
      }
      if (res is Map) {
        return AdminSponsorshipSummary.fromMap(res.cast<String, dynamic>());
      }
      return null;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<AdminSponsorshipInventorySurface>> listInventory() async {
    try {
      final res = await client.rpc('admin_list_sponsorship_inventory_v1');
      return (res as List)
          .whereType<Map>()
          .map(
            (m) => AdminSponsorshipInventorySurface.fromMap(
              m.cast<String, dynamic>(),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<AdminSponsorshipItem>> listSponsorships({
    String? status,
    String? surface,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc(
        'admin_list_sponsorships_v1',
        params: {
          'p_status': (status ?? '').trim().isEmpty ? null : status,
          'p_surface': (surface ?? '').trim().isEmpty ? null : surface,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return (res as List)
          .whereType<Map>()
          .map((m) => AdminSponsorshipItem.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String?> createSponsorship({
    required String businessId,
    required String packageId,
    required String surface,
    DateTime? startsAt,
    DateTime? endsAt,
    required Map<String, dynamic> targeting,
    int? dailyCap,
    int? totalCap,
  }) async {
    try {
      final res = await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_create_sponsorship_v1',
        params: {
          'p_business_id': businessId,
          'p_package_id': packageId,
          'p_surface': surface,
          'p_starts_at': startsAt?.toIso8601String(),
          'p_ends_at': endsAt?.toIso8601String(),
          'p_targeting': targeting,
          'p_daily_cap': dailyCap,
          'p_total_cap': totalCap,
        },
        reason: 'sponsorship_created',
        targetType: 'sponsorships',
        targetId: businessId,
      );
      if (res is Map) return res['id']?.toString();
      return null;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> setSponsorshipStatus({
    required String sponsorshipId,
    required String status,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_set_sponsorship_status_v1',
        params: {'p_sponsorship_id': sponsorshipId, 'p_status': status},
        reason: 'sponsorship_status_updated',
        targetType: 'sponsorships',
        targetId: sponsorshipId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<AdminSponsorshipLead>> listLeads({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc(
        'admin_list_sponsorship_leads_v1',
        params: {
          'p_status': (status ?? '').trim().isEmpty ? null : status,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return (res as List)
          .whereType<Map>()
          .map((m) => AdminSponsorshipLead.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> updateLeadStatus({
    required String leadId,
    required String status,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_update_sponsorship_lead_status_v1',
        params: {'p_id': leadId, 'p_status': status},
        reason: 'sponsorship_lead_status_updated',
        targetType: 'sponsorship_leads',
        targetId: leadId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> setBusinessVerified({
    required String businessId,
    required bool isVerified,
    required String tier,
    DateTime? endsAt,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_set_business_verified_v1',
        params: {
          'p_business_id': businessId,
          'p_is_verified': isVerified,
          'p_tier': tier,
          'p_ends_at': endsAt?.toIso8601String(),
        },
        reason: 'business_verified_status_updated',
        targetType: 'businesses',
        targetId: businessId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
