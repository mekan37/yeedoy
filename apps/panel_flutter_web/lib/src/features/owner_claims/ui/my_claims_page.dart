import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../../domain/models/owner_claim.dart';
import '../owner_claim_controller.dart';
import '../my_claims_controller.dart';
import '../../../ui/components/app_scaffold.dart';

class MyClaimsPage extends ConsumerStatefulWidget {
  const MyClaimsPage({super.key});

  @override
  ConsumerState<MyClaimsPage> createState() => _MyClaimsPageState();
}

class _MyClaimsPageState extends ConsumerState<MyClaimsPage> {
  bool _submittingAppeal = false;

  @override
  Widget build(BuildContext context) {
    final claimsAsync = ref.watch(myClaimsProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Sahiplik Başvurularım')),
      body: claimsAsync.when(
        loading: () => const _ClaimsSkeleton(),
        error: (e, _) => _ErrorState(
          message: AppErrorMapper.message(e),
          onRetry: () => ref.read(myClaimsProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          final rejected = items
              .where((e) => e.claim.status.trim().toLowerCase() == 'rejected')
              .toList();
          return RefreshIndicator(
            onRefresh: () => ref.read(myClaimsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: items.length + (rejected.isEmpty ? 0 : 1),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (rejected.isNotEmpty && i == 0) {
                  return _AppealCtaCard(
                    onAppeal: _submittingAppeal
                        ? null
                        : () => _openAppealSheet(rejected.first),
                    onLegal: () => context.go('/legal'),
                  );
                }
                final item = items[rejected.isNotEmpty ? i - 1 : i];
                return _ClaimCard(
                  item: item,
                  onAppeal: _submittingAppeal
                      ? null
                      : () => _openAppealSheet(item),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAppealSheet(OwnerClaimItem item) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final noteCtrl = TextEditingController(
      text: 'İtiraz: Kararın tekrar değerlendirilmesini talep ediyorum.',
    );
    final evidenceCtrl = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
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
                'İtiraz / Yeniden Başvuru - ${item.businessName}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Belge URL (vergi levhası, imza sirküsü vb.) eklersen otomatik kontrol daha sağlıklı çalışır.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Ad soyad'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefon'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: evidenceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Belge URL (opsiyonel)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'İtiraz notu'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('İtirazı Gönder'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true) return;
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad soyad ve telefon gerekli.')),
      );
      return;
    }

    setState(() => _submittingAppeal = true);
    try {
      final res = await ref
          .read(ownerClaimControllerProvider(item.claim.businessId).notifier)
          .submit(
            fullName: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            evidenceUrl: evidenceCtrl.text.trim().isEmpty
                ? null
                : evidenceCtrl.text.trim(),
            note: noteCtrl.text.trim(),
          );
      if (!mounted) return;
      if (res.ok) {
        await ref.read(myClaimsProvider.notifier).refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İtiraz başvurusu gönderildi.')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res.error ?? 'İşlem başarısız')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => _submittingAppeal = false);
      nameCtrl.dispose();
      phoneCtrl.dispose();
      noteCtrl.dispose();
      evidenceCtrl.dispose();
    }
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.item, required this.onAppeal});
  final OwnerClaimItem item;
  final VoidCallback? onAppeal;

  @override
  Widget build(BuildContext context) {
    final claim = item.claim;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.businessName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusChip(status: claim.status),
                const Spacer(),
                Text(
                  _fmtDate(claim.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
            if ((claim.adminNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                claim.adminNote!.trim(),
                style: const TextStyle(color: AppColors.slate),
              ),
            ],
            if (claim.status.trim().toLowerCase() == 'rejected') ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onAppeal,
                  icon: const Icon(Icons.gavel_outlined),
                  label: const Text('İtiraz Et'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppealCtaCard extends StatelessWidget {
  const _AppealCtaCard({required this.onAppeal, required this.onLegal});
  final VoidCallback? onAppeal;
  final VoidCallback onLegal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İtiraz süreci',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Reddedilen sahiplik taleplerinde itiraz edebilirsin. Belgeler yeniden incelenir.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onLegal,
                    child: const Text('Yasal detaylar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onAppeal,
                    child: const Text('İtiraz Et'),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final label = switch (normalized) {
      'approved' => 'Onaylandı',
      'rejected' => 'Reddedildi',
      'pending' => 'Beklemede',
      _ => status,
    };
    final color = switch (normalized) {
      'approved' => AppColors.success,
      'rejected' => AppColors.danger,
      _ => AppColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.assignment_outlined, size: 46, color: AppColors.muted),
          SizedBox(height: 10),
          Text(
            'Henüz başvuru yok',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Yaptığın başvurular burada listelenecek.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ClaimsSkeleton extends StatelessWidget {
  const _ClaimsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonLine(width: 160),
              SizedBox(height: 10),
              _SkeletonLine(width: 90),
              SizedBox(height: 10),
              _SkeletonLine(),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
              child: const Text('Tekrar dene'),
            ),
          ],
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

