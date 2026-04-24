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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.cardAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: businessesAsync.when(
        loading: () => const _ContextBarLoading(),
        error: (_, _) => _ContextBarError(
          onRetry: () => ref.invalidate(ownerBusinessesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _ContextBarEmpty(
              onGoBusinesses: () => context.go('/owner/businesses'),
            );
          }

          final current = items.firstWhere(
            (item) => item.businessId == selectedBusinessId,
            orElse: () => items.first,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;

              // Business avatar / icon
              final avatar = Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              );

              // Business name + location info
              final info = Row(
                children: [
                  avatar,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              context.l10n.ownerSelectedBusinessTitle,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (items.length > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${items.length} şube',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          current.businessName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textStrong,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            if (current.branchLabel?.trim().isNotEmpty == true)
                              current.branchLabel,
                            current.district,
                            current.city,
                          ].whereType<String>().join(' • '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              // Switcher dropdown (only shown when multiple businesses)
              if (items.length <= 1) {
                return info;
              }

              final switcher = DropdownButtonFormField<String>(
                initialValue: current.businessId,
                decoration: InputDecoration(
                  labelText: context.l10n.ownerBusinessSwitcherLabel,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: [
                  for (final item in items)
                    DropdownMenuItem(
                      value: item.businessId,
                      child: Text(
                        item.branchLabel?.trim().isNotEmpty == true
                            ? '${item.businessName} (${item.branchLabel})'
                            : item.businessName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(selectedOwnerBusinessIdProvider.notifier).state =
                      value;
                },
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    info,
                    const SizedBox(height: 10),
                    switcher,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 16),
                  SizedBox(width: 280, child: switcher),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/owner/businesses'),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text(context.l10n.ownerGoBusinessesAction),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ContextBarLoading extends StatelessWidget {
  const _ContextBarLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 36,
      child: LinearProgressIndicator(minHeight: 3),
    );
  }
}

class _ContextBarError extends StatelessWidget {
  const _ContextBarError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.ownerBusinessContextLoadError,
            style: const TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
          child: Text(context.l10n.retry),
        ),
      ],
    );
  }
}

class _ContextBarEmpty extends StatelessWidget {
  const _ContextBarEmpty({required this.onGoBusinesses});
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
