import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../data/admin_monetization_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_sponsorship_leads_controller.dart';
import 'monetization/admin_sponsorship_form.dart';
import '../../../shared/ui/design_system.dart';

class AdminSponsorshipLeadsPage extends ConsumerStatefulWidget {
  const AdminSponsorshipLeadsPage({super.key});

  @override
  ConsumerState<AdminSponsorshipLeadsPage> createState() =>
      _AdminSponsorshipLeadsPageState();
}

class _AdminSponsorshipLeadsPageState
    extends ConsumerState<AdminSponsorshipLeadsPage> {
  final scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(adminSponsorshipLeadsControllerProvider.notifier).loadMore();
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
    final st = ref.watch(adminSponsorshipLeadsControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Sponsor Talepleri',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => ref
                    .read(adminSponsorshipLeadsControllerProvider.notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              AppFilterChip(
                label: 'Tümü',
                selected: st.statusFilter.isEmpty,
                onTap: () => ref
                    .read(adminSponsorshipLeadsControllerProvider.notifier)
                    .setStatusFilter(''),
              ),
              AppFilterChip(
                label: 'Yeni',
                selected: st.statusFilter == 'new',
                onTap: () => ref
                    .read(adminSponsorshipLeadsControllerProvider.notifier)
                    .setStatusFilter('new'),
              ),
              AppFilterChip(
                label: 'İletişime Geçildi',
                selected: st.statusFilter == 'contacted',
                onTap: () => ref
                    .read(adminSponsorshipLeadsControllerProvider.notifier)
                    .setStatusFilter('contacted'),
              ),
              AppFilterChip(
                label: 'Kapandı',
                selected: st.statusFilter == 'closed',
                onTap: () => ref
                    .read(adminSponsorshipLeadsControllerProvider.notifier)
                    .setStatusFilter('closed'),
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
                            DataColumn(label: Text('İletişim')),
                            DataColumn(label: Text('Yüzey')),
                            DataColumn(label: Text('Durum')),
                            DataColumn(label: Text('İşletme Sahibi')),
                            DataColumn(label: Text('Oluşturan')),
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final lead in st.items)
                              DataRow(
                                cells: [
                                  DataCell(Text(lead.businessName)),
                                  DataCell(Text(lead.preferredSurface)),
                                  DataCell(Text(lead.status)),
                                  DataCell(Text(_short(lead.ownerUserId))),
                                  DataCell(Text(_fmtDate(lead.createdAt))),
                                  DataCell(
                                    TextButton(
                                      onPressed: () =>
                                          _openDetail(context, lead),
                                      child: const Text('Detay'),
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

  Future<void> _openDetail(
    BuildContext context,
    AdminSponsorshipLead lead,
  ) async {
    var status = lead.status;
    var saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> saveStatus() async {
            setModalState(() => saving = true);
            try {
              await ref
                  .read(adminMonetizationRepositoryProvider)
                  .updateLeadStatus(leadId: lead.id, status: status);
              await ref
                  .read(adminSponsorshipLeadsControllerProvider.notifier)
                  .refresh();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
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
                const Text(
                  'Lead Detayı',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text('İşletme: ${lead.businessName}'),
                Text('İşletme Sahibi: ${lead.ownerUserId}'),
                if ((lead.phone ?? '').isNotEmpty)
                  Text('Telefon: ${lead.phone}'),
                if ((lead.message ?? '').isNotEmpty)
                  Text('Mesaj: ${lead.message}'),
                const SizedBox(height: 8),
                Text('Hedeflenen: ${_fmtTargeting(lead.preferredTargeting)}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(status),
                  initialValue: status,
                  items: const [
                    DropdownMenuItem(value: 'new', child: Text('Yeni')),
                    DropdownMenuItem(
                      value: 'contacted',
                      child: Text('İletişime Geçildi'),
                    ),
                    DropdownMenuItem(value: 'closed', child: Text('Kapandı')),
                  ],
                  onChanged: (v) => setModalState(() => status = v ?? 'new'),
                  decoration: const InputDecoration(labelText: 'Durum'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: saving ? null : saveStatus,
                        child: Text(saving ? 'Kaydediliyor...' : 'Kaydet'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => AdminSponsorshipCreateSheet(
                            initialBusiness: AdminBusinessItem(
                              id: lead.businessId,
                              name: lead.businessName,
                              createdAt: lead.createdAt,
                              city: lead.city,
                              district: lead.district,
                            ),
                            initialSurface: lead.preferredSurface,
                            initialTargeting: lead.preferredTargeting,
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Sponsorluk Oluştur'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _fmtTargeting(Map<String, dynamic> t) {
  final c = (t['city'] as List?)?.join(',') ?? '';
  final d = (t['district'] as List?)?.join(',') ?? '';
  final k = (t['category'] as List?)?.join(',') ?? '';
  final parts = [
    if (c.isNotEmpty) 'city=[$c]',
    if (d.isNotEmpty) 'district=[$d]',
    if (k.isNotEmpty) 'category=[$k]',
  ];
  return parts.isEmpty ? '-' : parts.join(' ');
}

String _short(String id) => id.length > 8 ? '${id.substring(0, 8)}...' : id;

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
