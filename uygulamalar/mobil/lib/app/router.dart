import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import 'app_shell.dart';
import '../core/config/feature_flags.dart';
import '../core/security/route_sanitizer.dart';
import '../features/auth/domain/auth_providers.dart';
import '../features/auth/ui/login_page.dart';
import '../features/auth/ui/register_page.dart';
import '../features/auth/ui/forgot_password_page.dart';
import '../features/auth/ui/account_security_page.dart';
import '../features/perks/ui/perks_page.dart';
import '../features/price_alerts/ui/price_alerts_page.dart';
import '../features/business/ui/business_page.dart';
import '../features/smart_recommendation/ui/smart_recommendation_page.dart';
import '../features/chains/ui/chain_page.dart';
import '../features/compare/ui/compare_page.dart';
import '../features/discovery/ui/discovery_page.dart';
import '../features/favorites/ui/favorites_page.dart';
import '../features/gourmets/ui/following_page.dart';
import '../features/gourmets/ui/gourmets_page.dart';
import '../features/group_requests/ui/group_request_detail_page.dart';
import '../features/group_requests/ui/group_request_wizard_page.dart';
import '../features/group_requests/ui/my_group_requests_page.dart';
import '../features/heroes/ui/heroes_page.dart';
import '../features/menus/ui/menu_page.dart';
import '../features/menus/ui/menu_item_page.dart';
import '../features/menus/ui/public_menu_share_page.dart';
import '../features/notifications/ui/inbox_page.dart';
import '../features/onboarding/ui/onboarding_page.dart';
import '../features/profile/ui/account_info_page.dart';
import '../features/profile/ui/profile_page.dart';
import '../features/profile/ui/profile_settings_page.dart';
import '../features/profile/ui/social_accounts_page.dart';
import '../features/notifications/ui/notification_preferences_page.dart';
import '../features/support/ui/live_support_page.dart';
import '../features/support/ui/help_support_page.dart';
import '../features/support/ui/faq_page.dart';
import '../features/location/ui/location_picker_page.dart';
import '../features/contribute/ui/contribute_page.dart';
import '../features/reviews/ui/business_reviews_page.dart';
import '../features/reviews/ui/review_create_page.dart';
import '../features/smart_feed/ui/smart_feed_page.dart';
import '../features/splash/ui/splash_page.dart';
import '../features/suggestions/ui/my_suggestions_page.dart';
import '../features/suggestions/ui/suggest_business_page.dart';
import '../features/suspended_meals/ui/my_suspended_claims_page.dart';
import '../features/taste_twin/ui/taste_twin_page.dart';
import '../features/top_businesses/ui/top_businesses_page.dart';
import '../features/collab_lists/ui/collab_lists_page.dart';
import '../features/collab_lists/ui/collab_list_detail_page.dart';
import '../features/collab_lists/ui/collab_list_join_page.dart';
import '../features/legal/ui/data_deletion_page.dart';
import '../features/legal/ui/legal_page.dart';
import '../features/legal/ui/legal_acceptance_page.dart';
import '../features/legal/legal_providers.dart';
import '../features/devtools/ui/developer_tools_page.dart';
import '../features/grup_oy/ui/oy_ver_sayfasi.dart';
import '../features/sadakat/ui/sadakat_kartlarim_sayfasi.dart';
import '../features/shared/ui/labs_page.dart';
import '../features/yemek_gunlugu/ui/yemek_gunlugu_sayfasi.dart';
import '../core/i18n/app_localizations.dart';
import '../core/config/app_config.dart';

bool _bootSplashHandled = false;

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  final flags = ref.watch(featureFlagsProvider);
  final legalSnapshot = ref.watch(legalAcceptanceSnapshotProvider);
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

      final adminOrOwnerPath =
          path == '/admin' ||
          path.startsWith('/admin/') ||
          path == '/owner' ||
          path.startsWith('/owner/');
      if (adminOrOwnerPath) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/panel-web?from=$from';
      }

      final hasSharedFavorites =
          path.startsWith('/favorites') &&
          (state.uri.queryParameters['ids'] ?? '').trim().isNotEmpty;
      final requiresAuth =
          (path.startsWith('/favorites') && !hasSharedFavorites) ||
          path.startsWith('/profile') ||
          path.startsWith('/inbox') ||
          path.startsWith('/my-suggestions') ||
          path.startsWith('/following') ||
          path.startsWith('/taste-twin') ||
          path.startsWith('/my-suspended') ||
          path.startsWith('/group-requests') ||
          path.startsWith('/collab-lists');

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
      final legalAcceptanceRoute =
          path == '/legal/acceptance' || path.startsWith('/legal/acceptance');
      final legalAcceptanceCheckFailed = legalSnapshot.hasError;
      final pendingLegalAcceptance =
          legalSnapshot.asData?.value?.requiresMandatoryAcceptance ?? false;
      if (loggedIn &&
          (pendingLegalAcceptance || legalAcceptanceCheckFailed) &&
          !legalAcceptanceRoute) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/legal/acceptance?from=$from';
      }

      final photoFeedRoute =
          path == '/feed' ||
          path.startsWith('/feed/') ||
          path == '/gourmets' ||
          path.startsWith('/gourmets/') ||
          path == '/following' ||
          path.startsWith('/following/');
      if (!flags.enablePhotoFeed && photoFeedRoute) {
        return '/discover';
      }

      final experimentalHubRoute = path == '/labs' || path.startsWith('/labs/');
      if (experimentalHubRoute && !flags.hasExperimentalNavigation) {
        return '/discover';
      }

      final labsRoute =
          path == '/heroes' ||
          path.startsWith('/heroes/') ||
          path == '/taste-twin' ||
          path.startsWith('/taste-twin/') ||
          path == '/group-requests' ||
          path.startsWith('/group-requests/') ||
          path == '/budget-combos' ||
          path.startsWith('/budget-combos/') ||
          path == '/compare' ||
          path.startsWith('/compare/') ||
          path == '/my-suspended' ||
          path.startsWith('/my-suspended/') ||
          path == '/chain' ||
          path.startsWith('/chain/');
      if (!flags.enableLabs && labsRoute) {
        return '/discover';
      }
      final devToolsRoute =
          path == '/dev-tools' || path.startsWith('/dev-tools/');
      if (devToolsRoute && !(kDebugMode || AppConfig.devToolsEnabled)) {
        return '/discover';
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
      GoRoute(
        path: '/legal/acceptance',
        builder: (context, state) {
          final from = sanitizeInternalRedirect(
            state.uri.queryParameters['from'],
          );
          return LegalAcceptancePage(fromPath: from);
        },
      ),
      GoRoute(
        path: '/panel-web',
        builder: (context, state) {
          final from = sanitizeFreeText(state.uri.queryParameters['from']);
          return _PanelWebOnlyPage(fromPath: from);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.uri.toString(), child: child);
        },
        routes: [
          GoRoute(path: '/feed', builder: (c, s) => const SmartFeedPage()),
          GoRoute(
            path: '/discover',
            builder: (c, s) {
              final sort = s.uri.queryParameters['sort'];
              return DiscoveryPage(
                initialSort: sort == 'price_asc' ? 'priceLow' : null,
              );
            },
          ),
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
          GoRoute(
            path: '/contribute',
            builder: (c, s) => const ContributePage(),
          ),
          GoRoute(
            path: '/price-alerts',
            builder: (c, s) => const PriceAlertsPage(),
          ),
        ],
      ),
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
        path: '/labs',
        pageBuilder: (c, s) =>
            buildFadeSlidePage(state: s, child: const LabsPage()),
      ),
      GoRoute(
        path: '/compare',
        pageBuilder: (c, s) =>
            buildFadeSlidePage(state: s, child: const ComparePage()),
      ),
      GoRoute(
        path: '/account-info',
        pageBuilder: (c, s) =>
            buildFadeSlidePage(state: s, child: const AccountInfoPage()),
      ),
      GoRoute(
        path: '/social-accounts',
        pageBuilder: (c, s) =>
            buildFadeSlidePage(state: s, child: const SocialAccountsPage()),
      ),
      GoRoute(
        path: '/live-support',
        pageBuilder: (c, s) =>
            buildFadeSlidePage(state: s, child: const LiveSupportPage()),
      ),
      GoRoute(
        path: '/help-support',
        pageBuilder: (c, s) =>
            buildFadeSlidePage(state: s, child: const HelpSupportPage()),
      ),
      GoRoute(
        path: '/faq',
        pageBuilder: (c, s) =>
            buildFadeSlidePage(state: s, child: const FaqPage()),
      ),
      GoRoute(
        path: '/location-picker',
        pageBuilder: (c, s) =>
            buildFadeSlidePage(state: s, child: const LocationPickerPage()),
      ),
      GoRoute(
        path: '/notification-preferences',
        pageBuilder: (c, s) => buildFadeSlidePage(
          state: s,
          child: const NotificationPreferencesPage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (c, s) =>
            buildFadeSlidePage(state: s, child: const ProfileSettingsPage()),
      ),
      GoRoute(
        path: '/budget-combos',
        pageBuilder: (c, s) => buildFadeSlidePage(
          state: s,
          child: const SmartRecommendationPage(),
        ),
      ),
      GoRoute(
        path: '/loyalty-cards',
        // MVP defer: loyalty/sadakat özelliği kapalı (bkz.
        // docs/engineering/2026-yeedoy-loyalty-mvp-defer-decision.md).
        // Nav'dan erişim zaten kaldırıldı; deep-link/manuel URL erişimine
        // karşı güvenlik için redirect eklendi. DB/RPC dosyaları dokunulmadan
        // bırakıldı, route tanımı geriye dönük uyumluluk için saklı tutuldu.
        redirect: (c, s) => '/profile',
        pageBuilder: (c, s) => buildFadeSlidePage(
          state: s,
          child: const SadakatKartlarimSayfasi(),
        ),
      ),
      GoRoute(
        path: '/food-journal',
        pageBuilder: (c, s) => buildFadeSlidePage(
          state: s,
          child: const YemekGunluguSayfasi(),
        ),
      ),
      GoRoute(
        path: '/group-vote/:token',
        pageBuilder: (c, s) => buildFadeSlidePage(
          state: s,
          child: OyVerSayfasi(token: s.pathParameters['token']!),
        ),
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
        path: '/suggest-business',
        builder: (c, s) => const SuggestBusinessPage(),
      ),
      GoRoute(
        path: '/dev-tools',
        builder: (c, s) => const DeveloperToolsPage(),
      ),
      GoRoute(
        path: '/my-suggestions',
        builder: (c, s) => const MySuggestionsPage(),
      ),
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
      GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (c, s) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/account-security',
        builder: (c, s) => const AccountSecurityPage(),
      ),
      GoRoute(
        path: '/perks/:businessId',
        builder: (c, s) {
          final id = sanitizeUuid(s.pathParameters['businessId']) ?? '';
          final name = s.uri.queryParameters['name'] ?? '';
          return PerksPage(businessId: id, businessName: name);
        },
      ),
      GoRoute(path: '/legal', builder: (c, s) => const LegalPage()),
      GoRoute(
        path: '/data-deletion',
        builder: (c, s) => const DataDeletionPage(),
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
        path: '/my-suspended',
        builder: (c, s) => const MySuspendedClaimsPage(),
      ),
      GoRoute(
        path: '/collab-lists',
        builder: (c, s) => const CollabListsPage(),
      ),
      GoRoute(
        path: '/collab-lists/join',
        builder: (c, s) {
          final token = sanitizeFreeText(
            s.uri.queryParameters['token'],
            maxLen: 40,
          );
          return CollabListJoinPage(token: token);
        },
      ),
      GoRoute(
        path: '/collab-lists/:id',
        builder: (c, s) {
          final id = sanitizeUuid(s.pathParameters['id']) ?? '';
          return CollabListDetailPage(listId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => const _NotFoundPage(),
  );
});

class _PanelWebOnlyPage extends StatelessWidget {
  const _PanelWebOnlyPage({required this.fromPath});

  final String fromPath;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.panelAccessTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 48),
              const SizedBox(height: 12),
              Text(
                t.panelWebOnlyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              if (fromPath.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  t.panelRedirectedPath(fromPath),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/discover'),
                child: Text(t.panelBackToDiscover),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.notFoundTitle)),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/discover'),
          child: Text(t.discover),
        ),
      ),
    );
  }
}
