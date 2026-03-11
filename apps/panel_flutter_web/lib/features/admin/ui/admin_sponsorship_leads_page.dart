import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
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
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.adminSponsorshipLeadsTitle,
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
                label: l10n.tumu,
                selected: st.statusFilter.isEmpty,
                onTap: () => ref
                    .read(adminSponsorshipLeadsControllerProvider.notifier)
                    .setStatusFilter(''),
              ),
              AppFilterChip(
                label: l10n.adminSponsorshipLeadStatusNew,
                selected: st.statusFilter == 'new',
                onTap: () => ref
                    .read(adminSponsorshipLeadsControllerProvider.notifier)
                    .setStatusFilter('new'),
              ),
              AppFilterChip(
                label: l10n.adminSponsorshipLeadStatusContacted,
                selected: st.statusFilter == 'contacted',
                onTap: () => ref
                    .read(adminSponsorshipLeadsControllerProvider.notifier)
                    .setStatusFilter('contacted'),
              ),
              AppFilterChip(
                label: l10n.adminSponsorshipLeadStatusClosed,
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
                            DataColumn(
                              label: Text(l10n.adminSponsorshipLeadsContactColumn),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipsSurfaceColumn),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipsStatusColumn),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipLeadsOwnerColumn),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipLeadsCreatedAtColumn),
                            ),
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final lead in st.items)
                              DataRow(
                                cells: [
                                  DataCell(Text(lead.businessName)),
                                  DataCell(
                                    Text(
                                      _surfaceLabel(
                                        context,
                                        lead.preferredSurface,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(_leadStatusLabel(context, lead.status)),
                                  ),
                                  DataCell(Text(_short(lead.ownerUserId))),
                                  DataCell(Text(_fmtDate(lead.createdAt))),
                                  DataCell(
                                    TextButton(
                                      onPressed: () =>
                                          _openDetail(context, lead),
                                      child: Text(l10n.adminCommonDetails),
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
                          child: Center(
                            child: Text(l10n.adminCommonNoRecordsFound),
                          ),
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
    final l10n = context.l10n;
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
              ).showSnackBar(SnackBar(content: Text(l10n.adminCommonUpdated)));
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
                  l10n.adminSponsorshipLeadsDetailTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text('${l10n.businessLabel}: ${lead.businessName}'),
                Text(
                  '${l10n.adminSponsorshipLeadsOwnerColumn}: ${lead.ownerUserId}',
                ),
                if ((lead.phone ?? '').isNotEmpty)
                  Text('${l10n.adminSponsorshipLeadsPhoneLabel}: ${lead.phone}'),
                if ((lead.message ?? '').isNotEmpty)
                  Text('${l10n.adminSponsorshipLeadsMessageLabel}: ${lead.message}'),
                const SizedBox(height: 8),
                Text(
                  '${l10n.adminSponsorshipLeadsTargetingLabel}: ${_fmtTargeting(lead.preferredTargeting)}',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(status),
                  initialValue: status,
                  items: [
                    DropdownMenuItem(
                      value: 'new',
                      child: Text(l10n.adminSponsorshipLeadStatusNew),
                    ),
                    DropdownMenuItem(
                      value: 'contacted',
                      child: Text(l10n.adminSponsorshipLeadStatusContacted),
                    ),
                    DropdownMenuItem(
                      value: 'closed',
                      child: Text(l10n.adminSponsorshipLeadStatusClosed),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => status = v ?? 'new'),
                  decoration: InputDecoration(
                    labelText: l10n.adminSponsorshipsStatusColumn,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: saving ? null : saveStatus,
                        child: Text(saving ? l10n.saving : l10n.save),
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
                      label: Text(l10n.adminSponsorshipLeadsCreateSponsorship),
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

String _leadStatusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  switch (status) {
    case 'new':
      return l10n.adminSponsorshipLeadStatusNew;
    case 'contacted':
      return l10n.adminSponsorshipLeadStatusContacted;
    case 'closed':
      return l10n.adminSponsorshipLeadStatusClosed;
    default:
      return status;
  }
}

String _surfaceLabel(BuildContext context, String surface) {
  final l10n = context.l10n;
  switch (surface) {
    case 'discovery':
      return l10n.adminSponsorshipPackagesSurfaceDiscovery;
    case 'business_page':
      return l10n.adminSponsorshipPackagesSurfaceBusinessPage;
    case 'verified':
      return l10n.adminSponsorshipPackagesSurfaceVerified;
    case 'premium':
      return l10n.adminSponsorshipPackagesSurfacePremium;
    default:
      return surface;
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
