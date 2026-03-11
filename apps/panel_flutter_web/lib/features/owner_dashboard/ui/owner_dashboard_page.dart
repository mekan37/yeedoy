import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/app_role_providers.dart';
import '../../../core/security/business_rbac.dart';
import '../../../shared/ui/components/app_section_header.dart';
import '../../owner_businesses/domain/owner_business_state.dart';
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
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionHeader(
          title: l10n.ownerDashboardOverview,
          subtitle: Text(
            l10n.ownerDashboardOperationsDescription,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 12),
        OwnerOperationsQuickActionsCard(businessId: businessId),
        const SizedBox(height: 12),
        OwnerQualityScoreCard(businessId: businessId),
        const SizedBox(height: 12),
        OwnerMoatCard(businessId: businessId),
      ],
    );
  }
}
