import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeedoy/app/theme/app_tokens.dart';
import 'package:yeedoy/core/location/user_location_controller.dart';
import 'package:yeedoy/features/auth/domain/auth_providers.dart';
import 'package:yeedoy/features/profile/ui/components/profile_identity_card.dart';
import 'package:yeedoy/features/profile/ui/profile_page.dart';
import 'package:yeedoy/l10n/app_localizations.dart';
import 'package:yeedoy/l10n/app_localizations_tr.dart';

ThemeData _theme() => ThemeData(
  extensions: const <ThemeExtension<dynamic>>[
    AppTokens(
      space4: 4,
      space8: 8,
      space12: 12,
      space16: 16,
      space20: 20,
      space24: 24,
      radius12: 12,
      radius16: 16,
      radius20: 20,
      radius24: 24,
      elevation1: 1,
      elevation2: 6,
      elevation3: 12,
      minHitTarget: 44,
      fast: Duration(milliseconds: 150),
      medium: Duration(milliseconds: 180),
      slow: Duration(milliseconds: 220),
    ),
  ],
);

class _FakeLocationController extends UserLocationController {
  @override
  UserLocationState build() => const UserLocationState(
    city: null,
    district: null,
    neighborhood: null,
    mode: 'auto',
    loading: false,
    permissionDenied: true,
    error: null,
  );
}

Future<void> _pumpProfilePage(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});

  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: ProfilePage()),
      ),
      GoRoute(
        path: '/favorites',
        builder: (_, _) => const Scaffold(body: Text('Favorites Page')),
      ),
      GoRoute(
        path: '/inbox',
        builder: (_, _) => const Scaffold(body: Text('Inbox Page')),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('Login Page')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProvider.overrideWith((ref) => null),
        myProfileProvider.overrideWith((ref) async => null),
        userLocationProvider.overrideWith(_FakeLocationController.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: _theme(),
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final t = AppLocalizationsTr();

  group('ProfilePage redesign (guest)', () {
    testWidgets(
      'renders home header, hero card, quick actions and account list',
      (tester) async {
        await _pumpProfilePage(tester);

        expect(find.text(t.profileHomeTitle), findsOneWidget);
        // The page renders a static greeting "Merhaba! 👋" (not the
        // discoveryGreetingHelloAnon l10n key) above profileHomeTitle.
        expect(find.text('Merhaba! 👋'), findsOneWidget);

        // Quick actions grid: Favorilerim, Yorumlarım, Bildirim Kutusu, Profil Ayarları.
        expect(find.text(t.profileQuickActionsTitle), findsOneWidget);
        expect(find.text(t.profileQuickActionFavorites), findsOneWidget);
        expect(find.text('Yorumlarım'), findsOneWidget);
        expect(find.text(t.drawerInbox), findsOneWidget);
        // profileSettings label appears twice: once in the quick actions
        // grid, once in the account list below.
        expect(find.text(t.profileSettings), findsNWidgets(2));

        // Account list: section title + literal-string rows (Adreslerim,
        // Bildirim Tercihleri, Yardım ve Destek) — no "Hesap Güvenliği" row
        // in the current design.
        expect(find.text(t.profileAccountSectionTitle), findsOneWidget);
        expect(find.text('Adreslerim'), findsOneWidget);
        expect(find.text('Bildirim Tercihleri'), findsOneWidget);
        expect(find.text('Yardım ve Destek'), findsOneWidget);

        // Badges banner concept no longer exists on this page; nothing to
        // assert here other than the absence of legacy l10n strings.
        expect(find.text(t.profileBadgesBannerTitle), findsNothing);

        // Location row (above the stats row) is hidden when there is no
        // device location. The "Adreslerim" account-list row also uses the
        // location_on_outlined icon, so we assert there is exactly one
        // instance (the account-list row) rather than asserting absence.
        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      },
    );

    testWidgets('Favorilerim quick action navigates to /favorites', (
      tester,
    ) async {
      await _pumpProfilePage(tester);

      await tester.tap(find.text(t.profileQuickActionFavorites));
      await tester.pumpAndSettle();

      expect(find.text('Favorites Page'), findsOneWidget);
    });
  });
}
