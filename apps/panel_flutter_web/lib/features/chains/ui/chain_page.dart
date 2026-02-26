import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../src/ui/components/app_scaffold.dart';

class ChainPage extends ConsumerStatefulWidget {
  const ChainPage({super.key, required this.chainId});

  final String chainId;

  @override
  ConsumerState<ChainPage> createState() => _ChainPageState();
}

class _ChainPageState extends ConsumerState<ChainPage> {
  Position? _pos;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _pos = pos);
    } catch (_) {
      // location optional
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      _chainOverviewProvider((widget.chainId, _pos?.latitude, _pos?.longitude)),
    );
    return AppScaffold(
      appBar: AppBar(title: const Text('Chain')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            AppErrorMapper.message(e),
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Sube bulunamadi.',
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }
          final first = items.first;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_chainOverviewProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(
                  first.chainName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (first.chainDescription.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    first.chainDescription,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Yakın şubeler',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Şube menü ve fiyatları farklı olabilir.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                for (final b in items) ...[
                  Card(
                    child: ListTile(
                      title: Text(
                        b.businessName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${b.branchLabel.isEmpty ? '-' : b.branchLabel} • ${b.district} / ${b.city}'
                        '${b.priceCompareLabel == null ? '' : '\n${b.priceCompareLabel}'}',
                      ),
                      trailing: b.distanceKm == null
                          ? null
                          : Text(
                              '${b.distanceKm!.toStringAsFixed(b.distanceKm! < 10 ? 1 : 0)} km',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                      onTap: () => context.go('/b/${b.businessId}'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

final _chainOverviewProvider = FutureProvider.autoDispose
    .family<List<_ChainBranchItem>, (String, double?, double?)>((
      ref,
      tuple,
    ) async {
      final client = ref.read(supabaseProvider);
      final chainId = tuple.$1;
      final lat = tuple.$2;
      final lng = tuple.$3;
      dynamic res;
      try {
        res = await client.rpc(
          'get_chain_overview_v2',
          params: {
            'p_chain_id': chainId,
            'p_lat': lat,
            'p_lng': lng,
            'p_limit': 40,
          },
        );
      } catch (_) {
        res = await client.rpc(
          'get_chain_overview_v1',
          params: {
            'p_chain_id': chainId,
            'p_lat': lat,
            'p_lng': lng,
            'p_limit': 40,
          },
        );
      }
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((e) => _ChainBranchItem.fromMap(e.cast<String, dynamic>()))
          .toList();
    });

class _ChainBranchItem {
  const _ChainBranchItem({
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
    required this.priceCompareLabel,
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
  final String? priceCompareLabel;

  factory _ChainBranchItem.fromMap(Map<String, dynamic> map) {
    final d = map['distance_km'];
    final avgPriceCents = (map['avg_price_cents'] as num?)?.toInt();
    final chainAvgPriceCents = (map['chain_avg_price_cents'] as num?)?.toInt();
    final deltaPct = (map['price_delta_pct'] as num?)?.toDouble();
    return _ChainBranchItem(
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
      priceCompareLabel: _priceCompareLabel(deltaPct),
    );
  }

  static String? _priceCompareLabel(double? priceDeltaPct) {
    if (priceDeltaPct == null) return null;
    if (priceDeltaPct >= 10) {
      return 'Bu şube daha pahalı (%${priceDeltaPct.toStringAsFixed(0)})';
    }
    if (priceDeltaPct <= -10) {
      return 'Bu şube daha uygun (%${priceDeltaPct.abs().toStringAsFixed(0)})';
    }
    return 'Zincir ortalamasına yakın';
  }
}

