import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../data/admin_b2b_exports_repository.dart';
import 'web_download.dart';

class AdminB2bExportsPage extends ConsumerStatefulWidget {
  const AdminB2bExportsPage({super.key});

  @override
  ConsumerState<AdminB2bExportsPage> createState() =>
      _AdminB2bExportsPageState();
}

class _AdminB2bExportsPageState extends ConsumerState<AdminB2bExportsPage> {
  int _days = 30;
  bool _loadingTrends = false;
  bool _loadingIndex = false;
  bool _loadingInflation = false;
  bool _loadingAnomalies = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'B2B Veri Ihraci',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'B2B Insights: fiyat endeksi + bolgesel trend raporlari CSV olarak indirilebilir.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _InsightChip(label: 'Fiyat Endeksi'),
              _InsightChip(label: 'Bolgesel Trend'),
              _InsightChip(label: 'Menu Enflasyonu'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Donem:'),
              DropdownButton<int>(
                value: _days,
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 gun')),
                  DropdownMenuItem(value: 30, child: Text('30 gun')),
                  DropdownMenuItem(value: 90, child: Text('90 gun')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _days = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ExportCard(
            title: 'Anonim Trend Verisi',
            description:
                'Gun, sehir, ilce ve etkinlik bazinda anonimlestirilmis trend kaydi.',
            loading: _loadingTrends,
            onExport: _exportAnonymousTrends,
          ),
          const SizedBox(height: 12),
          _ExportCard(
            title: 'Bolgesel Fiyat Endeksi',
            description:
                'Sehir/ilce bazinda ortalama ve medyan fiyat, onceki doneme gore degisim.',
            loading: _loadingIndex,
            onExport: _exportRegionalPriceIndex,
          ),
          const SizedBox(height: 12),
          _ExportCard(
            title: 'Menu Enflasyonu Raporu',
            description:
                'Urun bazinda donem icindeki ilk/son fiyat ve enflasyon yuzdesi.',
            loading: _loadingInflation,
            onExport: _exportMenuInflation,
          ),
          const SizedBox(height: 12),
          _ExportCard(
            title: 'Fiyat Anomali Raporu',
            description:
                'Kisa surede asiri fiyat artis/yukselis yapan urunleri listeler.',
            loading: _loadingAnomalies,
            onExport: _exportPriceAnomalies,
          ),
        ],
      ),
    );
  }

  Future<void> _exportAnonymousTrends() async {
    setState(() => _loadingTrends = true);
    try {
      final csv = await ref
          .read(adminB2bExportsRepositoryProvider)
          .exportAnonymousTrendsCsv(days: _days);
      if (!mounted) return;
      downloadCsv('b2b_anonymous_trends_${_stamp()}.csv', csv);
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _loadingTrends = false);
    }
  }

  Future<void> _exportRegionalPriceIndex() async {
    setState(() => _loadingIndex = true);
    try {
      final csv = await ref
          .read(adminB2bExportsRepositoryProvider)
          .exportRegionalPriceIndexCsv(days: _days);
      if (!mounted) return;
      downloadCsv('b2b_regional_price_index_${_stamp()}.csv', csv);
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _loadingIndex = false);
    }
  }

  Future<void> _exportMenuInflation() async {
    setState(() => _loadingInflation = true);
    try {
      final csv = await ref
          .read(adminB2bExportsRepositoryProvider)
          .exportMenuInflationCsv(days: _days);
      if (!mounted) return;
      downloadCsv('b2b_menu_inflation_${_stamp()}.csv', csv);
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _loadingInflation = false);
    }
  }

  Future<void> _exportPriceAnomalies() async {
    setState(() => _loadingAnomalies = true);
    try {
      final csv = await ref
          .read(adminB2bExportsRepositoryProvider)
          .exportPriceAnomaliesCsv(days: _days, thresholdPct: 40);
      if (!mounted) return;
      downloadCsv('b2b_price_anomalies_${_stamp()}.csv', csv);
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _loadingAnomalies = false);
    }
  }

  void _snackError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
  }

  String _stamp() {
    final now = DateTime.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.title,
    required this.description,
    required this.loading,
    required this.onExport,
  });

  final String title;
  final String description;
  final bool loading;
  final Future<void> Function() onExport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: loading ? null : onExport,
              icon: const Icon(Icons.download_outlined),
              label: Text(loading ? 'Hazirlaniyor...' : 'CSV indir'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textStrong,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
