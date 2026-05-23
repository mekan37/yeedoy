import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeedoy/app/app.dart';
import 'package:yeedoy/app/router.dart';
import 'package:yeedoy/core/network/supabase_provider.dart';
import 'package:yeedoy/core/config/feature_flags.dart';
import 'package:yeedoy/features/auth/domain/auth_providers.dart';
import 'package:yeedoy/features/auth/ui/login_page.dart';
import 'package:yeedoy/features/business/ui/business_page.dart';
import 'package:yeedoy/features/devtools/ui/developer_tools_page.dart';
import 'package:yeedoy/features/discovery/ui/discovery_page.dart';
import 'package:yeedoy/features/heroes/ui/heroes_page.dart';
import 'package:yeedoy/features/legal/ui/legal_page.dart';
import 'package:yeedoy/features/menus/ui/menu_item_page.dart';
import 'package:yeedoy/features/menus/ui/menu_page.dart';
import 'package:yeedoy/features/menus/ui/public_menu_share_page.dart';
import 'package:yeedoy/features/onboarding/ui/onboarding_page.dart';
import 'package:yeedoy/features/reviews/ui/review_create_page.dart';
import 'package:yeedoy/features/smart_feed/ui/smart_feed_page.dart';
import 'package:yeedoy/features/shared/ui/labs_page.dart';
import 'package:yeedoy/features/shared/ui/widgets/report_bottom_sheet.dart';

const _businessId = '11111111-1111-4111-8111-111111111111';
const _menuId = '22222222-2222-4222-8222-222222222222';
const _menuItemId = '33333333-3333-4333-8333-333333333333';
final _testSupabaseClient = SupabaseClient(
  'https://example.supabase.co',
  'test-anon-key',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile smoke', () {
    testWidgets('cold start lands on onboarding when onboarding is unseen', (
      tester,
    ) async {
      final container = await _pumpApp(tester, seenOnboarding: false);
      addTearDown(container.dispose);

      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets(
      'router keeps admin-owner flows in panel and auth-guards favorites',
      (tester) async {
        final container = await _pumpApp(tester, seenOnboarding: false);
        addTearDown(container.dispose);
        final router = container.read(appRouterProvider);

        await tester.pump(const Duration(milliseconds: 2200));
        await tester.pumpAndSettle();

        router.go('/owner');
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.language), findsOneWidget);

        router.go('/favorites');
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);

        router.go('/legal');
        await tester.pumpAndSettle();
        expect(find.byType(LegalPage), findsOneWidget);
      },
    );

    testWidgets(
      'smoke path covers login, discovery, business, menu, review and report',
      (tester) async {
        final container = await _pumpApp(tester, seenOnboarding: true);
        addTearDown(container.dispose);
        final router = container.read(appRouterProvider);

        await tester.pump(const Duration(milliseconds: 2200));
        await _pumpUntilFound(tester, find.byType(DiscoveryPage));
        expect(find.byType(DiscoveryPage), findsOneWidget);

        router.go('/favorites');
        await _pumpUntilFound(tester, find.byType(LoginPage));
        expect(find.byType(LoginPage), findsOneWidget);

        router.go('/discover');
        await _pumpUntilFound(tester, find.byType(DiscoveryPage));
        expect(find.byType(DiscoveryPage), findsOneWidget);

        router.go('/b/$_businessId');
        await _pumpUntilFound(tester, find.byType(BusinessPage));
        expect(find.byType(BusinessPage), findsOneWidget);

        final reportButton = find.byIcon(Icons.flag_outlined);
        expect(reportButton, findsWidgets);
        await tester.tap(reportButton.first);
        await _pumpUntilFound(tester, find.byType(ReportBottomSheet));
        expect(find.byType(ReportBottomSheet), findsOneWidget);
        Navigator.of(tester.element(find.byType(ReportBottomSheet))).pop();
        await tester.pump();

        router.go('/b/$_businessId/menu/$_menuId');
        await _pumpUntilFound(tester, find.byType(MenuPage));
        expect(find.byType(MenuPage), findsOneWidget);

        router.go('/b/$_businessId/menu/$_menuId/item/$_menuItemId');
        await _pumpUntilFound(tester, find.byType(MenuItemPage));
        expect(find.byType(MenuItemPage), findsOneWidget);

        router.go('/b/$_businessId/review');
        await _pumpUntilFound(tester, find.byType(ReviewCreatePage));
        expect(find.byType(ReviewCreatePage), findsOneWidget);

        await tester.enterText(find.byType(TextField).last, 'P0 smoke review');
        await tester.tap(find.byType(FilledButton).first);
        await _pumpUntilFound(tester, find.byType(LoginPage));
        expect(find.byType(LoginPage), findsOneWidget);
      },
    );

    testWidgets('runtime feature flags gate feed routes and labs hub', (
      tester,
    ) async {
      final container = await _pumpApp(tester, seenOnboarding: true);
      addTearDown(container.dispose);

      await tester.pump(const Duration(milliseconds: 2200));
      await _pumpUntilFound(tester, find.byType(DiscoveryPage));
      expect(find.byType(DiscoveryPage), findsOneWidget);

      container.read(appRouterProvider).go('/feed');
      await _pumpUntilFound(tester, find.byType(DiscoveryPage));
      expect(find.byType(SmartFeedPage), findsNothing);
      container.read(appRouterProvider).go('/labs');
      await _pumpUntilFound(tester, find.byType(DiscoveryPage));
      expect(find.byType(LabsPage), findsNothing);

      await container
          .read(featureFlagsProvider.notifier)
          .setFlag('enablePhotoFeed', true);
      await tester.pumpAndSettle();

      container.read(appRouterProvider).go('/labs');
      await _pumpUntilFound(tester, find.byType(LabsPage));
      expect(find.byType(LabsPage), findsOneWidget);

      container.read(appRouterProvider).go('/feed');
      await _pumpUntilFound(tester, find.byType(SmartFeedPage));
      expect(find.byType(SmartFeedPage), findsOneWidget);

      await container
          .read(featureFlagsProvider.notifier)
          .setFlag('enableLabs', false);
      await tester.pumpAndSettle();

      container.read(appRouterProvider).go('/heroes');
      await _pumpUntilFound(tester, find.byType(DiscoveryPage));
      expect(find.byType(HeroesPage), findsNothing);

      await container
          .read(featureFlagsProvider.notifier)
          .setFlag('enableLabs', true);
      await tester.pumpAndSettle();

      container.read(appRouterProvider).go('/labs');
      await _pumpUntilFound(tester, find.byType(LabsPage));
      expect(find.byType(LabsPage), findsOneWidget);

      container.read(appRouterProvider).go('/heroes');
      await _pumpUntilFound(tester, find.byType(HeroesPage));
      expect(find.byType(HeroesPage), findsOneWidget);
    });

    testWidgets('deep-link and qr routes resolve to menu share page', (
      tester,
    ) async {
      final container = await _pumpApp(tester, seenOnboarding: true);
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pump(const Duration(milliseconds: 2200));
      await _pumpUntilFound(tester, find.byType(DiscoveryPage));

      router.go('/menu/$_menuId?src=qr&businessId=$_businessId');
      await _pumpUntilFound(tester, find.byType(PublicMenuSharePage));
      expect(find.byType(PublicMenuSharePage), findsOneWidget);
    });

    testWidgets('developer tools simulates push payload routes', (tester) async {
      final container = await _pumpApp(tester, seenOnboarding: true);
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pump(const Duration(milliseconds: 2200));
      await _pumpUntilFound(tester, find.byType(DiscoveryPage));

      router.go('/dev-tools');
      await _pumpUntilFound(tester, find.byType(DeveloperToolsPage));
      expect(find.byType(DeveloperToolsPage), findsOneWidget);

      final actionButton = find.widgetWithText(
        OutlinedButton,
        'Run price change sample',
      );
      await tester.scrollUntilVisible(
        actionButton,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(actionButton);
      await tester.pumpAndSettle();
      await tester.tap(actionButton);
      await _pumpUntilFound(tester, find.byType(MenuItemPage));
      expect(find.byType(MenuItemPage), findsOneWidget);
    });
  });
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required bool seenOnboarding,
}) async {
  SharedPreferences.setMockInitialValues({
    'seen_onboarding_v1': seenOnboarding,
  });
  final container = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream<AuthState>.value(
          const AuthState(AuthChangeEvent.initialSession, null),
        ),
      ),
      supabaseProvider.overrideWithValue(_testSupabaseClient),
      ensureMyProfileProvider.overrideWith((ref) {}),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const YeedoyApp()),
  );
  await tester.pump();
  return container;
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final endAt = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endAt)) {
    await tester.pump(const Duration(milliseconds: 120));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Finder not found within $timeout: $finder');
}
