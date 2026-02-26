import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/location/location_mapping.dart';
import '../../../core/location/user_location_controller.dart';
import '../../../core/storage/location_prefs.dart';
import '../../../features/discovery/domain/city_districts_provider.dart';
import 'app_card.dart';

class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  ConsumerState<LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  final qCtrl = TextEditingController();
  String? selectedCity;
  bool makeDefault = true;
  Future<List<(String city, String district)>>? recentFuture;

  @override
  void initState() {
    super.initState();
    recentFuture = LocationPrefs.readRecent();
  }

  @override
  void dispose() {
    qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cityDistrictsProvider);
    final loc = ref.watch(userLocationProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: async.when(
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 240,
            child: Center(child: Text(AppErrorMapper.message(e))),
          ),
          data: (rows) {
            final list = rows
                .map(
                  (r) => (
                    (r['city'] ?? '').toString(),
                    (r['district'] ?? '').toString(),
                    (r['count'] as num?)?.toInt() ?? 0,
                  ),
                )
                .where((t) => t.$1.isNotEmpty && t.$2.isNotEmpty)
                .toList();

            final cityMap = <String, String>{};
            for (final t in list) {
              final canonical = canonicalCity(t.$1).trim();
              if (canonical.isEmpty) continue;
              cityMap.putIfAbsent(canonical.toLowerCase(), () => canonical);
            }
            final cities = cityMap.values.toList()..sort();
            selectedCity ??= canonicalCity(loc.city ?? '').trim();
            if (!cities.contains(selectedCity)) {
              selectedCity = null;
            }

            final filtered = list.where((t) {
              final q = qCtrl.text.trim();
              if (q.isEmpty) return canonicalCity(t.$1) == selectedCity;
              return locationContainsQuery(
                city: t.$1,
                district: t.$2,
                query: q,
              );
            }).toList()..sort((a, b) => b.$3.compareTo(a.$3));

            final popular =
                list.where((t) => canonicalCity(t.$1) == selectedCity).toList()
                  ..sort((a, b) => b.$3.compareTo(a.$3));
            final popularTop = popular.take(10).toList();

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Konum Seç',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Manuel seçimde il/ilçe bazlı arama yapılır. Yakınımdaki kalitesi için yarıçap (5/10/20 km) ve konum izni daha iyi sonuç verir.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.my_location,
                          color: AppColors.textStrong,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Otomatik konumu kullan',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () async {
                            await ref
                                .read(userLocationProvider.notifier)
                                .useAutoLocation();
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Kullan'),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Şimdi değil'),
                    ),
                  ),
                  SwitchListTile(
                    value: makeDefault,
                    onChanged: (v) => setState(() => makeDefault = v),
                    title: const Text(
                      'Varsayılan yap',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Seçtiğin konum bir sonraki açılışta da kullanılsın.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<(String city, String district)>>(
                    future: recentFuture,
                    builder: (context, snap) {
                      final recent =
                          snap.data ?? <(String city, String district)>[];
                      if (recent.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          const Text(
                            'Son Seçilenler',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final r in recent) ...[
                                  _LocChip(
                                    label: '${r.$2} • ${r.$1}',
                                    selected:
                                        (r.$1 == loc.city &&
                                        r.$2 == loc.district),
                                    onTap: () async {
                                      await ref
                                          .read(userLocationProvider.notifier)
                                          .setManualLocation(
                                            city: r.$1,
                                            district: r.$2,
                                            persist: makeDefault,
                                          );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue:
                        selectedCity != null && cities.contains(selectedCity)
                        ? selectedCity
                        : null,
                    items: cities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCity = v),
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'İlçe ara',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (qCtrl.text.trim().isEmpty) ...[
                    const Text(
                      'Popüler ilçeler',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in popularTop)
                          _LocChip(
                            label: '${p.$2} (${p.$3})',
                            selected:
                                (p.$1 == loc.city && p.$2 == loc.district),
                            onTap: () async {
                              await ref
                                  .read(userLocationProvider.notifier)
                                  .setManualLocation(
                                    city: p.$1,
                                    district: p.$2,
                                    persist: makeDefault,
                                  );
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final city = filtered[i].$1;
                        final district = filtered[i].$2;
                        final count = filtered[i].$3;
                        final selected =
                            (city == loc.city && district == loc.district);

                        return Card(
                          child: ListTile(
                            title: Text(
                              district,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              '$city • $count işletme',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            trailing: selected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                  )
                                : null,
                            onTap: () async {
                              await ref
                                  .read(userLocationProvider.notifier)
                                  .setManualLocation(
                                    city: city,
                                    district: district,
                                    persist: makeDefault,
                                  );
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LocChip extends StatelessWidget {
  const _LocChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.30)
              : AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }
}

