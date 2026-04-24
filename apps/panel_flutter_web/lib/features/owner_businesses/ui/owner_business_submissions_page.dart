import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../domain/owner_business_models.dart';
import '../domain/owner_business_providers.dart';

class OwnerBusinessSubmissionsPage extends ConsumerWidget {
  const OwnerBusinessSubmissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(ownerBusinessSubmissionsProvider);
    final l10n = context.l10n;

    final header = PanelPageHeader(
      eyebrow: 'Owner',
      title: Text(l10n.ownerMyApplications),
      description: 'İşletme başvurularınızın durumunu takip edin.',
    );

    return submissionsAsync.when(
      loading: () => ListView(
        padding: EdgeInsets.zero,
        children: [
          header,
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _SubmissionsSkeleton(),
          ),
        ],
      ),
      error: (e, _) => ListView(
        padding: EdgeInsets.zero,
        children: [
          header,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _ErrorState(
              message: AppErrorMapper.message(e),
              onRetry: () => ref.invalidate(ownerBusinessSubmissionsProvider),
            ),
          ),
        ],
      ),
      data: (items) {
        if (items.isEmpty) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              header,
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _EmptyState(),
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(ownerBusinessSubmissionsProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: header),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _SubmissionCard(item: items[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.item});
  final BusinessSubmission item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.danger,
      _ => AppColors.warning,
    };
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textStrong,
                              ),
                            ),
                          ),
                          Text(
                            _fmtDate(item.createdAt),
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.district} • ${item.city}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(_statusIcon(item.status), size: 13, color: color),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(context, item.status),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if ((item.adminNote ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.adminNote!.trim(),
                            style: const TextStyle(
                                color: AppColors.slate, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmissionsSkeleton extends StatelessWidget {
  const _SubmissionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(width: 160),
                SizedBox(height: 8),
                _SkeletonLine(width: 120),
                SizedBox(height: 12),
                _SkeletonLine(width: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.width});
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(height: 10, width: width, color: AppColors.border);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.assignment_outlined,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.ownerBusinessSubmissionsEmptyTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ownerBusinessSubmissionsEmptyDescription,
            style: const TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_outlined, size: 15),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

IconData _statusIcon(String status) => switch (status) {
  'approved' => Icons.check_circle_rounded,
  'rejected' => Icons.cancel_rounded,
  _ => Icons.schedule_rounded,
};

String _statusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  return switch (status) {
    'approved' => l10n.approved,
    'rejected' => l10n.rejected,
    _ => l10n.pending,
  };
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
