import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../data/admin_monetization_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_sponsorship_packages_controller.dart';
import '../domain/admin_sponsorships_controller.dart';
import 'monetization/admin_sponsorship_form.dart';
import 'web_download.dart';

class AdminSponsorshipsPage extends ConsumerStatefulWidget {
  const AdminSponsorshipsPage({super.key});

  @override
  ConsumerState<AdminSponsorshipsPage> createState() =>
      _AdminSponsorshipsPageState();
}

class _AdminSponsorshipsPageState extends ConsumerState<AdminSponsorshipsPage> {
  final scrollCtrl = ScrollController();
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(adminSponsorshipsControllerProvider.notifier).loadMore();
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
    final st = ref.watch(adminSponsorshipsControllerProvider);
    final packages = ref
        .watch(adminSponsorshipPackagesControllerProvider)
        .items;
    final packagesById = {for (final p in packages) p.id: p};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Sponsorships',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: exporting ? null : () => _exportCsv(st),
                icon: const Icon(Icons.download),
                label: Text(exporting ? 'Indiriliyor...' : 'CSV Dışa Aktar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => const AdminSponsorshipCreateSheet(),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Sponsorluk'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => ref
                    .read(adminSponsorshipsControllerProvider.notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _filters(st),
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
                            DataColumn(label: Text('İşletme')),
                            DataColumn(label: Text('Yüzey')),
                            DataColumn(label: Text('Durum')),
                            DataColumn(label: Text('Tarih')),
                            DataColumn(label: Text('Paket')),
                            DataColumn(label: Text('Kota')),
                            DataColumn(label: Text('Oluşturma')),
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final item in st.items)
                              DataRow(
                                cells: [
                                  DataCell(Text(item.businessName)),
                                  DataCell(Text(item.surface)),
                                  DataCell(Text(item.status)),
                                  DataCell(
                                    Text(_range(item.startsAt, item.endsAt)),
                                  ),
                                  DataCell(
                                    Text(
                                      packagesById[item.packageId]?.name ??
                                          item.packageId,
                                    ),
                                  ),
                                  DataCell(
                                    Text(_caps(item.dailyCap, item.totalCap)),
                                  ),
                                  DataCell(Text(_fmtDate(item.createdAt))),
                                  DataCell(_actions(item)),
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

  Widget _filters(AdminSponsorshipsState st) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Wrap(spacing: 8, children: [])],
    );
  }

  Widget _actions(AdminSponsorshipItem item) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: () => _setStatus(item.id, 'active'),
          child: const Text('Aktif Et'),
        ),
        const SizedBox(width: 6),
        OutlinedButton(
          onPressed: () => _setStatus(item.id, 'paused'),
          child: const Text('Duraklat'),
        ),
        const SizedBox(width: 6),
        TextButton(
          onPressed: () => _setStatus(item.id, 'ended'),
          child: const Text('Bitir'),
        ),
      ],
    );
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await ref
          .read(adminMonetizationRepositoryProvider)
          .setSponsorshipStatus(sponsorshipId: id, status: status);
      ref.read(adminSponsorshipsControllerProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _exportCsv(AdminSponsorshipsState st) async {
    setState(() => exporting = true);
    try {
      final repo = ref.read(adminMonetizationRepositoryProvider);
      final rows = <AdminSponsorshipItem>[];
      var offset = 0;
      const limit = 200;
      while (true) {
        final batch = await repo.listSponsorships(
          status: st.statusFilter,
          surface: st.surfaceFilter,
          limit: limit,
          offset: offset,
        );
        rows.addAll(batch);
        if (batch.length < limit) break;
        offset += limit;
      }

      final csv = _buildCsv(rows);
      downloadCsv('sponsorships_${_stamp()}.csv', csv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }
}

String _caps(int? daily, int? total) {
  final d = daily == null ? '-' : daily.toString();
  final t = total == null ? '-' : total.toString();
  return 'D:$d / T:$t';
}

String _range(DateTime? s, DateTime? e) {
  if (s == null && e == null) return '-';
  final ss = s == null ? 'âˆ' : _fmtDate(s);
  final ee = e == null ? 'âˆ' : _fmtDate(e);
  return '$ss â†’ $ee';
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _csvEscape(String v) {
  final s = v.replaceAll('"', '""');
  return '"$s"';
}

String _buildCsv(List<AdminSponsorshipItem> rows) {
  final buf = StringBuffer();
  buf.writeln(
    [
      'id',
      'status',
      'surface',
      'created_at',
      'business_id',
      'business_name',
      'city',
      'district',
      'package_id',
      'starts_at',
      'ends_at',
      'daily_cap',
      'total_cap',
      'source',
      'created_by',
    ].join(','),
  );
  for (final r in rows) {
    buf.writeln(
      [
        _csvEscape(r.id),
        _csvEscape(r.status),
        _csvEscape(r.surface),
        _csvEscape(r.createdAt.toIso8601String()),
        _csvEscape(r.businessId),
        _csvEscape(r.businessName),
        _csvEscape(r.city ?? ''),
        _csvEscape(r.district ?? ''),
        _csvEscape(r.packageId),
        _csvEscape(r.startsAt?.toIso8601String() ?? ''),
        _csvEscape(r.endsAt?.toIso8601String() ?? ''),
        _csvEscape(r.dailyCap?.toString() ?? ''),
        _csvEscape(r.totalCap?.toString() ?? ''),
        _csvEscape(r.source),
        _csvEscape(r.createdBy ?? ''),
      ].join(','),
    );
  }
  return buf.toString();
}

String _stamp() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  return '$y$m${d}_$hh$mm';
}
