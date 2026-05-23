import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeedoy/uygulama/tema/uygulama_tokenleri.dart';
import 'package:yeedoy/core/analitik/analitik_deposu.dart';
import 'package:yeedoy/core/analitik/uygulama_olaylari.dart';
import 'package:yeedoy/core/depolama/uygulama_baslatma_tercihleri.dart';
import 'package:yeedoy/features/onboarding/ui/onboarding_sayfasi.dart';
import 'package:yeedoy/l10n/app_localizations.dart';

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

Future<List<String>> _pumpOnboarding(
  WidgetTester tester, {
  Locale? locale,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final events = <String>[];
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/discover',
        builder: (context, state) => const Text('discover'),
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) => Text(state.uri.toString()),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analyticsRepositoryProvider.overrideWith(
          (_) => AnalyticsRepository.forTest(
            rpc: (_, {params}) async {
              events.add((params?['p_event_name'] ?? '').toString());
              return [
                {'ok': true},
              ];
            },
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: _theme(),
        locale: locale ?? const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

Future<void> _goToNotificationSlide(WidgetTester tester) async {
  await tester.tap(find.text('Devam'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Devam'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Onboarding renders three localized value slides', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Şehrin Fiyatlarını\nSen Belirle'), findsOneWidget);

    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('Topluluğun Gücü'), findsOneWidget);

    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('Anlık Bildirimler'), findsOneWidget);
  });

  testWidgets('Onboarding supports English notification copy', (tester) async {
    await _pumpOnboarding(tester, locale: const Locale('en'));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Instant notifications'), findsOneWidget);
    expect(find.text('Allow Notifications'), findsOneWidget);
  });

  testWidgets('Skipping notifications completes onboarding', (tester) async {
    final events = await _pumpOnboarding(tester);
    await _goToNotificationSlide(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Şimdi değil').last);
    await tester.pumpAndSettle();

    expect(find.text('discover'), findsOneWidget);
    expect(await AppLaunchPrefs.seenOnboarding(), isTrue);
    expect(events, contains(AppEvents.onboardingNotificationSkip));
    expect(events, contains(AppEvents.onboardingComplete));
  });

  testWidgets('Register CTA routes with signup mode', (tester) async {
    await _pumpOnboarding(tester);
    await _goToNotificationSlide(tester);

    await tester.tap(find.text('Kayıt Ol'));
    await tester.pumpAndSettle();

    expect(find.text('/login?mode=signup'), findsOneWidget);
  });
}
