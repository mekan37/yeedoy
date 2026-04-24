import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/business_rbac.dart';
import '../../admin/ui/admin_audit_page.dart';
import '../../owner_businesses/domain/owner_business_state.dart';
import '../../../shared/ui/components/owner_business_guard.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';

class OwnerActivityPage extends ConsumerWidget {
  const OwnerActivityPage({super.key, this.businessId});

  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedBusinessId = businessId?.trim().isNotEmpty == true
        ? businessId!.trim()
        : (ref.watch(selectedOwnerBusinessIdProvider) ?? '');

    if (resolvedBusinessId.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: OwnerPanelFeedback.empty(
          icon: Icons.receipt_long_outlined,
          title: context.l10n.ownerActivityMissingBusinessTitle,
          description: context.l10n.ownerActivityMissingBusinessDescription,
        ),
      );
    }

    return OwnerBusinessGuard(
      businessId: resolvedBusinessId,
      permission: BusinessPermission.businessRead,
      builder: (context, ref) =>
          AdminAuditPage(ownerMode: true, businessId: resolvedBusinessId),
    );
  }
}
