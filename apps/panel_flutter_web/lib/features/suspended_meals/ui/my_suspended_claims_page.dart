import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../src/ui/components/app_scaffold.dart';
import '../../../src/ui/design_system.dart';
import '../domain/my_suspended_claim_controller.dart';
import '../domain/my_suspended_claim_models.dart';

class MySuspendedClaimsPage extends ConsumerStatefulWidget {
  const MySuspendedClaimsPage({super.key});

  @override
  ConsumerState<MySuspendedClaimsPage> createState() =>
      _MySuspendedClaimsPageState();
}

class _MySuspendedClaimsPageState extends ConsumerState<MySuspendedClaimsPage> {
  final scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(mySuspendedClaimsControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(mySuspendedClaimsControllerProvider);
    final controller = ref.read(mySuspendedClaimsControllerProvider.notifier);

    return AppScaffold(
      appBar: AppBar(title: const Text('Askıda Yemeklerim')),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.refresh(force: true);
          await ref
              .read(mySuspendedBadgeProvider.notifier)
              .refresh(force: true);
        },
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppFilterChip(
                  label: 'Tümü',
                  selected: st.statusFilter.isEmpty,
                  onTap: () => controller.setStatusFilter(''),
                ),
                AppFilterChip(
                  label: 'Beklemede',
                  selected: st.statusFilter == 'pending',
                  onTap: () => controller.setStatusFilter('pending'),
                ),
                AppFilterChip(
                  label: 'Kod Hazır',
                  selected: st.statusFilter == 'approved',
                  onTap: () => controller.setStatusFilter('approved'),
                ),
                AppFilterChip(
                  label: 'Teslim Alındı',
                  selected: st.statusFilter == 'fulfilled',
                  onTap: () => controller.setStatusFilter('fulfilled'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (st.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppErrorMapper.message(st.error),
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => controller.refresh(force: true),
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            if (st.isLoading && st.items.isEmpty)
              const _MySuspendedSkeleton()
            else if (!st.isLoading && st.items.isEmpty)
              const Center(child: Text('Kayıt yok.'))
            else
              Column(
                children: [
                  for (final item in st.items) ...[
                    _ClaimCard(item: item, onTap: () => _openDetails(item)),
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
  }

  Future<void> _openDetails(MySuspendedClaimItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.businessName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _locText(item.district, item.city),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              _StatusBadge(status: item.status),
              const SizedBox(height: 10),
              if (item.status == 'approved') ...[
                const Text(
                  'Teslim kodu',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  item.verifyCode ?? '—',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: item.verifyCode == null
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await Clipboard.setData(
                              ClipboardData(text: item.verifyCode!),
                            );
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Kod kopyalandı')),
                            );
                          },
                    icon: const Icon(Icons.copy),
                    label: const Text('Kopyala'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Restorana gidip bu kodu söyle.'),
              ] else if (item.status == 'pending') ...[
                const Text('İnceleniyor'),
              ] else if (item.status == 'fulfilled') ...[
                const Text('Teslim alındı'),
                const SizedBox(height: 6),
                Text(
                  _fmtDate(item.fulfilledAt ?? item.createdAt),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.item, required this.onTap});

  final MySuspendedClaimItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.businessName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    _formatPrice(item.amountCents),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _locText(item.district, item.city),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatusBadge(status: item.status),
                  const SizedBox(width: 8),
                  Text(
                    _relativeTime(item.createdAt),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return AppBadge(label: _statusLabel(status), tone: _statusTone(status));
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'approved':
      return 'Kod Hazır';
    case 'fulfilled':
      return 'Teslim Alındı';
    case 'pending':
    default:
      return 'Beklemede';
  }
}

AppBadgeTone _statusTone(String status) {
  switch (status) {
    case 'approved':
      return AppBadgeTone.success;
    case 'fulfilled':
      return AppBadgeTone.neutral;
    case 'pending':
    default:
      return AppBadgeTone.warning;
  }
}

class _MySuspendedSkeleton extends StatelessWidget {
  const _MySuspendedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _SkeletonCard(),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 10, color: AppColors.card),
            const SizedBox(height: 6),
            Container(height: 10, width: 160, color: AppColors.card),
            const SizedBox(height: 10),
            Container(height: 10, width: 120, color: AppColors.card),
          ],
        ),
      ),
    );
  }
}

String _locText(String district, String city) {
  final d = district.trim();
  final c = city.trim();
  if (d.isEmpty && c.isEmpty) return 'Konum yok';
  if (d.isEmpty) return c;
  if (c.isEmpty) return d;
  return '$d • $c';
}

String _formatPrice(int? cents) {
  if (cents == null) return '—';
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  return 'â‚º$text';
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inDays < 1) return 'Bugün';
  if (diff.inDays == 1) return 'Dün';
  if (diff.inDays < 30) return '${diff.inDays} gün önce';
  final months = (diff.inDays / 30).floor();
  return '$months ay önce';
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

