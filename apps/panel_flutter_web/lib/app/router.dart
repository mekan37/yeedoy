import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/security/app_role_providers.dart';
import '../core/security/route_sanitizer.dart';
import '../features/auth/domain/auth_providers.dart';
import '../features/auth/ui/business_login_page.dart';
import '../features/auth/ui/business_register_page.dart';
import '../features/marketing/ui/web_home_page.dart';
import '../src/features/admin/domain/admin_permissions.dart';
import '../src/features/admin/ui/admin_appeals_page.dart';
import '../src/features/admin/ui/admin_audit_page.dart';
import '../src/features/admin/ui/admin_b2b_exports_page.dart';
import '../src/features/admin/ui/admin_business_submissions_page.dart';
import '../src/features/admin/ui/admin_claims_page.dart';
import '../src/features/admin/ui/admin_dashboard_page.dart';
import '../src/features/admin/ui/admin_dev_tools_page.dart';
import '../src/features/admin/ui/admin_group_requests_page.dart';
import '../src/features/admin/ui/admin_growth_page.dart';
import '../src/features/admin/ui/admin_incident_center_page.dart';
import '../src/features/admin/ui/admin_price_suggestions_page.dart';
import '../src/features/admin/ui/admin_reports_page.dart';
import '../src/features/admin/ui/admin_shell.dart';
import '../src/features/admin/ui/admin_sponsorship_leads_page.dart';
import '../src/features/admin/ui/admin_sponsorship_packages_page.dart';
import '../src/features/admin/ui/admin_sponsorships_page.dart';
import '../src/features/admin/ui/admin_suggestions_page.dart';
import '../src/features/admin/ui/admin_suspended_claims_page.dart';
import '../src/features/admin/ui/admin_table_feedback_page.dart';
import '../src/features/admin/ui/admin_temp_uploads_page.dart';
import '../src/features/admin/ui/admin_verified_page.dart';
import '../src/features/owner_businesses/ui/owner_business_submissions_page.dart';
import '../src/features/owner_businesses/ui/owner_new_business_page.dart';
import '../src/features/owner_onboarding/ui/owner_onboarding_page.dart';
import '../src/features/owner_price_suggestions/ui/owner_price_suggestions_page.dart';
import '../src/features/owner_requests/ui/owner_group_requests_page.dart';
import '../src/features/owner_suspended/ui/owner_suspended_claims_page.dart';
import '../src/ui/pages/legal_page.dart';
import '../src/ui/pages/owner/owner_businesses_page.dart';
import '../src/ui/pages/owner/owner_dashboard_page.dart';
import '../src/ui/pages/owner/owner_menu_builder_page.dart';
import '../src/ui/pages/owner/owner_perks_page.dart';
import '../src/ui/shells/owner_shell.dart';

String _panelHomeForRole(AppRole role) {
  return switch (role) {
    AppRole.admin || AppRole.communityMod => '/admin',
    AppRole.owner => '/owner',
    AppRole.user => '/',
  };
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  final appRoleAsync = ref.watch(appRoleProvider);
  final authRefresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) {
    authRefresh.value++;
  });
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final loggedIn = session != null;
      final path = state.uri.path;
      final isBusinessAuthRoute =
          path == '/isletme-giris' || path == '/isletme-kayit';
      final isPublicRoute =
          path == '/' || path == '/legal' || isBusinessAuthRoute;
      final isAdminRoute = path == '/admin' || path.startsWith('/admin/');
      final isOwnerRoute = path == '/owner' || path.startsWith('/owner/');
      final isPanelRoute = isAdminRoute || isOwnerRoute;

      if (!loggedIn && isPanelRoute) {
        final redirect = Uri.encodeComponent(state.uri.toString());
        return '/isletme-giris?redirect=$redirect';
      }

      if (loggedIn && isBusinessAuthRoute) {
        final redirect = sanitizeInternalRedirect(
          state.uri.queryParameters['redirect'],
        );
        if (redirect != null) return redirect;
        return appRoleAsync.maybeWhen(
          data: _panelHomeForRole,
          orElse: () => null,
        );
      }

      if (loggedIn && isAdminRoute) {
        final canAccess = appRoleAsync.maybeWhen(
          data: (role) => canAccessAdminRoute(role, path),
          orElse: () => false,
        );
        if (!canAccess) return '/owner';
      }

      if (loggedIn && isOwnerRoute) {
        final isOwnerOrAdmin = appRoleAsync.maybeWhen(
          data: (role) => role == AppRole.owner || role == AppRole.admin,
          orElse: () => false,
        );
        if (!isOwnerOrAdmin) return '/';
      }

      if (!isPublicRoute && !isPanelRoute) {
        return loggedIn
            ? _panelHomeForRole(appRoleAsync.asData?.value ?? AppRole.user)
            : '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const WebHomePage()),
      GoRoute(
        path: '/isletme-giris',
        builder: (c, s) => const BusinessLoginPage(),
      ),
      GoRoute(
        path: '/isletme-kayit',
        builder: (c, s) => const BusinessRegisterPage(),
      ),
      GoRoute(path: '/legal', builder: (c, s) => const LegalPage()),
      ShellRoute(
        builder: (context, state, child) {
          return OwnerShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/owner',
            builder: (c, s) => const OwnerDashboardPage(),
          ),
          GoRoute(
            path: '/owner/suspended',
            builder: (c, s) => OwnerSuspendedClaimsPage(
              businessId:
                  sanitizeUuid(s.uri.queryParameters['businessId']) ?? '',
            ),
          ),
          GoRoute(
            path: '/owner/price-suggestions',
            builder: (c, s) => OwnerPriceSuggestionsPage(
              businessId:
                  sanitizeUuid(s.uri.queryParameters['businessId']) ?? '',
            ),
          ),
          GoRoute(
            path: '/owner/menus',
            builder: (c, s) => const OwnerMenuBuilderPage(),
          ),
          GoRoute(
            path: '/owner/requests',
            builder: (c, s) => const OwnerGroupRequestsPage(),
          ),
          GoRoute(
            path: '/owner/businesses',
            builder: (c, s) => const OwnerBusinessesPageWrapper(),
          ),
          GoRoute(
            path: '/owner/businesses/new',
            builder: (c, s) => const OwnerNewBusinessPage(),
          ),
          GoRoute(
            path: '/owner/businesses/submissions',
            builder: (c, s) => const OwnerBusinessSubmissionsPage(),
          ),
          GoRoute(
            path: '/owner/onboarding',
            builder: (c, s) => OwnerOnboardingPage(
              businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
              redirect: sanitizeInternalRedirect(
                s.uri.queryParameters['redirect'],
              ),
            ),
          ),
          GoRoute(
            path: '/owner/perks',
            builder: (c, s) => const OwnerPerksPage(),
          ),
          GoRoute(
            path: '/owner/audit',
            builder: (c, s) => const AdminAuditPage(ownerMode: true),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/admin',
            builder: (c, s) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (c, s) => const AdminReportsPage(),
          ),
          GoRoute(
            path: '/admin/appeals',
            builder: (c, s) => const AdminAppealsPage(),
          ),
          GoRoute(
            path: '/admin/growth',
            builder: (c, s) => const AdminGrowthPage(),
          ),
          GoRoute(
            path: '/admin/claims',
            builder: (c, s) => const AdminClaimsPage(),
          ),
          GoRoute(
            path: '/admin/suspended',
            builder: (c, s) => const AdminSuspendedClaimsPage(),
          ),
          GoRoute(
            path: '/admin/price-suggestions',
            builder: (c, s) => const AdminPriceSuggestionsPage(),
          ),
          GoRoute(
            path: '/admin/suggestions',
            builder: (c, s) => const AdminSuggestionsPage(),
          ),
          GoRoute(
            path: '/admin/sponsorships',
            builder: (c, s) => const AdminSponsorshipsPage(),
          ),
          GoRoute(
            path: '/admin/sponsorship-packages',
            builder: (c, s) => const AdminSponsorshipPackagesPage(),
          ),
          GoRoute(
            path: '/admin/sponsorship-leads',
            builder: (c, s) => const AdminSponsorshipLeadsPage(),
          ),
          GoRoute(
            path: '/admin/verified',
            builder: (c, s) => const AdminVerifiedPage(),
          ),
          GoRoute(
            path: '/admin/group-requests',
            builder: (c, s) => const AdminGroupRequestsPage(),
          ),
          GoRoute(
            path: '/admin/business-submissions',
            builder: (c, s) => const AdminBusinessSubmissionsPage(),
          ),
          GoRoute(
            path: '/admin/table-feedback',
            builder: (c, s) => const AdminTableFeedbackPage(),
          ),
          GoRoute(
            path: '/admin/audit',
            builder: (c, s) => const AdminAuditPage(),
          ),
          GoRoute(
            path: '/admin/dev-tools',
            builder: (c, s) => const AdminDevToolsPage(),
          ),
          GoRoute(
            path: '/admin/b2b-exports',
            builder: (c, s) => const AdminB2bExportsPage(),
          ),
          GoRoute(
            path: '/admin/incidents',
            builder: (c, s) => const AdminIncidentCenterPage(),
          ),
          GoRoute(
            path: '/admin/temp-uploads',
            builder: (c, s) => const AdminTempUploadsPage(),
          ),
        ],
      ),
    ],
  );
});
