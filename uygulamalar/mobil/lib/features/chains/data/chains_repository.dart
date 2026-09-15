import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

final chainsRepositoryProvider = Provider<ChainsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return ChainsRepository(client);
});

class ChainBranchItem {
  const ChainBranchItem({
    required this.businessId,
    required this.businessName,
    required this.chainName,
    required this.chainDescription,
    required this.branchLabel,
    required this.city,
    required this.district,
    required this.distanceKm,
    required this.avgPriceCents,
    required this.chainAvgPriceCents,
    required this.priceDeltaPct,
  });

  final String businessId;
  final String businessName;
  final String chainName;
  final String chainDescription;
  final String branchLabel;
  final String city;
  final String district;
  final double? distanceKm;
  final int? avgPriceCents;
  final int? chainAvgPriceCents;
  final double? priceDeltaPct;

  factory ChainBranchItem.fromMap(Map<String, dynamic> map) {
    final d = map['distance_km'];
    final avgPriceCents = (map['avg_price_cents'] as num?)?.toInt();
    final chainAvgPriceCents = (map['chain_avg_price_cents'] as num?)?.toInt();
    final deltaPct = (map['price_delta_pct'] as num?)?.toDouble();
    return ChainBranchItem(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      chainName: (map['chain_name'] ?? '').toString(),
      chainDescription: (map['chain_description'] ?? '').toString(),
      branchLabel: (map['branch_label'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      distanceKm: d is num
          ? d.toDouble()
          : double.tryParse((d ?? '').toString()),
      avgPriceCents: avgPriceCents,
      chainAvgPriceCents: chainAvgPriceCents,
      priceDeltaPct: deltaPct,
    );
  }
}

class ChainsRepository {
  ChainsRepository(this.client);
  final SupabaseClient client;

  /// v2→v1 fallback: v2 mesafe/fiyat karşılaştırması ekliyor, eski
  /// sürümlerde/olası regresyonda v1'e düşer.
  Future<List<ChainBranchItem>> getChainOverview({
    required String chainId,
    double? lat,
    double? lng,
    int limit = 40,
  }) async {
    dynamic res;
    try {
      res = await client.rpc(
        'get_chain_overview_v2',
        params: {
          'p_chain_id': chainId,
          'p_lat': lat,
          'p_lng': lng,
          'p_limit': limit,
        },
      );
    } catch (_) {
      res = await client.rpc(
        'get_chain_overview_v1',
        params: {
          'p_chain_id': chainId,
          'p_lat': lat,
          'p_lng': lng,
          'p_limit': limit,
        },
      );
    }
    final rows = (res as List?) ?? const [];
    return rows
        .whereType<Map>()
        .map((e) => ChainBranchItem.fromMap(e.cast<String, dynamic>()))
        .toList();
  }
}
