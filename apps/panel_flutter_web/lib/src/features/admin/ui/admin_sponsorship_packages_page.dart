import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../domain/admin_models.dart';
import '../domain/admin_sponsorship_packages_controller.dart';

class AdminSponsorshipPackagesPage extends ConsumerStatefulWidget {
  const AdminSponsorshipPackagesPage({super.key});

  @override
  ConsumerState<AdminSponsorshipPackagesPage> createState() =>
      _AdminSponsorshipPackagesPageState();
}

class _AdminSponsorshipPackagesPageState
    extends ConsumerState<AdminSponsorshipPackagesPage> {
  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminSponsorshipPackagesControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Sponsor Paketleri',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openPackageSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Paket'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => ref
                    .read(adminSponsorshipPackagesControllerProvider.notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh),
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
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('İsim')),
                            DataColumn(label: Text('Yüzey')),
                            DataColumn(label: Text('Süre')),
                            DataColumn(label: Text('Fiyat')),
                            DataColumn(label: Text('Aktif')),
                            DataColumn(label: Text('Oluşturma')),
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final p in st.items)
                              DataRow(
                                cells: [
                                  DataCell(Text(p.name)),
                                  DataCell(Text(p.surface)),
                                  DataCell(Text('${p.durationDays} gün')),
                                  DataCell(Text(p.priceDisplay)),
                                  DataCell(
                                    Switch(
                                      value: p.isActive,
                                      onChanged: (v) => _toggleActive(p, v),
                                    ),
                                  ),
                                  DataCell(Text(_fmtDate(p.createdAt))),
                                  DataCell(
                                    TextButton(
                                      onPressed: () =>
                                          _openPackageSheet(context, item: p),
                                      child: const Text('Düzenle'),
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
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(AdminSponsorshipPackage item, bool v) async {
    try {
      await ref
          .read(adminSponsorshipPackagesControllerProvider.notifier)
          .upsertPackage(
            id: item.id,
            name: item.name,
            surface: item.surface,
            durationDays: item.durationDays,
            priceDisplay: item.priceDisplay,
            isActive: v,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _openPackageSheet(
    BuildContext context, {
    AdminSponsorshipPackage? item,
  }) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final durationCtrl = TextEditingController(
      text: item?.durationDays.toString() ?? '',
    );
    final priceCtrl = TextEditingController(text: item?.priceDisplay ?? '');
    var surface = item?.surface ?? 'discovery';
    var isActive = item?.isActive ?? true;
    var saving = false;

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
                  .read(adminSponsorshipPackagesControllerProvider.notifier)
                  .upsertPackage(
                    id: item?.id,
                    name: nameCtrl.text.trim(),
                    surface: surface,
                    durationDays: int.tryParse(durationCtrl.text.trim()) ?? 0,
                    priceDisplay: priceCtrl.text.trim(),
                    isActive: isActive,
                  );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Kaydedildi.')));
            } catch (e) {
              if (ctx.mounted) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item == null ? 'Yeni Paket' : 'Paket Düzenle',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'İsim'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(surface),
                  initialValue: surface,
                  items: const [
                    DropdownMenuItem(value: 'discovery', child: Text('Keşfet')),
                    DropdownMenuItem(
                      value: 'business_page',
                      child: Text('İşletme Sayfası'),
                    ),
                    DropdownMenuItem(
                      value: 'verified',
                      child: Text('Doğrulandı'),
                    ),
                    DropdownMenuItem(value: 'premium', child: Text('Premium')),
                  ],
                  onChanged: (v) =>
                      setModalState(() => surface = v ?? 'discovery'),
                  decoration: const InputDecoration(labelText: 'Yüzey'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Süre (gün)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Fiyat Gösterim',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isActive,
                  onChanged: (v) => setModalState(() => isActive = v),
                  title: const Text('Aktif'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(saving ? 'Kaydediliyor...' : 'Kaydet'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
