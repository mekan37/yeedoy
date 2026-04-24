import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/app_role_providers.dart';
import '../../../core/security/business_rbac.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../owner_businesses/domain/owner_business_state.dart';
import 'owner_dashboard_sections.dart';

class OwnerGrowthPage extends ConsumerWidget {
  const OwnerGrowthPage({super.key, this.businessId});

  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final effectiveBusinessId = (businessId ?? '').trim().isNotEmpty
        ? businessId!.trim()
        : ref.watch(selectedOwnerBusinessIdProvider);

    if (effectiveBusinessId != null && effectiveBusinessId.isNotEmpty) {
      final canReadAsync = ref.watch(
        hasBusinessPermissionProvider((
          effectiveBusinessId,
          BusinessPermission.businessRead,
        )),
      );
      final canRead = canReadAsync.when<bool?>(
        loading: () => null,
        error: (_, _) => false,
        data: (value) => value,
      );
      if (canRead == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!canRead) {
        return Center(child: Text(l10n.ownerDashboardNoPermission));
      }
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        PanelPageHeader(
          eyebrow: 'Owner',
          title: Text(l10n.ownerGrowthTitle),
          description: l10n.ownerGrowthDescription,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            children: [
              OwnerKpiOverviewCard(businessId: effectiveBusinessId),
              const SizedBox(height: 12),
              OwnerGrowthBarChartCard(businessId: effectiveBusinessId),
              const SizedBox(height: 12),
              OwnerAnalyticsPreviewCard(businessId: effectiveBusinessId),
              const SizedBox(height: 12),
              OwnerGrowthSignalsCard(businessId: effectiveBusinessId),
              const SizedBox(height: 12),
              OwnerSponsorshipCatalogCard(businessId: effectiveBusinessId),
              const SizedBox(height: 12),
              OwnerProLeadCard(businessId: effectiveBusinessId),
            ],
          ),
        ),
      ],
    );
  }
}
