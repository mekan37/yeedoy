import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/top_businesses_controller.dart';
import '../widgets/top_business_card.dart';
import '../widgets/top_business_skeleton.dart';
import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';

class TopBusinessesStrip extends ConsumerWidget {
  const TopBusinessesStrip({
    super.key,
    required this.period,
  });

  final String period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = period == 'month' ? ref.watch(topBusinessesMonthProvider) : ref.watch(topBusinessesWeekProvider);

    return async.when(
      loading: () => SizedBox(
        height: 190,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, _) => const TopBusinessSkeleton(),
        ),
      ),
      error: (e, _) => Row(
        children: [
          Expanded(
            child: Text(
              AppErrorMapper.message(e),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              final notifier = period == 'month'
                  ? ref.read(topBusinessesMonthProvider.notifier)
                  : ref.read(topBusinessesWeekProvider.notifier);
              notifier.refresh(force: true);
            },
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Text(
            'Henüz yeterli veri yok',
            style: TextStyle(color: AppColors.muted),
          );
        }

        return SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => TopBusinessCard(
              item: list[i],
              badge: period == 'month' ? 'Ay' : 'Hafta',
              width: 220,
              onTap: () => context.go('/b/${list[i].id}'),
            ),
          ),
        );
      },
    );
  }
}




