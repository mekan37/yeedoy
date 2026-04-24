import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../domain/perk_models.dart';
import '../domain/perk_providers.dart';

class PerksPage extends ConsumerWidget {
  const PerksPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perksAsync = ref.watch(businessPerksProvider(businessId));

    return AppScaffold(
      appBar: AppBar(
        title: Text('$businessName – Ayrıcalıklar'),
      ),
      body: perksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => _ErrorView(error: AppErrorMapper.message(e), onRetry: () => ref.invalidate(businessPerksProvider(businessId))),
        data: (perks) => perks.isEmpty
            ? const _EmptyView()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: perks.length,
                separatorBuilder: (context2, idx) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _PerkCard(perk: perks[i]),
              ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard_outlined, size: 56, color: AppColors.muted),
          const SizedBox(height: 12),
          const Text(
            'Aktif ayrıcalık yok',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bu işletme henüz aktif bir kampanya sunmuyor.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerkCard extends StatelessWidget {
  const _PerkCard({required this.perk});

  final BusinessPerk perk;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isNew = now.difference(perk.createdAt).inDays < 7;
    final hasExpiry = perk.endsAt != null;
    final daysLeft = hasExpiry ? perk.endsAt!.difference(now).inDays : null;
    final isExpiringSoon = daysLeft != null && daysLeft <= 3 && daysLeft >= 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.card_giftcard_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              perk.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                          if (isNew) ...[
                            const SizedBox(width: 6),
                            _Badge(label: 'YENİ', color: AppColors.success),
                          ],
                          if (isExpiringSoon) ...[
                            const SizedBox(width: 6),
                            _Badge(label: 'Son $daysLeft gün', color: AppColors.warning),
                          ],
                        ],
                      ),
                      if (perk.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          perk.description!,
                          style: const TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (perk.requiresCheckin || hasExpiry) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (perk.requiresCheckin)
                    _InfoChip(
                      icon: Icons.location_on_outlined,
                      label: 'Check-in gerektirir',
                    ),
                  if (perk.startsAt != null)
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'Başlangıç: ${_fmt(perk.startsAt!)}',
                    ),
                  if (perk.endsAt != null)
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: 'Bitiş: ${_fmt(perk.endsAt!)}',
                      highlighted: isExpiringSoon,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) => DateFormat('d MMM y', 'tr').format(dt);
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.highlighted = false});

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.warning : AppColors.muted;
    final bg = highlighted ? AppColors.warning.withValues(alpha: 0.1) : AppColors.cardAlt;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
