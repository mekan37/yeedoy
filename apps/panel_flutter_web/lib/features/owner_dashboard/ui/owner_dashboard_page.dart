import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/app_role_providers.dart';
import '../../../core/security/business_rbac.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../../shared/ui/components/panel_action_button.dart';
import '../../owner_businesses/domain/owner_business_state.dart';
import '../domain/owner_growth_provider.dart';
import '../domain/owner_kpi_provider.dart';
import 'owner_dashboard_sections.dart';

class OwnerDashboardPage extends ConsumerWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final businessId = ref.watch(selectedOwnerBusinessIdProvider);

    if (businessId != null && businessId.isNotEmpty) {
      final canReadAsync = ref.watch(
        hasBusinessPermissionProvider((businessId, BusinessPermission.businessRead)),
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
          title: const Text('Genel Bakış'),
          description: 'İşletmenizin bugünkü durumu, büyüme sinyalleri ve hızlı işlemler.',
          compactActions: [
            PanelActionButton(
              label: 'Yenile',
              tooltip: 'Verileri yenile',
              icon: Icons.refresh_rounded,
              variant: PanelActionButtonVariant.ghost,
              onPressed: () {
                ref.invalidate(ownerKpiSummaryProvider(businessId));
                ref.invalidate(ownerGrowthSummaryProvider(businessId));
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OwnerOperationsQuickActionsCard(businessId: businessId),
              const SizedBox(height: 16),
              _SectionLabel(label: 'Performans'),
              const SizedBox(height: 8),
              OwnerKpiOverviewCard(businessId: businessId),
              const SizedBox(height: 12),
              OwnerAnalyticsPreviewCard(businessId: businessId),
              const SizedBox(height: 16),
              _SectionLabel(label: 'İşletme Sağlığı'),
              const SizedBox(height: 8),
              OwnerQualityScoreCard(businessId: businessId),
              const SizedBox(height: 12),
              OwnerMoatCard(businessId: businessId),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.muted,
        letterSpacing: 0.8,
      ),
    );
  }
}
