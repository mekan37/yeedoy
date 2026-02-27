import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../domain/owner_suspended_controller.dart';
import '../domain/owner_suspended_models.dart';
import '../../owner_onboarding/domain/owner_onboarding_providers.dart';
import '../../../shared/ui/components/app_scaffold.dart';
import '../../../shared/ui/components/owner_business_guard.dart';
import '../../../shared/ui/design_system.dart';

class OwnerSuspendedClaimsPage extends ConsumerStatefulWidget {
  const OwnerSuspendedClaimsPage({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<OwnerSuspendedClaimsPage> createState() =>
      _OwnerSuspendedClaimsPageState();
}

class _OwnerSuspendedClaimsPageState
    extends ConsumerState<OwnerSuspendedClaimsPage> {
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
              ownerSuspendedClaimsControllerProvider(
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
          ownerSuspendedClaimsControllerProvider(widget.businessId),
        );
        final controller = ref.read(
          ownerSuspendedClaimsControllerProvider(widget.businessId).notifier,
        );

        return AppScaffold(
          appBar: AppBar(title: const Text('Askıda Yönetimi')),
          body: RefreshIndicator(
            onRefresh: () => controller.refresh(force: true),
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    AppFilterChip(
                      label: 'Pending',
                      selected: st.statusFilter == 'pending',
                      onTap: () => controller.setStatusFilter('pending'),
                    ),
                    AppFilterChip(
                      label: 'Approved',
                      selected: st.statusFilter == 'approved',
                      onTap: () => controller.setStatusFilter('approved'),
                    ),
                    AppFilterChip(
                      label: 'Fulfilled',
                      selected: st.statusFilter == 'fulfilled',
                      onTap: () => controller.setStatusFilter('fulfilled'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (st.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      AppErrorMapper.message(st.error),
                      style: context.bodyStyle.copyWith(color: Colors.red),
                    ),
                  ),
                if (st.isLoading && st.items.isEmpty)
                  const _OwnerSuspendedSkeleton()
                else if (!st.isLoading && st.items.isEmpty)
                  AppEmptyState(
                    icon: Icons.volunteer_activism_outlined,
                    title: 'Kayıt yok',
                    description: 'Yeni askıda talepler burada görünecek.',
                  )
                else
                  Column(
                    children: [
                      for (final item in st.items) ...[
                        _ClaimCard(
                          item: item,
                          onApprove: item.status == 'pending'
                              ? () => _onApprove(item)
                              : null,
                          onFulfill: item.status == 'approved'
                              ? () => _onFulfill(item)
                              : null,
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

  Future<void> _onApprove(OwnerSuspendedClaimItem item) async {
    try {
      final code = await ref
          .read(
            ownerSuspendedClaimsControllerProvider(widget.businessId).notifier,
          )
          .approve(item.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Teslim kodu'),
          content: Text('Teslim kodu: $code\nBu kodu ihtiyaç sahibine söyle.'),
          actions: [
            AppButton(label: 'Tamam', onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _onFulfill(OwnerSuspendedClaimItem item) async {
    final code = await _askCode();
    if (code == null) return;
    try {
      await ref
          .read(
            ownerSuspendedClaimsControllerProvider(widget.businessId).notifier,
          )
          .fulfill(claimId: item.id, code: code);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Teslim edildi.')));
    } catch (e) {
      if (!mounted) return;
      final msg = AppErrorMapper.message(e);
      final isBad = msg.contains('bad_code') || msg.contains('kod');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(isBad ? 'Kod hatalı.' : msg)));
    }
  }

  Future<String?> _askCode() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teslim kodu'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(hintText: '6 haneli kod'),
        ),
        actions: [
          AppButton(
            label: 'Vazgeç',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: 'Gönder',
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (res == null || res.isEmpty) return null;
    return res;
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    required this.item,
    required this.onApprove,
    required this.onFulfill,
  });

  final OwnerSuspendedClaimItem item;
  final VoidCallback? onApprove;
  final VoidCallback? onFulfill;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.claimantName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  _formatPrice(item.amountCents),
                  style: context.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.mealMessage.isEmpty ? '-' : item.mealMessage,
              style: context.bodyStyle.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(_ageLabel(item.ageHours), style: context.captionStyle),
            const SizedBox(height: 10),
            if (onApprove != null || onFulfill != null)
              Row(
                children: [
                  if (onApprove != null)
                    Expanded(
                      child: AppButton(label: 'Onayla', onPressed: onApprove),
                    ),
                  if (onApprove != null && onFulfill != null)
                    const SizedBox(width: 10),
                  if (onFulfill != null)
                    Expanded(
                      child: AppButton(
                        label: 'Teslim Et',
                        variant: AppButtonVariant.secondary,
                        onPressed: onFulfill,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _OwnerSuspendedSkeleton extends StatelessWidget {
  const _OwnerSuspendedSkeleton();

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

String _ageLabel(double hours) {
  if (hours >= 24) {
    final days = hours / 24.0;
    return '${days.toStringAsFixed(1)}g';
  }
  return '${hours.toStringAsFixed(1)}s';
}

String _formatPrice(int? cents) {
  if (cents == null) return '-';
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  return 'TL $text';
}



