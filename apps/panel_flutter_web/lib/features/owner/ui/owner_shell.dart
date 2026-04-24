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
import '../../../shared/ui/components/currency_selector.dart';
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
        backgroundColor: AppColors.bg,
        body: Row(
          children: [
            _OwnerSidebar(location: location),
            Expanded(
              child: Column(
                children: [
                  _OwnerTopBar(impersonation: impersonation),
                  const Divider(height: 1, color: AppColors.border),
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(context.l10n.ownerShellPanelTitle),
        actions: const [CurrencySelector()],
      ),
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

// ---------------------------------------------------------------------------
// Top bar (wide layout only)
// ---------------------------------------------------------------------------

class _OwnerTopBar extends ConsumerWidget {
  const _OwnerTopBar({required this.impersonation});

  final AdminImpersonationState impersonation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.card,
      child: Row(
        children: [
          if (impersonation.isActive) ...[
            _ImpersonationChip(
              impersonation: impersonation,
              onStop: () =>
                  ref.read(adminImpersonationActionsProvider).stop(),
            ),
            const SizedBox(width: 12),
          ],
          const Spacer(),
          const CurrencySelector(),
        ],
      ),
    );
  }
}

class _ImpersonationChip extends StatelessWidget {
  const _ImpersonationChip({
    required this.impersonation,
    required this.onStop,
  });

  final AdminImpersonationState impersonation;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.switch_account_outlined,
              size: 14, color: AppColors.warning),
          const SizedBox(width: 6),
          Text(
            l10n.adminImpersonationBannerTitle(
              impersonation.userLabel ?? impersonation.userId ?? '-',
            ),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onStop,
            child: const Icon(Icons.close, size: 14, color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar (wide layout)
// ---------------------------------------------------------------------------

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
    if (location.startsWith('/owner/ai-analysis')) return 6;
    if (location.startsWith('/owner/team')) return 7;
    if (location.startsWith('/owner/requests')) return 8;
    if (location.startsWith('/owner/suspended')) return 9;
    if (location.startsWith('/owner/activity') ||
        location.startsWith('/owner/audit')) {
      return 10;
    }
    if (location.startsWith('/owner/reviews')) return 11;
    if (location.startsWith('/owner/settings')) return 12;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final idx = _indexFromLocation();
    final selectedId = ref.watch(selectedOwnerBusinessIdProvider);

    void goRoute(String base) => _goBusinessRoute(context, base, selectedId);

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // ── Brand header ─────────────────────────────────────────────────
          _SidebarBrand(l10n: l10n),
          // ── Nav ──────────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              children: [
                // Ana Sayfa
                _NavItem(
                  selected: idx == 0,
                  icon: Icons.dashboard_rounded,
                  label: l10n.ownerShellOverviewLabel,
                  onTap: () => context.go('/owner'),
                ),
                const SizedBox(height: 8),
                // ── İşletme Yönetimi ─────────────────────────────────────
                _NavSection(label: 'İşletme Yönetimi'),
                _NavItem(
                  selected: idx == 1,
                  icon: Icons.storefront_rounded,
                  label: l10n.ownerBusinessesTitle,
                  description: 'Şubeler ve detaylar',
                  onTap: () => context.go('/owner/businesses'),
                ),
                _NavItem(
                  selected: idx == 2,
                  icon: Icons.menu_book_rounded,
                  label: l10n.ownerMenuManagementTitle,
                  description: 'Ürün ve kategori düzenle',
                  onTap: () => context.go('/owner/menus'),
                ),
                _NavItem(
                  selected: idx == 3,
                  icon: Icons.delete_sweep_rounded,
                  label: l10n.ownerShellTrashLabel,
                  description: 'Silinen ürünleri geri al',
                  onTap: () => goRoute('/owner/trash'),
                ),
                _NavItem(
                  selected: idx == 12,
                  icon: Icons.schedule_rounded,
                  label: 'Çalışma Saatleri',
                  description: 'Açılış/kapanış programı',
                  onTap: () => goRoute('/owner/settings/hours'),
                ),
                const SizedBox(height: 8),
                // ── Büyüme & Analiz ───────────────────────────────────────
                _NavSection(label: 'Büyüme & Analiz'),
                _NavItem(
                  selected: idx == 4,
                  icon: Icons.trending_up_rounded,
                  label: l10n.ownerShellGrowthLabel,
                  description: 'Ziyaret ve tıklama grafikleri',
                  onTap: () => goRoute('/owner/growth'),
                ),
                _NavItem(
                  selected: idx == 5,
                  icon: Icons.price_check_rounded,
                  label: l10n.ownerShellPriceSuggestionsLabel,
                  description: 'Rekabetçi fiyat önerileri',
                  onTap: () => goRoute('/owner/price-suggestions'),
                ),
                _NavItem(
                  selected: idx == 6,
                  icon: Icons.psychology_rounded,
                  label: l10n.ownerShellAiAnalysisLabel,
                  description: 'Yapay zeka içgörüleri',
                  onTap: () => goRoute('/owner/ai-analysis'),
                ),
                const SizedBox(height: 8),
                // ── Ekip & Yönetim ────────────────────────────────────────
                _NavSection(label: 'Ekip & Yönetim'),
                _NavItem(
                  selected: idx == 7,
                  icon: Icons.manage_accounts_rounded,
                  label: l10n.ownerShellTeamLabel,
                  description: 'Roller ve erişim izinleri',
                  onTap: () => goRoute('/owner/team'),
                ),
                _NavItem(
                  selected: idx == 8,
                  icon: Icons.group_add_rounded,
                  label: l10n.ownerShellRequestsLabel,
                  description: 'Gelen üyelik talepleri',
                  onTap: () => context.go('/owner/requests'),
                ),
                _NavItem(
                  selected: idx == 9,
                  icon: Icons.pause_circle_rounded,
                  label: l10n.ownerShellSuspendedClaimsLabel,
                  description: 'Onay bekleyen talepler',
                  onTap: () => goRoute('/owner/suspended'),
                ),
                _NavItem(
                  selected: idx == 10,
                  icon: Icons.receipt_long_rounded,
                  label: l10n.ownerShellActivityLabel,
                  description: 'Tüm panel aktivitesi',
                  onTap: () => goRoute('/owner/activity'),
                ),
                _NavItem(
                  selected: idx == 11,
                  icon: Icons.rate_review_rounded,
                  label: l10n.ownerShellReviewsLabel,
                  description: 'Yorumları görüntüle ve yanıtla',
                  onTap: () => goRoute('/owner/reviews'),
                ),
              ],
            ),
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

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: AppColors.primaryDeep)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ownerShellPanelTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'İşletme Paneli',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  const _NavSection({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.muted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.description,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final String? description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 17,
                color: selected ? AppColors.primary : AppColors.slate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textStrong,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.7)
                            : AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer (mobile layout)
// ---------------------------------------------------------------------------

class _OwnerDrawer extends ConsumerWidget {
  const _OwnerDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedId = ref.watch(selectedOwnerBusinessIdProvider);

    void goRoute(String base) {
      Navigator.of(context).pop();
      _goBusinessRoute(context, base, selectedId);
    }

    void goPage(String path) {
      Navigator.of(context).pop();
      context.go(path);
    }

    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    l10n.ownerShellPanelTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'İşletme Paneli',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: l10n.ownerShellOverviewLabel,
                    onTap: () => goPage('/owner'),
                  ),
                  const _DrawerSection(label: 'İşletme Yönetimi'),
                  _DrawerItem(
                    icon: Icons.storefront_rounded,
                    label: l10n.ownerBusinessesTitle,
                    onTap: () => goPage('/owner/businesses'),
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_rounded,
                    label: l10n.ownerMenuManagementTitle,
                    onTap: () => goPage('/owner/menus'),
                  ),
                  _DrawerItem(
                    icon: Icons.delete_sweep_rounded,
                    label: l10n.ownerShellTrashLabel,
                    onTap: () => goRoute('/owner/trash'),
                  ),
                  _DrawerItem(
                    icon: Icons.schedule_rounded,
                    label: 'Çalışma Saatleri',
                    onTap: () => goRoute('/owner/settings/hours'),
                  ),
                  const _DrawerSection(label: 'Büyüme & Analiz'),
                  _DrawerItem(
                    icon: Icons.trending_up_rounded,
                    label: l10n.ownerShellGrowthLabel,
                    onTap: () => goRoute('/owner/growth'),
                  ),
                  _DrawerItem(
                    icon: Icons.price_check_rounded,
                    label: l10n.ownerShellPriceSuggestionsLabel,
                    onTap: () => goRoute('/owner/price-suggestions'),
                  ),
                  _DrawerItem(
                    icon: Icons.psychology_rounded,
                    label: l10n.ownerShellAiAnalysisLabel,
                    onTap: () => goRoute('/owner/ai-analysis'),
                  ),
                  const _DrawerSection(label: 'Ekip & Yönetim'),
                  _DrawerItem(
                    icon: Icons.manage_accounts_rounded,
                    label: l10n.ownerShellTeamLabel,
                    onTap: () => goRoute('/owner/team'),
                  ),
                  _DrawerItem(
                    icon: Icons.group_add_rounded,
                    label: l10n.ownerShellRequestsLabel,
                    onTap: () => goPage('/owner/requests'),
                  ),
                  _DrawerItem(
                    icon: Icons.pause_circle_rounded,
                    label: l10n.ownerShellSuspendedClaimsLabel,
                    onTap: () => goRoute('/owner/suspended'),
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_rounded,
                    label: l10n.ownerShellActivityLabel,
                    onTap: () => goRoute('/owner/activity'),
                  ),
                  _DrawerItem(
                    icon: Icons.rate_review_rounded,
                    label: l10n.ownerShellReviewsLabel,
                    onTap: () => goRoute('/owner/reviews'),
                  ),
                ],
              ),
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

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.muted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: AppColors.slate),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

// ---------------------------------------------------------------------------
// Impersonation banner (mobile layout fallback)
// ---------------------------------------------------------------------------

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
