import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import 'app_routes.dart';
import '../features/splash/ui/splash_page.dart';

import '../features/discovery/ui/discovery_page.dart';
import '../features/onboarding/ui/onboarding_page.dart';
import 'package:yeedoy/features/business/ui/business_page.dart';
import '../features/reviews/ui/review_create_page.dart';
import '../features/favorites/ui/favorites_page.dart';
import '../features/profile/ui/profile_page.dart';
import '../features/notifications/ui/inbox_page.dart';
import '../features/auth/ui/login_page.dart';
import '../features/suggestions/ui/suggest_business_page.dart';
import '../features/suggestions/ui/my_suggestions_page.dart';
import '../features/auth/domain/auth_providers.dart';
import '../core/security/app_role_providers.dart';
import '../core/security/route_sanitizer.dart';
import '../core/config/feature_flags.dart';
import '../core/config/app_config.dart';
import '../src/features/top_businesses/ui/top_businesses_page.dart';
import '../features/reviews/ui/business_reviews_page.dart';
import '../features/gourmets/ui/gourmets_page.dart';
import '../features/gourmets/ui/following_page.dart';
import '../features/smart_feed/ui/smart_feed_page.dart';
import '../features/taste_twin/ui/taste_twin_page.dart';
import '../features/menus/ui/menu_page.dart';
import 'package:yeedoy/features/menus/ui/menu_item_page.dart';
import '../features/menus/ui/public_menu_share_page.dart';
import '../features/heroes/ui/heroes_page.dart';
import '../features/suspended_meals/ui/my_suspended_claims_page.dart';
import '../features/budget_combos/ui/budget_combo_results_page.dart';
import '../features/compare/ui/compare_page.dart';
import '../features/chains/ui/chain_page.dart';
import '../features/group_requests/ui/group_request_wizard_page.dart';
import '../features/group_requests/ui/my_group_requests_page.dart';
import '../features/group_requests/ui/group_request_detail_page.dart';
import '../src/features/owner_claims/ui/my_claims_page.dart';
import '../src/features/admin/ui/admin_shell.dart';
import '../src/features/admin/ui/admin_dashboard_page.dart';
import '../src/features/admin/ui/admin_reports_page.dart';
import '../src/features/admin/ui/admin_growth_page.dart';
import '../src/features/admin/ui/admin_claims_page.dart';
import '../src/features/admin/ui/admin_suggestions_page.dart';
import '../src/features/admin/ui/admin_audit_page.dart';
import '../src/features/admin/ui/admin_suspended_claims_page.dart';
import '../src/features/admin/ui/admin_price_suggestions_page.dart';
import '../src/features/admin/ui/admin_sponsorship_packages_page.dart';
import '../src/features/admin/ui/admin_sponsorships_page.dart';
import '../src/features/admin/ui/admin_sponsorship_leads_page.dart';
import '../src/features/admin/ui/admin_verified_page.dart';
import '../src/features/admin/ui/admin_table_feedback_page.dart';
import '../src/features/admin/ui/admin_group_requests_page.dart';
import '../src/features/admin/ui/admin_dev_tools_page.dart';
import '../src/features/admin/ui/admin_b2b_exports_page.dart';
import '../src/features/admin/ui/admin_incident_center_page.dart';
import '../src/features/admin/ui/admin_appeals_page.dart';
import '../src/features/admin/ui/admin_temp_uploads_page.dart';
import '../features/admin/ui/translations_debug_page.dart';
import '../src/features/owner_suspended/ui/owner_suspended_claims_page.dart';
import '../src/features/owner_price_suggestions/ui/owner_price_suggestions_page.dart';
import '../src/features/owner_onboarding/ui/owner_onboarding_page.dart';
import '../src/features/owner_requests/ui/owner_group_requests_page.dart';
import '../src/features/owner_businesses/ui/owner_new_business_page.dart';
import '../src/features/owner_businesses/ui/owner_business_submissions_page.dart';
import '../src/features/admin/ui/admin_business_submissions_page.dart';
import '../src/features/admin/domain/admin_permissions.dart';
import '../src/ui/pages/legal_page.dart';
import '../src/ui/pages/crisis_status_page.dart';
import '../src/ui/shells/owner_shell.dart';
import '../src/ui/pages/owner/owner_dashboard_page.dart';
import '../src/ui/pages/owner/owner_businesses_page.dart';
import '../src/ui/pages/owner/owner_menu_builder_page.dart';
import '../src/ui/pages/owner/owner_perks_page.dart';

bool _bootSplashHandled = false;

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  final appRoleAsync = ref.watch(appRoleProvider);
  ref.watch(ensureMyProfileProvider);
  final authRefresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) {
    authRefresh.value++;
  });
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final loggedIn = session != null;
      final path = state.uri.path;
      if (!_bootSplashHandled) {
        if (path == '/splash') {
          _bootSplashHandled = true;
        } else {
          final redirect = Uri.encodeComponent(state.uri.toString());
          return '/splash?redirect=$redirect';
        }
      }
      final hasSharedFavorites =
          path.startsWith('/favorites') &&
          (state.uri.queryParameters['ids'] ?? '').trim().isNotEmpty;
      final requiresAuth =
          (path.startsWith('/favorites') && !hasSharedFavorites) ||
          path.startsWith('/profile') ||
          path.startsWith('/inbox') ||
          path.startsWith('/my-suggestions') ||
          path.startsWith('/my-claims') ||
          path.startsWith('/following') ||
          path.startsWith('/taste-twin') ||
          path.startsWith('/my-suspended') ||
          path.startsWith('/group-requests') ||
          path == '/admin' ||
          path.startsWith('/admin/') ||
          path == '/owner' ||
          path.startsWith('/owner/');

      if (!loggedIn && requiresAuth) {
        final redirect = Uri.encodeComponent(state.uri.toString());
        return '/login?redirect=$redirect';
      }
      if (loggedIn && path == '/login') {
        final redirect = sanitizeInternalRedirect(
          state.uri.queryParameters['redirect'],
        );
        if (redirect != null) return redirect;
        return '/discover';
      }
      final adminRoute = path == '/admin' || path.startsWith('/admin/');
      if (loggedIn && adminRoute) {
        final canAccess = appRoleAsync.maybeWhen(
          data: (role) => canAccessAdminRoute(role, path),
          orElse: () => false,
        );
        if (!canAccess) return '/discover';
      }

      final photoFeedRoute =
          path == '/feed' ||
          path.startsWith('/feed/') ||
          path == '/gourmets' ||
          path.startsWith('/gourmets/');
      if (!FeatureFlags.enablePhotoFeed && photoFeedRoute) {
        return '/discover';
      }

      final labsRoute =
          path == '/heroes' ||
          path.startsWith('/heroes/') ||
          path == '/taste-twin' ||
          path.startsWith('/taste-twin/') ||
          path == '/group-requests' ||
          path.startsWith('/group-requests/') ||
          path == '/compare' ||
          path.startsWith('/compare/') ||
          path == '/chain' ||
          path.startsWith('/chain/') ||
          path == '/labs/translations';
      if (!FeatureFlags.enableLabs && labsRoute) {
        return '/discover';
      }
      if (!kDebugMode && path == '/labs/translations') {
        return '/discover';
      }
      final adminDevToolsRoute =
          path == '/admin/dev-tools' || path.startsWith('/admin/dev-tools/');
      if (adminDevToolsRoute && !(kDebugMode || AppConfig.devToolsEnabled)) {
        return '/admin';
      }
      final ownerRoute = path == '/owner' || path.startsWith('/owner/');
      if (loggedIn && ownerRoute) {
        final isOwnerOrAdmin = appRoleAsync.maybeWhen(
          data: (role) => role == AppRole.owner || role == AppRole.admin,
          orElse: () => false,
        );
        if (!isOwnerOrAdmin) return '/discover';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (c, s) {
          final redirect = sanitizeInternalRedirect(
            s.uri.queryParameters['redirect'],
          );
          return SplashPage(redirectPath: redirect);
        },
      ),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingPage()),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.uri.toString(), child: child);
        },
        routes: [
          GoRoute(path: '/feed', builder: (c, s) => const SmartFeedPage()),
          GoRoute(path: '/discover', builder: (c, s) => const DiscoveryPage()),
          GoRoute(
            path: '/c/:slug',
            builder: (c, s) {
              final slug = sanitizeSlug(s.pathParameters['slug']);
              if (slug.isEmpty) return const DiscoveryPage();
              return FavoritesPage(sharedCollectionSlug: slug);
            },
          ),
          GoRoute(
            path: '/favorites',
            builder: (c, s) {
              final ids = sanitizeUuidCsv(s.uri.queryParameters['ids']);
              final cname = sanitizeFreeText(s.uri.queryParameters['cname']);
              final nearby = s.uri.queryParameters['nearby'] == '1';
              return FavoritesPage(
                sharedBusinessIds: ids,
                sharedCollectionName: cname.isEmpty ? null : cname,
                nearbyMode: nearby,
              );
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (c, s) {
              final tab = s.uri.queryParameters['tab'];
              final initialTab = switch (tab) {
                'alerts' => 1,
                'feed' => 2,
                _ => 0,
              };
              return ProfilePage(initialTab: initialTab);
            },
          ),
          GoRoute(path: '/inbox', builder: (c, s) => const InboxPage()),
        ],
      ),

      // Push sayfalari (tab ustune gelir, geri ok otomatik)
      GoRoute(
        path: '/menu/:menuId',
        pageBuilder: (c, s) {
          final menuId = sanitizeUuid(s.pathParameters['menuId']);
          if (menuId == null) {
            return buildFadeSlidePage(state: s, child: const DiscoveryPage());
          }
          return buildFadeSlidePage(
            state: s,
            child: PublicMenuSharePage(menuId: menuId),
          );
        },
      ),
      GoRoute(
        path: '/compare',
        pageBuilder: (c, s) =>
            buildFadeSlidePage(state: s, child: const ComparePage()),
      ),
      GoRoute(
        path: '/budget-combos',
        pageBuilder: (c, s) {
          final qp = s.uri.queryParameters;
          final city = sanitizeFreeText(qp['city']);
          final district = sanitizeFreeText(qp['district']);
          final party = int.tryParse(qp['party'] ?? '') ?? 2;
          final budget = int.tryParse(qp['budget'] ?? '') ?? 0;
          final categoryRaw = sanitizeFreeText(qp['category']);
          final category = categoryRaw.isEmpty ? null : categoryRaw;
          final radius = double.tryParse(qp['radius'] ?? '');
          return buildFadeSlidePage(
            state: s,
            child: BudgetComboResultsPage(
              city: city,
              district: district,
              partySize: party,
              budgetTotalCents: budget,
              category: category,
              radiusKm: radius,
            ),
          );
        },
      ),
      GoRoute(
        path: '/b/:id',
        pageBuilder: (c, s) {
          final businessId = sanitizeUuid(s.pathParameters['id']);
          if (businessId == null) {
            return buildFadeSlidePage(state: s, child: const DiscoveryPage());
          }
          return buildFadeSlidePage(
            state: s,
            child: BusinessPage(businessId: businessId),
          );
        },
      ),
      GoRoute(
        path: '/chain/:id',
        pageBuilder: (c, s) {
          final chainId = sanitizeUuid(s.pathParameters['id']);
          if (chainId == null) {
            return buildFadeSlidePage(state: s, child: const DiscoveryPage());
          }
          return buildFadeSlidePage(
            state: s,
            child: ChainPage(chainId: chainId),
          );
        },
      ),
      GoRoute(
        path: '/b/:id/review',
        pageBuilder: (c, s) {
          final businessId = sanitizeUuid(s.pathParameters['id']);
          if (businessId == null) {
            return buildFadeSlidePage(state: s, child: const DiscoveryPage());
          }
          return buildFadeSlidePage(
            state: s,
            child: ReviewCreatePage(businessId: businessId),
          );
        },
      ),
      GoRoute(
        path: '/b/:id/reviews',
        pageBuilder: (c, s) {
          final businessId = sanitizeUuid(s.pathParameters['id']);
          if (businessId == null) {
            return buildFadeSlidePage(state: s, child: const DiscoveryPage());
          }
          return buildFadeSlidePage(
            state: s,
            child: BusinessReviewsPage(businessId: businessId),
          );
        },
      ),
      GoRoute(
        path: '/b/:id/menu/:menuId',
        pageBuilder: (c, s) {
          final businessId = sanitizeUuid(s.pathParameters['id']);
          final menuId = sanitizeUuid(s.pathParameters['menuId']);
          if (businessId == null || menuId == null) {
            return buildFadeSlidePage(state: s, child: const DiscoveryPage());
          }
          return buildFadeSlidePage(
            state: s,
            child: MenuPage(businessId: businessId, menuId: menuId),
          );
        },
      ),
      GoRoute(
        path: '/b/:id/menu/:menuId/item/:itemId',
        pageBuilder: (c, s) {
          final businessId = sanitizeUuid(s.pathParameters['id']);
          final menuId = sanitizeUuid(s.pathParameters['menuId']);
          final itemId = sanitizeUuid(s.pathParameters['itemId']);
          if (businessId == null || menuId == null || itemId == null) {
            return buildFadeSlidePage(state: s, child: const DiscoveryPage());
          }
          return buildFadeSlidePage(
            state: s,
            child: MenuItemPage(
              businessId: businessId,
              menuId: menuId,
              menuItemId: itemId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/b/:id/menu-item/:itemId',
        pageBuilder: (c, s) {
          final businessId = sanitizeUuid(s.pathParameters['id']);
          final itemId = sanitizeUuid(s.pathParameters['itemId']);
          final menuId = sanitizeUuid(s.uri.queryParameters['menuId']) ?? '';
          if (businessId == null || itemId == null) {
            return buildFadeSlidePage(state: s, child: const DiscoveryPage());
          }
          return buildFadeSlidePage(
            state: s,
            child: MenuItemPage(
              businessId: businessId,
              menuId: menuId,
              menuItemId: itemId,
            ),
          );
        },
      ),
      GoRoute(path: '/suggest', builder: (c, s) => const SuggestBusinessPage()),
      GoRoute(
        path: '/my-suggestions',
        builder: (c, s) => const MySuggestionsPage(),
      ),
      GoRoute(path: '/my-claims', builder: (c, s) => const MyClaimsPage()),
      GoRoute(
        path: '/group-requests',
        builder: (c, s) => const MyGroupRequestsPage(),
      ),
      GoRoute(
        path: '/group-requests/new',
        builder: (c, s) => const GroupRequestWizardPage(),
      ),
      GoRoute(
        path: '/group-requests/:id',
        builder: (c, s) {
          final requestId = sanitizeUuid(s.pathParameters['id']);
          if (requestId == null) return const DiscoveryPage();
          return GroupRequestDetailPage(requestId: requestId);
        },
      ),
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/legal', builder: (c, s) => const LegalPage()),
      GoRoute(
        path: '/guvenlik-durumu',
        builder: (c, s) => const CrisisStatusPage(),
      ),
      GoRoute(
        path: '/top-businesses',
        builder: (c, s) {
          final period = s.uri.queryParameters['period'];
          final safePeriod = (period == 'month') ? 'month' : 'week';
          return TopBusinessesPage(period: safePeriod);
        },
      ),
      GoRoute(path: '/gourmets', builder: (c, s) => const GourmetsPage()),
      GoRoute(path: '/following', builder: (c, s) => const FollowingPage()),
      GoRoute(path: '/taste-twin', builder: (c, s) => const TasteTwinPage()),
      GoRoute(path: '/heroes', builder: (c, s) => const HeroesPage()),
      GoRoute(
        path: '/labs/translations',
        builder: (c, s) => const TranslationsDebugPage(),
      ),
      GoRoute(
        path: '/my-suspended',
        builder: (c, s) => const MySuspendedClaimsPage(),
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

