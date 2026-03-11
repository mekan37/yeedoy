import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../features/owner_businesses/domain/owner_business_providers.dart';
import '../../../features/owner_businesses/domain/owner_business_state.dart';
import 'app_empty_state.dart';

class OwnerBusinessContextBar extends ConsumerWidget {
  const OwnerBusinessContextBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(ownerBusinessesProvider);
    final selectedBusinessId = ref.watch(selectedOwnerBusinessIdProvider);

    businessesAsync.whenData((items) {
      if (items.isEmpty || selectedBusinessId != null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(selectedOwnerBusinessIdProvider.notifier).state =
            items.first.businessId;
      });
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.cardAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: businessesAsync.when(
        loading: () => const _OwnerBusinessContextLoading(),
        error: (_, _) => _OwnerBusinessContextError(
          onRetry: () => ref.invalidate(ownerBusinessesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _OwnerBusinessContextEmpty(
              onGoBusinesses: () => context.go('/owner/businesses'),
            );
          }

          final current = items.firstWhere(
            (item) => item.businessId == selectedBusinessId,
            orElse: () => items.first,
          );
          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final switcher = DropdownButtonFormField<String>(
                initialValue: current.businessId,
                decoration: InputDecoration(
                  labelText: context.l10n.ownerBusinessSwitcherLabel,
                  isDense: true,
                ),
                items: [
                  for (final item in items)
                    DropdownMenuItem(
                      value: item.businessId,
                      child: Text(
                        item.branchLabel?.trim().isNotEmpty == true
                            ? '${item.businessName} (${item.branchLabel})'
                            : item.businessName,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(selectedOwnerBusinessIdProvider.notifier).state = value;
                },
              );

              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.ownerSelectedBusinessTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    current.businessName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    current.branchLabel?.trim().isNotEmpty == true
                        ? '${current.branchLabel} • ${current.district}, ${current.city}'
                        : '${current.district}, ${current.city}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              );

              final actions = TextButton.icon(
                onPressed: () => context.go('/owner/businesses'),
                icon: const Icon(Icons.storefront_outlined),
                label: Text(context.l10n.ownerGoBusinessesAction),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    info,
                    const SizedBox(height: 12),
                    switcher,
                    const SizedBox(height: 8),
                    actions,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: info),
                  SizedBox(width: 320, child: switcher),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _OwnerBusinessContextLoading extends StatelessWidget {
  const _OwnerBusinessContextLoading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(minHeight: 6),
        ),
      ],
    );
  }
}

class _OwnerBusinessContextError extends StatelessWidget {
  const _OwnerBusinessContextError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.ownerBusinessContextLoadError,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.l10n.retry),
        ),
      ],
    );
  }
}

class _OwnerBusinessContextEmpty extends StatelessWidget {
  const _OwnerBusinessContextEmpty({required this.onGoBusinesses});

  final VoidCallback onGoBusinesses;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.storefront_outlined,
      title: context.l10n.ownerBusinessContextEmptyTitle,
      description: context.l10n.ownerBusinessContextEmptyDescription,
      ctaLabel: context.l10n.ownerGoBusinessesAction,
      onCta: onGoBusinesses,
    );
  }
}
