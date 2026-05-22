import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/ag/baglanti_durumu_saglayicisi.dart';
import '../core/ayarlar/ozellik_bayraklari.dart';
import '../core/sabitler/uygulama_metinleri.dart';
import '../core/ceviri/uygulama_yerellesmeleri.dart';
import '../core/konum/kullanici_konum_kontrolcusu.dart';
import '../uygulama/tema/renkler.dart';
import '../features/bildirimler/ui/bilesenler/bildirim_zili.dart';
import '../features/shared/ui/bilesenler/uygulama_ust_cubugu.dart';
import '../features/shared/ui/bilesenler/alt_navigasyon.dart';
import '../features/shared/ui/bilesenler/uygulama_cekmecesi.dart';
import '../features/shared/ui/bilesenler/konum_secici_paneli.dart';
import '../features/shared/ui/tasarim_sistemi.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(featureFlagsProvider);
    final loc = ref.watch(userLocationProvider);
    final bagli = ref.watch(baglantiDurumuProvider).when(
      data: (v) => v,
      loading: () => true,
      error: (e, _) => true,
    );
    final titleStyle = context.appText.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        final last = _lastBackPress;
        if (last != null && now.difference(last) < const Duration(seconds: 2)) {
          // Second tap within 2s — allow exit
          Navigator.of(context).maybePop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).localeName.startsWith('tr')
                  ? 'Çıkmak için tekrar basın'
                  : 'Press back again to exit',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        appBar: AppAppBar(
          centerTitle: false,
          title: Text(AppStrings.appName, style: titleStyle),
          actions: [
            _LocationPill(
              label: _locationLabel(loc),
              onTap: () => _openLocationSheet(context),
            ),
            if (flags.hasExperimentalNavigation)
              IconButton(
                tooltip: 'Labs',
                icon: const Icon(Icons.science_outlined),
                onPressed: () => context.go('/labs'),
              ),
            IconButton(
              tooltip: 'Bildirim Kutusu',
              onPressed: () => context.go('/inbox'),
              icon: const NotificationsBell(),
            ),
          ],
        ),
        body: Column(
          children: [
            // M-19: Çevrimdışı mod göstergesi
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: bagli ? 0 : 32,
              color: const Color(0xFFF59E0B),
              child: bagli
                  ? null
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_outlined, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'İnternet bağlantısı yok',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
            Expanded(child: widget.child),
          ],
        ),
        drawer: const AppDrawer(),
        bottomNavigationBar: const AppBottomNav(),
      ),
    );
  }

  void _openLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const LocationPickerSheet(),
    );
  }

  static String _locationLabel(UserLocationState loc) {
    final city = (loc.city ?? '').trim();
    final district = (loc.district ?? '').trim();
    if (city.isEmpty && district.isEmpty) return 'Şehir seç';
    if (city.isEmpty) return district;
    if (district.isEmpty) return city;
    return '$district • $city';
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width < 380 ? 112.0 : 148.0;
    return Padding(
      padding: EdgeInsets.only(right: tokens.space4),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: tokens.minHitTarget),
            padding: EdgeInsets.symmetric(horizontal: tokens.space8),
            decoration: BoxDecoration(
              color: AppColors.cardAlt,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place_outlined, size: 18),
                SizedBox(width: tokens.space8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
