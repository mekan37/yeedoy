import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/design_system.dart';
import '../data/chains_repository.dart';

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
                      onTap: () => context.go('/b/${b.businessId}'),
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
    .family<List<ChainBranchItem>, (String, double?, double?)>((
      ref,
      tuple,
    ) async {
      final repository = ref.watch(chainsRepositoryProvider);
      return repository.getChainOverview(
        chainId: tuple.$1,
        lat: tuple.$2,
        lng: tuple.$3,
      );
    });
