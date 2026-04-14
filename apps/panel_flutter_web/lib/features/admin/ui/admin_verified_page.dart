import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/panel_page_header.dart';
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
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelPageHeader(
            padding: EdgeInsets.zero,
            title: Text(l10n.adminVerifiedTitle),
            actions: [
              IconButton(onPressed: _search, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.adminVerifiedSearchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _search,
                child: Text(
                  loading
                      ? l10n.adminVerifiedSearching
                      : l10n.adminVerifiedSearchAction,
                ),
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
                          columns: [
                            DataColumn(
                              label: Text(l10n.adminSuggestionsNameColumn),
                            ),
                            DataColumn(label: Text(l10n.city)),
                            DataColumn(label: Text(l10n.district)),
                            DataColumn(
                              label: Text(l10n.adminVerifiedVerificationColumn),
                            ),
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
                                    Text(
                                      b.isVerified
                                          ? l10n.adminVerifiedYes
                                          : l10n.adminVerifiedNo,
                                    ),
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () => _openEdit(context, b),
                                      child: Text(l10n.duzenle),
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
    final l10n = context.l10n;
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
                  l10n.adminVerifiedSettingsTitle,
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
                  title: Text(l10n.adminVerifiedVerificationColumn),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey(tier),
                  initialValue: tier,
                  items: [
                    DropdownMenuItem(
                      value: 'verified',
                      child: Text(l10n.adminVerifiedTierVerified),
                    ),
                    DropdownMenuItem(
                      value: 'premium',
                      child: Text(l10n.adminVerifiedTierPremium),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => tier = v ?? 'verified'),
                  decoration: InputDecoration(
                    labelText: l10n.adminVerifiedTierLabel,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: endsCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.adminVerifiedEndsAtLabel,
                  ),
                ),
                const SizedBox(height: 12),
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

DateTime? _parseDate(String input) {
  if (input.isEmpty) return null;
  return DateTime.tryParse(input);
}
