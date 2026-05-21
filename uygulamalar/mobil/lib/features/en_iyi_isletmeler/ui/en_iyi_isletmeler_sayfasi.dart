import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import 'bilesenler/en_iyi_isletme_karti.dart';
import '../domain/en_iyi_isletme.dart';
import '../domain/en_iyi_isletmeler_sayfasi_kontrolcu.dart';

class TopBusinessesPage extends ConsumerWidget {
  const TopBusinessesPage({super.key, required this.period});
  final String period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(topBusinessesListProvider(period));
    final title = period == 'month'
        ? t.bestBusinessesThisMonth
        : t.bestBusinessesThisWeek;

    return AppScaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(topBusinessesListProvider(period).notifier)
            .refresh(force: true),
        child: async.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: List.generate(6, (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: AppSkeletonCard(lines: 3),
            )),
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                AppErrorMapper.message(e),
                style: const TextStyle(color: AppColors.danger),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref
                    .read(topBusinessesListProvider(period).notifier)
                    .refresh(force: true),
                child: Text(t.retry),
              ),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 20),
                  Text(
                    t.topBusinessesNotEnoughData,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = list[i];
                return _TopBusinessListTile(
                  item: item,
                  badge: period == 'month'
                      ? t.topBusinessesBadgeMonth
                      : t.topBusinessesBadgeWeek,
                  onTap: () => context.go('/isletme/${item.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TopBusinessListTile extends StatelessWidget {
  const _TopBusinessListTile({
    required this.item,
    required this.badge,
    required this.onTap,
  });

  final TopBusiness item;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TopBusinessCard(item: item, badge: badge, onTap: onTap);
  }
}






