import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/app_scaffold.dart';
import '../domain/owner_business_models.dart';
import '../domain/owner_business_providers.dart';

class OwnerBusinessSubmissionsPage extends ConsumerWidget {
  const OwnerBusinessSubmissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(ownerBusinessSubmissionsProvider);
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.ownerMyApplications)),
      body: submissionsAsync.when(
        loading: () => const _SubmissionsSkeleton(),
        error: (e, _) => _ErrorState(
          message: AppErrorMapper.message(e),
          onRetry: () => ref.invalidate(ownerBusinessSubmissionsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(ownerBusinessSubmissionsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _SubmissionCard(item: items[i]),
            ),
          );
        },
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${item.district} • ${item.city}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _statusLabel(context, item.status),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _fmtDate(item.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
            if ((item.adminNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.adminNote!.trim(),
                style: const TextStyle(color: AppColors.slate),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubmissionsSkeleton extends StatelessWidget {
  const _SubmissionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
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
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.width});
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(height: 10, width: width, color: AppColors.card);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_outlined, size: 46, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(
            l10n.ownerBusinessSubmissionsEmptyTitle,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ownerBusinessSubmissionsEmptyDescription,
            style: const TextStyle(color: AppColors.muted),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

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
