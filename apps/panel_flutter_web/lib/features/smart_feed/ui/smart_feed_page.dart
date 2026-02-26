import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/media/app_network_image.dart';
import '../../../core/weather/weather_hint_provider.dart';
import '../../../src/ui/components/app_scaffold.dart';
import '../../budget_combos/ui/budget_combo_entry_card.dart';
import '../../discovery/ui/discovery_page.dart';
import '../domain/smart_feed_controller.dart';
import '../domain/smart_feed_models.dart';
import '../../../src/ui/design_system.dart';

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
    final st = ref.watch(smartFeedProvider);
    final prefs = st.preferences;
    final weatherHint = ref
        .watch(weatherHintProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        appBar: AppBar(
          title: const Text('Akış'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Akış'),
              Tab(text: 'Keşfet'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () =>
                  ref.read(smartFeedProvider.notifier).loadInitial(),
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
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
                                .loadInitial(),
                            child: const Text('Tekrar dene'),
                          ),
                        ],
                      ),
                    ),
                  if (st.loading && st.items.isEmpty)
                    const _FeedSkeleton()
                  else if (!st.loading && st.items.isEmpty)
                    const AppEmptyState(
                      icon: Icons.dynamic_feed_outlined,
                      title: 'Henüz akış yok',
                      description:
                          'Filtreleri gevşetebilir ya da ilk katkıyı sen ekleyebilirsin.',
                    )
                  else ...[
                    for (final item in st.items) ...[
                      _FeedCard(item: item, preferences: prefs),
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
    _FeedOption(label: 'Kahve', value: 'coffee'),
    _FeedOption(label: 'Burger', value: 'burger'),
    _FeedOption(label: 'Meyhane', value: 'meyhane'),
    _FeedOption(label: 'Uygun Fiyatlı', value: 'cheap'),
  ];

  static const _bundleOptions = [
    _FeedOption(label: 'Öğrenci Dostu', value: 'student_friendly'),
    _FeedOption(label: 'İlk Randevu', value: 'first_date'),
    _FeedOption(label: 'Gece Çorbası', value: 'night_soup'),
  ];

  @override
  Widget build(BuildContext context) {
    final priceEnabled = preferences.priceMaxCents != null;
    final priceValue = (preferences.priceMaxCents ?? 15000) / 100.0;
    final clampedPrice = priceValue.clamp(50.0, 400.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Kürasyon'),
          const SizedBox(height: 10),
          const Text(
            'Kategoriler',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _categoryOptions)
                FilterChip(
                  label: Text(option.label),
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
          const Text('Senaryo', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _bundleOptions)
                FilterChip(
                  label: Text(option.label),
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
              const Text(
                'Bütçe',
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
                  'En fazla â‚º${priceValue.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      onChanged(preferences.copyWith(priceMaxCents: null)),
                  child: const Text('Sınırsız'),
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
    final title = (item.payload['title'] ?? _fallbackTitle(item.eventType))
        .toString();
    final subtitle = (item.payload['subtitle'] ?? '').toString();
    final imageUrl = (item.payload['image_url'] ?? '').toString();
    final cta = _ctaFor(context, item);
    final timestamp = _relativeTime(item.createdAt);
    final reasons = _contextBadges(item, preferences);

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
    final label = _eventLabel(type);
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
  const _FeedOption({required this.label, required this.value});
  final String label;
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
    final now = DateTime.now();
    final dayLabel = _dayPartLabel(now);
    final timeLabel = _timePartLabel(now);
    final categoryHint = preferences.categories.isNotEmpty
        ? preferences.categories.first
        : null;
    final bundleHint = preferences.bundles.isNotEmpty
        ? preferences.bundles.first
        : null;

    final subtitleParts = <String>[
      if (weatherHint != null && weatherHint!.isNotEmpty) weatherHint!,
      if (categoryHint != null) 'Tercih: $categoryHint',
      if (bundleHint != null) 'Senaryo: $bundleHint',
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
                      ? 'Bugünün akışını senin ritmine göre hazırlıyoruz.'
                      : subtitleParts.join(' • '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => context.go('/discover'),
            child: const Text('Keşfet'),
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

List<String> _toggle(List<String> current, String value, bool selected) {
  final next = [...current];
  if (selected) {
    if (!next.contains(value)) next.add(value);
  } else {
    next.remove(value);
  }
  return next;
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} saat önce';
  return '${diff.inDays} gün önce';
}

String _eventLabel(String type) {
  switch (type) {
    case 'menu_updated':
      return 'Menü';
    case 'price_verified':
      return 'Fiyat';
    case 'price_changed':
      return 'Fiyat';
    case 'photo_added':
      return 'Fotoğraf';
    case 'daily_menu':
      return 'Günlük';
    case 'sponsored':
      return 'Sponsor';
    default:
      return 'Akış';
  }
}

String _fallbackTitle(String type) {
  switch (type) {
    case 'menu_updated':
      return 'Menü güncellendi';
    case 'price_verified':
      return 'Fiyat doğrulandı';
    case 'price_changed':
      return 'Fiyat güncellendi';
    case 'photo_added':
      return 'Yeni fotoğraf eklendi';
    case 'daily_menu':
      return 'Günün menüsü';
    case 'sponsored':
      return 'Sponsorlu içerik';
    default:
      return 'Yeni içerik';
  }
}

_CtaConfig? _ctaFor(BuildContext context, SmartFeedEvent item) {
  final businessId = item.businessId;
  if (businessId.isEmpty) return null;
  switch (item.eventType) {
    case 'menu_updated':
      if (item.refType == 'menu' && (item.refId ?? '').isNotEmpty) {
        final menuId = item.refId!;
        return _CtaConfig(
          label: 'Menüye git',
          onTap: () => context.go('/b/$businessId/menu/$menuId'),
        );
      }
      return _CtaConfig(
        label: 'Menüye git',
        onTap: () => context.go('/b/$businessId'),
      );
    case 'price_verified':
    case 'price_changed':
      if ((item.refId ?? '').isNotEmpty) {
        final menuId = item.payload['menu_id']?.toString();
        final menuItemId = item.refId!;
        final route = (menuId != null && menuId.isNotEmpty)
            ? '/b/$businessId/menu/$menuId/item/$menuItemId'
            : '/b/$businessId/menu-item/$menuItemId';
        return _CtaConfig(label: 'Ürünü aç', onTap: () => context.go(route));
      }
      return _CtaConfig(
        label: 'Menüye git',
        onTap: () => context.go('/b/$businessId'),
      );
    case 'photo_added':
      if ((item.refId ?? '').isNotEmpty) {
        return _CtaConfig(
          label: 'Fotoğrafa bak',
          onTap: () => context.go('/b/$businessId/menu-item/${item.refId}'),
        );
      }
      return _CtaConfig(
        label: 'İşletmeye git',
        onTap: () => context.go('/b/$businessId'),
      );
    default:
      return _CtaConfig(
        label: 'İşletmeye git',
        onTap: () => context.go('/b/$businessId'),
      );
  }
}

List<String> _contextBadges(SmartFeedEvent item, SmartFeedPreferences prefs) {
  final reasons = <String>[];
  final now = DateTime.now();
  final dayPart = (item.payload['day_label'] ?? _dayPartLabel(now)).toString();
  final timePart = (item.payload['time_label'] ?? _timePartLabel(now))
      .toString();
  reasons.add('$dayPart • $timePart');

  final distance = item.payload['distance_km'];
  if (distance is num) {
    reasons.add('Yakınında ${distance.toStringAsFixed(1)} km');
  }

  final category = (item.payload['category'] ?? '').toString().trim();
  if (category.isNotEmpty && prefs.categories.contains(category)) {
    reasons.add('Sana uygun kategori');
  }

  final bundle = (item.payload['bundle'] ?? '').toString().trim();
  if (bundle.isNotEmpty && prefs.bundles.contains(bundle)) {
    reasons.add('Senin senaryon');
  }

  final similar = item.payload['similar_users_count'];
  if (similar is num && similar >= 3) {
    reasons.add('Benzer kullanıcılar seviyor');
  }

  final weather = (item.payload['weather_hint'] ?? '').toString().trim();
  if (weather.isNotEmpty) {
    reasons.add(weather);
  }

  return reasons.take(4).toList();
}

String _dayPartLabel(DateTime now) {
  final wd = now.weekday;
  if (wd == DateTime.saturday || wd == DateTime.sunday) {
    return 'Hafta sonu';
  }
  return 'Hafta içi';
}

String _timePartLabel(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 11) return 'Sabah';
  if (hour >= 11 && hour < 16) return 'Öğle';
  if (hour >= 16 && hour < 22) return 'Akşam';
  return 'Gece';
}

