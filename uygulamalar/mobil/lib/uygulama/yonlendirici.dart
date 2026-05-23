import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'uygulama_rotalari.dart';
import 'uygulama_kabugu.dart';
import '../core/ayarlar/ozellik_bayraklari.dart';
import '../core/guvenlik/rota_temizleyici.dart';
import '../features/kimlik/domain/kimlik_saglayicilari.dart';
import '../features/kimlik/ui/giris_sayfasi.dart';
import '../features/kimlik/ui/sifremi_unuttum_sayfasi.dart';
import '../features/kimlik/ui/hesap_guvenligi_sayfasi.dart';
import '../features/ayricaliklar/ui/ayricaliklar_sayfasi.dart';
import '../features/isletme/ui/isletme_sayfasi.dart';
import '../features/butce_kombinasyonlari/ui/butce_kombinasyonlari_sonuc_sayfasi.dart';
import '../features/zincirler/ui/zincir_sayfasi.dart';
import '../features/karsilastirma/ui/karsilastirma_sayfasi.dart';
import '../features/kesif/ui/kesif_sayfasi.dart';
import '../features/favoriler/ui/favoriler_sayfasi.dart';
import '../features/gurmeler/ui/takip_sayfasi.dart';
import '../features/gurmeler/ui/gurmeler_sayfasi.dart';
import '../features/grup_istekleri/ui/grup_istek_detay_sayfasi.dart';
import '../features/grup_istekleri/ui/grup_istek_wizard_sayfasi.dart';
import '../features/grup_istekleri/ui/grup_isteklerim_sayfasi.dart';
import '../features/kahramanlar/ui/kahramanlar_sayfasi.dart';
import '../features/menuler/ui/menuler_sayfasi.dart';
import '../features/menuler/ui/menu_urun_sayfasi.dart';
import '../features/menuler/ui/acik_menu_paylasim_sayfasi.dart';
import '../features/bildirimler/ui/gelen_kutusu_sayfasi.dart';
import '../features/onboarding/ui/onboarding_sayfasi.dart';
import '../features/profil/ui/profil_sayfasi.dart';
import '../features/yorumlar/ui/isletme_yorumlari_sayfasi.dart';
import '../features/yorumlar/ui/yorum_ekleme_sayfasi.dart';
import '../features/akilli_akis/ui/akilli_akis_sayfasi.dart';
import '../features/acilis/ui/acilis_sayfasi.dart';
import '../features/oneriler/ui/benim_onerilerim_sayfasi.dart';
import '../features/oneriler/ui/isletme_oneri_sayfasi.dart';
import '../features/askidaki_ogunler/ui/askidaki_ogunler_sayfasi.dart';
import '../features/tat_ikizi/ui/tat_ikizi_sayfasi.dart';
import '../features/en_iyi_isletmeler/ui/en_iyi_isletmeler_sayfasi.dart';
import '../features/ortak_listeler/ui/ortak_listeler_sayfasi.dart';
import '../features/ortak_listeler/ui/ortak_liste_detay_sayfasi.dart';
import '../features/ortak_listeler/ui/ortak_liste_katilim_sayfasi.dart';
import '../features/sadakat/ui/sadakat_kartlarim_sayfasi.dart';
import '../features/yemek_gunlugu/ui/yemek_gunlugu_sayfasi.dart';
import '../features/masa_siparisi/ui/siparis_basarili_sayfasi.dart';
import '../features/masa_siparisi/ui/siparislerim_sayfasi.dart';
import '../features/yasal/ui/yasal_sayfasi.dart';
import '../features/yasal/ui/yasal_kabul_sayfasi.dart';
import '../features/sahiplen/ui/sahiplen_sayfasi.dart';
import '../features/yerlestir/ui/yerlestir_sayfasi.dart';
import '../features/yasal/yasal_saglayicilari.dart';
import '../features/gelistirme_araclari/ui/gelistirme_araclari_sayfasi.dart';
import '../features/gomulu/ui/gomulu_goruntuleyici_sayfasi.dart';
import '../features/grup_oy/ui/oy_ver_sayfasi.dart';
import '../features/shared/ui/deney_sayfasi.dart';
import '../core/ceviri/uygulama_yerellesmeleri.dart';
import '../core/ayarlar/uygulama_ayarlari.dart';

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
          path.startsWith('/grup-istekleri') ||
          path.startsWith('/ortak-listeler') ||
          path.startsWith('/sadakat-kartlarim') ||
          path.startsWith('/yemek-gunlugum') ||
          path.startsWith('/siparislerim');

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
          path == '/yasal/kabul' || path.startsWith('/yasal/kabul');
      final legalAcceptanceCheckFailed = legalSnapshot.hasError;
      final pendingLegalAcceptance =
          legalSnapshot.asData?.value?.requiresMandatoryAcceptance ?? false;
      if (loggedIn &&
          (pendingLegalAcceptance || legalAcceptanceCheckFailed) &&
          !legalAcceptanceRoute) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/yasal/kabul?from=$from';
      }

      final photoFeedRoute =
          path == '/feed' ||
          path.startsWith('/feed/') ||
          path == '/gourmets' ||
          path.startsWith('/gurmeler/') ||
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
          path == '/kahramanlar' ||
          path.startsWith('/kahramanlar/') ||
          path == '/taste-twin' ||
          path.startsWith('/taste-twin/') ||
          path == '/grup-istekleri' ||
          path.startsWith('/grup-istekleri/') ||
          path == '/budget-combos' ||
          path.startsWith('/budget-combos/') ||
          path == '/compare' ||
          path.startsWith('/karsilastirma/') ||
          path == '/my-suspended' ||
          path.startsWith('/my-suspended/') ||
          path == '/zincir' ||
          path.startsWith('/zincir/');
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
        path: '/yasal/kabul',
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
              return DiscoveryPage(initialSort: sort == 'price_asc' ? 'priceLow' : null);
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
        path: '/isletme/:id',
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
        path: '/zincir/:id',
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
        path: '/isletme/:id/review',
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
        path: '/isletme/:id/reviews',
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
        path: '/isletme/:id/menu/:menuId',
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
        path: '/isletme/:id/menu/:menuId/item/:itemId',
        pageBuilder: (c, s) {
          final businessId = sanitizeUuid(s.pathParameters['id']);
          final menuId = sanitizeUuid(s.pathParameters['menuId']);
          final itemId = sanitizeUuid(s.pathParameters['itemId']);
          if (businessId == null || menuId == null || itemId == null) {
            return buildFadeSlidePage(state: s, child: const DiscoveryPage());
          }
          final excluded = (s.extra is Set<String>)
              ? s.extra as Set<String>
              : const <String>{};
          return buildFadeSlidePage(
            state: s,
            child: MenuItemPage(
              businessId: businessId,
              menuId: menuId,
              menuItemId: itemId,
              excludedAllergens: excluded,
            ),
          );
        },
      ),
      GoRoute(
        path: '/isletme/:id/menu-item/:itemId',
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
        path: '/dev-tools',
        builder: (c, s) => const DeveloperToolsPage(),
      ),
      GoRoute(
        path: '/gomulu',
        builder: (c, s) {
          final url = sanitizeFreeText(
            s.uri.queryParameters['url'],
            maxLen: 2048,
          );
          final title = sanitizeFreeText(
            s.uri.queryParameters['title'],
            maxLen: 120,
          );
          if (url.isEmpty) return const DiscoveryPage();
          return EmbedViewerPage(
            url: url,
            title: title.isEmpty ? null : title,
          );
        },
      ),
      GoRoute(
        path: '/my-suggestions',
        builder: (c, s) => const MySuggestionsPage(),
      ),
      GoRoute(
        path: '/grup-istekleri',
        builder: (c, s) => const MyGroupRequestsPage(),
      ),
      GoRoute(
        path: '/grup-istekleri/new',
        builder: (c, s) => const GroupRequestWizardPage(),
      ),
      GoRoute(
        path: '/grup-istekleri/:id',
        builder: (c, s) {
          final requestId = sanitizeUuid(s.pathParameters['id']);
          if (requestId == null) return const DiscoveryPage();
          return GroupRequestDetailPage(requestId: requestId);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (c, s) =>
            LoginPage(initialSignup: s.uri.queryParameters['mode'] == 'signup'),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (c, s) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/account-security',
        builder: (c, s) => const AccountSecurityPage(),
      ),
      GoRoute(
        path: '/ayricaliklar/:businessId',
        builder: (c, s) {
          final id = sanitizeUuid(s.pathParameters['businessId']) ?? '';
          final name = s.uri.queryParameters['name'] ?? '';
          return PerksPage(businessId: id, businessName: name);
        },
      ),
      GoRoute(path: '/legal', builder: (c, s) => const LegalPage()),
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
      GoRoute(path: '/kahramanlar', builder: (c, s) => const HeroesPage()),
      GoRoute(
        path: '/my-suspended',
        builder: (c, s) => const MySuspendedClaimsPage(),
      ),
      GoRoute(
        path: '/ortak-listeler',
        builder: (c, s) => const CollabListsPage(),
      ),
      GoRoute(
        path: '/ortak-listeler/join',
        builder: (c, s) {
          final token = sanitizeFreeText(
            s.uri.queryParameters['token'],
            maxLen: 40,
          );
          return CollabListJoinPage(token: token);
        },
      ),
      GoRoute(
        path: '/ortak-listeler/:id',
        builder: (c, s) {
          final id = sanitizeUuid(s.pathParameters['id']) ?? '';
          return CollabListDetailPage(listId: id);
        },
      ),
      GoRoute(
        path: '/oyoyla/:token',
        builder: (c, s) {
          final token = s.pathParameters['token'] ?? '';
          return OyVerSayfasi(token: token);
        },
      ),
      GoRoute(
        path: '/sadakat-kartlarim',
        builder: (c, s) => const SadakatKartlarimSayfasi(),
      ),
      GoRoute(
        path: '/yemek-gunlugum',
        builder: (c, s) => const YemekGunluguSayfasi(),
      ),
      GoRoute(
        path: '/siparislerim',
        builder: (c, s) => const SiparislerimSayfasi(),
      ),
      GoRoute(
        path: '/sahiplen',
        builder: (c, s) => SahiplenSayfasi(
          isletmeId: s.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: '/yerlestir/:businessId',
        builder: (c, s) => YerlestirSayfasi(
          businessId: s.pathParameters['businessId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/siparis-basarili',
        builder: (c, s) {
          final extra = s.extra;
          final map = (extra is Map<String, dynamic>) ? extra : const <String, dynamic>{};
          return SiparisBasariliSayfasi(
            businessName: (map['businessName'] ?? '').toString(),
            masaNo: (map['masaNo'] ?? '').toString(),
            orderId: (map['orderId'] ?? '').toString(),
          );
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




























