import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../data/admin_businesses_repository.dart';
import '../data/admin_monetization_repository.dart';
import '../domain/admin_models.dart';

class AdminVerifiedPage extends ConsumerStatefulWidget {
  const AdminVerifiedPage({super.key});

  @override
  ConsumerState<AdminVerifiedPage> createState() => _AdminVerifiedPageState();
}

class _AdminVerifiedPageState extends ConsumerState<AdminVerifiedPage> {
  final searchCtrl = TextEditingController();
  List<AdminBusinessItem> items = [];
  bool loading = false;
  Object? error;

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Do?Yrulama / Premium',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(onPressed: _search, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'I?Yletme ara (isim/adres)',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _search,
                child: Text(loading ? 'Aranıyor...' : 'Ara'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (error != null)
            Text(
              AppErrorMapper.message(error),
              style: const TextStyle(color: AppColors.danger),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: loading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('İsim')),
                            DataColumn(label: Text('Şehir')),
                            DataColumn(label: Text('İlçe')),
                            DataColumn(label: Text('Do?Yrulama')),
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final b in items)
                              DataRow(
                                cells: [
                                  DataCell(Text(b.name)),
                                  DataCell(Text(b.city ?? '-')),
                                  DataCell(Text(b.district ?? '-')),
                                  DataCell(
                                    Text(b.isVerified ? 'Evet' : 'Hayır'),
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () => _openEdit(context, b),
                                      child: const Text('Düzenle'),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (!loading && items.isEmpty)
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

  Future<void> _search() async {
    final q = searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final repo = ref.read(adminBusinessesRepositoryProvider);
      final res = await repo.listBusinesses(limit: 20, offset: 0, query: q);
      setState(() => items = res);
    } catch (e) {
      setState(() => error = e);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _openEdit(BuildContext context, AdminBusinessItem b) async {
    var isVerified = b.isVerified;
    var tier = 'verified';
    final endsCtrl = TextEditingController();
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
                  .read(adminMonetizationRepositoryProvider)
                  .setBusinessVerified(
                    businessId: b.id,
                    isVerified: isVerified,
                    tier: tier,
                    endsAt: _parseDate(endsCtrl.text.trim()),
                  );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _search();
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Güncellendi.')));
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppErrorMapper.message(e))),
              );
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
                  'Do?Yrulama Ayarlari',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  b.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isVerified,
                  onChanged: (v) => setModalState(() => isVerified = v),
                  title: const Text('Do?Yrulama'),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey(tier),
                  initialValue: tier,
                  items: const [
                    DropdownMenuItem(
                      value: 'verified',
                      child: Text('Do?Yrulandi'),
                    ),
                    DropdownMenuItem(value: 'premium', child: Text('Premium')),
                  ],
                  onChanged: (v) => setModalState(() => tier = v ?? 'verified'),
                  decoration: const InputDecoration(labelText: 'Tier'),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: endsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Biti?Y (YYYY-MM-DD)',
                  ),
                ),
                const SizedBox(height: 12),
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

DateTime? _parseDate(String input) {
  if (input.isEmpty) return null;
  return DateTime.tryParse(input);
}
