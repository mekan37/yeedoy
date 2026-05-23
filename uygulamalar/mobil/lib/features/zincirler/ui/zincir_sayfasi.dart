import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';

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
    final t = context.l10n;
    final tokens = AppTokens.of(context);
    final titleStyle = context.appText.titleMedium?.copyWith(
      fontWeight: FontWeight.w900,
    );
    final sectionTitleStyle = context.appText.titleSmall?.copyWith(
      fontWeight: FontWeight.w900,
    );
    final branchTitleStyle = context.appText.bodyLarge?.copyWith(
      fontWeight: FontWeight.w900,
    );
    final hintStyle = context.appText.bodySmall?.copyWith(
      color: AppColors.muted,
    );
    final async = ref.watch(
      _chainOverviewProvider((widget.chainId, _pos?.latitude, _pos?.longitude)),
    );
    return AppScaffold(
      appBar: AppBar(title: Text(t.chainPageTitle)),
      body: async.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => const AppSkeletonCard(),
        ),
        error: (e, _) => Center(
          child: Text(
            AppErrorMapper.message(e),
            style: context.bodyStyle.copyWith(color: AppColors.danger),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(t.chainPageNoBranches, style: context.subtitleStyle),
            );
          }
          final first = items.first;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_chainOverviewProvider),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                tokens.space16,
                tokens.space12,
                tokens.space16,
                tokens.space24,
              ),
              children: [
                Text(first.chainName, style: titleStyle),
                if (first.chainDescription.trim().isNotEmpty) ...[
                  SizedBox(height: tokens.space4),
                  Text(first.chainDescription, style: context.subtitleStyle),
                ],
                SizedBox(height: tokens.space12),
                Text(t.chainPageNearbyBranchesTitle, style: sectionTitleStyle),
                SizedBox(height: tokens.space4),
                Text(t.chainPageBranchMenuPriceHint, style: hintStyle),
                SizedBox(height: tokens.space8),
                for (final b in items) ...[
                  Card(
                    child: ListTile(
                      title: Text(b.businessName, style: branchTitleStyle),
                      subtitle: Text(
                        '${b.branchLabel.isEmpty ? '-' : b.branchLabel} • ${b.district} / ${b.city}'
                        '${_priceCompareLabel(context, b.priceDeltaPct) == null ? '' : '\n${_priceCompareLabel(context, b.priceDeltaPct)}'}',
                      ),
                      trailing: b.distanceKm == null
                          ? null
                          : Text(
                              '${b.distanceKm!.toStringAsFixed(b.distanceKm! < 10 ? 1 : 0)} km',
                              style: context.captionStyle,
                            ),
                      onTap: () => context.go('/isletme/${b.businessId}'),
                    ),
                  ),
                  SizedBox(height: tokens.space8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

String? _priceCompareLabel(BuildContext context, double? priceDeltaPct) {
  final t = context.l10n;
  if (priceDeltaPct == null) return null;
  if (priceDeltaPct >= 10) {
    return t.chainPageBranchMoreExpensive(priceDeltaPct.toStringAsFixed(0));
  }
  if (priceDeltaPct <= -10) {
    return t.chainPageBranchMoreAffordable(
      priceDeltaPct.abs().toStringAsFixed(0),
    );
  }
  return t.chainPageBranchNearAverage;
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
    );
  }
}



