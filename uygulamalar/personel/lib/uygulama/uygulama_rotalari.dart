import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/riverpod_uzantilari.dart';
import '../features/kimlik/domain/kimlik_bildiricisi.dart';
import '../features/kimlik/domain/kimlik_durum.dart';
import '../features/kimlik/ui/giris_sayfasi.dart';
import '../features/dashboard/ui/dashboard_sayfasi.dart';
import '../features/menu_yonetimi/ui/menu_yonetimi_sayfasi.dart';
import '../features/ayarlar/ui/ayarlar_sayfasi.dart';
import '../features/qr_tarayici/ui/qr_tarayici_sayfasi.dart';
import '../features/yorumlar/ui/yorumlar_sayfasi.dart';
import '../features/kampanya/ui/kampanya_sayfasi.dart';
import '../features/shared/ui/ana_kabuk.dart';
import '../features/shared/ui/yukleniyor_sayfasi.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final kimlikListenable = _KimlikListenable(ref);

  return GoRouter(
    refreshListenable: kimlikListenable,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final kimlikDurum = ref.read(kimlikProvider).valueOrNull;
      final yukleniyor = ref.read(kimlikProvider).isLoading;
      final hataVar = ref.read(kimlikProvider).hasError;

      if (yukleniyor) return '/yukleniyor';

      if (hataVar || kimlikDurum is KimlikGirilmemis) {
        return state.uri.toString() == '/giris' ? null : '/giris';
      }

      if (kimlikDurum is KimlikDogrulaniyor) return '/yukleniyor';

      if (kimlikDurum is KimlikYetkisiz) {
        return state.uri.toString() == '/yetkisiz' ? null : '/yetkisiz';
      }

      if (state.uri.toString() == '/giris' ||
          state.uri.toString() == '/yukleniyor') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/yukleniyor',
        builder: (_, _) => const YukleniyorSayfasi(),
      ),
      GoRoute(
        path: '/qr-tarayici',
        builder: (_, _) => const QrTarayiciSayfasi(),
      ),
      GoRoute(
        path: '/yorumlar',
        builder: (_, _) => const YorumlarSayfasi(),
      ),
      GoRoute(
        path: '/kampanya',
        builder: (_, _) => const KampanyaSayfasi(),
      ),
      GoRoute(
        path: '/giris',
        builder: (_, _) => const GirisSayfasi(),
      ),
      GoRoute(
        path: '/yetkisiz',
        builder: (_, state) {
          final kimlik = ref.read(kimlikProvider).valueOrNull;
          final mesaj = kimlik is KimlikYetkisiz ? kimlik.mesaj : null;
          return _YetkisizSayfasi(mesaj: mesaj);
        },
      ),
      ShellRoute(
        builder: (_, _, child) => AnaKabuk(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardSayfasi(),
          ),
          GoRoute(
            path: '/menu',
            builder: (_, _) => const MenuYonetimiSayfasi(),
          ),
          GoRoute(
            path: '/ayarlar',
            builder: (_, _) => const AyarlarSayfasi(),
          ),
        ],
      ),
    ],
  );
});

class _KimlikListenable extends ChangeNotifier {
  _KimlikListenable(Ref ref) {
    ref.listen(kimlikProvider, (_, _) => notifyListeners());
  }
}

class _YetkisizSayfasi extends ConsumerWidget {
  final String? mesaj;
  const _YetkisizSayfasi({this.mesaj});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 20),
              Text(
                'Erişim Yok',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                mesaj ??
                    'Bu uygulamaya erişim için onaylı işletme kaydı gereklidir. Lütfen destek ile iletişime geçin.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(kimlikProvider.notifier).cikisYap(),
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
