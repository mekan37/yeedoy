import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/assets/category_assets.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../../core/utils/greeting_utils.dart';
import '../data/price_alerts_repository.dart';
import '../domain/price_alert_models.dart';
import '../domain/price_alerts_provider.dart';
import 'price_alert_sheet.dart';

enum _AlertTab { active, triggered, paused }

class PriceAlertsPage extends ConsumerStatefulWidget {
  const PriceAlertsPage({super.key});

  @override
  ConsumerState<PriceAlertsPage> createState() => _PriceAlertsPageState();
}

class _PriceAlertsPageState extends ConsumerState<PriceAlertsPage> {
  _AlertTab _tab = _AlertTab.active;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return CustomScrollView(
      slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeBasedGreeting(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.priceAlerts,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Uygun fiyatları kaçırma, alarm kur!',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),

                    // ── Promo banner ────────────────────────────────────
                    _PromoBanner(
                      onTap: () => showPriceAlertSheet(
                        context: context,
                        initialQuery: '',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Tab selector ────────────────────────────────────
                    _TabBar(
                      selected: _tab,
                      onChanged: (t) => setState(() => _tab = t),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Tab content ─────────────────────────────────────────────
            if (_tab == _AlertTab.active || _tab == _AlertTab.paused)
              _AlertsSliver(
                tab: _tab,
                onToggle: _toggleAlert,
                onDelete: _deleteAlert,
              )
            else
              _TriggeredSliver(),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _TipBanner(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
    );
  }

  Future<void> _toggleAlert(PriceAlert alert) async {
    try {
      await ref
          .read(priceAlertsRepositoryProvider)
          .toggleAlert(alert.id, active: !alert.isActive);
      ref.invalidate(myPriceAlertsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(e))),
      );
    }
  }

  Future<void> _deleteAlert(PriceAlert alert) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alarmı sil'),
        content: const Text('Bu alarm silinecek. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(priceAlertsRepositoryProvider).deleteAlert(alert.id);
      ref.invalidate(myPriceAlertsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(e))),
      );
    }
  }
}

// ── Promo Banner ────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fiyat düşünce haberin olsun!',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Alarmlarını ayarla, fırsatları ilk sen yakala.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'Alarm Kur',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab Bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onChanged});
  final _AlertTab selected;
  final ValueChanged<_AlertTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _TabPill(
            label: 'Aktif Alarmlar',
            selected: selected == _AlertTab.active,
            onTap: () => onChanged(_AlertTab.active),
          ),
          _TabPill(
            label: 'Tetiklenenler',
            selected: selected == _AlertTab.triggered,
            onTap: () => onChanged(_AlertTab.triggered),
          ),
          _TabPill(
            label: 'Pasif Alarmlar',
            selected: selected == _AlertTab.paused,
            onTap: () => onChanged(_AlertTab.paused),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Alerts Sliver (Aktif / Pasif) ────────────────────────────────────────────

class _AlertsSliver extends ConsumerWidget {
  const _AlertsSliver({
    required this.tab,
    required this.onToggle,
    required this.onDelete,
  });
  final _AlertTab tab;
  final Future<void> Function(PriceAlert) onToggle;
  final Future<void> Function(PriceAlert) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myPriceAlertsProvider(const PriceAlertsParams()));
    return async.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            AppErrorMapper.message(e),
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
      data: (all) {
        final items = tab == _AlertTab.active
            ? all.where((a) => a.isActive).toList()
            : all.where((a) => !a.isActive).toList();
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: AppEmptyState(
                icon: Icons.notifications_off_outlined,
                title: tab == _AlertTab.active
                    ? 'Aktif alarm yok'
                    : 'Pasif alarm yok',
                description: tab == _AlertTab.active
                    ? 'Alarm kur ve fiyat düşünce bildirim al.'
                    : 'Duraklatılmış alarm bulunmuyor.',
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _AlertCard(
                alert: items[i],
                onToggle: () => onToggle(items[i]),
                onDelete: () => onDelete(items[i]),
              ),
            ),
            childCount: items.length,
          ),
        );
      },
    );
  }
}

// ── Alert Card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onToggle,
    required this.onDelete,
  });
  final PriceAlert alert;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imageAsset = CategoryAssets.resolve(alert.category);
    final locationText = [alert.city, alert.district]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imageAsset,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        alert.query,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textStrong,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Sil'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (v) {
                        if (v == 'delete') onDelete();
                      },
                    ),
                  ],
                ),

                if (alert.category != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    alert.category!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Hedef Fiyat row
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Hedef Fiyat',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatCents(alert.maxPriceCents),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                if (locationText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        locationText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // Action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onToggle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textStrong,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(
                        alert.isActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 16,
                      ),
                      label: Text(
                        alert.isActive ? 'Duraklat' : 'Aktifleştir',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Triggered Sliver ─────────────────────────────────────────────────────────

class _TriggeredSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAlertEventsProvider(const AlertEventsParams()));
    return async.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            AppErrorMapper.message(e),
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: AppEmptyState(
                icon: Icons.notifications_active_outlined,
                title: 'Henüz tetiklenen alarm yok',
                description: 'Fiyat hedefine ulaşınca burada görünecek.',
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _TriggeredCard(item: items[i]),
            ),
            childCount: items.length,
          ),
        );
      },
    );
  }
}

class _TriggeredCard extends StatelessWidget {
  const _TriggeredCard({required this.item});
  final AlertEventItem item;

  @override
  Widget build(BuildContext context) {
    final prev = item.event.previousPriceCents;
    final matched = item.event.matchedPriceCents;
    final pctDrop = (prev != null && prev > 0)
        ? (((prev - matched) / prev) * 100).round()
        : null;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              CategoryAssets.resolve(null),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.businessName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textStrong,
                  ),
                ),
                if (item.menuItemName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.menuItemName!,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Eşleşen Fiyat',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatCents(matched),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ],
                ),
                if (prev != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Önceki Fiyat',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatCents(prev),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
                if (pctDrop != null && pctDrop > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '%$pctDrop düştü',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tip Banner ───────────────────────────────────────────────────────────────

class _TipBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fiyatlar değişiyor, fırsatlar kaçmasın!',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Alarmlarını düzenli kontrol etmeyi unutma.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
        ],
      ),
    );
  }
}

String _formatCents(int cents) {
  final tl = cents ~/ 100;
  final kr = cents % 100;
  return kr == 0 ? '₺$tl' : '₺$tl,${kr.toString().padLeft(2, '0')}';
}
