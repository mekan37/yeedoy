import '../features/notifications/domain/android_debug_push_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../core/network/connectivity_restore_service.dart';
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

class _GlobalPushIntentListener extends ConsumerWidget {
  const _GlobalPushIntentListener({
    required this.router,
    required this.data,
    required this.child,
  });

  final GoRouter router;
  final MediaQueryData data;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(androidDebugPushLifecycleProvider);
    ref.watch(connectivityRestoreLifecycleProvider);
    ref.watch(offlineSyncLifecycleProvider);
    ref.watch(pushNotificationLifecycleProvider);
    ref.listen<PushTapIntent?>(pushTapIntentProvider, (previous, next) {
      if (next == null) return;
      assert(() {
        debugPrint('[GlobalPushIntentListener] route=${next.route}');
        return true;
      }());
      router.go(next.route);
      ref.read(pushTapIntentProvider.notifier).clear();
    });

    final pendingPushIntent = ref.watch(pushTapIntentProvider);
    if (pendingPushIntent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final current = ref.read(pushTapIntentProvider);
        if (current == null) return;
        assert(() {
          debugPrint('[GlobalPushIntentListener] pendingRoute=${current.route}');
          return true;
        }());
        router.go(current.route);
        ref.read(pushTapIntentProvider.notifier).clear();
      });
    }

    return MediaQuery(data: data, child: child);
  }
}


