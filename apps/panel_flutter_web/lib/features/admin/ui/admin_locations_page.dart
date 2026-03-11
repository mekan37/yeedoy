import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../domain/admin_locations_controller.dart';

class AdminLocationsPage extends ConsumerStatefulWidget {
  const AdminLocationsPage({super.key});

  @override
  ConsumerState<AdminLocationsPage> createState() => _AdminLocationsPageState();
}

class _AdminLocationsPageState extends ConsumerState<AdminLocationsPage> {
  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  String table = 'businesses';
  String column = 'city';
  bool caseInsensitive = true;
  bool submitting = false;

  @override
  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminLocationsControllerProvider);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminLocationsTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: table,
                  items: [
                    DropdownMenuItem(
                      value: 'businesses',
                      child: Text(l10n.adminLocationsTableBusinesses),
                    ),
                    DropdownMenuItem(
                      value: 'business_suggestions',
                      child: Text(l10n.adminLocationsTableBusinessSuggestions),
                    ),
                  ],
                  onChanged: (v) => setState(() => table = v ?? table),
                  decoration: InputDecoration(
                    labelText: l10n.adminLocationsTableLabel,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: column,
                  items: [
                    DropdownMenuItem(value: 'city', child: Text(l10n.city)),
                    DropdownMenuItem(
                      value: 'district',
                      child: Text(l10n.district),
                    ),
                  ],
                  onChanged: (v) => setState(() => column = v ?? column),
                  decoration: InputDecoration(
                    labelText: l10n.adminLocationsFieldLabel,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Checkbox(
                    value: caseInsensitive,
                    onChanged: (v) => setState(() => caseInsensitive = v ?? true),
                  ),
                  Text(l10n.adminLocationsCaseInsensitive),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: fromCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.adminLocationsFromLabel,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: toCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.adminLocationsToLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: st.isLoading || submitting
                    ? null
                    : () async {
                        try {
                          final count =
                              await ref.read(adminLocationsControllerProvider.notifier).preview(
                                table: table,
                                column: column,
                                from: fromCtrl.text.trim(),
                                caseInsensitive: caseInsensitive,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.adminLocationsAffectedCount(count),
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppErrorMapper.message(e))),
                          );
                        }
                      },
                child: Text(
                  st.isLoading ? l10n.adminLocationsChecking : l10n.preview,
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: st.isLoading || submitting
                    ? null
                    : () async {
                        final from = fromCtrl.text.trim();
                        final to = toCtrl.text.trim();
                        if (from.isEmpty || to.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.adminLocationsValuesRequired),
                            ),
                          );
                          return;
                        }
                        final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.adminLocationsConfirmTitle),
                                content: Text(
                                  l10n.adminLocationsConfirmMessage(from, to),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(l10n.cancel),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(l10n.apply),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (!ok) return;
                        setState(() => submitting = true);
                        try {
                          await ref.read(adminLocationsControllerProvider.notifier).apply(
                                table: table,
                                column: column,
                                from: from,
                                to: to,
                                caseInsensitive: caseInsensitive,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.adminCommonUpdated)),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppErrorMapper.message(e))),
                          );
                        } finally {
                          if (mounted) setState(() => submitting = false);
                        }
                      },
                child: Text(
                  submitting ? l10n.adminLocationsApplying : l10n.apply,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (st.previewCount > 0)
            Text(
              l10n.adminLocationsAffectedCount(st.previewCount),
              style: const TextStyle(color: AppColors.muted),
            ),
          if (st.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                AppErrorMapper.message(st.error),
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}





