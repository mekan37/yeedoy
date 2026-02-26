import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/location/user_location_controller.dart';
import '../../../features/discovery/domain/business_card.dart';
import '../../../features/business/domain/business.dart';
import '../../../features/price_alerts/domain/price_alert_models.dart';
import '../../../features/price_alerts/domain/price_alerts_provider.dart';
import '../../../features/profile/domain/moat_signals_provider.dart';
import '../../../features/profile/domain/user_moat_signals.dart';
import '../../auth/domain/auth_providers.dart';
import '../../../src/data/repositories/favorites_repository.dart';
import '../../../src/ui/achievements/achievement_visuals.dart';
import '../../../src/ui/components/app_scaffold.dart';
import '../domain/inbox_models.dart';
import '../domain/inbox_provider.dart';
import '../../../src/ui/design_system.dart';

final recentBusinessesProvider = FutureProvider<List<Business>>((ref) async {
  return OfflineCachePrefs.loadRecentBusinesses();
});

final favoritePriceChangesProvider = FutureProvider<List<BusinessCardModel>>((
  ref,
) async {
  final repo = ref.read(favoritesRepositoryProvider);
  final res = await repo.getMyFavoritesWithBusinesses(limit: 20);
  return res.items.where((e) => (e.recentPriceVerifiedCount ?? 0) > 0).toList();
});

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(inboxProvider);
    final controller = ref.read(inboxProvider.notifier);
    final recentBusinesses = ref.watch(recentBusinessesProvider);
    final favoriteChanges = ref.watch(favoritePriceChangesProvider);
    final userLocation = ref.watch(userLocationProvider);
    final user = ref.watch(userProvider);
    final moatSignalsAsync = user == null
        ? const AsyncValue<UserMoatSignals?>.data(null)
        : ref.watch(myMoatSignalsProvider);
    final alertEventsAsync = user == null
        ? const AsyncValue<List<AlertEventItem>>.data([])
        : ref.watch(
            myAlertEventsProvider(const AlertEventsParams(limit: 3, offset: 0)),
          );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Bildirim Kutusu'),
        actions: [
          TextButton(
            onPressed: st.items.isEmpty ? null : () => controller.markAllRead(),
            child: const Text('Tümünü okundu işaretle'),
          ),
          IconButton(
            onPressed: () => controller.refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (st.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  AppErrorMapper.message(st.error),
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            if (st.isLoading && st.items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _ReengagementCards(
                recentBusinesses: recentBusinesses,
                favoriteChanges: favoriteChanges,
                alertEvents: alertEventsAsync,
                userLocation: userLocation,
                moatSignals: moatSignalsAsync.asData?.value,
              ),
              const SizedBox(height: 12),
              if (st.items.isEmpty)
                const AppEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Bildirim yok',
                  description:
                      'Fiyat önerisi, claim, rapor ve yorum cevabı bildirimleri burada görünecek.',
                ),
              for (final item in st.items) ...[
                _buildInboxTile(
                  context: context,
                  ref: ref,
                  controller: controller,
                  item: item,
                  unread: !st.isRead(item),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

Widget _buildInboxTile({
  required BuildContext context,
  required WidgetRef ref,
  required InboxController controller,
  required InboxItem item,
  required bool unread,
}) {
  final visual = _visualFor(item);
  return _InboxTile(
    icon: visual.icon,
    accentColor: visual.color,
    title: item.title,
    message: _messageForInboxItem(item),
    timeText: _relative(item.createdAt),
    unread: unread,
    onTap: () async {
      await controller.markRead(item.id);
      if (!context.mounted) return;
      final clientId = await getAnalyticsClientId();
      await ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.notificationOpen,
            source: 'inbox_page',
            clientId: clientId,
            meta: {'type': item.type, 'target_path': item.targetPath},
          );
      if (item.type == 'achievement_unlocked') {
        await ref
            .read(analyticsRepositoryProvider)
            .logEvent(
              eventName: AppEvents.achievementUnlock,
              source: 'inbox_page',
              clientId: clientId,
              meta: {
                'achievement_id':
                    (item.meta['achievement_id'] ?? item.meta['id']).toString(),
              },
            );
      }
      if (!context.mounted) return;
      context.go(item.targetPath);
    },
  );
}

String _messageForInboxItem(InboxItem item) {
  if (item.type != 'achievement_unlocked') return item.message;
  final xp = (item.meta['xp'] as num?)?.toInt();
  final level = (item.meta['level'] as num?)?.toInt();
  final leveledUp = item.meta['leveled_up'] == true;
  final parts = <String>[item.message];
  if (xp != null && xp > 0) parts.add('+$xp XP');
  if (level != null && level > 0) {
    parts.add(leveledUp ? 'Yeni seviye: $level' : 'Seviye: $level');
  }
  return parts.join(' • ');
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.message,
    required this.timeText,
    required this.unread,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String message;
  final String timeText;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accentColor.withValues(alpha: 0.12),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            if (unread)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        subtitle: Text(message),
        trailing: Text(
          timeText,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
    );
  }
}

String _relative(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Şimdi';
  if (diff.inHours < 1) return '${diff.inMinutes} dk';
  if (diff.inDays < 1) return '${diff.inHours} sa';
  if (diff.inDays < 30) return '${diff.inDays} gün';
  final d = time.day.toString().padLeft(2, '0');
  final m = time.month.toString().padLeft(2, '0');
  return '$d.$m.${time.year}';
}

class _InboxVisual {
  const _InboxVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

_InboxVisual _visualFor(InboxItem item) {
  final status = (item.meta['status'] ?? '').toString();
  switch (item.type) {
    case 'price_suggestion_result':
    case 'price_verification_result':
      return _InboxVisual(
        icon: Icons.price_check_outlined,
        color: status == 'approved' ? AppColors.success : AppColors.danger,
      );
    case 'favorite_price_changed':
      return const _InboxVisual(
        icon: Icons.sell_outlined,
        color: AppColors.warning,
      );
    case 'claim_result':
      return _InboxVisual(
        icon: Icons.verified_outlined,
        color: status == 'approved' ? AppColors.success : AppColors.danger,
      );
    case 'owner_new_price_suggestion':
      return const _InboxVisual(
        icon: Icons.attach_money_outlined,
        color: AppColors.info,
      );
    case 'owner_new_review':
      return const _InboxVisual(
        icon: Icons.rate_review_outlined,
        color: AppColors.info,
      );
    case 'owner_business_reported':
      return const _InboxVisual(
        icon: Icons.flag_outlined,
        color: AppColors.warning,
      );
    case 'achievement_unlocked':
      final achievementId =
          (item.meta['achievement_id'] ?? item.meta['id'] ?? '').toString();
      final visual = appAchievementVisualForId(achievementId);
      return _InboxVisual(icon: visual.icon, color: visual.color);
    case 'nearby_trending':
      return const _InboxVisual(
        icon: Icons.local_fire_department_outlined,
        color: AppColors.warning,
      );
    case 'report_result':
      return _InboxVisual(
        icon: Icons.report_outlined,
        color: status == 'kapandı' ? AppColors.success : AppColors.warning,
      );
    case 'review_reply':
      return const _InboxVisual(
        icon: Icons.reply_outlined,
        color: AppColors.info,
      );
    default:
      return const _InboxVisual(
        icon: Icons.notifications_outlined,
        color: AppColors.info,
      );
  }
}

class _ReengagementCards extends StatelessWidget {
  const _ReengagementCards({
    required this.recentBusinesses,
    required this.favoriteChanges,
    required this.alertEvents,
    required this.userLocation,
    required this.moatSignals,
  });

  final AsyncValue<List<Business>> recentBusinesses;
  final AsyncValue<List<BusinessCardModel>> favoriteChanges;
  final AsyncValue<List<AlertEventItem>> alertEvents;
  final UserLocationState userLocation;
  final UserMoatSignals? moatSignals;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if ((alertEvents.asData?.value ?? const []).isNotEmpty)
        _PriceAlertCard(item: alertEvents.asData!.value.first),
      AppCard(
        onTap: () => context.go('/discover'),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.card,
              child: Icon(Icons.waving_hand, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Seni özledik',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Yakındaki yeni menülere göz at.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    ];

    final recent = recentBusinesses.asData?.value ?? const [];
    final recentAlertMap = <String, AlertEventItem>{
      for (final e in (alertEvents.asData?.value ?? const <AlertEventItem>[]))
        if ((e.event.businessId).trim().isNotEmpty) e.event.businessId: e,
    };
    final selected = _pickRecentBusiness(
      recent: recent,
      userLocation: userLocation,
      recentAlertMap: recentAlertMap,
    );
    if (selected != null) {
      final item = selected.business;
      final location = [
        if (item.district != null && item.district!.trim().isNotEmpty)
          item.district,
        if (item.city != null && item.city!.trim().isNotEmpty) item.city,
      ].whereType<String>().join(' • ');
      final title = selected.isClosed
          ? 'Son baktığın işletme kapandı görünüyor'
          : (selected.hasPriceChange
                ? 'Son baktığın yerde fiyat değişti'
                : (selected.isNearby
                      ? 'Son baktığın yer yakında'
                      : 'Son baktığın yer'));
      final subtitle = selected.hasPriceChange
          ? _buildAlertInsight(selected.alert!)
          : (selected.isClosed
                ? _lifecycleWarning(item.lifecycleStatus)
                : 'Sana yakın olduğu için öne alındı');
      cards.add(
        AppCard(
          onTap: () => context.go('/b/${item.id}'),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.card,
                child: Icon(Icons.history, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location.isEmpty ? item.name : '${item.name} • $location',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: selected.isClosed
                            ? AppColors.warning
                            : AppColors.muted,
                        fontSize: 11,
                        fontWeight: selected.hasPriceChange || selected.isClosed
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      );
    }

    final favoriteItems = favoriteChanges.asData?.value ?? const [];
    if (favoriteItems.isNotEmpty) {
      final item = favoriteItems.first;
      final count = item.recentPriceVerifiedCount ?? 0;
      cards.add(
        AppCard(
          onTap: () => context.go('/b/${item.id}'),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.card,
                child: Icon(Icons.price_change, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Favorilerinde fiyat değişti',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.name} • Son $count doğrulama',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      );
    }

    if (moatSignals != null) {
      final hint = _segmentHint(moatSignals!);
      cards.add(
        AppCard(
          onTap: () => context.go('/profile'),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.card,
                child: Icon(
                  Icons.psychology_alt_outlined,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sana uygun bugünün görevi',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final card in cards) ...[card, const SizedBox(height: 10)],
      ],
    );
  }
}

String _segmentHint(UserMoatSignals signals) {
  switch (signals.primarySegment) {
    case 'price_hunter':
      return 'Bugün 1 fiyat doğrula; güven skorun daha hızlı artsin.';
    case 'photo_proof':
      return 'Bugün 1 net menu/fotograf kaniti ekle.';
    case 'explorer':
      return 'Bugün yeni bir mekan aç ve fiyat durumunu kontrol et.';
    default:
      if (signals.isSilentQuality) {
        return 'Sessiz kalite katkıcın güçlü, doğru veriyi sürdür.';
      }
      return 'Bugün küçük bir katkıyla grafini güçlendir.';
  }
}

class _PriceAlertCard extends StatelessWidget {
  const _PriceAlertCard({required this.item});
  final AlertEventItem item;

  @override
  Widget build(BuildContext context) {
    final title = item.menuItemName?.trim().isNotEmpty == true
        ? item.menuItemName!
        : (item.alertQuery?.trim().isNotEmpty == true
              ? item.alertQuery!
              : 'Fiyat uyarısı');
    final location = _formatLocation(
      item.alertCity ?? item.businessCity,
      item.alertDistrict ?? item.businessDistrict,
    );
    final insight = _buildAlertInsight(item);
    return AppCard(
      onTap: () => context.go('/profile?tab=alerts'),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.card,
            child: Icon(Icons.notifications_active, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  insight,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (location.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}

String _buildAlertInsight(AlertEventItem item) {
  final matched = item.event.matchedPriceCents;
  final prev = item.event.previousPriceCents;
  final maxTarget = item.alertMaxPriceCents;
  final districtAvg = item.event.districtAvgPriceCents;
  final parts = <String>[];

  if (prev != null && prev > 0 && matched > 0) {
    final diff = matched - prev;
    final pct = (diff.abs() / prev) * 100;
    if (pct >= 10) {
      parts.add(
        'Fiyat %${pct.toStringAsFixed(0)} ${diff > 0 ? 'çıktı' : 'düştü'}',
      );
    }
  }

  if (maxTarget != null &&
      maxTarget > 0 &&
      matched > 0 &&
      matched < maxTarget) {
    final pct = ((maxTarget - matched) / maxTarget) * 100;
    if (pct >= 10) parts.add('Şuan %${pct.toStringAsFixed(0)} daha ucuz');
  }

  if (districtAvg != null && districtAvg > 0 && matched > 0) {
    final diff = matched - districtAvg;
    final pct = (diff.abs() / districtAvg) * 100;
    if (pct >= 10) {
      parts.add(
        diff > 0
            ? 'Bu semtte ortalamanın üstüne çıktı'
            : 'Bu semtte ortalamanın altına indi',
      );
    }
  }

  if (parts.isEmpty) return 'Fiyat alarmı tetiklendi';
  return parts.join(' • ');
}

String _formatLocation(String? city, String? district) {
  final c = (city ?? '').trim();
  final d = (district ?? '').trim();
  if (c.isEmpty && d.isEmpty) return '';
  if (c.isEmpty) return d;
  if (d.isEmpty) return c;
  return '$d • $c';
}

class _RecentPick {
  const _RecentPick({
    required this.business,
    required this.hasPriceChange,
    required this.isNearby,
    required this.isClosed,
    this.alert,
  });

  final Business business;
  final bool hasPriceChange;
  final bool isNearby;
  final bool isClosed;
  final AlertEventItem? alert;
}

_RecentPick? _pickRecentBusiness({
  required List<Business> recent,
  required UserLocationState userLocation,
  required Map<String, AlertEventItem> recentAlertMap,
}) {
  if (recent.isEmpty) return null;
  _RecentPick? best;
  var bestScore = -1 << 30;
  for (var i = 0; i < recent.length; i++) {
    final business = recent[i];
    final alert = recentAlertMap[business.id];
    final hasPriceChange = alert != null;
    final isNearby = _isNearby(userLocation, business);
    final isClosed = _isClosedLifecycle(business.lifecycleStatus);
    var score = (recent.length - i);
    if (hasPriceChange) score += 100;
    if (isClosed) score += 70;
    if (isNearby) score += 50;
    if (score > bestScore) {
      bestScore = score;
      best = _RecentPick(
        business: business,
        hasPriceChange: hasPriceChange,
        isNearby: isNearby,
        isClosed: isClosed,
        alert: alert,
      );
    }
  }
  return best;
}

bool _isNearby(UserLocationState loc, Business business) {
  final city = (loc.city ?? '').trim().toLowerCase();
  final district = (loc.district ?? '').trim().toLowerCase();
  if (city.isEmpty || district.isEmpty) return false;
  return (business.city ?? '').trim().toLowerCase() == city &&
      (business.district ?? '').trim().toLowerCase() == district;
}

bool _isClosedLifecycle(String? status) {
  final s = (status ?? '').trim().toLowerCase();
  return s == 'closed' || s == 'archived';
}

String _lifecycleWarning(String? status) {
  final s = (status ?? '').trim().toLowerCase();
  if (s == 'closed' || s == 'archived') return 'İşletme kapandı (arşiv).';
  if (s == 'moved') return 'İşletme taşındı.';
  if (s == 'temporarily_closed') return 'İşletme geçici kapalı.';
  return 'Durum güncellendi.';
}

