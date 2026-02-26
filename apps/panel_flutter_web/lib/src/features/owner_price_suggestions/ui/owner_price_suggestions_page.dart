import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/content/microcopy_style_guide.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../owner_onboarding/domain/owner_onboarding_providers.dart';
import '../../../ui/components/app_scaffold.dart';
import '../../../ui/components/owner_business_guard.dart';
import '../../../ui/design_system.dart';
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

        return AppScaffold(
          appBar: AppBar(title: const Text('Fiyat Onayları')),
          body: RefreshIndicator(
            onRefresh: () => controller.refresh(force: true),
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                if (st.error != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppErrorMapper.message(st.error),
                          style: context.bodyStyle.copyWith(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        label: MicrocopyStyleGuide.retry,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => controller.refresh(force: true),
                      ),
                    ],
                  ),
                if (st.isLoading && st.items.isEmpty)
                  const _OwnerPriceSkeleton()
                else if (!st.isLoading && st.items.isEmpty)
                  AppEmptyState(
                    icon: Icons.price_change_outlined,
                    title: 'Kayıt yok',
                    description: 'Yeni fiyat önerileri burada listelenecek.',
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
        );
      },
    );
  }

  Future<void> _approve(OwnerPriceSuggestionItem item) async {
    final ok = await _confirm(context, 'Onaylansın mı?');
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
      ).showSnackBar(const SnackBar(content: Text('Onaylandı.')));
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
            title: const Text('Reddet'),
            content: TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ret nedeni (en az 3 karakter)',
              ),
              onChanged: (value) {
                final next = value.trim().length >= 3;
                if (next == canSubmit) return;
                setModalState(() => canSubmit = next);
              },
            ),
            actions: [
              AppButton(
                label: MicrocopyStyleGuide.cancel,
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.pop(ctx, false),
              ),
              AppButton(
                label: MicrocopyStyleGuide.reject,
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
      ).showSnackBar(const SnackBar(content: Text('Reddedildi.')));
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
    final confidencePct = (item.qualityConfidence * 100).clamp(0, 100).round();
    final hasAnomaly = item.anomalyScore >= 0.5 || item.anomalyFlags.isNotEmpty;
    final hasConflict = item.conflictState == 'queued' || conflictCount > 1;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuItemName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(_fmtDate(item.createdAt), style: context.captionStyle),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      AppBadge(
                        label: 'Güven $confidencePct%',
                        tone: confidencePct >= 70
                            ? AppBadgeTone.success
                            : AppBadgeTone.warning,
                      ),
                      if (hasConflict)
                        AppBadge(
                          label:
                              'Çakışma: ${item.conflictVariants24h > 0 ? item.conflictVariants24h : conflictCount} fiyat',
                          tone: AppBadgeTone.warning,
                        ),
                      if (hasAnomaly)
                        AppBadge(
                          label: item.anomalyFlags.isEmpty
                              ? 'Anomali'
                              : 'Anomali: ${item.anomalyFlags.first}',
                          tone: AppBadgeTone.danger,
                        ),
                    ],
                  ),
                  if (conflictCount > 1 && !hasConflict) ...[
                    const SizedBox(height: 4),
                    AppBadge(
                      label:
                          'Çakışma: aynı ürün için $conflictCount farklı öneri var',
                      tone: AppBadgeTone.warning,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPrice(item.suggestedPriceCents),
                  style: context.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppButton(
                      label: MicrocopyStyleGuide.approve,
                      variant: AppButtonVariant.ghost,
                      onPressed: onApprove,
                    ),
                    const SizedBox(width: 6),
                    AppButton(
                      label: MicrocopyStyleGuide.reject,
                      variant: AppButtonVariant.secondary,
                      onPressed: onReject,
                    ),
                  ],
                ),
              ],
            ),
          ],
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
      title: const Text('Emin misin?'),
      content: Text(message),
      actions: [
        AppButton(
          label: MicrocopyStyleGuide.cancel,
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        AppButton(
          label: MicrocopyStyleGuide.approve,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  return res ?? false;
}



