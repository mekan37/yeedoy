import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/constants/app_strings.dart';
import 'core/i18n/app_localizations.dart';
import 'features/auth/domain/auth_providers.dart';
import 'features/auth/ui/login_page.dart';
import 'features/admin/ui/admin_shell.dart';
import 'features/admin/ui/admin_dashboard_page.dart';
import 'features/admin/ui/admin_reports_page.dart';
import 'features/admin/ui/admin_growth_page.dart';
import 'features/admin/ui/admin_claims_page.dart';
import 'features/admin/ui/admin_suggestions_page.dart';
import 'features/admin/ui/admin_audit_page.dart';
import 'features/admin/ui/admin_businesses_page.dart';
import 'features/admin/ui/admin_locations_page.dart';
import 'features/admin/ui/admin_suspended_claims_page.dart';
import 'features/admin/ui/admin_price_suggestions_page.dart';
import 'features/admin/ui/admin_sponsorships_page.dart';
import 'features/admin/ui/admin_sponsorship_packages_page.dart';
import 'features/admin/ui/admin_sponsorship_leads_page.dart';
import 'features/admin/ui/admin_verified_page.dart';
import 'features/admin/ui/admin_table_feedback_page.dart';
import 'features/admin/ui/admin_receipt_submissions_page.dart';
import 'app/theme/app_theme.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  final authRefresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) {
    authRefresh.value++;
  });
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: '/admin',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final loggedIn = session != null;
      final path = state.uri.path;

      if (!loggedIn && !path.startsWith('/login')) {
        return '/login';
      }
      if (loggedIn && path == '/login') {
        return '/admin';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
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
            path: '/admin/businesses',
            builder: (c, s) => const AdminBusinessesPage(),
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
            path: '/admin/tools/locations',
            builder: (c, s) => const AdminLocationsPage(),
          ),
          GoRoute(
            path: '/admin/audit',
            builder: (c, s) => const AdminAuditPage(),
          ),
          GoRoute(
            path: '/admin/table-feedback',
            builder: (c, s) => const AdminTableFeedbackPage(),
          ),
          GoRoute(
            path: '/admin/receipt-submissions',
            builder: (c, s) => const AdminReceiptSubmissionsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/:rest(.*)',
        builder: (context, state) {
          final target = Uri.base
              .replace(
                path: state.uri.path,
                queryParameters: state.uri.queryParameters,
              )
              .toString();
          return _AdminExternalRedirectPage(targetUrl: target);
        },
      ),
    ],
  );
});

class YeedoyAdminApp extends ConsumerWidget {
  const YeedoyAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: '${AppStrings.appName} Admin',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return const Locale('tr');
            for (final s in supportedLocales) {
              if (s.languageCode == locale.languageCode) return s;
            }
            return const Locale('tr');
          },
          theme: buildAppTheme(),
          routerConfig: router,
        );
      },
    );
  }
}

class _AdminExternalRedirectPage extends StatefulWidget {
  const _AdminExternalRedirectPage({required this.targetUrl});

  final String targetUrl;

  @override
  State<_AdminExternalRedirectPage> createState() =>
      _AdminExternalRedirectPageState();
}

class _AdminExternalRedirectPageState
    extends State<_AdminExternalRedirectPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uri = Uri.parse(widget.targetUrl);
      await launchUrl(uri, webOnlyWindowName: '_self');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Yönlendiriliyor...')));
  }
}


