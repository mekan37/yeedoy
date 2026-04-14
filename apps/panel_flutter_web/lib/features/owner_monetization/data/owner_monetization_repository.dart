import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';

final ownerMonetizationRepositoryProvider =
    Provider<OwnerMonetizationRepository>((ref) {
      final client = ref.watch(supabaseProvider);
      return OwnerMonetizationRepository(client);
    });

class OwnerMonetizationRepository {
  OwnerMonetizationRepository(this._client);

  final SupabaseClient _client;

  Future<List<OwnerSponsorshipCatalogItem>> fetchSponsorshipCatalog({
    required String businessId,
  }) async {
    try {
      final res = await _client.rpc(
        'owner_get_sponsorship_catalog_v1',
        params: {'p_business_id': businessId},
      );
      return (res as List)
          .whereType<Map>()
          .map(
            (row) => OwnerSponsorshipCatalogItem.fromMap(
              row.cast<String, dynamic>(),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> submitSponsorshipLead({
    required String businessId,
    required String phone,
    required String message,
    required String preferredSurface,
    required Map<String, dynamic> preferredTargeting,
  }) async {
    try {
      final res = await _client.rpc(
        'submit_sponsorship_lead_v1',
        params: {
          'p_business_id': businessId,
          'p_phone': phone.trim(),
          'p_message': message.trim(),
          'p_preferred_surface': preferredSurface,
          'p_preferred_targeting': preferredTargeting,
        },
      );
      if (res is Map) {
        final ok = res['ok'] == true;
        if (!ok) {
          throw Exception(
            res['error']?.toString() ?? 'Talep kaydi basarisiz.',
          );
        }
      }
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

class OwnerSponsorshipCatalogItem {
  OwnerSponsorshipCatalogItem({
    required this.packageId,
    required this.packageName,
    required this.surface,
    required this.durationDays,
    required this.priceDisplay,
    required this.priceCents,
    required this.currencyCode,
    required this.inventoryLimit,
    required this.surfaceLiveUnits,
    required this.surfaceOpenSlots,
    required this.businessLiveUnits,
    required this.businessImpressions30d,
    required this.businessUniqueUsers30d,
    required this.latestLeadStatus,
  });

  final String packageId;
  final String packageName;
  final String surface;
  final int durationDays;
  final String priceDisplay;
  final int priceCents;
  final String currencyCode;
  final int inventoryLimit;
  final int surfaceLiveUnits;
  final int surfaceOpenSlots;
  final int businessLiveUnits;
  final int businessImpressions30d;
  final int businessUniqueUsers30d;
  final String? latestLeadStatus;

  factory OwnerSponsorshipCatalogItem.fromMap(Map<String, dynamic> map) {
    int asInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return OwnerSponsorshipCatalogItem(
      packageId: map['package_id']?.toString() ?? '',
      packageName: map['package_name']?.toString() ?? '',
      surface: map['surface']?.toString() ?? '',
      durationDays: asInt(map['duration_days']),
      priceDisplay: map['price_display']?.toString() ?? '',
      priceCents: asInt(map['price_cents']),
      currencyCode: map['currency_code']?.toString() ?? 'TRY',
      inventoryLimit: asInt(map['inventory_limit']),
      surfaceLiveUnits: asInt(map['surface_live_units']),
      surfaceOpenSlots: asInt(map['surface_open_slots']),
      businessLiveUnits: asInt(map['business_live_units']),
      businessImpressions30d: asInt(map['business_impressions_30d']),
      businessUniqueUsers30d: asInt(map['business_unique_users_30d']),
      latestLeadStatus: map['latest_lead_status']?.toString(),
    );
  }
}

