import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../owner_onboarding/domain/owner_onboarding_providers.dart';
import '../../../shared/ui/components/owner_business_guard.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../../shared/ui/design_system.dart';
import '../domain/owner_price_suggestion_models.dart';
import '../domain/owner_price_suggestions_controller.dart';

class OwnerPriceSuggestionsPage extends ConsumerStatefulWidget {
  const OwnerPriceSuggestionsPage({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<OwnerPriceSuggestionsPage> createState() =>
      _OwnerPriceSuggestionsPageState();
}

class _OwnerPriceSuggestionsPageState
    extends ConsumerState<OwnerPriceSuggestionsPage> {
  final scrollCtrl = ScrollController();
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref
            .read(
              ownerPriceSuggestionsControllerProvider(
                widget.businessId,
              ).notifier,
            )
            .loadMore();
      }
    });
    ref.listenManual(ownerOnboardingProgressProvider(widget.businessId), (
      previous,
      next,
    ) {
      final onboardingBypass =
          GoRouterState.of(context).uri.queryParameters['onboarding'] == '1';
      if (onboardingBypass || _redirecting || !mounted) return;
      next.whenData((progress) {
        if (_redirecting || progress.stepCompleted >= 5 || !mounted) return;
        _redirecting = true;
        final redirect = Uri.encodeComponent(
          GoRouterState.of(context).uri.toString(),
        );
        context.go(
          '/owner/onboarding?businessId=${widget.businessId}&redirect=$redirect',
        );
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OwnerBusinessGuard(
      businessId: widget.businessId,
      builder: (context, ref) {
        final st = ref.watch(
          ownerPriceSuggestionsControllerProvider(widget.businessId),
        );
        final controller = ref.read(
          ownerPriceSuggestionsControllerProvider(widget.businessId).notifier,
        );
        final conflictCountByItem = <String, int>{};
        for (final item in st.items) {
          final key = item.menuItemId.isEmpty
              ? item.menuItemName
              : item.menuItemId;
          conflictCountByItem[key] = (conflictCountByItem[key] ?? 0) + 1;
        }

        return RefreshIndicator(
          onRefresh: () => controller.refresh(force: true),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.zero,
            children: [
              PanelPageHeader(
                eyebrow: 'Owner',
                title: Text(l10n.ownerPriceSuggestionsTitle),
                description: 'Rakip verilerine dayalı fiyat önerilerini onaylayın veya reddedin.',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    if (st.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppErrorMapper.message(st.error),
                                style: context.bodyStyle.copyWith(color: AppColors.danger),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppButton(
                              label: l10n.retry,
                              variant: AppButtonVariant.secondary,
                              onPressed: () => controller.refresh(force: true),
                            ),
                          ],
                        ),
                      ),
                    if (st.isLoading && st.items.isEmpty)
                      const _OwnerPriceSkeleton()
                    else if (!st.isLoading && st.items.isEmpty)
                      AppEmptyState(
                        icon: Icons.price_change_outlined,
                        title: l10n.ownerPriceSuggestionsEmptyTitle,
                        description: l10n.ownerPriceSuggestionsEmptyDescription,
                      )
                    else
                      Column(
                        children: [
                          for (final item in st.items) ...[
                            _OwnerPriceRow(
                              item: item,
                              conflictCount:
                                  conflictCountByItem[item.menuItemId.isEmpty
                                      ? item.menuItemName
                                      : item.menuItemId] ??
                                  1,
                              onApprove: () => _approve(item),
                              onReject: () => _reject(item),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (st.isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _approve(OwnerPriceSuggestionItem item) async {
    final ok = await _confirm(
      context,
      context.l10n.ownerPriceSuggestionsApproveConfirm,
    );
    if (!ok) return;
    try {
      await ref
          .read(
            ownerPriceSuggestionsControllerProvider(widget.businessId).notifier,
          )
          .approve(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerPriceSuggestionsApproved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _reject(OwnerPriceSuggestionItem item) async {
    final noteCtrl = TextEditingController();
    var canSubmit = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: Text(context.l10n.ownerRejectAction),
            content: TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.ownerPriceSuggestionsRejectReasonLabel,
              ),
              onChanged: (value) {
                final next = value.trim().length >= 3;
                if (next == canSubmit) return;
                setModalState(() => canSubmit = next);
              },
            ),
            actions: [
              AppButton(
                label: context.l10n.cancel,
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.pop(ctx, false),
              ),
              AppButton(
                label: context.l10n.ownerRejectAction,
                variant: AppButtonVariant.danger,
                onPressed: canSubmit ? () => Navigator.pop(ctx, true) : null,
              ),
            ],
          );
        },
      ),
    );
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (!mounted) return;
    if (ok != true) return;
    try {
      await ref
          .read(
            ownerPriceSuggestionsControllerProvider(widget.businessId).notifier,
          )
          .reject(suggestionId: item.id, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerPriceSuggestionsRejected)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }
}

class _OwnerPriceRow extends StatelessWidget {
  const _OwnerPriceRow({
    required this.item,
    required this.conflictCount,
    required this.onApprove,
    required this.onReject,
  });
  final OwnerPriceSuggestionItem item;
  final int conflictCount;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final confidencePct = (item.qualityConfidence * 100).clamp(0, 100).round();
    final hasAnomaly = item.anomalyScore >= 0.5 || item.anomalyFlags.isNotEmpty;
    final hasConflict = item.conflictState == 'queued' || conflictCount > 1;
    final accentColor = hasAnomaly
        ? AppColors.danger
        : hasConflict
            ? AppColors.warning
            : AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.menuItemName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textStrong,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _fmtDate(item.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: accentColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _formatPrice(item.suggestedPriceCents),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          AppBadge(
                            label: l10n.ownerPriceSuggestionsConfidence(
                              confidencePct,
                            ),
                            tone: confidencePct >= 70
                                ? AppBadgeTone.success
                                : AppBadgeTone.warning,
                          ),
                          if (hasConflict)
                            AppBadge(
                              label: l10n.ownerPriceSuggestionsConflictCount(
                                item.conflictVariants24h > 0
                                    ? item.conflictVariants24h
                                    : conflictCount,
                              ),
                              tone: AppBadgeTone.warning,
                            ),
                          if (hasAnomaly)
                            AppBadge(
                              label: item.anomalyFlags.isEmpty
                                  ? l10n.ownerPriceSuggestionsAnomaly
                                  : l10n.ownerPriceSuggestionsAnomalyFlag(
                                      item.anomalyFlags.first,
                                    ),
                              tone: AppBadgeTone.danger,
                            ),
                          if (conflictCount > 1 && !hasConflict)
                            AppBadge(
                              label: l10n.ownerPriceSuggestionsConflictVariants(
                                conflictCount,
                              ),
                              tone: AppBadgeTone.warning,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          FilledButton.icon(
                            onPressed: onApprove,
                            icon: const Icon(Icons.check_outlined, size: 15),
                            label: Text(l10n.ownerApproveAction),
                          ),
                          OutlinedButton.icon(
                            onPressed: onReject,
                            icon: const Icon(Icons.close_outlined, size: 15),
                            label: Text(l10n.ownerRejectAction),
                          ),
                        ],
                      ),
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

class _OwnerPriceSkeleton extends StatelessWidget {
  const _OwnerPriceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: AppSkeletonCard(lines: 3),
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _formatPrice(int? cents) {
  if (cents == null) return '-';
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  return 'TL $text';
}

Future<bool> _confirm(BuildContext context, String message) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.ownerAreYouSure),
      content: Text(message),
      actions: [
        AppButton(
          label: context.l10n.cancel,
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        AppButton(
          label: context.l10n.approved,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  return res ?? false;
}



