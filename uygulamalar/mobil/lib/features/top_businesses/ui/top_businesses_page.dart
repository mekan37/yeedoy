import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import 'widgets/top_business_card.dart';
import '../domain/top_business.dart';
import '../domain/top_businesses_page_controller.dart';

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
          loading: () => const Center(child: CircularProgressIndicator()),
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
                  onTap: () => context.go('/b/${item.id}'),
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

