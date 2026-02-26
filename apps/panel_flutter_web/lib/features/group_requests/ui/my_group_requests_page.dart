import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../data/group_requests_repository.dart';
import '../domain/group_request_models.dart';
import '../../../src/ui/design_system.dart';

class MyGroupRequestsPage extends ConsumerWidget {
  const MyGroupRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taleplerim'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(_myRequestsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/group-requests/new'),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Talep'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_myRequestsProvider),
        child: ref.watch(_myRequestsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppEmptyState(
                icon: Icons.error_outline,
                title: 'Yüklenemedi',
                description: AppErrorMapper.message(e),
                ctaLabel: 'Tekrar dene',
                onCta: () => ref.invalidate(_myRequestsProvider),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  AppEmptyState(
                    icon: Icons.groups_outlined,
                    title: 'Talep yok',
                    description: 'İlk grup yemeği talebini oluştur.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = items[index];
                return AppCard(
                  onTap: () => context.go('/group-requests/${req.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${req.city} • ${_formatDate(req.dateTime)}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${req.partySize} kişi • ${_formatPrice(req.budgetTotalCents)}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      _StatusChip(status: req.status),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

final _myRequestsProvider = FutureProvider<List<GroupRequest>>((ref) async {
  return ref.read(groupRequestsRepositoryProvider).listMyRequests();
});

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'open' => ('Açık', AppColors.info),
      'awarded' => ('Kazandırıldı', AppColors.success),
      'closed' => ('Kapandı', AppColors.warning),
      'cancelled' => ('İptal', AppColors.danger),
      _ => ('Bilinmiyor', AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
    );
  }
}

String _formatDate(DateTime time) {
  return '${time.day.toString().padLeft(2, '0')}.'
      '${time.month.toString().padLeft(2, '0')}.'
      '${time.year}';
}

String _formatPrice(int cents) {
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  return 'â‚º$text';
}


