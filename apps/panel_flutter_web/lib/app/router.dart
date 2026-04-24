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
import '../features/admin/ui/admin_appeals_page.dart'
    deferred as admin_appeals_page;
import '../features/admin/ui/admin_audit_page.dart'
    deferred as admin_audit_page;
import '../features/admin/ui/admin_b2b_exports_page.dart'
    deferred as admin_b2b_exports_page;
import '../features/admin/ui/admin_businesses_page.dart'
    deferred as admin_businesses_page;
import '../features/admin/ui/admin_business_submissions_page.dart'
    deferred as admin_business_submissions_page;
import '../features/admin/ui/admin_claims_page.dart'
    deferred as admin_claims_page;
import '../features/admin/ui/admin_dashboard_page.dart';
import '../features/admin/ui/admin_dev_tools_page.dart'
    deferred as admin_dev_tools_page;
import '../features/admin/ui/admin_group_requests_page.dart'
    deferred as admin_group_requests_page;
import '../features/admin/ui/admin_growth_page.dart'
    deferred as admin_growth_page;
import '../features/admin/ui/admin_incident_center_page.dart'
    deferred as admin_incident_center_page;
import '../features/admin/ui/admin_menu_restore_page.dart'
    deferred as admin_menu_restore_page;
import '../features/admin/ui/admin_observability_page.dart'
    deferred as admin_observability_page;
import '../features/admin/ui/admin_price_suggestions_page.dart'
    deferred as admin_price_suggestions_page;
import '../features/admin/ui/admin_queue_page.dart'
    deferred as admin_queue_page;
import '../features/admin/ui/admin_receipt_submissions_page.dart'
    deferred as admin_receipt_submissions_page;
import '../features/admin/ui/admin_reports_page.dart'
    deferred as admin_reports_page;
import '../features/admin/ui/admin_search_page.dart'
    deferred as admin_search_page;
import '../features/admin/ui/admin_shell.dart';
import '../features/admin/ui/admin_sponsorship_leads_page.dart'
    deferred as admin_sponsorship_leads_page;
import '../features/admin/ui/admin_sponsorship_packages_page.dart'
    deferred as admin_sponsorship_packages_page;
import '../features/admin/ui/admin_sponsorships_page.dart'
    deferred as admin_sponsorships_page;
import '../features/admin/ui/admin_suggestions_page.dart'
    deferred as admin_suggestions_page;
import '../features/admin/ui/admin_suspended_claims_page.dart'
    deferred as admin_suspended_claims_page;
import '../features/admin/ui/admin_table_feedback_page.dart'
    deferred as admin_table_feedback_page;
import '../features/admin/ui/admin_temp_uploads_page.dart'
    deferred as admin_temp_uploads_page;
import '../features/admin/ui/admin_user_access_page.dart'
    deferred as admin_user_access_page;
import '../features/admin/ui/admin_verified_page.dart'
    deferred as admin_verified_page;
import '../features/owner_businesses/ui/owner_business_submissions_page.dart'
    deferred as owner_business_submissions_page;
import '../features/owner_businesses/ui/owner_businesses_page.dart'
    deferred as owner_businesses_page;
import '../features/owner_businesses/ui/owner_new_business_page.dart'
    deferred as owner_new_business_page;
import '../features/legal/legal_routes.dart';
import '../features/owner_analytics/ui/owner_analytics_page.dart'
    deferred as owner_analytics_page;
import '../features/owner_menu_management/ui/owner_menus_page.dart'
    deferred as owner_menus_page;
import '../features/owner_menu_management/ui/owner_menu_trash_page.dart'
    deferred as owner_menu_trash_page;
import '../features/owner_price_suggestions/ui/owner_price_suggestions_page.dart'
    deferred as owner_price_suggestions_page;
import '../features/owner_requests/ui/owner_group_requests_page.dart'
    deferred as owner_group_requests_page;
import '../features/owner_suspended/ui/owner_suspended_claims_page.dart'
    deferred as owner_suspended_claims_page;
import '../features/legal/ui/legal_page.dart';
import '../features/owner/ui/owner_shell.dart';
import '../features/owner/ui/owner_activity_page.dart'
    deferred as owner_activity_page;
import '../features/owner_dashboard/ui/owner_dashboard_page.dart';
import '../features/owner_dashboard/ui/owner_growth_page.dart'
    deferred as owner_growth_page;
import '../features/owner_onboarding/ui/owner_onboarding_page.dart'
    deferred as owner_onboarding_page;
import '../features/owner_team/ui/owner_team_page.dart'
    deferred as owner_team_page;
import '../features/owner_ai_analysis/ui/owner_ai_analysis_page.dart'
    deferred as owner_ai_analysis_page;
import '../features/owner_reviews/ui/owner_reviews_page.dart'
    deferred as owner_reviews_page;
import '../features/owner_business_hours/ui/owner_business_hours_page.dart'
    deferred as owner_business_hours_page;
import '../features/owner_custom_domain/ui/owner_custom_domain_page.dart'
    deferred as owner_custom_domain_page;
import '../shared/ui/components/deferred_page_loader.dart';
import '../shared/ui/pages/forbidden_page.dart';

GoRouter buildAppRouter(Ref ref, {String initialLocation = '/'}) {
  final session = ref.watch(sessionProvider);
  final appRoleAsync = ref.watch(appRoleProvider);
  final authRefresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) {
    authRefresh.value++;
  });
  ref.listen(appRoleProvider, (_, _) {
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_growth_page.loadLibrary,
              builder: (_) => owner_growth_page.OwnerGrowthPage(
                businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
              ),
            ),
          ),
          GoRoute(
            path: '/owner/suspended',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_suspended_claims_page.loadLibrary,
              builder: (_) => owner_suspended_claims_page.OwnerSuspendedClaimsPage(
                businessId:
                    sanitizeUuid(s.uri.queryParameters['businessId']) ?? '',
              ),
            ),
          ),
          GoRoute(
            path: '/owner/price-suggestions',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_price_suggestions_page.loadLibrary,
              builder: (_) => owner_price_suggestions_page.OwnerPriceSuggestionsPage(
                businessId:
                    sanitizeUuid(s.uri.queryParameters['businessId']) ?? '',
              ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_menu_trash_page.loadLibrary,
              builder: (_) => owner_menu_trash_page.OwnerMenuTrashPage(
                businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
              ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_group_requests_page.loadLibrary,
              builder: (_) => owner_group_requests_page.OwnerGroupRequestsPage(),
            ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_new_business_page.loadLibrary,
              builder: (_) => owner_new_business_page.OwnerNewBusinessPage(),
            ),
          ),
          GoRoute(
            path: '/owner/businesses/submissions',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_business_submissions_page.loadLibrary,
              builder: (_) =>
                  owner_business_submissions_page.OwnerBusinessSubmissionsPage(),
            ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_activity_page.loadLibrary,
              builder: (_) => owner_activity_page.OwnerActivityPage(
                businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
              ),
            ),
          ),
          GoRoute(
            path: '/owner/audit',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_activity_page.loadLibrary,
              builder: (_) => owner_activity_page.OwnerActivityPage(
                businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
              ),
            ),
          ),
          GoRoute(
            path: '/owner/team',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_team_page.loadLibrary,
              builder: (_) => owner_team_page.OwnerTeamPage(
                businessId: sanitizeUuid(s.uri.queryParameters['businessId']),
              ),
            ),
          ),
          GoRoute(
            path: '/owner/ai-analysis',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_ai_analysis_page.loadLibrary,
              builder: (_) => owner_ai_analysis_page.OwnerAiAnalysisPage(
                businessId:
                    sanitizeUuid(s.uri.queryParameters['businessId']) ?? '',
              ),
            ),
          ),
          GoRoute(
            path: '/owner/reviews',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_reviews_page.loadLibrary,
              builder: (_) => owner_reviews_page.OwnerReviewsPage(
                businessId:
                    sanitizeUuid(s.uri.queryParameters['businessId']) ?? '',
              ),
            ),
          ),
          GoRoute(
            path: '/owner/settings/hours',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: owner_business_hours_page.loadLibrary,
              builder: (_) => owner_business_hours_page.OwnerBusinessHoursPage(
                businessId:
                    sanitizeUuid(s.uri.queryParameters['businessId']) ?? '',
              ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_search_page.loadLibrary,
              builder: (_) => admin_search_page.AdminSearchPage(
                initialQuery: s.uri.queryParameters['q'],
              ),
            ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_appeals_page.loadLibrary,
              builder: (_) => admin_appeals_page.AdminAppealsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/growth',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_growth_page.loadLibrary,
              builder: (_) => admin_growth_page.AdminGrowthPage(),
            ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_suspended_claims_page.loadLibrary,
              builder: (_) =>
                  admin_suspended_claims_page.AdminSuspendedClaimsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/price-suggestions',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_price_suggestions_page.loadLibrary,
              builder: (_) =>
                  admin_price_suggestions_page.AdminPriceSuggestionsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/suggestions',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_suggestions_page.loadLibrary,
              builder: (_) => admin_suggestions_page.AdminSuggestionsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/sponsorships',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_sponsorships_page.loadLibrary,
              builder: (_) => admin_sponsorships_page.AdminSponsorshipsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/sponsorship-packages',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_sponsorship_packages_page.loadLibrary,
              builder: (_) =>
                  admin_sponsorship_packages_page.AdminSponsorshipPackagesPage(),
            ),
          ),
          GoRoute(
            path: '/admin/sponsorship-leads',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_sponsorship_leads_page.loadLibrary,
              builder: (_) =>
                  admin_sponsorship_leads_page.AdminSponsorshipLeadsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/verified',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_verified_page.loadLibrary,
              builder: (_) => admin_verified_page.AdminVerifiedPage(),
            ),
          ),
          GoRoute(
            path: '/admin/group-requests',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_group_requests_page.loadLibrary,
              builder: (_) =>
                  admin_group_requests_page.AdminGroupRequestsPage(),
            ),
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
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_table_feedback_page.loadLibrary,
              builder: (_) =>
                  admin_table_feedback_page.AdminTableFeedbackPage(),
            ),
          ),
          GoRoute(
            path: '/admin/receipt-submissions',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_receipt_submissions_page.loadLibrary,
              builder: (_) =>
                  admin_receipt_submissions_page.AdminReceiptSubmissionsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/audit',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_audit_page.loadLibrary,
              builder: (_) => admin_audit_page.AdminAuditPage(),
            ),
          ),
          GoRoute(
            path: '/admin/trash',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_menu_restore_page.loadLibrary,
              builder: (_) => admin_menu_restore_page.AdminMenuRestorePage(
                initialBusinessId: sanitizeUuid(
                  s.uri.queryParameters['businessId'],
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/dev-tools',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_dev_tools_page.loadLibrary,
              builder: (_) => admin_dev_tools_page.AdminDevToolsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/observability',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_observability_page.loadLibrary,
              builder: (_) =>
                  admin_observability_page.AdminObservabilityPage(),
            ),
          ),
          GoRoute(
            path: '/admin/b2b-exports',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_b2b_exports_page.loadLibrary,
              builder: (_) => admin_b2b_exports_page.AdminB2bExportsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/incidents',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_incident_center_page.loadLibrary,
              builder: (_) =>
                  admin_incident_center_page.AdminIncidentCenterPage(),
            ),
          ),
          GoRoute(
            path: '/admin/temp-uploads',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_temp_uploads_page.loadLibrary,
              builder: (_) => admin_temp_uploads_page.AdminTempUploadsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/users/:id',
            builder: (c, s) => DeferredPageLoader(
              loadLibrary: admin_user_access_page.loadLibrary,
              builder: (_) => admin_user_access_page.AdminUserAccessPage(
                userId: sanitizeUuid(s.pathParameters['id']) ?? '',
              ),
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
