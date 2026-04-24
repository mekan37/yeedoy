import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/navigation/public_menu_url.dart';
import '../../../core/web/web_utils.dart';
import '../../owner_dashboard/domain/owner_growth_provider.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../data/owner_business_repository.dart';
import '../domain/owner_business_models.dart';
import '../domain/owner_business_providers.dart';
import '../domain/owner_business_state.dart';

class OwnerBusinessesPage extends ConsumerStatefulWidget {
  const OwnerBusinessesPage({super.key});

  @override
  ConsumerState<OwnerBusinessesPage> createState() =>
      _OwnerBusinessesPageState();
}

class _OwnerBusinessesPageState extends ConsumerState<OwnerBusinessesPage> {
  String _selectedChainId = '';

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(ownerBusinessesProvider);

    return businessesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: OwnerPanelFeedback.loading(),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: OwnerPanelFeedback.error(
            title: context.l10n.ownerBusinessesTitle,
            description: AppErrorMapper.message(e),
            onRetry: () => ref.invalidate(ownerBusinessesProvider),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: OwnerPanelFeedback.empty(
                icon: Icons.store_outlined,
                title: context.l10n.ownerNoBusinessesTitle,
                description: context.l10n.ownerNoBusinessesDescription,
              ),
            );
          }

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
          if (visible.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: OwnerPanelFeedback.empty(
                icon: Icons.account_tree_outlined,
                title: context.l10n.ownerNoBusinessesTitle,
                description: context.l10n.ownerBusinessContextEmptyDescription,
              ),
            );
          }

          final selectedBusinessIdState = ref.watch(
            selectedOwnerBusinessIdProvider,
          );
          final selectedBusinessId = visible.any(
            (e) => e.businessId == selectedBusinessIdState,
          )
              ? selectedBusinessIdState!
              : visible.first.businessId;
          if (selectedBusinessIdState != selectedBusinessId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ref.read(selectedOwnerBusinessIdProvider.notifier).state =
                  selectedBusinessId;
            });
          }
          final selectedBusiness = visible.firstWhere(
            (e) => e.businessId == selectedBusinessId,
          );

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ownerBusinessesProvider),
            child: CustomScrollView(
              cacheExtent: 1200,
              slivers: [
                SliverToBoxAdapter(
                  child: PanelPageHeader(
                    eyebrow: 'Owner',
                    title: Text(context.l10n.ownerBusinessesTitle),
                    description: 'Sahip olduğunuz işletmeleri yönetin, menüye erişin ve performansı takip edin.',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (chains.isNotEmpty) ...[
                        _ChainSwitcher(
                          chains: chains,
                          selectedChainId: _selectedChainId,
                          onChanged: (id) => setState(() => _selectedChainId = id),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _BranchQuickActions(
                        selectedBusinessId: selectedBusinessId,
                        ownerRole: selectedBusiness.ownerRole,
                        onEditCommerceLinks: () =>
                            _openCommerceLinksSheet(selectedBusinessId),
                        onCreateQrMenu: () => _openQrMenu(selectedBusinessId),
                        onOpenPublicMenu: () => _openPublicMenu(
                          selectedBusinessId,
                          publicSlug: selectedBusiness.publicSlug,
                          slug: selectedBusiness.slug,
                        ),
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
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final business = visible[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == visible.length - 1 ? 0 : 10,
                        ),
                        child: _BusinessCard(
                          item: business,
                          selected: business.businessId == selectedBusinessId,
                          onCreateQrMenu: () => _openQrMenu(business.businessId),
                          onOpenPublicMenu: () => _openPublicMenu(
                            business.businessId,
                            publicSlug: business.publicSlug,
                            slug: business.slug,
                          ),
                        ),
                      );
                    }, childCount: visible.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
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
                    decoration: InputDecoration(
                      labelText: l10n.ownerGetirUrlLabel,
                    ),
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
                                      reservationUrl: reservationCtrl.text
                                          .trim(),
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

  Future<void> _openPublicMenu(
    String businessId, {
    String? publicSlug,
    String? slug,
  }) async {
    final url = buildPublicMenuUrl(
      businessId: businessId,
      businessPublicSlug: publicSlug,
      businessSlug: slug,
    );
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openQrMenu(String businessId) async {
    final session = ref.read(supabaseProvider).auth.currentSession;
    if (session == null) {
      final loginUrl = buildQrLoginUrl(businessId: businessId);
      final uri = Uri.parse(loginUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      final url = buildQrMenuUrl(businessId: businessId);
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    submitPostRedirect(buildPanelSessionHandoffUrl(), {
      'access_token': session.accessToken,
      'refresh_token': refreshToken,
      'business_id': businessId,
      'lang': 'tr',
      'theme': 'bold',
    }, target: '_blank');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerDigitalMenuOpenedInNewTab)),
      );
    }
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

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.item,
    required this.selected,
    required this.onCreateQrMenu,
    required this.onOpenPublicMenu,
  });

  final OwnerBusiness item;
  final bool selected;
  final VoidCallback onCreateQrMenu;
  final VoidCallback onOpenPublicMenu;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.claimStatus) {
      'approved' => AppColors.success,
      'rejected' => AppColors.danger,
      _ => AppColors.warning,
    };
    final statusIcon = switch (item.claimStatus) {
      'approved' => Icons.check_circle_rounded,
      'rejected' => Icons.cancel_rounded,
      _ => Icons.schedule_rounded,
    };
    final roleLabel = item.ownerRole == 'owner'
        ? context.l10n.ownerRoleOwner
        : context.l10n.ownerRoleManager;
    final location = '${item.district} • ${item.city}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          else
            const BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status accent bar
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.businessName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textStrong,
                              ),
                            ),
                          ),
                          if (selected)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Seçili',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              roleLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.branchLabel?.trim().isNotEmpty == true
                            ? '${item.branchLabel} • $location'
                            : location,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      if (item.chainName?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.hub_rounded,
                                size: 12, color: AppColors.muted),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.ownerChainPrefix(item.chainName!),
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(context, item.claimStatus),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _fmtDate(item.claimedAt),
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: onCreateQrMenu,
                            icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                            label: Text(context.l10n.adminBusinessesQrMenuAction),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: onOpenPublicMenu,
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: Text(context.l10n.ownerPublicMenuLinkAction),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
    required this.onCreateQrMenu,
    required this.onOpenPublicMenu,
  });
  final String selectedBusinessId;
  final String ownerRole;
  final VoidCallback onEditCommerceLinks;
  final VoidCallback onCreateQrMenu;
  final VoidCallback onOpenPublicMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HIZ­LI İŞLEMLER',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 720 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.4,
              children: [
                _QuickActionTile(
                  icon: Icons.menu_book_rounded,
                  label: l10n.ownerMenuAction,
                  primary: true,
                  onTap: () => context
                      .go('/owner/menus?businessId=$selectedBusinessId'),
                ),
                _QuickActionTile(
                  icon: Icons.open_in_new_rounded,
                  label: l10n.ownerPublicMenuLinkAction,
                  primary: true,
                  onTap: onOpenPublicMenu,
                ),
                _QuickActionTile(
                  icon: Icons.trending_up_rounded,
                  label: l10n.ownerShellGrowthLabel,
                  onTap: () => context
                      .go('/owner/growth?businessId=$selectedBusinessId'),
                ),
                _QuickActionTile(
                  icon: Icons.price_change_rounded,
                  label: l10n.ownerPriceVerificationAction,
                  onTap: () => context.go(
                    '/owner/price-suggestions?businessId=$selectedBusinessId',
                  ),
                ),
                _QuickActionTile(
                  icon: Icons.qr_code_2_rounded,
                  label: l10n.adminBusinessesQrMenuAction,
                  onTap: onCreateQrMenu,
                ),
                _QuickActionTile(
                  icon: Icons.link_rounded,
                  label: l10n.ownerReservationOrderLinksAction,
                  onTap: onEditCommerceLinks,
                ),
                _QuickActionTile(
                  icon: Icons.group_add_rounded,
                  label: ownerRole == 'manager'
                      ? l10n.ownerRequestsOwnerOnly
                      : l10n.ownerRequestsAction,
                  disabled: ownerRole == 'manager',
                  onTap: ownerRole == 'manager'
                      ? null
                      : () => context.go(
                          '/owner/requests?businessId=$selectedBusinessId',
                        ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.primary = false,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final bg = disabled
        ? AppColors.bg
        : primary
            ? AppColors.primary
            : AppColors.card;
    final fg = disabled
        ? AppColors.muted
        : primary
            ? Colors.white
            : AppColors.textStrong;
    final iconFg = disabled
        ? AppColors.muted
        : primary
            ? Colors.white
            : AppColors.primary;
    final border = disabled || primary ? Colors.transparent : AppColors.border;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconFg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
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
    );
  }
}

String _pricePositionLabel(
  BuildContext context,
  String position,
  double? gapPct,
) {
  final pctText = gapPct == null
      ? ''
      : ' (%${gapPct.abs().toStringAsFixed(0)})';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
