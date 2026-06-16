import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yeedoy/app/theme/app_tokens.dart';
import 'package:yeedoy/core/config/feature_flags.dart';
import 'package:yeedoy/features/auth/domain/auth_providers.dart';
import 'package:yeedoy/features/shared/ui/labs_page.dart';
import 'package:yeedoy/l10n/app_localizations.dart';

class TestFeatureFlagsController extends FeatureFlagsController {
  TestFeatureFlagsController(this._state);

  final FeatureFlagsState _state;

  @override
  FeatureFlagsState build() => _state;
}

void main() {
  ThemeData buildTheme() {
    return ThemeData(
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
  }

  Future<void> pumpLabsPage(
    WidgetTester tester, {
    required FeatureFlagsState flags,
  }) async {
    final router = GoRouter(
      initialLocation: '/labs',
      routes: [
        GoRoute(path: '/labs', builder: (context, state) => const LabsPage()),
        GoRoute(path: '/login', builder: (context, state) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagsProvider.overrideWith(
            () => TestFeatureFlagsController(flags),
          ),
          userProvider.overrideWith((ref) => null),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: buildTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows feed experiments without labs-only entries', (
    tester,
  ) async {
    await pumpLabsPage(
      tester,
      flags: const FeatureFlagsState(
        localFlags: {
          'enablePhotoFeed': true,
          'enableLabs': false,
        },
      ),
    );

    // 'Feed' appears in both the status chip row and the entry list.
    expect(find.text('Feed'), findsAtLeastNWidgets(1));
    expect(find.text('Food experts'), findsOneWidget);
    expect(find.text('Heroes'), findsNothing);
    expect(find.text('Smart Picks'), findsNothing);
  });

  testWidgets('shows labs-only entries when labs flag is enabled', (
    tester,
  ) async {
    await pumpLabsPage(
      tester,
      flags: const FeatureFlagsState(
        localFlags: {
          'enablePhotoFeed': false,
          'enableLabs': true,
        },
      ),
    );

    // 'Heroes' appears in both the status chip row and the entry list.
    expect(find.text('Heroes'), findsAtLeastNWidgets(1));
    expect(find.text('Group requests'), findsOneWidget);
    expect(find.text('Smart Picks'), findsOneWidget);
    expect(find.text('Feed'), findsNothing);
  });
}



