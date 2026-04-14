import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/panel_page_header.dart';
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
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelPageHeader(
            padding: EdgeInsets.zero,
            title: Text(l10n.adminSponsorshipPackagesTitle),
            actions: [
              FilledButton.icon(
                onPressed: () => _openPackageSheet(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.adminSponsorshipPackagesNewPackage),
              ),
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
                          columns: [
                            DataColumn(
                              label: Text(l10n.adminSponsorshipPackagesNameColumn),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipsSurfaceColumn),
                            ),
                            DataColumn(
                              label: Text(
                                l10n.adminSponsorshipPackagesDurationColumn,
                              ),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipPackagesPriceColumn),
                            ),
                            DataColumn(
                              label: Text(
                                l10n.adminSponsorshipPackagesInventoryColumn,
                              ),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipPackagesActiveColumn),
                            ),
                            DataColumn(
                              label: Text(
                                l10n.adminSponsorshipPackagesCreatedAtColumn,
                              ),
                            ),
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final p in st.items)
                              DataRow(
                                cells: [
                                  DataCell(Text(p.name)),
                                  DataCell(Text(_surfaceLabel(context, p.surface))),
                                  DataCell(
                                    Text(
                                      l10n.adminSponsorshipPackagesDurationValue(
                                        p.durationDays,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(p.priceDisplay),
                                        Text(
                                          _formatMoneyCents(
                                            p.priceCents,
                                            p.currencyCode,
                                          ),
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text('${p.inventoryLimit}')),
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
                                      child: Text(l10n.duzenle),
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
            priceCents: item.priceCents,
            currencyCode: item.currencyCode,
            inventoryLimit: item.inventoryLimit,
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
    final l10n = context.l10n;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final durationCtrl = TextEditingController(
      text: item?.durationDays.toString() ?? '',
    );
    final priceCtrl = TextEditingController(text: item?.priceDisplay ?? '');
    final priceCentsCtrl = TextEditingController(
      text: item?.priceCents.toString() ?? '',
    );
    final inventoryCtrl = TextEditingController(
      text: item?.inventoryLimit.toString() ?? '1',
    );
    var surface = item?.surface ?? 'discovery';
    var currencyCode = item?.currencyCode ?? 'TRY';
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
                    priceCents: int.tryParse(priceCentsCtrl.text.trim()) ?? 0,
                    currencyCode: currencyCode.trim().toUpperCase(),
                    inventoryLimit:
                        int.tryParse(inventoryCtrl.text.trim()) ?? 1,
                    isActive: isActive,
                  );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.adminCommonSaved)));
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
                  item == null
                      ? l10n.adminSponsorshipPackagesNewPackage
                      : l10n.adminSponsorshipPackagesEditPackage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.adminSponsorshipPackagesNameColumn,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(surface),
                  initialValue: surface,
                  items: [
                    DropdownMenuItem(
                      value: 'discovery',
                      child: Text(
                        l10n.adminSponsorshipPackagesSurfaceDiscovery,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'business_page',
                      child: Text(
                        l10n.adminSponsorshipPackagesSurfaceBusinessPage,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'verified',
                      child: Text(
                        l10n.adminSponsorshipPackagesSurfaceVerified,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'stories',
                      child: Text(
                        l10n.adminSponsorshipPackagesSurfaceStories,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'premium',
                      child: Text(
                        l10n.adminSponsorshipPackagesSurfacePremium,
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setModalState(() => surface = v ?? 'discovery'),
                  decoration: InputDecoration(
                    labelText: l10n.adminSponsorshipsSurfaceColumn,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.adminSponsorshipPackagesDurationInput,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.adminSponsorshipPackagesPriceInput,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCentsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText:
                              l10n.adminSponsorshipPackagesPriceAmountInput,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(currencyCode),
                        initialValue: currencyCode,
                        items: const [
                          DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        ],
                        onChanged: (v) =>
                            setModalState(() => currencyCode = v ?? 'TRY'),
                        decoration: InputDecoration(
                          labelText: l10n.adminSponsorshipPackagesCurrencyInput,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: inventoryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.adminSponsorshipPackagesInventoryInput,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isActive,
                  onChanged: (v) => setModalState(() => isActive = v),
                  title: Text(l10n.adminSponsorshipPackagesActiveColumn),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(saving ? l10n.saving : l10n.save),
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

String _surfaceLabel(BuildContext context, String surface) {
  final l10n = context.l10n;
  switch (surface) {
    case 'discovery':
      return l10n.adminSponsorshipPackagesSurfaceDiscovery;
    case 'business_page':
      return l10n.adminSponsorshipPackagesSurfaceBusinessPage;
    case 'verified':
      return l10n.adminSponsorshipPackagesSurfaceVerified;
    case 'stories':
      return l10n.adminSponsorshipPackagesSurfaceStories;
    case 'premium':
      return l10n.adminSponsorshipPackagesSurfacePremium;
    default:
      return surface;
  }
}

String _formatMoneyCents(int amount, String currencyCode) {
  final whole = amount / 100;
  return '${whole.toStringAsFixed(2)} $currencyCode';
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
