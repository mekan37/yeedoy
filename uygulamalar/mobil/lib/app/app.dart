import '../features/notifications/domain/android_debug_push_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/connectivity_restore_service.dart';
import '../core/privacy/consent_guard.dart';
import '../core/privacy/data/consent_provider.dart';
import '../core/storage/theme_prefs.dart';
import '../features/auth/domain/auth_providers.dart';
import '../features/notifications/domain/push_notification_lifecycle_provider.dart';
import '../features/notifications/domain/push_notification_service.dart';
import '../core/storage/offline_sync_service.dart';
import 'router.dart';
import '../core/i18n/app_localizations.dart';
import '../core/i18n/locale_controller.dart';
import 'theme/app_theme.dart';

class YeedoyApp extends ConsumerWidget {
  const YeedoyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider).asData?.value;
    final themeMode =
        ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.appName,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return const Locale('tr');
            for (final s in supportedLocales) {
              if (s.languageCode == locale.languageCode) return s;
            }
            return const Locale('tr');
          },
          theme: buildAppTheme(),
          darkTheme: buildDarkAppTheme(),
          themeMode: themeMode,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return _GlobalPushIntentListener(
              router: router,
              data: media.copyWith(
                textScaler: media.textScaler.clamp(
                  minScaleFactor: 1,
                  maxScaleFactor: 1.4,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          routerConfig: router,
        );
      },
    );
  }
}

class _GlobalPushIntentListener extends ConsumerStatefulWidget {
  const _GlobalPushIntentListener({
    required this.router,
    required this.data,
    required this.child,
  });

  final GoRouter router;
  final MediaQueryData data;
  final Widget child;

  @override
  ConsumerState<_GlobalPushIntentListener> createState() =>
      _GlobalPushIntentListenerState();
}

class _GlobalPushIntentListenerState
    extends ConsumerState<_GlobalPushIntentListener> {
  /// Prevents the consent sheet from being shown more than once per session,
  /// even if the widget rebuilds (e.g. theme/locale changes).
  bool _consentShown = false;

  @override
  void initState() {
    super.initState();
    // Schedule the consent check after the first frame so that:
    // 1. The Navigator is mounted and can host the bottom sheet.
    // 2. ConsentNotifier._init() has had a chance to load from SharedPreferences.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowConsent();
    });
  }

  Future<void> _maybeShowConsent() async {
    if (!mounted || _consentShown) return;

    // ConsentNotifier._init() is async. Do not rely on a single event-loop
    // turn here; wait for persisted preferences before deciding whether the
    // sheet is needed.
    await ref.read(consentNotifierProvider.notifier).load();

    if (!mounted || _consentShown) return;
    final state = ref.read(consentNotifierProvider);
    if (state.hasDecided) return;

    // Mark before await so concurrent rebuilds can never enter twice.
    _consentShown = true;

    // `context` here sits ABOVE the GoRouter's Navigator (this widget wraps
    // the router's child inside MaterialApp.builder), so it has no Navigator
    // ancestor. Use the router's navigator context instead, which does.
    final navigatorContext =
        widget.router.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;
    await ConsentGuard.checkAndShow(navigatorContext, ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(androidDebugPushLifecycleProvider);
    ref.watch(connectivityRestoreLifecycleProvider);
    ref.watch(offlineSyncLifecycleProvider);
    ref.watch(pushNotificationLifecycleProvider);

    // Password-recovery deep link: redirect to account-security page
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (prev, next) {
      final event = next.asData?.value.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.router.go('/account-security');
        });
      }
    });

    ref.listen<PushTapIntent?>(pushTapIntentProvider, (previous, next) {
      if (next == null) return;
      assert(() {
        debugPrint('[GlobalPushIntentListener] route=${next.route}');
        return true;
      }());
      widget.router.go(next.route);
      ref.read(pushTapIntentProvider.notifier).clear();
    });

    final pendingPushIntent = ref.watch(pushTapIntentProvider);
    if (pendingPushIntent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final current = ref.read(pushTapIntentProvider);
        if (current == null) return;
        assert(() {
          debugPrint(
            '[GlobalPushIntentListener] pendingRoute=${current.route}',
          );
          return true;
        }());
        widget.router.go(current.route);
        ref.read(pushTapIntentProvider.notifier).clear();
      });
    }

    return MediaQuery(data: widget.data, child: widget.child);
  }
}
