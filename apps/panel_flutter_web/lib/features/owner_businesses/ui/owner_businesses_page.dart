import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../owner_dashboard/domain/owner_growth_provider.dart';
import '../../../shared/ui/components/app_scaffold.dart';
import '../data/owner_business_repository.dart';
import '../domain/owner_business_models.dart';
import '../domain/owner_business_providers.dart';

class OwnerBusinessesPage extends ConsumerStatefulWidget {
  const OwnerBusinessesPage({super.key});

  @override
  ConsumerState<OwnerBusinessesPage> createState() =>
      _OwnerBusinessesPageState();
}

class _OwnerBusinessesPageState extends ConsumerState<OwnerBusinessesPage> {
  String? _selectedBusinessId;
  String _selectedChainId = '';

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(ownerBusinessesProvider);

    return AppScaffold(
      appBar: AppBar(
        title: Text(context.l10n.ownerBusinessesTitle),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(ownerBusinessesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: businessesAsync.when(
        loading: () => const _OwnerBusinessesSkeleton(),
        error: (e, _) => _ErrorState(
          message: AppErrorMapper.message(e),
          onRetry: () => ref.invalidate(ownerBusinessesProvider),
        ),
        data: (items) {
          if (items.isEmpty) return const _EmptyState();

          final chains = <String, String>{};
          for (final item in items) {
            final chainId = item.chainId;
            final chainName = item.chainName;
            if (chainId == null || chainId.isEmpty) continue;
            if (chainName == null || chainName.isEmpty) continue;
            chains[chainId] = chainName;
          }

          if (_selectedChainId.isNotEmpty &&
              !chains.containsKey(_selectedChainId)) {
            _selectedChainId = '';
          }

          final visible = _selectedChainId.isEmpty
              ? items
              : items.where((e) => e.chainId == _selectedChainId).toList();
          if (visible.isEmpty) return const _EmptyState();

          _selectedBusinessId ??= visible.first.businessId;
          if (!visible.any((e) => e.businessId == _selectedBusinessId)) {
            _selectedBusinessId = visible.first.businessId;
          }
          final selectedBusinessId = _selectedBusinessId!;
          final selectedBusiness = visible.firstWhere(
            (e) => e.businessId == selectedBusinessId,
          );

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ownerBusinessesProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (chains.isNotEmpty) ...[
                  _ChainSwitcher(
                    chains: chains,
                    selectedChainId: _selectedChainId,
                    onChanged: (id) => setState(() => _selectedChainId = id),
                  ),
                  const SizedBox(height: 10),
                ],
                _BusinessSwitcher(
                  items: visible,
                  selectedBusinessId: selectedBusinessId,
                  onChanged: (id) => setState(() => _selectedBusinessId = id),
                ),
                const SizedBox(height: 12),
                _BranchQuickActions(
                  selectedBusinessId: selectedBusinessId,
                  ownerRole: selectedBusiness.ownerRole,
                  onEditCommerceLinks: () =>
                      _openCommerceLinksSheet(selectedBusinessId),
                ),
                if (_selectedChainId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/chain/$_selectedChainId'),
                      icon: const Icon(Icons.hub_outlined),
                      label: Text(context.l10n.ownerChainPage),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _OwnerGrowthCard(businessId: selectedBusinessId),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.go('/owner/businesses/new'),
                        icon: const Icon(Icons.add_business),
                        label: Text(context.l10n.ownerNewBusinessTitle),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/owner/businesses/submissions'),
                        icon: const Icon(Icons.assignment_outlined),
                        label: Text(context.l10n.ownerMyApplications),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final business in visible) ...[
                  _BusinessCard(
                    item: business,
                    selected: business.businessId == selectedBusinessId,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCommerceLinksSheet(String businessId) async {
    final l10n = context.l10n;
    final reservationCtrl = TextEditingController();
    final yemeksepetiCtrl = TextEditingController();
    final trendyolgoCtrl = TextEditingController();
    final getirCtrl = TextEditingController();
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.ownerReservationOrderLinksTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reservationCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.ownerReservationUrlLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: yemeksepetiCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.ownerYemeksepetiUrlLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: trendyolgoCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.ownerTrendyolGoUrlLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: getirCtrl,
                    decoration: InputDecoration(labelText: l10n.ownerGetirUrlLabel),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              try {
                                await ref
                                    .read(ownerBusinessRepositoryProvider)
                                    .updateCommerceLinks(
                                      businessId: businessId,
                                      reservationUrl: reservationCtrl.text.trim(),
                                      orderYemeksepetiUrl: yemeksepetiCtrl.text
                                          .trim(),
                                      orderTrendyolgoUrl: trendyolgoCtrl.text
                                          .trim(),
                                      orderGetirUrl: getirCtrl.text.trim(),
                                    );
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.ownerLinksUpdated),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppErrorMapper.message(e)),
                                    ),
                                  );
                                }
                                setModalState(() => saving = false);
                              }
                            },
                      child: Text(saving ? l10n.saving : l10n.save),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    reservationCtrl.dispose();
    yemeksepetiCtrl.dispose();
    trendyolgoCtrl.dispose();
    getirCtrl.dispose();
  }
}

class _ChainSwitcher extends StatelessWidget {
  const _ChainSwitcher({
    required this.chains,
    required this.selectedChainId,
    required this.onChanged,
  });

  final Map<String, String> chains;
  final String selectedChainId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${context.l10n.ownerChainLabel}:',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedChainId.isEmpty ? '__all__' : selectedChainId,
            items: [
              DropdownMenuItem(
                value: '__all__',
                child: Text(context.l10n.ownerAllBranches),
              ),
              ...chains.entries.map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              onChanged(value == '__all__' ? '' : value);
            },
          ),
        ),
      ],
    );
  }
}

class _BusinessSwitcher extends StatelessWidget {
  const _BusinessSwitcher({
    required this.items,
    required this.selectedBusinessId,
    required this.onChanged,
  });

  final List<OwnerBusiness> items;
  final String selectedBusinessId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${context.l10n.ownerBranchLabel}:',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedBusinessId,
            items: [
              for (final item in items)
                DropdownMenuItem(
                  value: item.businessId,
                  child: Text(
                    item.branchLabel?.trim().isNotEmpty == true
                        ? '${item.businessName} (${item.branchLabel})'
                        : item.businessName,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.item, required this.selected});

  final OwnerBusiness item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.claimStatus) {
      'approved' => AppColors.success,
      'rejected' => AppColors.danger,
      _ => AppColors.warning,
    };
    final roleLabel = item.ownerRole == 'owner'
        ? context.l10n.ownerRoleOwner
        : context.l10n.ownerRoleManager;
    final location = '${item.district} • ${item.city}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.businessName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.branchLabel?.trim().isNotEmpty == true
                  ? '${item.branchLabel} • $location'
                  : location,
              style: const TextStyle(color: AppColors.muted),
            ),
            if (item.chainName?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                context.l10n.ownerChainPrefix(item.chainName!),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _statusLabel(context, item.claimStatus),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _fmtDate(item.claimedAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchQuickActions extends StatelessWidget {
  const _BranchQuickActions({
    required this.selectedBusinessId,
    required this.ownerRole,
    required this.onEditCommerceLinks,
  });
  final String selectedBusinessId;
  final String ownerRole;
  final VoidCallback onEditCommerceLinks;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () =>
                  context.go('/owner/menus?businessId=$selectedBusinessId'),
              icon: const Icon(Icons.restaurant_menu),
              label: Text(context.l10n.ownerMenuAction),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go(
                '/owner/price-suggestions?businessId=$selectedBusinessId',
              ),
              icon: const Icon(Icons.price_change_outlined),
              label: Text(context.l10n.ownerPriceVerificationAction),
            ),
            OutlinedButton.icon(
              onPressed: ownerRole == 'manager'
                  ? null
                  : () => context.go(
                      '/owner/requests?businessId=$selectedBusinessId',
                    ),
              icon: const Icon(Icons.groups_2_outlined),
              label: Text(
                ownerRole == 'manager'
                    ? context.l10n.ownerRequestsOwnerOnly
                    : context.l10n.ownerRequestsAction,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onEditCommerceLinks,
              icon: const Icon(Icons.link_outlined),
              label: Text(context.l10n.ownerReservationOrderLinksAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerGrowthCard extends ConsumerWidget {
  const _OwnerGrowthCard({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final growthAsync = ref.watch(ownerGrowthSummaryProvider(businessId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: growthAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 6),
          error: (e, _) => Text(
            AppErrorMapper.message(e),
            style: const TextStyle(color: AppColors.danger),
          ),
          data: (data) {
            if (data == null) {
              return Text(
                context.l10n.ownerStatsNotFound,
                style: const TextStyle(color: AppColors.muted),
              );
            }
            final searchImpressions = data.searchImpressions;
            final conversionRate = searchImpressions > 0
                ? (data.conversions / searchImpressions) * 100.0
                : 0.0;
            final pricePosition = _pricePositionLabel(
              context,
              data.districtPricePosition,
              data.districtPriceGapPct,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.ownerPerformanceLast30Days,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill(
                      label: context.l10n.ownerMetricMenuViews,
                      value: '${data.menuViews}',
                    ),
                    _MetricPill(
                      label: context.l10n.ownerMetricQrScans,
                      value: '${data.qrScans}',
                    ),
                    _MetricPill(
                      label: context.l10n.ownerMetricSearchImpressions,
                      value: '$searchImpressions',
                    ),
                    _MetricPill(
                      label: context.l10n.ownerMetricConversion,
                      value:
                          '${data.conversions} (${conversionRate.toStringAsFixed(1)}%)',
                    ),
                    _MetricPill(
                      label: context.l10n.ownerMetricOutboundClicks,
                      value: context.l10n.ownerOutboundClicksValue(
                        data.outboundClicks,
                        data.reservationClicks,
                        data.orderClicks,
                      ),
                    ),
                    _MetricPill(
                      label: context.l10n.ownerMetricPriceDropoff,
                      value: '${data.priceDropoffEstimate}',
                    ),
                    _MetricPill(
                      label: context.l10n.ownerMetricPriceVsCompetitors,
                      value: pricePosition,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _pricePositionLabel(BuildContext context, String position, double? gapPct) {
  final pctText = gapPct == null ? '' : ' (%${gapPct.abs().toStringAsFixed(0)})';
  return switch (position) {
    'higher' => context.l10n.ownerPricePositionHigher(pctText),
    'lower' => context.l10n.ownerPricePositionLower(pctText),
    'similar' => context.l10n.ownerPricePositionSimilar,
    _ => context.l10n.ownerPricePositionNoData,
  };
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OwnerBusinessesSkeleton extends StatelessWidget {
  const _OwnerBusinessesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonLine(width: 160),
              SizedBox(height: 8),
              _SkeletonLine(width: 120),
              SizedBox(height: 12),
              _SkeletonLine(width: 90),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.width});
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(height: 10, width: width, color: AppColors.card);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              context.l10n.ownerNoBusinessesTitle,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.ownerNoBusinessesDescription,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(BuildContext context, String status) {
  return switch (status) {
    'approved' => context.l10n.approved,
    'rejected' => context.l10n.rejected,
    'pending' => context.l10n.pending,
    _ => status,
  };
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
