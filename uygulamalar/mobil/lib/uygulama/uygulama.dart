import '../features/bildirimler/domain/android_hata_bildirim_koprusu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ag/baglanti_kurtarma_servisi.dart';
import '../core/depolama/tema_tercihleri.dart';
import '../features/kimlik/domain/kimlik_saglayicilari.dart';
import '../features/bildirimler/domain/push_bildirim_yasam_dongusu_saglayicisi.dart';
import '../features/bildirimler/domain/push_bildirim_servisi.dart';
import '../core/depolama/cevrimdisi_esitleme_servisi.dart';
import 'yonlendirici.dart';
import '../core/ceviri/uygulama_yerellesmeleri.dart';
import '../core/ceviri/yerel_kontrolcusu.dart';
import 'tema/uygulama_temasi.dart';

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

    // Password-recovery deep link: redirect to account-security page
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (prev, next) {
      final event = next.asData?.value.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          router.go('/account-security');
        });
      }
    });

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





