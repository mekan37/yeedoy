import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../uygulama/tema/renkler.dart';
import '../../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../../core/konum/konum_esleme.dart';
import '../../../../core/konum/kullanici_konum_kontrolcusu.dart';
import '../../../../core/depolama/konum_tercihleri.dart';
import '../../../kesif/domain/sehir_ilceler_saglayicisi.dart';
import '../tasarim_sistemi.dart';

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
    final t = AppLocalizations.of(context);
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
                  Text(t.selectLocation, style: context.sectionTitleStyle),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      t.locationPickerManualHint,
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
                        Expanded(
                          child: Text(
                            t.locationPickerUseAuto,
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        AppButton(
                          label: t.use,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            await ref
                                .read(userLocationProvider.notifier)
                                .useAutoLocation();
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: t.notNow,
                      variant: AppButtonVariant.ghost,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SwitchListTile(
                    value: makeDefault,
                    onChanged: (v) => setState(() => makeDefault = v),
                    title: Text(
                      t.locationPickerMakeDefault,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      t.locationPickerMakeDefaultHint,
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
                          Text(
                            t.locationPickerRecent,
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
                    decoration: InputDecoration(
                      labelText: t.groupRequestWizardCityLabel,
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: t.locationPickerSearchDistrict,
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (qCtrl.text.trim().isEmpty) ...[
                    Text(
                      t.locationPickerPopularDistricts,
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
                              t.locationPickerBusinessCount(city, count),
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




