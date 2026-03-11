import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/app_role_providers.dart';
import '../../../core/security/admin_impersonation_provider.dart';
import '../../../core/security/business_rbac_localizations.dart';
import '../../owner_businesses/domain/owner_business_state.dart';
import '../../../shared/ui/components/owner_business_context_bar.dart';
import '../../../shared/ui/components/permission_denied_view.dart';

class OwnerShell extends ConsumerWidget {
  const OwnerShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerAccessAsync = ref.watch(isOwnerProvider);
    return ownerAccessAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => _forbidden(context),
      data: (canAccess) {
        if (!canAccess) return _forbidden(context);
        return _buildAuthorizedShell(context, ref);
      },
    );
  }

  Widget _buildAuthorizedShell(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isWide = kIsWeb && width >= 1024;
    final impersonation = ref.watch(adminImpersonationProvider);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _OwnerSidebar(location: location),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  const _OwnerHeader(),
                  if (impersonation.isActive)
                    _OwnerImpersonationBanner(impersonation: impersonation),
                  const OwnerBusinessContextBar(),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ownerShellPanelTitle)),
      drawer: const _OwnerDrawer(),
      body: Column(
        children: [
          if (impersonation.isActive)
            _OwnerImpersonationBanner(impersonation: impersonation),
          const OwnerBusinessContextBar(),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _forbidden(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.forbiddenTitle)),
      body: PermissionDeniedView(
        primaryRoute: '/',
        primaryLabel: context.l10n.forbiddenBackHomeAction,
      ),
    );
  }
}

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.header, AppColors.headerAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Text(
            l10n.ownerShellPanelTitle,
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.go('/owner/businesses'),
            icon: const Icon(Icons.storefront_outlined, color: Colors.white),
            label: Text(
              l10n.ownerBusinessesTitle,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerSidebar extends ConsumerWidget {
  const _OwnerSidebar({required this.location});
  final String location;

  int _indexFromLocation() {
    if (location.startsWith('/owner/businesses')) return 1;
    if (location.startsWith('/owner/menus')) return 2;
    if (location.startsWith('/owner/trash')) return 3;
    if (location.startsWith('/owner/growth') ||
        location.startsWith('/owner/analytics')) {
      return 4;
    }
    if (location.startsWith('/owner/price-suggestions')) return 5;
    if (location.startsWith('/owner/suspended')) return 6;
    if (location.startsWith('/owner/requests')) return 7;
    if (location.startsWith('/owner/team')) return 8;
    if (location.startsWith('/owner/activity') || location.startsWith('/owner/audit')) {
      return 9;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final idx = _indexFromLocation();
    final selectedId = ref.watch(selectedOwnerBusinessIdProvider);
    return SizedBox(
      width: 260,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _OwnerNavItem(
            selected: idx == 0,
            icon: Icons.dashboard_outlined,
            label: l10n.ownerShellOverviewLabel,
            onTap: () => context.go('/owner'),
          ),
          _OwnerNavItem(
            selected: idx == 1,
            icon: Icons.storefront_outlined,
            label: l10n.ownerBusinessesTitle,
            onTap: () => context.go('/owner/businesses'),
          ),
          _OwnerNavItem(
            selected: idx == 2,
            icon: Icons.menu_book_outlined,
            label: l10n.ownerMenuManagementTitle,
            onTap: () => context.go('/owner/menus'),
          ),
          _OwnerNavItem(
            selected: idx == 3,
            icon: Icons.delete_sweep_outlined,
            label: l10n.ownerShellTrashLabel,
            onTap: () => _goBusinessRoute(context, '/owner/trash', selectedId),
          ),
          _OwnerNavItem(
            selected: idx == 4,
            icon: Icons.trending_up_outlined,
            label: l10n.ownerShellGrowthLabel,
            onTap: () => _goBusinessRoute(context, '/owner/growth', selectedId),
          ),
          _OwnerNavItem(
            selected: idx == 5,
            icon: Icons.price_check_outlined,
            label: l10n.ownerShellPriceSuggestionsLabel,
            onTap: () => _goBusinessRoute(
              context,
              '/owner/price-suggestions',
              selectedId,
            ),
          ),
          _OwnerNavItem(
            selected: idx == 6,
            icon: Icons.volunteer_activism_outlined,
            label: l10n.ownerShellSuspendedClaimsLabel,
            onTap: () =>
                _goBusinessRoute(context, '/owner/suspended', selectedId),
          ),
          _OwnerNavItem(
            selected: idx == 7,
            icon: Icons.groups_outlined,
            label: l10n.ownerShellRequestsLabel,
            onTap: () => context.go('/owner/requests'),
          ),
          _OwnerNavItem(
            selected: idx == 8,
            icon: Icons.manage_accounts_outlined,
            label: l10n.ownerShellTeamLabel,
            onTap: () => _goBusinessRoute(context, '/owner/team', selectedId),
          ),
          _OwnerNavItem(
            selected: idx == 9,
            icon: Icons.receipt_long_outlined,
            label: l10n.ownerShellActivityLabel,
            onTap: () => _goBusinessRoute(context, '/owner/activity', selectedId),
          ),
        ],
      ),
    );
  }

  void _goBusinessRoute(BuildContext context, String base, String? businessId) {
    if (businessId == null || businessId.isEmpty) {
      context.go('/owner/businesses');
      return;
    }
    context.go('$base?businessId=$businessId');
  }
}

class _OwnerDrawer extends ConsumerWidget {
  const _OwnerDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedId = ref.watch(selectedOwnerBusinessIdProvider);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.ownerShellPanelTitle,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text(l10n.ownerShellOverviewLabel),
              onTap: () => context.go('/owner'),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(l10n.ownerBusinessesTitle),
              onTap: () => context.go('/owner/businesses'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.ownerMenuManagementTitle),
              onTap: () => context.go('/owner/menus'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: Text(l10n.ownerShellTrashLabel),
              onTap: () => _goBusinessRoute(context, '/owner/trash', selectedId),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up_outlined),
              title: Text(l10n.ownerShellGrowthLabel),
              onTap: () => _goBusinessRoute(context, '/owner/growth', selectedId),
            ),
            ListTile(
              leading: const Icon(Icons.price_check_outlined),
              title: Text(l10n.ownerShellPriceSuggestionsLabel),
              onTap: () => _goBusinessRoute(
                context,
                '/owner/price-suggestions',
                selectedId,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: Text(l10n.ownerShellSuspendedClaimsLabel),
              onTap: () =>
                  _goBusinessRoute(context, '/owner/suspended', selectedId),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(l10n.ownerShellRequestsLabel),
              onTap: () => context.go('/owner/requests'),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: Text(l10n.ownerShellTeamLabel),
              onTap: () => _goBusinessRoute(context, '/owner/team', selectedId),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(l10n.ownerShellActivityLabel),
              onTap: () => _goBusinessRoute(context, '/owner/activity', selectedId),
            ),
          ],
        ),
      ),
    );
  }

  void _goBusinessRoute(BuildContext context, String base, String? businessId) {
    if (businessId == null || businessId.isEmpty) {
      context.go('/owner/businesses');
      return;
    }
    context.go('$base?businessId=$businessId');
  }
}

class _OwnerNavItem extends StatelessWidget {
  const _OwnerNavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppColors.primary : AppColors.slate;
    final textColor = selected ? AppColors.textStrong : AppColors.slate;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerImpersonationBanner extends ConsumerWidget {
  const _OwnerImpersonationBanner({required this.impersonation});

  final AdminImpersonationState impersonation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.warning.withValues(alpha: 0.12),
      child: ListTile(
        leading: const Icon(Icons.switch_account_outlined),
        title: Text(
          l10n.adminImpersonationBannerTitle(
            impersonation.userLabel ?? impersonation.userId ?? '-',
          ),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          impersonation.roleOverride == null
              ? l10n.adminImpersonationUsingActualRole
              : l10n.adminImpersonationRoleOverride(
                  l10n.ownerTeamRoleLabel(impersonation.roleOverride!),
                ),
        ),
        trailing: TextButton(
          onPressed: () => ref.read(adminImpersonationActionsProvider).stop(),
          child: Text(l10n.adminImpersonationStopAction),
        ),
      ),
    );
  }
}
