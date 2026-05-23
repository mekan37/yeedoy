import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/medya/uygulama_ag_gorseli.dart';
import '../../../core/hava/hava_uyari_saglayicisi.dart';
import '../../../features/shared/ui/bilesenler/hava_durumu_ipucu_cubugu.dart';
import '../../butce_kombinasyonlari/ui/butce_kombinasyon_girdi_karti.dart';
import '../../kesif/ui/kesif_sayfasi.dart';
import '../domain/akilli_akis_kontrolcusu.dart';
import '../domain/akilli_akis_modelleri.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';

class SmartFeedPage extends ConsumerStatefulWidget {
  const SmartFeedPage({super.key});

  @override
  ConsumerState<SmartFeedPage> createState() => _SmartFeedPageState();
}

class _SmartFeedPageState extends ConsumerState<SmartFeedPage> {
  final scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(smartFeedProvider.notifier).loadMore();
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
    final t = AppLocalizations.of(context);
    final st = ref.watch(smartFeedProvider);
    final prefs = st.preferences;
    final weatherData = ref
        .watch(weatherHintDataProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final weatherHint = _localizedWeatherHint(context, weatherData);

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        appBar: AppBar(
          title: Text(t.profileFeedTab),
          bottom: TabBar(
            tabs: [
              Tab(text: t.profileFeedTab),
              Tab(text: t.discover),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () =>
                  ref.read(smartFeedProvider.notifier).loadInitial(force: true),
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  const WeatherHintBar(),
                  const SizedBox(height: 12),
                  _CurationBar(
                    preferences: prefs,
                    onChanged: (next) => ref
                        .read(smartFeedProvider.notifier)
                        .updatePreferences(next),
                  ),
                  const SizedBox(height: 14),
                  const BudgetComboEntryCard(),
                  const SizedBox(height: 14),
                  _SmartContextBanner(
                    preferences: prefs,
                    weatherHint: weatherHint,
                  ),
                  const SizedBox(height: 14),
                  if (st.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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
                            onPressed: () => ref
                                .read(smartFeedProvider.notifier)
                                .loadInitial(force: true),
                            child: Text(t.retry),
                          ),
                        ],
                      ),
                    ),
                  if (st.loading && st.items.isEmpty)
                    const _FeedSkeleton()
                  else if (!st.loading && st.items.isEmpty)
                    AppEmptyState(
                      icon: Icons.dynamic_feed_outlined,
                      title: t.smartFeedEmptyTitle,
                      description: t.smartFeedEmptyDescription,
                    )
                  else ...[
                    for (final item in st.items) ...[
                      RepaintBoundary(child: _FeedCard(item: item, preferences: prefs)),
                      const SizedBox(height: 10),
                    ],
                  ],
                  if (st.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
            const DiscoveryPage(),
          ],
        ),
      ),
    );
  }
}

class _CurationBar extends StatelessWidget {
  const _CurationBar({required this.preferences, required this.onChanged});

  final SmartFeedPreferences preferences;
  final ValueChanged<SmartFeedPreferences> onChanged;

  static const _categoryOptions = [
    _FeedOption(value: 'coffee'),
    _FeedOption(value: 'burger'),
    _FeedOption(value: 'meyhane'),
    _FeedOption(value: 'cheap'),
  ];

  static const _bundleOptions = [
    _FeedOption(value: 'student_friendly'),
    _FeedOption(value: 'first_date'),
    _FeedOption(value: 'night_soup'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final priceEnabled = preferences.priceMaxCents != null;
    final priceValue = (preferences.priceMaxCents ?? 15000) / 100.0;
    final clampedPrice = priceValue.clamp(50.0, 400.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: t.smartFeedCurationTitle),
          const SizedBox(height: 10),
          Text(t.smartFeedCategoriesLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _categoryOptions)
                FilterChip(
                  label: Text(_categoryLabel(t, option.value)),
                  selected: preferences.categories.contains(option.value),
                  onSelected: (selected) {
                    final updated = _toggle(
                      preferences.categories,
                      option.value,
                      selected,
                    );
                    onChanged(preferences.copyWith(categories: updated));
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(t.smartFeedScenarioLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _bundleOptions)
                FilterChip(
                  label: Text(_bundleLabel(t, option.value)),
                  selected: preferences.bundles.contains(option.value),
                  onSelected: (selected) {
                    final updated = _toggle(
                      preferences.bundles,
                      option.value,
                      selected,
                    );
                    onChanged(preferences.copyWith(bundles: updated));
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                t.budget,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Switch(
                value: priceEnabled,
                onChanged: (v) {
                  onChanged(
                    preferences.copyWith(priceMaxCents: v ? 15000 : null),
                  );
                },
              ),
            ],
          ),
          if (priceEnabled) ...[
            Row(
              children: [
                Text(
                  t.smartFeedBudgetMax(priceValue.toStringAsFixed(0)),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      onChanged(preferences.copyWith(priceMaxCents: null)),
                  child: Text(t.smartFeedUnlimited),
                ),
              ],
            ),
            Slider(
              min: 50,
              max: 400,
              divisions: 35,
              value: clampedPrice,
              onChanged: (v) => onChanged(
                preferences.copyWith(priceMaxCents: (v * 100).round()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.item, required this.preferences});
  final SmartFeedEvent item;
  final SmartFeedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final title = (item.payload['title'] ?? _fallbackTitle(context, item.eventType))
        .toString();
    final subtitle = (item.payload['subtitle'] ?? '').toString();
    final imageUrl = (item.payload['image_url'] ?? '').toString();
    final cta = _ctaFor(context, item);
    final timestamp = _relativeTime(context, item.createdAt);
    final reasons = _contextBadges(context, item, preferences);

    return AppCard(
      onTap: cta?.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: item.businessName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.businessName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _EventBadge(type: item.eventType),
            ],
          ),
          const SizedBox(height: 10),
          if (imageUrl.isNotEmpty) ...[
            _FeedImage(url: imageUrl),
            const SizedBox(height: 10),
          ],
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppColors.muted)),
          ],
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final reason in reasons) _ReasonChip(label: reason),
              ],
            ),
          ],
          if (cta != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: cta.onTap,
                child: Text(cta.label),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'M';
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
}

class _EventBadge extends StatelessWidget {
  const _EventBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final label = _eventLabel(context, type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
}

class _CtaConfig {
  const _CtaConfig({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
}

class _FeedOption {
  const _FeedOption({required this.value});
  final String value;
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        6,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: AppSkeletonCard(),
        ),
      ),
    );
  }
}

class _FeedImage extends StatelessWidget {
  const _FeedImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: AppNetworkImage(
        url: url,
        variant: AppImageVariant.medium,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _SmartContextBanner extends StatelessWidget {
  const _SmartContextBanner({
    required this.preferences,
    required this.weatherHint,
  });
  final SmartFeedPreferences preferences;
  final String? weatherHint;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final dayLabel = _dayPartLabel(context, now);
    final timeLabel = _timePartLabel(context, now);
    final categoryHint = preferences.categories.isNotEmpty
        ? preferences.categories.first
        : null;
    final bundleHint = preferences.bundles.isNotEmpty
        ? preferences.bundles.first
        : null;

    final subtitleParts = <String>[
      if (weatherHint != null && weatherHint!.isNotEmpty) weatherHint!,
      if (categoryHint != null)
        t.smartFeedPreferenceHint(_categoryLabel(t, categoryHint)),
      if (bundleHint != null) t.smartFeedScenarioHint(_bundleLabel(t, bundleHint)),
    ];

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.textStrong),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayLabel • $timeLabel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleParts.isEmpty
                      ? t.smartFeedContextDefault
                      : subtitleParts.join(' • '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => context.go('/discover'),
            child: Text(t.discover),
          ),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
}

String _categoryLabel(AppLocalizations t, String value) {
  switch (value) {
    case 'coffee':
      return t.discoveryFilterCafe;
    case 'burger':
      return t.discoveryHomeCategoryBurger;
    case 'meyhane':
      return t.smartFeedCategoryMeyhane;
    case 'cheap':
      return t.smartFeedCategoryAffordable;
    default:
      return value;
  }
}

String _bundleLabel(AppLocalizations t, String value) {
  switch (value) {
    case 'student_friendly':
      return t.smartFeedBundleStudentFriendly;
    case 'first_date':
      return t.smartFeedBundleFirstDate;
    case 'night_soup':
      return t.smartFeedBundleNightSoup;
    default:
      return value;
  }
}

List<String> _toggle(List<String> current, String value, bool selected) {
  final next = [...current];
  if (selected) {
    if (!next.contains(value)) next.add(value);
  } else {
    next.remove(value);
  }
  return next;
}

String _relativeTime(BuildContext context, DateTime time) {
  final t = AppLocalizations.of(context);
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 60) return t.smartFeedMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return t.smartFeedHoursAgo(diff.inHours);
  return t.smartFeedDaysAgo(diff.inDays);
}

String _eventLabel(BuildContext context, String type) {
  final t = AppLocalizations.of(context);
  switch (type) {
    case 'menu_updated':
      return t.smartFeedEventMenu;
    case 'price_verified':
      return t.smartFeedEventPrice;
    case 'price_changed':
      return t.smartFeedEventPrice;
    case 'photo_added':
      return t.smartFeedEventPhoto;
    case 'daily_menu':
      return t.smartFeedEventDaily;
    case 'sponsored':
      return t.smartFeedEventSponsor;
    default:
      return t.profileFeedTab;
  }
}

String _fallbackTitle(BuildContext context, String type) {
  final t = AppLocalizations.of(context);
  switch (type) {
    case 'menu_updated':
      return t.profileFeedEventMenuUpdated;
    case 'price_verified':
      return t.profileFeedEventPriceVerified;
    case 'price_changed':
      return t.smartFeedFallbackPriceChanged;
    case 'photo_added':
      return t.smartFeedFallbackPhotoAdded;
    case 'daily_menu':
      return t.smartFeedFallbackDailyMenu;
    case 'sponsored':
      return t.profileFeedEventSponsored;
    default:
      return t.smartFeedFallbackNewContent;
  }
}

_CtaConfig? _ctaFor(BuildContext context, SmartFeedEvent item) {
  final t = AppLocalizations.of(context);
  final businessId = item.businessId;
  if (businessId.isEmpty) return null;
  switch (item.eventType) {
    case 'menu_updated':
      if (item.refType == 'menu' && (item.refId ?? '').isNotEmpty) {
        final menuId = item.refId!;
        return _CtaConfig(
          label: t.smartFeedCtaGoToMenu,
          onTap: () => context.go('/isletme/$businessId/menu/$menuId'),
        );
      }
      return _CtaConfig(
        label: t.smartFeedCtaGoToMenu,
        onTap: () => context.go('/isletme/$businessId'),
      );
    case 'price_verified':
    case 'price_changed':
      if ((item.refId ?? '').isNotEmpty) {
        final menuId = item.payload['menu_id']?.toString();
        final menuItemId = item.refId!;
        final route = (menuId != null && menuId.isNotEmpty)
            ? '/isletme/$businessId/menu/$menuId/item/$menuItemId'
            : '/isletme/$businessId/menu-item/$menuItemId';
        return _CtaConfig(label: t.smartFeedCtaOpenItem, onTap: () => context.go(route));
      }
      return _CtaConfig(
        label: t.smartFeedCtaGoToMenu,
        onTap: () => context.go('/isletme/$businessId'),
      );
    case 'photo_added':
      if ((item.refId ?? '').isNotEmpty) {
        return _CtaConfig(
          label: t.smartFeedCtaViewPhoto,
          onTap: () => context.go('/isletme/$businessId/menu-item/${item.refId}'),
        );
      }
      return _CtaConfig(
        label: t.smartFeedCtaGoToBusiness,
        onTap: () => context.go('/isletme/$businessId'),
      );
    default:
      return _CtaConfig(
        label: t.smartFeedCtaGoToBusiness,
        onTap: () => context.go('/isletme/$businessId'),
      );
  }
}

List<String> _contextBadges(
  BuildContext context,
  SmartFeedEvent item,
  SmartFeedPreferences prefs,
) {
  final t = AppLocalizations.of(context);
  final reasons = <String>[];
  final now = DateTime.now();
  final dayPart = (item.payload['day_label'] ?? _dayPartLabel(context, now))
      .toString();
  final timePart = (item.payload['time_label'] ?? _timePartLabel(context, now))
      .toString();
  reasons.add('$dayPart • $timePart');

  final distance = item.payload['distance_km'];
  if (distance is num) {
    reasons.add(t.smartFeedNearbyKm(distance.toStringAsFixed(1)));
  }

  final category = (item.payload['category'] ?? '').toString().trim();
  if (category.isNotEmpty && prefs.categories.contains(category)) {
    reasons.add(t.smartFeedReasonCategoryMatch);
  }

  final bundle = (item.payload['bundle'] ?? '').toString().trim();
  if (bundle.isNotEmpty && prefs.bundles.contains(bundle)) {
    reasons.add(t.smartFeedReasonScenarioMatch);
  }

  final similar = item.payload['similar_users_count'];
  if (similar is num && similar >= 3) {
    reasons.add(t.smartFeedReasonSimilarUsers);
  }

  final weather = (item.payload['weather_hint'] ?? '').toString().trim();
  if (weather.isNotEmpty) {
    reasons.add(weather);
  }

  return reasons.take(4).toList();
}

String? _localizedWeatherHint(BuildContext context, WeatherHintData? data) {
  if (data == null) return null;
  final t = context.l10n;
  switch (data.kind) {
    case WeatherHintKind.rainy:
      return '${t.weatherHeadlineRainy} • ${t.weatherHintRainy}';
    case WeatherHintKind.snowy:
      return '${t.weatherHeadlineSnowy} • ${t.weatherHintSnowy}';
    case WeatherHintKind.hot:
      return '${t.weatherHeadlineHot} • ${t.weatherHintHot}';
    case WeatherHintKind.clear:
      return '${t.weatherHeadlineClear} • ${t.weatherHintClear}';
  }
}

String _dayPartLabel(BuildContext context, DateTime now) {
  final t = AppLocalizations.of(context);
  final wd = now.weekday;
  if (wd == DateTime.saturday || wd == DateTime.sunday) {
    return t.smartFeedDayWeekend;
  }
  return t.smartFeedDayWeekday;
}

String _timePartLabel(BuildContext context, DateTime now) {
  final t = AppLocalizations.of(context);
  final hour = now.hour;
  if (hour >= 5 && hour < 11) return t.smartFeedTimeMorning;
  if (hour >= 11 && hour < 16) return t.smartFeedTimeNoon;
  if (hour >= 16 && hour < 22) return t.smartFeedTimeEvening;
  return t.smartFeedTimeNight;
}









