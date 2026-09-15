import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/formatters.dart';
import '../data/group_requests_repository.dart';
import '../domain/group_requests_provider.dart';
import '../../../features/shared/ui/design_system.dart';

class MyGroupRequestsPage extends ConsumerWidget {
  const MyGroupRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.groupRequestMyRequestsTitle),
        actions: [
          IconButton(
            tooltip: t.yenile,
            onPressed: () => _refreshRequests(ref),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/group-requests/new'),
        icon: const Icon(Icons.add),
        label: Text(t.groupRequestNewRequestAction),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshRequests(ref),
        child: ref
            .watch(myRequestsProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppEmptyState(
                    icon: Icons.error_outline,
                    title: t.sectionLoadFailed,
                    description: AppErrorMapper.message(e),
                    ctaLabel: t.retry,
                    onCta: () => _refreshRequests(ref),
                  ),
                ],
              ),
              data: (items) {
                if (items.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppEmptyState(
                        icon: Icons.groups_outlined,
                        title: t.groupRequestNoRequestsTitle,
                        description: t.groupRequestNoRequestsDescription,
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
                            '${req.city} • ${formatShortDate(context, req.dateTime)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.groupRequestPartyAndBudget(
                              req.partySize,
                              formatCurrency(
                                context,
                                req.budgetTotalCents / 100.0,
                              ),
                            ),
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

void _refreshRequests(WidgetRef ref) {
  ref.read(groupRequestsRepositoryProvider).clearReadCache();
  ref.invalidate(myRequestsProvider);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (label, tone) = switch (status) {
      'open' => (t.groupRequestStatusOpen, AppBadgeTone.info),
      'awarded' => (t.groupRequestStatusAwarded, AppBadgeTone.success),
      'closed' => (t.groupRequestStatusClosed, AppBadgeTone.warning),
      'cancelled' => (t.groupRequestStatusCancelled, AppBadgeTone.danger),
      _ => (t.statusUnknownShort, AppBadgeTone.neutral),
    };
    return AppBadge(label: label, tone: tone);
  }
}
