import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/security/app_role_providers.dart';
import '../core/security/route_sanitizer.dart';
import '../features/auth/domain/business_auth_redirect.dart';
import '../features/auth/domain/auth_providers.dart';
import '../features/auth/ui/business_login_page.dart';
import '../features/auth/ui/business_register_page.dart';
import '../features/marketing/ui/web_home_page.dart';
import '../features/admin/domain/admin_permissions.dart';
import '../features/admin/ui/admin_appeals_page.dart';
import '../features/admin/ui/admin_audit_page.dart';
import '../features/admin/ui/admin_b2b_exports_page.dart';
import '../features/admin/ui/admin_businesses_page.dart'
    deferred as admin_businesses_page;
import '../features/admin/ui/admin_business_submissions_page.dart'
    deferred as admin_business_submissions_page;
import '../features/admin/ui/admin_claims_page.dart'
    deferred as admin_claims_page;
import '../features/admin/ui/admin_dashboard_page.dart';
import '../features/admin/ui/admin_dev_tools_page.dart';
import '../features/admin/ui/admin_group_requests_page.dart';
import '../features/admin/ui/admin_growth_page.dart';
import '../features/admin/ui/admin_incident_center_page.dart';
import '../features/admin/ui/admin_menu_restore_page.dart';
import '../features/admin/ui/admin_observability_page.dart';
import '../features/admin/ui/admin_price_suggestions_page.dart';
import '../features/admin/ui/admin_queue_page.dart'
    deferred as admin_queue_page;
import '../features/admin/ui/admin_receipt_submissions_page.dart';
import '../features/admin/ui/admin_reports_page.dart'
    deferred as admin_reports_page;
import '../features/admin/ui/admin_search_page.dart';
import '../features/admin/ui/admin_shell.dart';
import '../features/admin/ui/admin_sponsorship_leads_page.dart';
import '../features/admin/ui/admin_sponsorship_packages_page.dart';
import '../features/admin/ui/admin_sponsorships_page.dart';
import '../features/admin/ui/admin_suggestions_page.dart';
import '../features/admin/ui/admin_suspended_claims_page.dart';
import '../features/admin/ui/admin_table_feedback_page.dart';
import '../features/admin/ui/admin_temp_uploads_page.dart';
import '../features/admin/ui/admin_user_access_page.dart';
import '../features/admin/ui/admin_verified_page.dart';
import '../features/owner_businesses/ui/owner_business_submissions_page.dart';
import '../features/owner_businesses/ui/owner_businesses_page.dart'
    deferred as owner_businesses_page;
import '../features/owner_businesses/ui/owner_new_business_page.dart';
import '../features/legal/legal_routes.dart';
import '../features/owner_analytics/ui/owner_analytics_page.dart'
    deferred as owner_analytics_page;
import '../features/owner_menu_management/ui/owner_menus_page.dart'
    deferred as owner_menus_page;
import '../features/owner_menu_management/ui/owner_menu_trash_page.dart';
import '../features/owner_price_suggestions/ui/owner_price_suggestions_page.dart';
import '../features/owner_requests/ui/owner_group_requests_page.dart';
import '../features/owner_suspended/ui/owner_suspended_claims_page.dart';
import '../features/legal/ui/legal_page.dart';
import '../features/owner/ui/owner_shell.dart';
import '../features/owner/ui/owner_activity_page.dart';
import '../features/owner_dashboard/ui/owner_dashboard_page.dart';
import '../features/owner_dashboard/ui/owner_growth_page.dart';
import '../features/owner_onboarding/ui/owner_onboarding_page.dart'
    deferred as owner_onboarding_page;
import '../features/owner_team/ui/owner_team_page.dart';
import '../shared/ui/components/deferred_page_loader.dart';
import '../shared/ui/pages/forbidden_page.dart';

GoRouter buildAppRouter(Ref ref, {String initialLocation = '/'}) {
  final session = ref.watch(sessionProvider);
  final appRoleAsync = ref.watch(appRoleProvider);
  final authRefresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) {
    authRefresh.value++;
  });
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final loggedIn = session != null;
      final path = state.uri.path;
      final isBusinessAuthRoute =
          path == '/isletme-giris' || path == '/isletme-kayit';
      final isPublicRoute =
          path == '/' ||
          LegalRoutes.matches(path) ||
          isBusinessAuthRoute;
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
          data: businessHomeForRole,
          orElse: () => null,
        );
      }

      if (loggedIn && isAdminRoute) {
        final canAccess = appRoleAsync.maybeWhen(
          data: (role) => canAccessAdminRoute(role, path),
          orElse: () => false,
        );
        if (!canAccess) {
          final from = Uri.encodeComponent(state.uri.toString());
          return '/forbidden?panel=admin&from=$from';
        }
      }

      if (loggedIn && isOwnerRoute) {
        final isOwnerOrAdmin = appRoleAsync.maybeWhen(
          data: (role) => role == AppRole.owner || role == AppRole.admin,
          orElse: () => false,
        );
        if (!isOwnerOrAdmin) {
          final from = Uri.encodeComponent(state.uri.toString());
          return '/forbidden?panel=owner&from=$from';
        }
      }

      if (!isPublicRoute && !isPanelRoute) {
        return loggedIn
            ? businessHomeForRole(appRoleAsync.asData?.value ?? AppRole.user)
            : '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const WebHomePage()),
      GoRoute(path: '/login', builder: (c, s) => const BusinessLoginPage()),
      GoRoute(
        path: '/isletme-giris',
        builder: (c, s) => const BusinessLoginPage(),
      ),
      GoRoute(
        path: '/isletme-kayit',
        builder: (c, s) => const BusinessRegisterPage(),
      ),
      GoRoute(path: LegalRoutes.hub, builder: (c, s) => const LegalPage()),
      GoRoute(
        path: '${LegalRoutes.hub}/:slug',
        builder: (c, s) =>
            LegalDetailPage(slug: sanitizeSlug(s.pathParameters['slug'])),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (c, s) => ForbiddenPage(
          panel: s.uri.queryParameters['panel'],
          from: sanitizeInternalRedirect(s.uri.queryParameters['from']),
        ),
      ),
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
            path: '/owner/growth',
            builder: (c, s) => OwnerGrowthPage(
              businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
            ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_menus_page.loadLibrary,
              builder: (_) => owner_menus_page.OwnerMenusPage(),
            ),
          ),
          GoRoute(
            path: '/owner/trash',
            builder: (c, s) => OwnerMenuTrashPage(
              businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
            ),
          ),
          GoRoute(
            path: '/owner/analytics',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_analytics_page.loadLibrary,
              builder: (_) => owner_analytics_page.OwnerAnalyticsPage(
                businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
              ),
            ),
          ),
          GoRoute(
            path: '/owner/requests',
            builder: (c, s) => const OwnerGroupRequestsPage(),
          ),
          GoRoute(
            path: '/owner/businesses',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_businesses_page.loadLibrary,
              builder: (_) => owner_businesses_page.OwnerBusinessesPage(),
            ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_onboarding_page.loadLibrary,
              builder: (_) => owner_onboarding_page.OwnerOnboardingPage(
                businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
                redirect: sanitizeInternalRedirect(
                  s.uri.queryParameters['redirect'],
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/owner/activity',
            builder: (c, s) => OwnerActivityPage(
              businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
            ),
          ),
          GoRoute(
            path: '/owner/audit',
            builder: (c, s) => OwnerActivityPage(
              businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
            ),
          ),
          GoRoute(
            path: '/owner/team',
            builder: (c, s) => OwnerTeamPage(
              businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminShell(location: state.uri.toString(), child: child);
        },
        routes: [
          GoRoute(
            path: '/admin',
            builder: (c, s) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/search',
            builder: (c, s) =>
                AdminSearchPage(initialQuery: s.uri.queryParameters['q']),
          ),
          GoRoute(
            path: '/admin/queue',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_queue_page.loadLibrary,
              builder: (_) => admin_queue_page.AdminQueuePage(
                initialType: s.uri.queryParameters['type'],
                initialStatus: s.uri.queryParameters['status'],
                initialCity: s.uri.queryParameters['city'],
                initialQuery: s.uri.queryParameters['q'],
              ),
            ),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_reports_page.loadLibrary,
              builder: (_) => admin_reports_page.AdminReportsPage(),
            ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_claims_page.loadLibrary,
              builder: (_) => admin_claims_page.AdminClaimsPage(),
            ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_business_submissions_page.loadLibrary,
              builder: (_) =>
                  admin_business_submissions_page.AdminBusinessSubmissionsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/businesses',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_businesses_page.loadLibrary,
              builder: (_) => admin_businesses_page.AdminBusinessesPage(
                initialQuery: s.uri.queryParameters['q'],
              ),
            ),
          ),
          GoRoute(
            path: '/admin/table-feedback',
            builder: (c, s) => const AdminTableFeedbackPage(),
          ),
          GoRoute(
            path: '/admin/receipt-submissions',
            builder: (c, s) => const AdminReceiptSubmissionsPage(),
          ),
          GoRoute(
            path: '/admin/audit',
            builder: (c, s) => const AdminAuditPage(),
          ),
          GoRoute(
            path: '/admin/trash',
            builder: (c, s) => AdminMenuRestorePage(
              initialBusinessId: sanitizeUuid(
                s.uri.queryParameters['businessId'],
              ),
            ),
          ),
          GoRoute(
            path: '/admin/dev-tools',
            builder: (c, s) => const AdminDevToolsPage(),
          ),
          GoRoute(
            path: '/admin/observability',
            builder: (c, s) => const AdminObservabilityPage(),
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
          GoRoute(
            path: '/admin/users/:id',
            builder: (c, s) => AdminUserAccessPage(
              userId: sanitizeUuid(s.pathParameters['id']) ?? '',
            ),
          ),
        ],
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return buildAppRouter(ref);
});
