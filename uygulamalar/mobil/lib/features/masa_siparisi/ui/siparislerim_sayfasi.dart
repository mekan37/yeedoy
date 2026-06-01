import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../domain/masa_siparisi_gonder_bildiricisi.dart';
import '../domain/masa_siparisi_modeli.dart';

class SiparislerimSayfasi extends ConsumerWidget {
  const SiparislerimSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siparislerAsync = ref.watch(siparislerimProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: Text('Siparişlerim')),
      body: siparislerAsync.when(
        loading: () => const _SiparislerSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppErrorMapper.message(e),
                style: const TextStyle(color: AppColors.danger),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(siparislerimProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (siparisler) {
          if (siparisler.isEmpty) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Henüz sipariş vermediniz',
              description:
                  'Bir işletmenin sayfasından "Sipariş Ver" butonuna tıklayarak başlayabilirsiniz.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(siparislerimProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: siparisler.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) => RepaintBoundary(
                child: _SiparisSatiri(ozet: siparisler[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SiparisSatiri extends StatelessWidget {
  const _SiparisSatiri({required this.ozet});

  final MasaSiparisiOzet ozet;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(ozet.status);
    final zamanagoText = _relativeTime(ozet.createdAt);

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusInfo.renk.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(statusInfo.ikon, color: statusInfo.renk, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masa ${ozet.tableNo}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  zamanagoText,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusInfo.renk.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusInfo.etiket,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: statusInfo.renk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({Color renk, IconData ikon, String etiket}) _statusInfo(String status) {
    return switch (status) {
      'bekliyor' => (
          renk: AppColors.warning,
          ikon: Icons.schedule_rounded,
          etiket: 'Bekliyor',
        ),
      'hazirlaniyor' => (
          renk: AppColors.info,
          ikon: Icons.restaurant_outlined,
          etiket: 'Hazırlanıyor',
        ),
      'hazir' => (
          renk: AppColors.success,
          ikon: Icons.check_circle_outline,
          etiket: 'Hazır',
        ),
      'tamamlandi' => (
          renk: AppColors.muted,
          ikon: Icons.task_alt_outlined,
          etiket: 'Tamamlandı',
        ),
      'iptal' => (
          renk: AppColors.danger,
          ikon: Icons.cancel_outlined,
          etiket: 'İptal',
        ),
      _ => (
          renk: AppColors.muted,
          ikon: Icons.help_outline,
          etiket: status,
        ),
    };
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}

class _SiparislerSkeleton extends StatelessWidget {
  const _SiparislerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 5,
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (_, i) => const AppSkeletonCard(lines: 2),
    );
  }
}
