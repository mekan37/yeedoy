import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/i18n/app_localizations.dart';
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
import '../../favorites/data/favorites_repository.dart';
import '../../../features/shared/ui/achievements/achievement_visuals.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../domain/inbox_models.dart';
import '../domain/inbox_provider.dart';
import '../domain/push_notification_service.dart';
import '../../../features/shared/ui/design_system.dart';

final recentBusinessesProvider = FutureProvider<List<Business>>((ref) async {
  return OfflineCachePrefs.loadRecentBusinesses();
});

final favoritePriceChangesProvider = FutureProvider<List<BusinessCardModel>>((
  ref,
) async {
  final repo = ref.read(favoritesRepositoryProvider);
  final res = await repo.fetchMyFavoritesWithBusinesses(limit: 20);
  return res.items.where((e) => (e.recentPriceVerifiedCount ?? 0) > 0).toList();
});

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final st = ref.watch(inboxProvider);
    final controller = ref.read(inboxProvider.notifier);
    final recentBusinesses = ref.watch(recentBusinessesProvider);
    final favoriteChanges = ref.watch(favoritePriceChangesProvider);
    final userLocation = ref.watch(userLocationProvider);
    final notificationsDenied = ref.watch(notificationsDeniedProvider);
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
        title: Text(t.inboxTitle),
        actions: [
          TextButton(
            onPressed: st.items.isEmpty ? null : () => controller.markAllRead(),
            child: Text(t.inboxMarkAllRead),
          ),
          IconButton(
            tooltip: t.yenile,
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
            if (notificationsDenied)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: _NotificationDeniedBanner(),
              ),
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
                AppEmptyState(
                  icon: Icons.inbox_outlined,
                  title: t.inboxEmptyTitle,
                  description: t.inboxEmptyDescription,
                ),
              for (final item in st.items) ...[
                RepaintBoundary(
                  child: _buildInboxTile(
                    context: context,
                    ref: ref,
                    controller: controller,
                    item: item,
                    unread: !st.isRead(item),
                  ),
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

VoidCallback? _shareCallbackFor(InboxItem item) {
  if (item.type == 'favorite_price_changed') {
    return () {
      final businessId = item.meta['business_id']?.toString() ?? '';
      final businessName =
          item.meta['business_name']?.toString() ?? item.title;
      final prevCents = (item.meta['previous_price_cents'] as num?)?.toInt();
      final newCents = (item.meta['matched_price_cents'] as num?)?.toInt();
      final pct = prevCents != null && prevCents > 0 && newCents != null
          ? (((newCents - prevCents) / prevCents) * 100).round()
          : null;
      final emoji =
          (newCents != null && prevCents != null && newCents > prevCents)
              ? '🚨'
              : '✅';
      final shareText = [
        '$emoji $businessName',
        if (pct != null)
          'Fiyat %${pct.abs()} ${pct > 0 ? 'arttı' : 'düştü'}',
        'yeedoy.com/isletme/$businessId',
      ].join('\n');
      SharePlus.instance.share(ShareParams(text: shareText));
    };
  }

  if (item.type == 'achievement_unlocked') {
    return () {
      final achievementTitle =
          item.meta['title']?.toString() ?? 'rozet';
      final xp = (item.meta['xp'] as num?)?.toInt();
      final level = (item.meta['level'] as num?)?.toInt();
      final parts = ['🏅 Yeedoy\'da "$achievementTitle" rozeti kazandım!'];
      if (xp != null && xp > 0) parts.add('+$xp XP');
      if (level != null) parts.add('Seviye $level');
      parts.add('yeedoy.com/gurmeler');
      SharePlus.instance.share(ShareParams(text: parts.join(' • ')));
    };
  }

  return null;
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
    message: _messageForInboxItem(context, item),
    timeText: _relative(context, item.createdAt),
    unread: unread,
    onShare: _shareCallbackFor(item),
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

String _messageForInboxItem(BuildContext context, InboxItem item) {
  final t = AppLocalizations.of(context);

  if (item.type == 'favorite_price_changed') {
    final prevCents = (item.meta['previous_price_cents'] as num?)?.toInt();
    final newCents = (item.meta['matched_price_cents'] as num?)?.toInt();
    if (prevCents != null && newCents != null && newCents < prevCents) {
      final savingsCents = prevCents - newCents;
      final savings = _formatCents(savingsCents);
      return '${item.message} • $savings tasarruf';
    }
    return item.message;
  }

  if (item.type != 'achievement_unlocked') return item.message;
  final xp = (item.meta['xp'] as num?)?.toInt();
  final level = (item.meta['level'] as num?)?.toInt();
  final leveledUp = item.meta['leveled_up'] == true;
  final parts = <String>[item.message];
  if (xp != null && xp > 0) parts.add(t.inboxXpGain(xp));
  if (level != null && level > 0) {
    parts.add(leveledUp ? t.inboxNewLevel(level) : t.inboxLevel(level));
  }
  return parts.join(' • ');
}

String _formatCents(int cents) {
  final tl = cents ~/ 100;
  final kr = cents % 100;
  if (kr == 0) return '₺$tl';
  return '₺$tl,${kr.toString().padLeft(2, '0')}';
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
    this.onShare,
  });

  /// Either [IconData] (Material) or [FaIconData] (Font Awesome).
  final Object icon;
  final Color accentColor;
  final String title;
  final String message;
  final String timeText;
  final bool unread;
  final VoidCallback onTap;
  final VoidCallback? onShare;

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
              child: icon is FaIconData
                  ? FaIcon(icon as FaIconData, size: 18, color: accentColor)
                  : Icon(icon as IconData, size: 18, color: accentColor),
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
        trailing: onShare != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeText,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    iconSize: 20,
                    color: AppColors.muted,
                    tooltip: 'Paylaş',
                    onPressed: onShare,
                  ),
                ],
              )
            : Text(
                timeText,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
      ),
    );
  }
}

String _relative(BuildContext context, DateTime time) {
  final t = AppLocalizations.of(context);
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return t.inboxNow;
  if (diff.inHours < 1) return t.timeMinutes(diff.inMinutes);
  if (diff.inDays < 1) return t.timeHours(diff.inHours);
  if (diff.inDays < 30) return t.timeDays(diff.inDays);
  final d = time.day.toString().padLeft(2, '0');
  final m = time.month.toString().padLeft(2, '0');
  return '$d.$m.${time.year}';
}

class _InboxVisual {
  const _InboxVisual({required this.icon, required this.color});

  /// Either [IconData] (Material) or [FaIconData] (Font Awesome).
  final Object icon;
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
    final t = AppLocalizations.of(context);
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
                children: [
                  Text(
                    t.inboxReengagementTitle,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    t.inboxReengagementSubtitle,
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
          ? t.inboxRecentBusinessClosedTitle
          : (selected.hasPriceChange
                ? t.inboxRecentBusinessPriceChangedTitle
                : (selected.isNearby
                      ? t.inboxRecentBusinessNearbyTitle
                      : t.inboxRecentBusinessTitle));
      final subtitle = selected.hasPriceChange
          ? _buildAlertInsight(context, selected.alert!)
          : (selected.isClosed
                ? _lifecycleWarning(context, item.lifecycleStatus)
                : t.inboxRecentBusinessNearbyReason);
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
                    Text(
                      t.inboxFavoritesPriceChangedTitle,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.inboxFavoritesPriceChangedSubtitle(item.name, count),
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
      final hint = _segmentHint(context, moatSignals!);
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
                    Text(
                      t.inboxDailyTaskTitle,
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

String _segmentHint(BuildContext context, UserMoatSignals signals) {
  final t = AppLocalizations.of(context);
  switch (signals.primarySegment) {
    case 'price_hunter':
      return t.inboxSegmentPriceHunter;
    case 'photo_proof':
      return t.inboxSegmentPhotoProof;
    case 'explorer':
      return t.inboxSegmentExplorer;
    default:
      if (signals.isSilentQuality) {
        return t.inboxSegmentSilentQuality;
      }
      return t.inboxSegmentDefault;
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
              : AppLocalizations.of(context).priceAlert);
    final location = _formatLocation(
      item.alertCity ?? item.businessCity,
      item.alertDistrict ?? item.businessDistrict,
    );
    final insight = _buildAlertInsight(context, item);
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

String _buildAlertInsight(BuildContext context, AlertEventItem item) {
  final t = AppLocalizations.of(context);
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
        diff > 0
            ? t.inboxAlertPriceUp(pct.toStringAsFixed(0))
            : t.inboxAlertPriceDown(pct.toStringAsFixed(0)),
      );
    }
  }

  if (maxTarget != null &&
      maxTarget > 0 &&
      matched > 0 &&
      matched < maxTarget) {
    final pct = ((maxTarget - matched) / maxTarget) * 100;
    if (pct >= 10) {
      parts.add(t.inboxAlertCheaperNow(pct.toStringAsFixed(0)));
    }
  }

  if (districtAvg != null && districtAvg > 0 && matched > 0) {
    final diff = matched - districtAvg;
    final pct = (diff.abs() / districtAvg) * 100;
    if (pct >= 10) {
      parts.add(
        diff > 0
            ? t.inboxAlertAboveDistrictAverage
            : t.inboxAlertBelowDistrictAverage,
      );
    }
  }

  if (parts.isEmpty) return t.inboxAlertTriggered;
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

String _lifecycleWarning(BuildContext context, String? status) {
  final t = AppLocalizations.of(context);
  final s = (status ?? '').trim().toLowerCase();
  if (s == 'closed' || s == 'archived') return t.inboxBusinessClosedArchived;
  if (s == 'moved') return t.inboxBusinessMoved;
  if (s == 'temporarily_closed') return t.inboxBusinessTemporarilyClosed;
  return t.inboxBusinessStatusUpdated;
}

class _NotificationDeniedBanner extends StatelessWidget {
  const _NotificationDeniedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Bildirimler kapalı. Fiyat değişikliklerini kaçırmamak için bildirimlere izin ver.',
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('app-settings:')),
            child: const Text(
              'İzin ver',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

