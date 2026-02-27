import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/media/app_network_image.dart';
import '../../../core/network/supabase_provider.dart';
import '../data/admin_businesses_repository.dart';
import '../domain/admin_businesses_controller.dart';
import '../domain/admin_models.dart';
import 'web_upload.dart';

class AdminBusinessesPage extends ConsumerStatefulWidget {
  const AdminBusinessesPage({super.key});

  @override
  ConsumerState<AdminBusinessesPage> createState() =>
      _AdminBusinessesPageState();
}

class _AdminBusinessesPageState extends ConsumerState<AdminBusinessesPage> {
  final searchCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final districtCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  final Map<String, BusinessRiskSignal> _riskById = {};
  String _riskKey = '';
  bool _riskLoading = false;

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(adminBusinessesControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    cityCtrl.dispose();
    districtCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminBusinessesControllerProvider);
    final nextRiskKey = st.items.map((e) => e.id).join(',');
    if (nextRiskKey != _riskKey && st.items.isNotEmpty) {
      _riskKey = nextRiskKey;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _refreshRiskSignals(st.items),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Ä°ÅŸletmeler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              if (_riskLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                onPressed: () => ref
                    .read(adminBusinessesControllerProvider.notifier)
                    .refresh(force: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (v) => ref
                      .read(adminBusinessesControllerProvider.notifier)
                      .setQuery(v.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Ara (isim, adres)',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: cityCtrl,
                  onChanged: (v) => ref
                      .read(adminBusinessesControllerProvider.notifier)
                      .setCity(v.trim()),
                  decoration: const InputDecoration(hintText: 'Åehir'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: districtCtrl,
                  onChanged: (v) => ref
                      .read(adminBusinessesControllerProvider.notifier)
                      .setDistrict(v.trim()),
                  decoration: const InputDecoration(hintText: 'Ä°lÃ§e'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (st.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                AppErrorMapper.message(st.error),
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          Expanded(
            child: st.isLoading && st.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: scrollCtrl,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Logo')),
                            DataColumn(label: Text('Ä°sim')),
                            DataColumn(label: Text('Åehir')),
                            DataColumn(label: Text('Ä°lÃ§e')),
                            DataColumn(label: Text('Kategori')),
                            DataColumn(label: Text('Risk')),
                            DataColumn(label: Text('OluÅŸturulma')),
                            DataColumn(label: Text('Atanan')),
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final b in st.items)
                              DataRow(
                                cells: [
                                  DataCell(_logoPreview(b.logoUrl)),
                                  DataCell(Text(b.name)),
                                  DataCell(Text(b.city ?? '-')),
                                  DataCell(Text(b.district ?? '-')),
                                  DataCell(Text(b.category ?? '-')),
                                  DataCell(_riskCell(_riskById[b.id])),
                                  DataCell(Text(_fmtDate(b.createdAt))),
                                  DataCell(Text(b.assignedTo ?? '-')),
                                  DataCell(
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              _openDetails(context, b),
                                          child: const Text('DÃ¼zenle'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              _openMergeFlow(context, b),
                                          child: const Text('BirleÅŸtir'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (!st.isLoading && st.items.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(child: Text('Kayit bulunamadi.')),
                        ),
                      if (st.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    AdminBusinessItem item,
  ) async {
    final nameCtrl = TextEditingController(text: item.name);
    final categoryCtrl = TextEditingController(text: item.category ?? '');
    final addressCtrl = TextEditingController(text: item.address ?? '');
    final cityCtrl = TextEditingController(text: item.city ?? '');
    final districtCtrl = TextEditingController(text: item.district ?? '');
    final latCtrl = TextEditingController(text: item.lat?.toString() ?? '');
    final lngCtrl = TextEditingController(text: item.lng?.toString() ?? '');
    final logoCtrl = TextEditingController(text: item.logoUrl ?? '');
    final coverCtrl = TextEditingController(text: item.coverUrl ?? '');
    final client = ref.read(supabaseProvider);

    var logoUrl = item.logoUrl ?? '';
    var coverUrl = item.coverUrl ?? '';
    var saving = false;
    var uploadingLogo = false;
    var uploadingCover = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> save() async {
            setModalState(() => saving = true);
            try {
              await ref
                  .read(adminBusinessesControllerProvider.notifier)
                  .updateBusiness(
                    businessId: item.id,
                    name: nameCtrl.text.trim(),
                    category: categoryCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    city: cityCtrl.text.trim(),
                    district: districtCtrl.text.trim(),
                    lat: double.tryParse(latCtrl.text.trim()),
                    lng: double.tryParse(lngCtrl.text.trim()),
                    logoUrl: logoUrl.trim(),
                    coverUrl: coverUrl.trim(),
                  );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('GÃ¼ncellendi.')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppErrorMapper.message(e))),
                );
              }
              setModalState(() => saving = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ä°ÅŸletme DÃ¼zenle',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Bilgi'),
                      Tab(text: 'Medya'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 460,
                    child: TabBarView(
                      children: [
                        ListView(
                          children: [
                            TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Ä°sim',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: categoryCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Kategori',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: addressCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Adres',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: cityCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Åehir',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: districtCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Ä°lÃ§e',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: latCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Enlem',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: lngCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Boylam',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: saving ? null : save,
                                child: Text(
                                  saving ? 'Kaydediliyor...' : 'Kaydet',
                                ),
                              ),
                            ),
                          ],
                        ),
                        ListView(
                          children: [
                            const Text(
                              'Logo',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            if (logoUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppNetworkImage(
                                  url: logoUrl,
                                  variant: AppImageVariant.thumb,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: uploadingLogo
                                      ? null
                                      : () async {
                                          setModalState(
                                            () => uploadingLogo = true,
                                          );
                                          try {
                                            final res =
                                                await pickAndUploadWpImage(
                                                  client: client,
                                                  title: '${item.id}_logo',
                                                );
                                            if (res != null) {
                                              logoUrl = res.urlLarge;
                                              logoCtrl.text = logoUrl;
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppErrorMapper.message(e),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                          setModalState(
                                            () => uploadingLogo = false,
                                          );
                                        },
                                  icon: const Icon(Icons.upload),
                                  label: Text(
                                    uploadingLogo
                                        ? 'YÃ¼kleniyor...'
                                        : 'Upload (WP)',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: uploadingLogo
                                      ? null
                                      : () => setModalState(() {
                                          logoUrl = '';
                                          logoCtrl.text = '';
                                        }),
                                  child: const Text('Temizle'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: logoCtrl,
                              onChanged: (v) => logoUrl = v.trim(),
                              decoration: const InputDecoration(
                                labelText: 'Logo URL',
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Kapak',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            if (coverUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppNetworkImage(
                                  url: coverUrl,
                                  variant: AppImageVariant.medium,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: uploadingCover
                                      ? null
                                      : () async {
                                          setModalState(
                                            () => uploadingCover = true,
                                          );
                                          try {
                                            final res =
                                                await pickAndUploadWpImage(
                                                  client: client,
                                                  title: '${item.id}_cover',
                                                );
                                            if (res != null) {
                                              coverUrl = res.urlLarge;
                                              coverCtrl.text = coverUrl;
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppErrorMapper.message(e),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                          setModalState(
                                            () => uploadingCover = false,
                                          );
                                        },
                                  icon: const Icon(Icons.upload),
                                  label: Text(
                                    uploadingCover
                                        ? 'YÃ¼kleniyor...'
                                        : 'Upload (WP)',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: uploadingCover
                                      ? null
                                      : () => setModalState(() {
                                          coverUrl = '';
                                          coverCtrl.text = '';
                                        }),
                                  child: const Text('Temizle'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: coverCtrl,
                              onChanged: (v) => coverUrl = v.trim(),
                              decoration: const InputDecoration(
                                labelText: 'Kapak URL',
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: saving ? null : save,
                                child: Text(
                                  saving ? 'Kaydediliyor...' : 'Kaydet',
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshRiskSignals(List<AdminBusinessItem> items) async {
    setState(() => _riskLoading = true);
    try {
      final map = await ref
          .read(adminBusinessesRepositoryProvider)
          .getRiskSignals(items.map((e) => e.id).toList());
      if (!mounted) return;
      setState(() {
        _riskById
          ..clear()
          ..addAll(map);
      });
    } catch (_) {
      // no-op
    } finally {
      if (mounted) setState(() => _riskLoading = false);
    }
  }

  Future<void> _openMergeFlow(
    BuildContext context,
    AdminBusinessItem source,
  ) async {
    List<AdminBusinessItem> candidates = const [];
    try {
      candidates = await ref
          .read(adminBusinessesRepositoryProvider)
          .findMergeCandidates(source: source);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
      return;
    }
    if (!context.mounted) return;
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BirleÅŸtirme adayÄ± bulunamadÄ±.')),
      );
      return;
    }

    String selectedId = candidates.first.id;
    bool applyNow = false;
    final noteCtrl = TextEditingController(
      text: 'AynÄ± iÅŸletme kaydÄ± olabilir. BirleÅŸtirme kontrolÃ¼ Ã¶nerildi.',
    );
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${source.name}" iÃ§in birleÅŸtirme adayÄ± seÃ§in',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  for (final c in candidates)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        selectedId == c.id
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: selectedId == c.id
                            ? AppColors.success
                            : AppColors.muted,
                      ),
                      title: Text(c.name),
                      subtitle: Text(
                        '${c.district ?? ''} / ${c.city ?? ''}'.trim(),
                      ),
                      onTap: () => setModalState(() => selectedId = c.id),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Not'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  CheckboxListTile(
                    value: applyNow,
                    onChanged: (v) => setModalState(() => applyNow = v == true),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('AnÄ±nda birleÅŸtir (Zorla BirleÅŸtir)'),
                    subtitle: const Text(
                      'KapalÄ±ysa sadece merge talebi denetim kayda yazÄ±lÄ±r.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          final preview = await ref
                              .read(adminBusinessesRepositoryProvider)
                              .mergeBusinesses(
                                primaryBusinessId: selectedId,
                                duplicateBusinessId: source.id,
                                note: noteCtrl.text.trim(),
                                dryRun: true,
                              );
                          if (!ctx.mounted) return;
                          final summary =
                              (preview['summary'] as Map?)
                                  ?.cast<String, dynamic>() ??
                              const {};
                          final text =
                              'menus:${summary['menus'] ?? 0}, items:${summary['menu_items'] ?? 0}, reviews:${summary['reviews'] ?? 0}, media:${summary['media'] ?? 0}';
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Ã–nizleme: $text')),
                          );
                        },
                        child: const Text('Ã–nizleme'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          applyNow
                              ? 'BirleÅŸtir ve Uygula'
                              : 'BirleÅŸtirme Talebi OluÅŸtur',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (ok != true || !context.mounted) {
      noteCtrl.dispose();
      return;
    }
    try {
      if (applyNow) {
        final res = await ref
            .read(adminBusinessesRepositoryProvider)
            .mergeBusinesses(
              primaryBusinessId: selectedId,
              duplicateBusinessId: source.id,
              note: noteCtrl.text.trim(),
              dryRun: false,
            );
        final ok = res['ok'] == true;
        if (!ok) {
          throw Exception((res['error'] ?? 'merge_failed').toString());
        }
      } else {
        await ref
            .read(adminBusinessesRepositoryProvider)
            .logMergeProposal(
              primaryBusinessId: selectedId,
              duplicateBusinessId: source.id,
              note: noteCtrl.text.trim(),
            );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            applyNow
                ? 'BirleÅŸtirme tamamlandÄ±.'
                : 'BirleÅŸtirme talebi denetim kaydÄ±na eklendi.',
          ),
        ),
      );
      ref.read(adminBusinessesControllerProvider.notifier).refresh(force: true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      noteCtrl.dispose();
    }
  }
}

Widget _riskCell(BusinessRiskSignal? signal) {
  if (signal == null) {
    return const Text('-', style: TextStyle(color: AppColors.muted));
  }
  final text = signal.suspicious
      ? 'ÅÃ¼pheli'
      : (signal.riskScore >= 2 ? 'Orta' : 'DÃ¼ÅŸÃ¼k');
  final color = signal.suspicious
      ? AppColors.danger
      : (signal.riskScore >= 2 ? AppColors.warning : AppColors.success);
  return Tooltip(
    message:
        'Adres: ${signal.missingAddress ? 'yok' : 'var'} â€¢ Telefon: ${signal.missingPhone ? 'yok' : 'var'} â€¢ Foto: ${signal.photoCount} â€¢ EtkileÅŸim: ${signal.engagementCount}',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    ),
  );
}

Widget _logoPreview(String? url) {
  if (url == null || url.isEmpty) {
    return const SizedBox(
      width: 32,
      height: 32,
      child: Icon(Icons.image_not_supported),
    );
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: AppNetworkImage(
      url: url,
      variant: AppImageVariant.thumb,
      width: 32,
      height: 32,
      fit: BoxFit.cover,
    ),
  );
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
