import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/admin_impersonation_provider.dart';
import '../../../core/security/app_role_providers.dart';
import '../../../core/security/business_rbac_localizations.dart';
import '../../auth/data/auth_service_provider.dart';
import '../../auth/domain/auth_providers.dart';
import '../domain/admin_access_provider.dart';
import '../domain/admin_new_items_controller.dart';
import '../domain/admin_permissions.dart';
import '../domain/admin_realtime_lifecycle_provider.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static List<_AdminEntry> _entries(AppLocalizations l10n) => [
    _AdminEntry(
      index: 0,
      route: '/admin',
      label: l10n.adminShellDashboardLabel,
      description: l10n.adminShellDashboardDescription,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _AdminEntry(
      index: 24,
      route: '/admin/queue',
      label: l10n.adminShellQueueLabel,
      description: l10n.adminShellQueueDescription,
      icon: Icons.inbox_outlined,
      selectedIcon: Icons.inbox,
    ),
    _AdminEntry(
      index: 1,
      route: '/admin/reports',
      label: l10n.adminShellReportsLabel,
      description: l10n.adminShellReportsDescription,
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
      badgeKey: 'reports',
    ),
    _AdminEntry(
      index: 21,
      route: '/admin/appeals',
      label: l10n.adminShellAppealsLabel,
      description: l10n.adminShellAppealsDescription,
      icon: Icons.gavel_outlined,
      selectedIcon: Icons.gavel,
    ),
    _AdminEntry(
      index: 2,
      route: '/admin/growth',
      label: l10n.adminShellGrowthLabel,
      description: l10n.adminShellGrowthDescription,
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
    ),
    _AdminEntry(
      index: 3,
      route: '/admin/claims',
      label: l10n.adminShellClaimsLabel,
      description: l10n.adminShellClaimsDescription,
      icon: Icons.verified_outlined,
      selectedIcon: Icons.verified,
      badgeKey: 'claims',
    ),
    _AdminEntry(
      index: 4,
      route: '/admin/suspended',
      label: l10n.adminShellSuspendedClaimsLabel,
      description: l10n.adminShellSuspendedClaimsDescription,
      icon: Icons.volunteer_activism_outlined,
      selectedIcon: Icons.volunteer_activism,
      badgeKey: 'suspended',
    ),
    _AdminEntry(
      index: 5,
      route: '/admin/price-suggestions',
      label: l10n.adminShellPriceSuggestionsLabel,
      description: l10n.adminShellPriceSuggestionsDescription,
      icon: Icons.price_check_outlined,
      selectedIcon: Icons.price_check,
      badgeKey: 'price',
    ),
    _AdminEntry(
      index: 17,
      route: '/admin/receipt-submissions',
      label: l10n.adminShellReceiptSubmissionsLabel,
      description: l10n.adminShellReceiptSubmissionsDescription,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _AdminEntry(
      index: 6,
      route: '/admin/suggestions',
      label: l10n.adminShellSuggestionsLabel,
      description: l10n.adminShellSuggestionsDescription,
      icon: Icons.lightbulb_outline,
      selectedIcon: Icons.lightbulb,
      badgeKey: 'suggestions',
    ),
    _AdminEntry(
      index: 7,
      route: '/admin/businesses',
      label: l10n.adminShellBusinessesLabel,
      description: l10n.adminShellBusinessesDescription,
      icon: Icons.store_outlined,
      selectedIcon: Icons.store,
    ),
    _AdminEntry(
      index: 16,
      route: '/admin/business-submissions',
      label: l10n.adminShellBusinessSubmissionsLabel,
      description: l10n.adminShellBusinessSubmissionsDescription,
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
    ),
    _AdminEntry(
      index: 8,
      route: '/admin/sponsorships',
      label: l10n.adminShellSponsorshipsLabel,
      description: l10n.adminShellSponsorshipsDescription,
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
    ),
    _AdminEntry(
      index: 9,
      route: '/admin/sponsorship-packages',
      label: l10n.adminShellSponsorshipPackagesLabel,
      description: l10n.adminShellSponsorshipPackagesDescription,
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    _AdminEntry(
      index: 10,
      route: '/admin/sponsorship-leads',
      label: l10n.adminShellSponsorshipLeadsLabel,
      description: l10n.adminShellSponsorshipLeadsDescription,
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent,
    ),
    _AdminEntry(
      index: 11,
      route: '/admin/verified',
      label: l10n.adminShellVerifiedLabel,
      description: l10n.adminShellVerifiedDescription,
      icon: Icons.verified_outlined,
      selectedIcon: Icons.verified,
    ),
    _AdminEntry(
      index: 13,
      route: '/admin/tools/locations',
      label: l10n.adminShellLocationsLabel,
      description: l10n.adminShellLocationsDescription,
      icon: Icons.place_outlined,
      selectedIcon: Icons.place,
    ),
    _AdminEntry(
      index: 14,
      route: '/admin/audit',
      label: l10n.adminShellAuditLabel,
      description: l10n.adminShellAuditDescription,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _AdminEntry(
      index: 25,
      route: '/admin/trash',
      label: l10n.adminShellTrashLabel,
      description: l10n.adminShellTrashDescription,
      icon: Icons.restore_from_trash_outlined,
      selectedIcon: Icons.restore_from_trash,
    ),
    _AdminEntry(
      index: 15,
      route: '/admin/table-feedback',
      label: l10n.adminShellTableFeedbackLabel,
      description: l10n.adminShellTableFeedbackDescription,
      icon: Icons.table_bar_outlined,
      selectedIcon: Icons.table_bar,
    ),
    _AdminEntry(
      index: 12,
      route: '/admin/group-requests',
      label: l10n.adminShellGroupRequestsLabel,
      description: l10n.adminShellGroupRequestsDescription,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
    ),
    _AdminEntry(
      index: 18,
      route: '/admin/dev-tools',
      label: l10n.adminShellDevToolsLabel,
      description: l10n.adminShellDevToolsDescription,
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
    ),
    _AdminEntry(
      index: 23,
      route: '/admin/observability',
      label: l10n.adminShellObservabilityLabel,
      description: l10n.adminShellObservabilityDescription,
      icon: Icons.monitor_heart_outlined,
      selectedIcon: Icons.monitor_heart,
    ),
    _AdminEntry(
      index: 19,
      route: '/admin/b2b-exports',
      label: l10n.adminShellB2bExportsLabel,
      description: l10n.adminShellB2bExportsDescription,
      icon: Icons.dataset_outlined,
      selectedIcon: Icons.dataset,
    ),
    _AdminEntry(
      index: 20,
      route: '/admin/incidents',
      label: l10n.adminShellIncidentCenterLabel,
      description: l10n.adminShellIncidentCenterDescription,
      icon: Icons.crisis_alert_outlined,
      selectedIcon: Icons.crisis_alert,
    ),
    _AdminEntry(
      index: 22,
      route: '/admin/temp-uploads',
      label: l10n.adminShellTempUploadsLabel,
      description: l10n.adminShellTempUploadsDescription,
      icon: Icons.upload_file_outlined,
      selectedIcon: Icons.upload_file,
    ),
  ];

  _AdminEntry _searchEntry(AppLocalizations l10n) => _AdminEntry(
    index: -1,
    route: '/admin/search',
    label: l10n.adminSearchTitle,
    description: l10n.adminSearchDescription,
    icon: Icons.manage_search_outlined,
    selectedIcon: Icons.manage_search,
  );

  String _locationPath() {
    final uri = Uri.tryParse(location);
    return uri?.path ?? location;
  }

  int _indexFromLocation(List<_AdminEntry> entries, AppLocalizations l10n) {
    final path = _locationPath();
    if (path.startsWith('/admin/search')) return _searchEntry(l10n).index;
    final sorted = [...entries]..sort((a, b) => b.route.length.compareTo(a.route.length));
    for (final entry in sorted) {
      if (path.startsWith(entry.route)) return entry.index;
    }
    return 0;
  }

  _AdminEntry _entryForLocation(List<_AdminEntry> entries, AppLocalizations l10n) {
    final path = _locationPath();
    if (path.startsWith('/admin/search')) return _searchEntry(l10n);
    final sorted = [...entries]..sort((a, b) => b.route.length.compareTo(a.route.length));
    for (final entry in sorted) {
      if (path.startsWith(entry.route)) return entry;
    }
    return entries.first;
  }

  List<_AdminEntry> _visibleEntries(AppRole? role, List<_AdminEntry> entries) {
    if (role == AppRole.communityMod) {
      return entries
          .where(
            (entry) => canAccessAdminRoute(AppRole.communityMod, entry.route),
          )
          .toList(growable: false);
    }
    return entries;
  }

  String _projectRef(String url) {
    if (url.isEmpty) return '-';
    final host = Uri.parse(url).host;
    if (host.isEmpty) return '-';
    final parts = host.split('.');
    return parts.isNotEmpty ? parts.first : host;
  }

  String _shortId(String? id) {
    if (id == null || id.isEmpty) return '-';
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }

  int _badgeCount(String? key, AdminNewItemsState newItems) {
    switch (key) {
      case 'reports':
        return newItems.reportsNew;
      case 'claims':
        return newItems.claimsNew;
      case 'suspended':
        return newItems.suspendedClaimsNew;
      case 'price':
        return newItems.priceSuggestionsNew;
      case 'suggestions':
        return newItems.suggestionsNew;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (!kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminShellAdminTitle)),
        body: Center(
          child: Text(l10n.adminShellWebOnlyMessage),
        ),
      );
    }

    final adminAsync = ref.watch(adminAccessProvider);
    final roleAsync = ref.watch(appRoleProvider);
    final user = ref.watch(userProvider);
    final newItems = ref.watch(adminNewItemsProvider);
    final impersonation = ref.watch(adminImpersonationProvider);
    ref.watch(adminRealtimeLifecycleProvider);
    final projectRef = _projectRef(dotenv.env['SUPABASE_URL'] ?? '');
    final entries = _entries(l10n);

    return adminAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.adminShellAdminTitle)),
        body: Center(child: Text(l10n.adminShellAccessCheckFailed)),
      ),
      data: (hasAccess) {
        if (!hasAccess) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.forbiddenTitle)),
            body: Center(child: Text(l10n.adminShellAccessDenied)),
          );
        }

        final role = roleAsync.maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
        final visibleEntries = _visibleEntries(role, entries);
        final idx = _indexFromLocation(entries, l10n);
        final current = _entryForLocation(visibleEntries, l10n);

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 260,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    for (final entry in visibleEntries)
                      _AdminNavItem(
                        selected: idx == entry.index,
                        icon: entry.icon,
                        selectedIcon: entry.selectedIcon,
                        label: entry.label,
                        badgeCount: _badgeCount(entry.badgeKey, newItems),
                        onTap: () => context.go(entry.route),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    Container(
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
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                current.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                current.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              Text(
                                l10n.adminShellProjectInfo(
                                  projectRef,
                                  _shortId(user?.id),
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 360,
                            child: _AdminGlobalSearchField(location: location),
                          ),
                          const Spacer(),
                          Text(
                            user?.email ?? '-',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            onPressed: () async {
                              await ref.read(authServiceProvider).signOut();
                              if (context.mounted) context.go('/login');
                            },
                            icon: const Icon(Icons.logout),
                            label: Text(l10n.logout),
                          ),
                        ],
                      ),
                    ),
                    if (impersonation.isActive)
                      Material(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.switch_account_outlined),
                          title: Text(
                            l10n.adminImpersonationBannerTitle(
                              impersonation.userLabel ??
                                  impersonation.userId ??
                                  '-',
                            ),
                          ),
                          subtitle: Text(
                            impersonation.roleOverride == null
                                ? l10n.adminImpersonationUsingActualRole
                                : l10n.adminImpersonationRoleOverride(
                                    l10n.ownerTeamRoleLabel(
                                      impersonation.roleOverride!,
                                    ),
                                  ),
                          ),
                          trailing: TextButton(
                            onPressed: () => ref
                                .read(adminImpersonationActionsProvider)
                                .stop(),
                            child: Text(l10n.adminImpersonationStopAction),
                          ),
                        ),
                      ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminGlobalSearchField extends StatefulWidget {
  const _AdminGlobalSearchField({required this.location});

  final String location;

  @override
  State<_AdminGlobalSearchField> createState() => _AdminGlobalSearchFieldState();
}

class _AdminGlobalSearchFieldState extends State<_AdminGlobalSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _initialValue());
  }

  @override
  void didUpdateWidget(covariant _AdminGlobalSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _initialValue();
    if (next != _controller.text && _isSearchRoute(widget.location)) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: _controller,
      onSubmitted: (_) => _openSearch(context),
      decoration: InputDecoration(
        hintText: l10n.adminSearchTopbarHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: () => _openSearch(context),
          icon: const Icon(Icons.arrow_forward),
          tooltip: l10n.adminSearchRunAction,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.16),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  bool _isSearchRoute(String location) {
    final uri = Uri.tryParse(location);
    final path = uri?.path ?? location;
    return path.startsWith('/admin/search');
  }

  String _initialValue() {
    final uri = Uri.tryParse(widget.location);
    if (uri == null || uri.path != '/admin/search') return '';
    return (uri.queryParameters['q'] ?? '').trim();
  }

  void _openSearch(BuildContext context) {
    final query = _controller.text.trim();
    final route = query.isEmpty
        ? '/admin/search'
        : Uri(
            path: '/admin/search',
            queryParameters: {'q': query},
          ).toString();
    context.go(route);
  }
}

class _AdminEntry {
  const _AdminEntry({
    required this.index,
    required this.route,
    required this.label,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    this.badgeKey,
  });

  final int index;
  final String route;
  final String label;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final String? badgeKey;
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

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
          border: Border.all(
            color: selected ? AppColors.borderStrong : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: iconColor,
                  size: 20,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '+$badgeCount',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
